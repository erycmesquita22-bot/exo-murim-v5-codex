extends RefCounted
## Pure, deterministic crowd planner. Does not create actors, AI, inventory, collisions or saves.
const ALLOWED_ROLES = ["resident", "merchant", "disciple", "guard", "traveler"]
const ALLOWED_ACTIONS = ["walk", "idle", "talk", "observe"]

static func stable_seed(source: String) -> int:
	var value: int = 2166136261
	for byte_value in source.to_utf8_buffer():
		value = ((value ^ int(byte_value)) * 16777619) & 0xffffffff
	return value

static func valid_zone(z: Dictionary) -> bool:
	if str(z.get("id", "")).is_empty() or str(z.get("id", "")).length() > 128:
		return false
	if not z.get("points", null) is Array or z["points"].size() < 2 or z["points"].size() > 64:
		return false
	if str(z.get("role", "resident")) not in ALLOWED_ROLES:
		return false
	if str(z.get("activity", "walk")) not in ALLOWED_ACTIONS:
		return false
	if not z.get("capacity") is int or int(z.get("capacity", 0)) < 0 or int(z.get("capacity", 0)) > 60:
		return false
	for name in ["lateral", "safety_radius"]:
		if z.has(name) and (not (z[name] is float or z[name] is int) or not is_finite(float(z[name]))):
			return false
	if float(z.get("lateral", 0.6)) < 0.0 or float(z.get("lateral", 0.6)) > 3.5:
		return false
	if float(z.get("safety_radius", 1.8)) < 0.0 or float(z.get("safety_radius", 1.8)) > 20.0:
		return false
	var distinct := false
	var prior := Vector3.ZERO
	var previous_present := false
	for p in z["points"]:
		if not p is Array or p.size() != 3:
			return false
		for axis in p:
			if not (axis is int or axis is float) or not is_finite(float(axis)):
				return false
		var at: Vector3 = _point(p)
		if not at.is_finite() or absf(at.x) > 100000 or absf(at.y) > 100000 or absf(at.z) > 100000:
			return false
		if previous_present and at.distance_squared_to(prior) > 0.01:
			distinct = true
		prior = at
		previous_present = true
	# Zero-distance lanes have no meaningful crowd movement.
	if not distinct:
		return false
	return true

static func _point(p: Array) -> Vector3:
	return Vector3(float(p[0]), float(p[1]), float(p[2]))

static func _walk_route(points: Array, ratio: float) -> Vector3:
	var segments: Array[float] = []
	var total := 0.0
	for i in range(points.size() - 1):
		var length := _point(points[i]).distance_to(_point(points[i + 1]))
		segments.append(length)
		total += length
	if total < 0.1:
		return _point(points[0])
	var distance := ratio * total
	for i in range(segments.size()):
		if distance <= segments[i] or i == segments.size() - 1:
			return _point(points[i]).lerp(_point(points[i + 1]), clampf(distance / maxf(0.001, segments[i]), 0.0, 1.0))
		distance -= segments[i]
	return _point(points[points.size() - 1])

static func _route_length(route: Array) -> float:
	var total: float = 0.0
	for i in range(route.size()-1):total+=route[i].distance_to(route[i+1])
	return total

static func _walk_route_vectors(route: Array, ratio: float) -> Vector3:
	var distance: float = clampf(ratio,0.0,1.0)*_route_length(route)
	for i in range(route.size()-1):
		var length: float = route[i].distance_to(route[i+1])
		if distance<=length:return route[i].lerp(route[i+1],clampf(distance/maxf(0.000001,length),0.0,1.0))
		distance-=length
	return route[-1]

static func _subroute(points: Array, start_m: float, end_m: float) -> Array:
	var route: Array = []
	var all_points: Array = []
	for p in points:all_points.append(_point(p))
	var total: float = _route_length(all_points)
	route.append(_walk_route_vectors(all_points,start_m/total))
	var distance: float = 0.0
	for i in range(1,all_points.size()):
		distance+=all_points[i-1].distance_to(all_points[i])
		if distance>start_m and distance<end_m:route.append(all_points[i])
	route.append(_walk_route_vectors(all_points,end_m/total))
	return route

