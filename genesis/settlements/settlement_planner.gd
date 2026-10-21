extends RefCounted
## EXO Settlement Genesis 1 — pure, deterministic placement in regional XZ coordinates.
## No scenes, physics calls, assets, player state, or global RNG are used here.
## A failed plan returns status=invalid and errors; it never silently drops lots.

const VERSION = 4
const WorldPlanner = preload("res://genesis/world_planner.gd")
const SCALE_COUNTS = {"village": Vector2i(4, 10), "town": Vector2i(12, 26), "city": Vector2i(35, 48)}
const TYPES = {
	"village": ["farmstead", "residence", "residence", "residence"],
	"town": ["inn", "smithy", "herbalist", "residence", "residence", "residence"],
	"city": ["administration", "market", "inn", "smithy", "herbalist", "martial_school", "shrine", "warehouse"]
}

static func _nearest_point(p: Vector2, roads: Array) -> Dictionary:
	var best := INF
	var found := Vector2.ZERO
	var index := -1
	for k in range(roads.size()):
		var a: Vector2 = roads[k]["a"]
		var b: Vector2 = roads[k]["b"]
		var q := Geometry2D.get_closest_point_to_segment(p, a, b)
		var d := p.distance_to(q)
		if d < best:
			best = d
			found = q
			index = k
	return {"distance": best, "point": found, "index": index}

static func _river_distance(p: Vector2, rivers: Array, river_hub: Vector2) -> float:
	var nearest := INF
	for r in rivers:
		nearest = minf(nearest, p.distance_to(Geometry2D.get_closest_point_to_segment(p, river_hub, r["p"])))
	return nearest

static func _gate_distance(p: Vector2, gates: Array) -> float:
	var nearest := INF
	for gate in gates:
		nearest = minf(nearest, p.distance_to(Geometry2D.get_closest_point_to_segment(p, Vector2.ZERO, gate["p"])))
	return nearest

static func _path_blocked(a: Vector2, b: Vector2, existing: Array) -> bool:
	for lot in existing:
		var c: Vector2 = lot["p"]
		var nearest := Geometry2D.get_closest_point_to_segment(c, a, b)
		if nearest.distance_to(c) < float(lot["halfsize"]) + 1.0:
			return true
	return false

static func _fixture_valid(p: Vector2, gates: Array, rivers: Array, streets: Array, half_extent: float, sampler: Callable, river_hub: Vector2) -> bool:
	# Well footprint plus movement/road safety buffers; it must not occupy portal spokes.
	if absf(p.x) > half_extent - 16.0 or absf(p.y) > half_extent - 16.0:
		return false
	if _gate_distance(p, gates) < 18.5 or _river_distance(p, rivers, river_hub) < 14.0:
		return false
	var frontage: float = float(_nearest_point(p, streets)["distance"])
	if frontage < 7.0 or frontage > 26.0:
		return false
	return _terrain_spread(p, sampler) <= 8.0

static func _reserve_well(forward: Vector2, side: Vector2, gates: Array, rivers: Array, streets: Array, half_extent: float, sampler: Callable, river_hub: Vector2, reservations: Array = []) -> Dictionary:
	# Candidate order is fixed. A failed reservation produces an explicit invalid plan.
	for radius in [28.0, 35.0, 44.0, 54.0, 65.0, 76.0, 88.0]:
		for k in range(16):
			var angle := PI * 0.25 + TAU * float(k) / 16.0
			var p: Vector2 = forward * (radius * cos(angle)) + side * (radius * sin(angle))
			if _fixture_valid(p, gates, rivers, streets, half_extent, sampler, river_hub) and not _reserved_hit(p, 5.0, reservations):
				var road := _nearest_point(p, streets)
				return {"kind":"well", "p":p, "height":float(sampler.call(p)), "street_point":road["point"], "halfsize":2.5}
	return {}

static func _terrain_spread(p: Vector2, sampler: Callable) -> float:
	var hi := -INF
	var lo := INF
	for delta in [Vector2(0,0), Vector2(-5,-5), Vector2(5,-5), Vector2(5,5), Vector2(-5,5)]:
		var h: float = float(sampler.call(p + delta))
		if not is_finite(h):
			return INF
		hi = maxf(hi, h)
		lo = minf(lo, h)
	return hi - lo

static func _add_street(roads: Array, a: Vector2, b: Vector2, width: float, kind: String) -> void:
	roads.append({"a": a, "b": b, "width": width, "kind": kind})

