extends Node3D
## Six batched skin-aware voxel parts; no scene-tree node or AnimationPlayer per person.
const Parts = preload("res://exo_crowd_illusion/visuals/voxel_parts.gd")
const PART_NAMES = ["head", "body", "arm_r", "arm_l", "leg_r", "leg_l"]
var agents: Array = []
var instances: Dictionary = {}
var focus: Node3D
var elapsed := 0.0
var accumulator := 0.0
var tick_interval := 0.09
var danger_point := Vector3.ZERO
var danger_left := 0.0
var danger_duration := 5.0
var bounds_center := Vector3.ZERO
var bounds_radius := 0.0
var max_visible := 60
var panic_offset_limit := 2.2
var clip_distance := 75.0
var rendered_count := 0
var update_calls := 0

func configure(plan_data: Dictionary, camera_target: Node3D = null, mobile: bool = false, crowd_panic_limit: float = 2.2, atlas: Texture2D = null) -> void:
	panic_offset_limit = clampf(crowd_panic_limit, 0.0, 2.2)
	agents = plan_data.get("agents", []).duplicate(true)
	bounds_center = Vector3.ZERO
	bounds_radius = 0.0
	for child in get_children():
		remove_child(child);child.queue_free()
	instances.clear()
	elapsed = 0.0
	accumulator = 0.0
	rendered_count = 0
	if agents.size() > 0:
		for item in agents:
			bounds_center += item["position"]
		bounds_center /= float(agents.size())
		for item in agents:
			bounds_radius = maxf(bounds_radius, bounds_center.distance_to(item["position"]))
	focus = camera_target
	tick_interval = 0.15 if mobile else 0.09
	clip_distance = 46.0 if mobile else 75.0
	max_visible = 32 if mobile else 60
	var shader := load("res://exo_crowd_illusion/visuals/skin_atlas.gdshader") as Shader
	if atlas == null or atlas.get_width() != 2048 or atlas.get_height() != 2048:
		agents.clear()
		set_process(false)
		return
	set_process(true)
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("skin_atlas", atlas)
	for part in PART_NAMES:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.mesh = Parts.mesh_for(part)
		mm.instance_count = agents.size()
		mm.visible_instance_count = agents.size()
		var node := MultiMeshInstance3D.new()
		node.name = "Crowd_" + part
		node.multimesh = mm
		node.material_override = material
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
		instances[part] = mm
		for idx in range(agents.size()):
			var slot := int(agents[idx].get("skin_slot", 0)) % 64
			mm.set_instance_custom_data(idx, Color(float(slot % 8) / 8.0, float(slot / 8) / 8.0, 0, 1))
	_update_visuals()

func set_max_visible(amount: int) -> void:
	max_visible = clampi(amount, 0, 60)
	_update_visuals()

func react(position: Vector3, seconds: float = 4.0) -> void:
	danger_point = position
	danger_duration = clampf(seconds, 0.0, 10.0)
	danger_left = danger_duration

func _process(delta: float) -> void:
	elapsed += delta
	if danger_left > 0.0:
		danger_left = maxf(0.0, danger_left - delta)
	accumulator += delta
	if accumulator < tick_interval:
		return
	accumulator = fmod(accumulator, tick_interval)
	_update_visuals()

func _actor_pos(actor: Dictionary) -> Vector3:
	var a: Vector3 = actor["a"]
	var b: Vector3 = actor["b"]
	if a.is_equal_approx(b):
		return actor["position"]
	var length := maxf(0.01, a.distance_to(b))
	var route: Array = actor.get("route",[a,b])
	length = float(actor.get("route_length",length))
	var t := clampf(float(actor["phase"]) + elapsed * float(actor["speed"]) / length, 0.0, 1.0)
	return preload("res://exo_crowd_illusion/runtime/planner.gd")._walk_route_vectors(route,t)