static func _far_from_reserved(point: Vector3, reserved: Array, radius: float) -> bool:
	for item in reserved:
		var check := Vector3.ZERO
		if item is Vector3 and item.is_finite():
			check = item
		elif item is Array and item.size() == 3:
			var valid := true
			for axis in item:
				if not (axis is int or axis is float) or not is_finite(float(axis)):
					valid = false
					break
			if not valid:
				continue
			check = _point(item)
		else:
			continue
		if Vector2(point.x, point.z).distance_to(Vector2(check.x, check.z)) < radius:
			return false
	return true

static func plan(z: Dictionary, world_seed: String, density: float = 1.0, reserved: Array = []) -> Dictionary:
	if not valid_zone(z):
		return {"ok": false, "reason": "invalid_zone", "agents": []}
	var seed_string := world_seed + "|" + str(z["id"])
	var rng := RandomNumberGenerator.new()
	rng.seed = stable_seed(seed_string)
	if not is_finite(density):
		return {"ok": false, "reason": "nonfinite_density", "agents": []}
	var count := clampi(int(round(float(z["capacity"]) * clampf(density, 0.0, 1.0))), 0, 60)
	var agents: Array = []
	var points: Array = z["points"]
	var role := str(z.get("role", "resident"))
	var activity := str(z.get("activity", "walk"))
	var lateral := clampf(float(z.get("lateral", 0.6)), 0.0, 3.5)
	var all_points: Array = []
	for p in points:all_points.append(_point(p))
	var lane_length: float = _route_length(all_points)
	# Use arc length, NOT adjacent sample spacing: the host certifies every 0.25 m.
	# Current physical lanes are 12 m, so a fabricated 16 m gate blocks all crowd.
	if activity == "walk" and lane_length < 9.0:
		return {"ok":false,"reason":"walk_lane_too_short","agents":[]}
	for i in range(count):
		var progress: float = clampf((float(i)+0.35+rng.randf()*0.3)/maxf(1.0,float(count)),0.01,0.99)
		var span_m: float = rng.randf_range(9.0,minf(16.0,lane_length)) if activity=="walk" else 0.0
		var start_m: float = progress*maxf(0.0,lane_length-span_m)
		var route: Array = _subroute(points,start_m,start_m+span_m) if activity=="walk" else [_walk_route(points,progress)]
		# Bidirectional pedestrians use separate lateral tracks; nobody reverses at the end.
		if i%2==1:route.reverse()
		var unshifted: Array = route.duplicate()
		for j in range(route.size()):
			var tangent: Vector3 = unshifted[mini(j+1,route.size()-1)]-unshifted[maxi(j-1,0)]
			var normal := Vector3(-tangent.z,0,tangent.x).normalized()
			route[j]+=normal*lateral
		var safety_radius: float = maxf(1.3,float(z.get("safety_radius",1.8)))
		var route_ok: bool = true
		for j in range(maxi(1,route.size()-1)):
			var a: Vector3 = route[j];var b: Vector3 = route[mini(j+1,route.size()-1)]
			var steps: int = maxi(1,ceili(a.distance_to(b)/0.25))
			for k in range(steps+1):
				if not _far_from_reserved(a.lerp(b,float(k)/steps),reserved,safety_radius):route_ok=false;break
			if not route_ok:break
		if not route_ok:continue
		var first: Vector3 = route[0];var last: Vector3 = route[-1]
		var tangent: Vector3 = (last-first).normalized()
		var walking: bool = activity=="walk"
		agents.append({
			"id":"crowd/"+str(z["id"])+"/"+str(i),"role":role,"activity":activity,
			"position":first,"a":first,"b":last,"route":route,"route_length":_route_length(route),
			"speed":rng.randf_range(0.65,1.0) if walking else 0.0,"phase":0.0,
			"motion_phase":rng.randf_range(0.0,TAU),"skin_slot":rng.randi_range(0,63),
			"yaw":atan2(tangent.x,tangent.z),"scale":rng.randf_range(0.93,1.06)
		})
	return {"ok":true,"zone_id":str(z["id"]),"agents":agents,"requested":count,"placed":agents.size(),"world_seed":world_seed}