static func future_streets(spec: Dictionary, gates: Array, rivers: Array) -> Array:
	if gates.is_empty() or str(spec.get("kind",""))!="settlement":return []
	var scale: String=str(spec.get("settlement_scale","village"))
	if scale not in SCALE_COUNTS:return []
	var forward: Vector2=gates[0]["p"].normalized()
	var side: Vector2=Vector2(-forward.y,forward.x)
	var spacing: float=18.0 if scale in ["village","town"] else 22.0
	var reach: float=145.0 if scale=="city" else (72.0 if scale=="town" else 54.0)
	var streets: Array=[]
	_add_street(streets,-forward*reach,forward*reach,7.0,"main")
	_add_street(streets,-side*reach,side*reach,5.0,"cross")
	if scale in ["town","city"] or (scale=="village" and (gates.size()>=3 or rivers.size()>=2)):
		for direction in [-1.0,1.0]:
			var offset: Vector2=side*spacing*2.0*direction
			_add_street(streets,offset-forward*reach,offset+forward*reach,4.5,"side_street")
	if scale=="city":
		for direction in [-1.0,1.0]:
			var offset: Vector2=forward*spacing*2.0*direction
			_add_street(streets,offset-side*reach,offset+side*reach,4.5,"market_street")
	return streets

static func _reserved_hit(p: Vector2, radius: float, reservations: Array) -> bool:
	for rect in reservations:
		if p.x+radius>float(rect.min_x) and p.x-radius<float(rect.max_x) and p.y+radius>float(rect.min_z) and p.y-radius<float(rect.max_z):return true
	return false