func _update_visuals() -> void:
	if instances.is_empty():
		rendered_count=0
		return
	update_calls += 1
	var active := mini(agents.size(), max_visible)
	# LOD applies to whole zone; the geometry is shared by all actors in that zone.
	if is_instance_valid(focus) and agents.size() > 0:
		var center := to_global(bounds_center)
		if center.distance_squared_to(focus.global_position) > pow(clip_distance + bounds_radius, 2.0):
			active = 0
	rendered_count = active
	for part in PART_NAMES:
		var mm: MultiMesh = instances[part]
		mm.visible_instance_count = active
	var placed := 0
	for i in range(active):
		var actor: Dictionary = agents[i]
		var location := _actor_pos(actor)
		var a: Vector3 = actor["a"]
		var b: Vector3 = actor["b"]
		var route_length: float = maxf(0.01,float(actor.get("route_length",a.distance_to(b))))
		var arrived: bool = float(actor["phase"])+elapsed*float(actor["speed"])/route_length>=1.0
		var moving := a.distance_squared_to(b)>0.01 and not arrived
		var facing := float(actor["yaw"])
		if moving:
			var later: Vector3 = preload("res://exo_crowd_illusion/runtime/planner.gd")._walk_route_vectors(actor.get("route",[a,b]),minf(1.0,(elapsed*float(actor["speed"])+0.1)/route_length))
			var tangent: Vector3 = later-location
			if tangent.length_squared()>0.00001:facing=atan2(tangent.x,tangent.z)
		var panic_factor := 0.0
		if danger_left > 0.0 and to_global(location).distance_to(danger_point) < 14.0:
			panic_factor = minf(1.0, danger_left / 2.0)
			# R4: NO position displacement, not even cosmetic. Materialized safe
			# routes cannot certify off-lane movement near a door, wall or NPC.
		var scale_actor := float(actor["scale"])
		var pivot := Basis(Vector3.UP, facing).scaled(Vector3.ONE * scale_actor)
		var speed := 4.0 if moving else 1.4
		var step := sin(elapsed * speed * 3.0 + float(actor["motion_phase"])) * (0.6 if moving else 0.12)
		if panic_factor > 0.0:
			step += sin(elapsed * 12.0 + float(actor["motion_phase"])) * panic_factor * 0.35
		var stride := step if moving else 0.0
		var bounce := absf(step) * (0.04 if moving else 0.01)
		var arms := {"arm_l": -step, "arm_r": step, "leg_l": stride, "leg_r": -stride}
		var offsets := {"head": Vector3(0, 1.74 + bounce, 0), "body": Vector3(0, 1.12 + bounce, 0),
			"arm_l": Vector3(0.38, 1.37 + bounce, 0), "arm_r": Vector3(-0.38, 1.37 + bounce, 0),
			"leg_l": Vector3(0.125, 0.375, 0), "leg_r": Vector3(-0.125, 0.375, 0)}
		# Visual-only avoidance: crowd cannot make the protagonist appear
		# physically obstructed even though real collision is absent.
		if is_instance_valid(focus) and to_global(location).distance_squared_to(focus.global_position) < 1.44:
			continue
		var skin_slot := int(actor.get("skin_slot", 0)) % 64
		for part in PART_NAMES:
			instances[part].set_instance_custom_data(placed, Color(float(skin_slot % 8) / 8.0, float(skin_slot / 8) / 8.0, 0.0, 1.0))
			var local_basis := pivot
			var origin: Vector3 = location + pivot * offsets[part]
			if arms.has(part):
				var limb_rotation := Basis(Vector3.RIGHT,float(arms[part]))
				local_basis = pivot * limb_rotation
				var joint := Vector3(offsets[part].x,1.5+bounce if part.begins_with("arm") else 0.75,0)
				origin = location + pivot * (joint+limb_rotation*Vector3(0,-0.375,0))
			if part == "head":
				origin = location + pivot * offsets[part]
			instances[part].set_instance_transform(placed, Transform3D(local_basis, origin))
		placed += 1
	for part in PART_NAMES:
		instances[part].visible_instance_count = placed
	rendered_count = placed

func stats() -> Dictionary:
	return {"total": agents.size(), "visible": rendered_count, "updates": update_calls, "batches": instances.size(), "panic_active": danger_left > 0.0}
