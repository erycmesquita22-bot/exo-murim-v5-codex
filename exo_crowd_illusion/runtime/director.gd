extends RefCounted
const Planner = preload("res://exo_crowd_illusion/runtime/planner.gd")
const Renderer = preload("res://exo_crowd_illusion/runtime/zone_renderer.gd")
var container: Node3D
var region_id := -1
var zones: Array = []
var source_zones: Array = []
var world_seed := ""
var focus: Node3D
var density := 1.0
var mobile := false
var hour := 12
var status_notes: Array[String] = []
var reserved_points: Array = []
var area_index: Dictionary = {}
var official_context: Dictionary = {}
const HARD_CAP_PC = 180
const HARD_CAP_MOBILE = 80
const ZONE_LIMIT_PC = 16
const ZONE_LIMIT_MOBILE = 10

func attach_region(parent: Node3D, region_number: int, zone_specs: Array, seed: String, actor_focus: Node3D = null, target_mobile: bool = false, daytime: int = 12, reserved: Array = [], areas: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	var source_profiles: Variant = parent.get_meta("exo_crowd_visual_profiles", []) if is_instance_valid(parent) else []
	if not source_profiles is Array or source_profiles.is_empty():
		detach()
		return {"ok":false,"reason":"real_npc_visual_profiles_missing"}
	if not is_instance_valid(parent) or region_number < 0 or region_number > 87:
		return {"ok": false, "reason": "invalid_region"}
	if not is_finite(density):
		return {"ok": false, "reason": "density_invalid"}
	if zone_specs.size() > 512:
		return {"ok": false, "reason": "zone_input_limit_exceeded"}
	detach()
	status_notes.clear()
	source_zones = zone_specs.duplicate(true)
	region_id = region_number
	reserved_points = reserved.duplicate(true)
	area_index = areas.duplicate(true)
	official_context = context.duplicate(true)
	world_seed = seed
	focus = actor_focus
	mobile = target_mobile
	hour = posmod(daytime, 24)
	container = Node3D.new()
	container.name = "EXO_Crowd_Illusion_01"
	parent.add_child(container)
	var used := {}
	var accepted := 0
	var actors := 0
	var hard_cap := HARD_CAP_MOBILE if mobile else HARD_CAP_PC
	var zone_cap := ZONE_LIMIT_MOBILE if mobile else ZONE_LIMIT_PC
	for zone in zone_specs:
		if accepted >= zone_cap or actors >= hard_cap:
			break
		if not zone is Dictionary or not Planner.valid_zone(zone):
			status_notes.append("invalid_zone_rejected")
			continue
		var zone_id := str(zone["id"])
		if used.has(zone_id):
			status_notes.append("duplicate_zone_rejected:" + zone_id)
			continue
		used[zone_id] = true
		var effective := density * _schedule_factor(str(zone.get("role", "resident")), hour)
		var area: Variant = area_index.get(zone_id, {})
		if area is Dictionary:
			effective *= _district_factor(str(area.get("district", "")))
		# Only verified official context can adjust population. Never infer
		# prices or wealth from a visual NPC; absence stays conservative.
		if str(official_context.get("authority", "")) == "CrowdHostApproved":
			var weather: String = str(official_context.get("weather", "unknown"))
			if weather in ["rain", "storm", "snow"]:
				effective *= 0.6 if weather == "rain" else 0.3
			var population_factor: Variant = official_context.get("official_population_factor", 1.0)
			if (population_factor is float or population_factor is int) and is_finite(float(population_factor)):
				effective *= clampf(float(population_factor), 0.2, 1.0)
		effective = clampf(effective, 0.0, 1.0)
		var planned := Planner.plan(zone, world_seed + "|r" + str(region_number), effective, reserved)
		if not bool(planned.get("ok", false)):
			continue
		var planned_agents: Array = planned.get("agents", [])
		if planned_agents.size() > hard_cap - actors:
			planned_agents.resize(hard_cap - actors)
			planned["agents"] = planned_agents
			planned["placed"] = planned_agents.size()
		if planned_agents.is_empty():
			continue
		var renderer: Node3D = Renderer.new()
		renderer.name = "CrowdZone_" + zone_id.validate_node_name()
		container.add_child(renderer)
		renderer.configure(planned, focus, mobile, 0.35 if zone_id.begins_with("cf/") else 2.2, source_profiles, world_seed + "|r" + str(region_number), hour)
		zones.append({"spec": zone.duplicate(true), "renderer": renderer})
		accepted += 1
		actors += int(planned.get("placed", 0))
	return {"ok": true, "region_id": region_number, "zones": accepted, "ghosts": actors, "independent": true}

func _schedule_factor(role: String, time_hour: int) -> float:
	if role == "merchant":
		return 0.08 if time_hour < 6 or time_hour >= 21 else 1.0 if time_hour >= 9 and time_hour <= 17 else 0.48
	if role == "disciple":
		return 0.14 if time_hour < 6 or time_hour > 20 else 0.92
	if time_hour >= 23 or time_hour < 5:
		return 0.18
	return 0.85 if time_hour < 8 else 1.0

func _district_factor(district: String) -> float:
	match district:
		"commerce", "commercial", "market", "plaza": return 1.0
		"martial", "artisan": return 0.82
		"residential", "mixed", "civic": return 0.66
		"rural", "farmstead", "agricultural": return 0.45
		_: return 0.62

func set_hour(time_hour: int) -> void:
	if region_id < 0 or hour == posmod(time_hour, 24):
		return
	hour = posmod(time_hour, 24)
	_replan()

func set_density(percent: float) -> void:
	if not is_finite(percent):
		status_notes.append("nonfinite_density_rejected")
		return
	density = clampf(percent, 0.0, 1.0)
	_replan()

func set_mobile(value: bool) -> void:
	mobile = value
	_replan()

func _replan() -> void:
	if not is_instance_valid(container):
		return
	var parent := container.get_parent() as Node3D
	# Replan from ALL authored zones, including ones suppressed by nighttime/zero density.
	var current_zones: Array = source_zones.duplicate(true)
	var current_reserved: Array = reserved_points.duplicate(true)
	var current_areas: Dictionary = area_index.duplicate(true)
	var current_context: Dictionary = official_context.duplicate(true)
	var old_region := region_id
	var old_seed := world_seed
	var old_focus := focus
	var old_mobile := mobile
	var old_hour := hour
	attach_region(parent, old_region, current_zones, old_seed, old_focus, old_mobile, old_hour, current_reserved, current_areas, current_context)

func notify_event(kind: String, position: Vector3) -> bool:
	if kind not in ["combat", "danger"]:
		return false
	for row in zones:
		if is_instance_valid(row["renderer"]):
			row["renderer"].react(position, 5.0 if kind in ["combat", "danger"] else 1.8)
	return true

func detach() -> void:
	for row in zones:
		if is_instance_valid(row["renderer"]):
			row["renderer"].set_process(false)
	zones.clear()
	source_zones.clear()
	if is_instance_valid(container):
		# Remove synchronously before queue_free: 100 rapid replans must not
		# temporarily stack 100 previous population batches.
		var previous_parent: Node = container.get_parent()
		if is_instance_valid(previous_parent):
			previous_parent.remove_child(container)
		container.queue_free()
	container = null
	region_id = -1
	reserved_points.clear()
	area_index.clear()
	official_context.clear()

func status() -> Dictionary:
	var ghosts := 0
	var visible := 0
	var batches := 0
	for row in zones:
		if is_instance_valid(row["renderer"]):
			var info: Dictionary = row["renderer"].stats()
			ghosts += int(info.get("total", 0))
			visible += int(info.get("visible", 0))
			batches += int(info.get("batches", 0))
	return {"module": "crowd_illusion", "region_id": region_id, "zones": zones.size(), "ghosts": ghosts, "visible": visible, "batch_draw_groups": batches, "mobile": mobile, "density": density, "hour": hour, "notes": status_notes.duplicate()}