static func plan(spec: Dictionary, gates: Array, rivers: Array, half_extent: float, sampler: Callable, river_hub: Vector2 = Vector2(72,72), monument_reservations: Array = []) -> Dictionary:
	var invalid := {"status": "invalid", "version": VERSION, "errors": [], "lots": [], "streets": [], "fixtures": [], "target": 0}
	if str(spec.get("kind", "")) != "settlement":
		invalid["errors"].append("not_a_settlement")
		return invalid
	if gates.is_empty() or not sampler.is_valid():
		invalid["errors"].append("missing_terrain_or_gates")
		return invalid
	var scale: String = str(spec.get("settlement_scale", "village"))
	if not SCALE_COUNTS.has(scale):
		invalid["errors"].append("unknown_scale")
		return invalid
	var seed_value: String = str(spec.get("region_seed", "0"))
	var rng := RandomNumberGenerator.new()
	rng.seed = WorldPlanner.derive(seed_value, "settlement_core_v1")
	var span: Vector2i = SCALE_COUNTS[scale]
	var target: int = rng.randi_range(span.x, span.y)
	invalid["target"] = target
	var forward: Vector2 = gates[0]["p"].normalized()
	var side := Vector2(-forward.y, forward.x)
	var compact: bool=scale in ["village","town"]
	var gate_buffer: float=8.0 if compact else 12.0
	var spacing := 18.0 if compact else 22.0
	var reach := 145.0 if scale == "city" else 72.0 if scale == "town" else 54.0
	var streets: Array=future_streets(spec,gates,rivers)
	# Reserve critical civic infrastructure before placing residences.
	var well: Dictionary = _reserve_well(forward, side, gates, rivers, streets, half_extent, sampler, river_hub, monument_reservations)
	if well.is_empty():
		invalid["errors"].append("no_safe_well_site")
		invalid["streets"] = streets
		return invalid
	var candidates: Array = []
	if compact:
		# Reserve real 11m parcels along the civic streets. A 1.5m frontage gap
		# outside the 12m road material keeps the facade and pedestrian access clear.
		for street in streets:
			var direction: Vector2=(street.b-street.a).normalized()
			var lateral:=Vector2(-direction.y,direction.x)
			var middle: Vector2=(street.a+street.b)*.5
			for step_index in range(-4,5):
				for wing in [-1.0,1.0]:
					var p: Vector2=middle+direction*float(step_index)*18.0+lateral*14.5*wing
					candidates.append({"p":p,"rank":p.length_squared(),"ix":candidates.size(),"iy":0})
	var grid_limit := 7 if scale == "city" else 6
	for gx in range(-grid_limit, grid_limit):
		for gy in range(-grid_limit, grid_limit):
			var u: float = (float(gx) + 0.5) * spacing
			var v: float = (float(gy) + 0.5) * spacing
			var p: Vector2 = side * u + forward * v
			var score := p.length_squared() + rng.randf_range(-140.0, 140.0)
			candidates.append({"p": p, "rank": score, "ix": gx, "iy": gy})
	candidates.sort_custom(func(a, b): return float(a["rank"]) < float(b["rank"]) if not is_equal_approx(float(a["rank"]), float(b["rank"])) else (int(a["ix"]) * 50 + int(a["iy"])) < (int(b["ix"]) * 50 + int(b["iy"])))
	var lots: Array = []
	var cutoffs: Array = [1.25, 3.5, 8.0, 18.0]
	var pad := 5.5
	for spread_limit in cutoffs:
		for candidate in candidates:
			if lots.size() >= target:
				break
			var p: Vector2 = candidate["p"]
			if _reserved_hit(p, pad + 4.0, monument_reservations):
				continue
			if p.length() < (16.0 if compact else 22.0) or absf(p.x) > half_extent - 24 or absf(p.y) > half_extent - 24:
				continue
			if _gate_distance(p, gates) < pad + gate_buffer or _river_distance(p, rivers, river_hub) < pad + 11.0:
				continue
			var occupied := false
			for lot in lots:
				if p.distance_to(lot["p"]) < pad + float(lot["halfsize"]) + 5.0:
					occupied = true
					break
			if occupied:
				continue
			if p.distance_to(well["p"]) < pad + float(well["halfsize"]) + 3.0:
				continue
			if p.distance_to(Geometry2D.get_closest_point_to_segment(p, well["p"], well["street_point"])) < pad + float(well["halfsize"]) + 1.0:
				continue
			var closest := _nearest_point(p, streets)
			if float(closest["distance"]) < pad + 3.5 or float(closest["distance"]) > 29.0:
				continue
			var spread: float = _terrain_spread(p, sampler)
			if spread > spread_limit:
				continue
			var toward: Vector2 = (closest["point"] - p).normalized()
			var door: Vector2 = p + toward * (pad + 0.6)
			if _path_blocked(door, closest["point"], lots):
				continue
			if well["p"].distance_to(Geometry2D.get_closest_point_to_segment(well["p"], door, closest["point"])) < float(well["halfsize"]) + 1.0:
				continue
			var blocks_existing_access := false
			for previous in lots:
				if p.distance_to(Geometry2D.get_closest_point_to_segment(p, previous["door"], previous["street_point"])) < pad + 1.0:
					blocks_existing_access = true
					break
			if blocks_existing_access:
				continue
			var h: float = float(sampler.call(p))
			var lot_id: String = "r%02d_l%03d" % [int(spec["id"]), lots.size()]
			lots.append({"id": lot_id, "p": p, "height": h, "yaw": atan2(toward.x, toward.y), "halfsize": pad, "door": door, "street_point": closest["point"], "frontage": float(closest["distance"]), "terrain_spread": spread, "terraced": spread > 1.25, "function": "residence", "form": "linear", "district": "residential"})
		if lots.size() >= target:
			break
	if lots.size() != target:
		invalid["errors"].append("insufficient_valid_parcels:%d/%d" % [lots.size(), target])
		invalid["streets"] = streets
		invalid["lots"] = lots
		return invalid
	# The required civic functions are deterministic and occupy actual reserved lots.
	var functions: Array = TYPES[scale]
	for k in range(lots.size()):
		if k < functions.size():
			lots[k]["function"] = functions[k]
		if scale == "city" and k < functions.size():
			lots[k]["district"] = "civic" if k == 0 else "commerce" if k < 5 else "martial" if k == 5 else "cultural"
		elif scale == "town" and k < 3:
			lots[k]["district"] = "commerce"
		if scale == "village":
			lots[k]["district"] = "agricultural"
		if k % 7 == 6:
			lots[k]["form"] = "L"
		if scale == "city" and k % 11 == 10:
			lots[k]["form"] = "courtyard"
	var fixture: Array = [well]
	var result := {"status":"ready", "version":VERSION, "seed": seed_value, "region_id":int(spec["id"]), "scale": scale, "target":target, "lots":lots, "streets":streets, "fixtures":fixture, "errors":[], "metrics":{"terraced_lots":0, "mean_frontage_m":0.0}}
	var sum_frontage := 0.0
	for lot in lots:
		if lot["terraced"]:
			result["metrics"]["terraced_lots"] += 1
		sum_frontage += float(lot["frontage"])
	result["metrics"]["mean_frontage_m"] = sum_frontage / float(lots.size())
	return result

static func validate(plan_data: Dictionary, gates: Array, rivers: Array, half_extent: float, river_hub: Vector2 = Vector2(72,72)) -> Array:
	var problems: Array = []
	if plan_data.get("status", "invalid") != "ready":
		return plan_data.get("errors", ["not_ready"])
	var lots: Array = plan_data["lots"]
	var gate_buffer: float=8.0 if plan_data.get("scale","") in ["village","town"] else 12.0
	if lots.size() != int(plan_data["target"]):
		problems.append("count_mismatch")
	for i in range(lots.size()):
		var lot: Dictionary = lots[i]
		var p: Vector2 = lot["p"]
		if absf(p.x) > half_extent - 12 or absf(p.y) > half_extent - 12:
			problems.append("outside_region:%d" % i)
		if _gate_distance(p, gates) < float(lot["halfsize"]) + gate_buffer:
			problems.append("gate_road_collision:%d" % i)
		if _river_distance(p, rivers, river_hub) < float(lot["halfsize"]) + 11:
			problems.append("river_collision:%d" % i)
		for j in range(i + 1, lots.size()):
			if p.distance_to(lots[j]["p"]) < float(lot["halfsize"]) + float(lots[j]["halfsize"]) + 5:
				problems.append("parcel_overlap:%d,%d" % [i, j])
		if lot["door"].distance_to(lot["street_point"]) > 30:
			problems.append("unreachable_door:%d" % i)
		var street_dist: float = float(_nearest_point(p, plan_data["streets"])["distance"])
		if street_dist < float(lot["halfsize"]) + 3.5:
			problems.append("lot_over_street:%d" % i)
	if plan_data["streets"].size() < 2:
		problems.append("no_streets")
	var fixtures: Array = plan_data.get("fixtures", [])
	if fixtures.size() != 1:
		problems.append("fixture_count")
	for index in range(fixtures.size()):
		var fixture: Dictionary = fixtures[index]
		var fp: Vector2 = fixture["p"]
		var radius: float = float(fixture.get("halfsize", 2.5))
		if absf(fp.x) > half_extent - 16.0 or absf(fp.y) > half_extent - 16.0:
			problems.append("fixture_bounds:%d" % index)
		if _gate_distance(fp, gates) < 18.5:
			problems.append("fixture_gate_road:%d" % index)
		if _river_distance(fp, rivers, river_hub) < 14.0:
			problems.append("fixture_river:%d" % index)
		var road: Dictionary = _nearest_point(fp, plan_data["streets"])
		if float(road["distance"]) < 7.0 or float(road["distance"]) > 26.0:
			problems.append("fixture_street_access:%d" % index)
		for lot in lots:
			if fp.distance_to(lot["p"]) < radius + float(lot["halfsize"]) + 3.0:
				problems.append("fixture_lot_overlap:%s" % str(lot["id"]))
			if fp.distance_to(Geometry2D.get_closest_point_to_segment(fp, lot["door"], lot["street_point"])) < radius + 1.0:
				problems.append("fixture_blocks_door:%s" % str(lot["id"]))
			if lot["p"].distance_to(Geometry2D.get_closest_point_to_segment(lot["p"], fp, fixture["street_point"])) < radius + float(lot["halfsize"]) + 1.0:
				problems.append("lot_blocks_fixture_access:%s" % str(lot["id"]))
	for i in range(lots.size()):
		for j in range(lots.size()):
			if i == j:
				continue
			var a: Dictionary = lots[i]
			var b: Dictionary = lots[j]
			if b["p"].distance_to(Geometry2D.get_closest_point_to_segment(b["p"], a["door"], a["street_point"])) < float(b["halfsize"]) + 1.0:
				problems.append("lot_blocks_other_door:%d,%d" % [i,j])
	return problems

static func export_contract(plan_data: Dictionary) -> Dictionary:
	# JSON-safe, versioned; visual instances and loot are deliberately not included.
	var result := {"version":int(plan_data.get("version", VERSION)), "status":str(plan_data.get("status", "invalid")), "region_id":int(plan_data.get("region_id", -1)), "scale":str(plan_data.get("scale", "")), "target":int(plan_data.get("target", 0)), "lots":[], "streets":[], "fixtures":[], "errors":plan_data.get("errors", []).duplicate()}
	for lot in plan_data.get("lots", []):
		result["lots"].append({"id":str(lot["id"]), "position":[lot["p"].x,lot["p"].y], "height":lot["height"], "yaw":lot["yaw"], "halfsize":lot["halfsize"], "door":[lot["door"].x,lot["door"].y], "function":lot["function"], "form":lot["form"], "terraced":lot["terraced"]})
	for street in plan_data.get("streets", []):
		result["streets"].append({"a":[street["a"].x,street["a"].y], "b":[street["b"].x,street["b"].y], "width":street["width"], "kind":street["kind"]})
	for fixture in plan_data.get("fixtures", []):
		result["fixtures"].append({"kind":fixture["kind"], "position":[fixture["p"].x,fixture["p"].y], "height":fixture["height"], "street_point":[fixture["street_point"].x,fixture["street_point"].y], "halfsize":fixture.get("halfsize", 2.5)})
	return result
