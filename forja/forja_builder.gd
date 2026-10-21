extends RefCounted
## Instanciador. Depende exclusivamente do kit de assets previamente aprovado.
const Kit = preload("res://godot/modular_kit.gd")
const Planner = preload("res://forja/forja_planner.gd")
const Details = preload("res://forja/detail_pass.gd")

static func _vector(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))

static func _add_anchor(house: Node3D, key: String, coordinates: Array) -> void:
	var anchor := Marker3D.new()
	anchor.name = key
	house.add_child(anchor)
	anchor.position = _vector(coordinates)

static func _is_vec3(v: Variant) -> bool:
	if not (v is Array) or v.size() != 3: return false
	for n in v:
		if (typeof(n) != TYPE_INT and typeof(n) != TYPE_FLOAT) or not is_finite(float(n)):
			return false
	return true

static func _is_rect(v: Variant) -> bool:
	if not (v is Array) or v.size() != 4: return false
	for number in v:
		if (typeof(number) != TYPE_INT and typeof(number) != TYPE_FLOAT) or not is_finite(float(number)):
			return false
	return true

static func _near(a: float, b: float) -> bool:
	return absf(a - b) <= 0.001

static func is_plan_compatible(plan: Dictionary) -> bool:
	if int(plan.get("schema_version", -1)) != Planner.SCHEMA_VERSION: return false
	if str(plan.get("type", "")) != "murim_gable_house": return false
	if str(plan.get("lot_id", "")).is_empty(): return false
	if int(plan.get("width_m", -1)) not in [4, 6, 8]: return false
	if int(plan.get("stories", -1)) not in [1, 2]: return false
	if str(plan.get("role", "")) not in Planner.ALLOWED_ROLES: return false
	if str(plan.get("palette", "")) not in Planner.PALETTES: return false
	if str(plan.get("archetype", "")) not in Planner.ARCHETYPES: return false
	if str(plan.get("detail_profile", "")) not in Planner.DETAIL_PROFILES: return false
	if not plan.has("decor_seed") or typeof(plan["decor_seed"]) != TYPE_INT: return false
	if str(plan["archetype"]) == "courtyard" and int(plan["width_m"]) != 6: return false
	if str(plan["role"]) == "inn" and (int(plan["width_m"]) < 6 or int(plan["stories"]) != 2): return false
	if int(plan.get("yaw_quadrants", -1)) not in [0, 1, 2, 3]: return false
	for key in ["origin_world", "entrance_local", "gate_local", "approach_local", "interior_anchor_local", "npc_anchor_local"]:
		if not _is_vec3(plan.get(key, [])): return false
	for key in ["footprint_local_xz", "access_local_xz"]:
		if not _is_rect(plan.get(key, [])): return false
	if not (plan.get("lot_dimensions_m", null) is Array) or plan["lot_dimensions_m"].size() != 2: return false
	for measure in plan["lot_dimensions_m"]:
		if (typeof(measure) != TYPE_INT and typeof(measure) != TYPE_FLOAT) or not is_finite(float(measure)) or float(measure) <= 0.0: return false
	if str(plan.get("signature", "")).is_empty(): return false
	var role: String = str(plan["role"])
	var archetype: String = str(plan["archetype"])
	if (role == "dwelling") != (archetype in ["standard","veranda","courtyard"]): return false
	var linked: Dictionary = {"shop":"merchant","tea_house":"teahouse","workshop":"forge","herbalist":"herb_shop","inn":"inn"}
	if role != "dwelling" and str(linked.get(role,"INVALID")) != archetype: return false
	var width: float = float(plan["width_m"])
	var door_x: float = Planner._door_x(int(plan["width_m"]))
	var front: float = 6.95 if archetype == "courtyard" else 4.95
	var approach_front: float = 9.20 if archetype == "courtyard" else 5.35
	var footprint: Array = plan["footprint_local_xz"]
	var access: Array = plan["access_local_xz"]
	if not (_near(float(footprint[0]), -width*0.5-1.35) and _near(float(footprint[1]), -2.65)
		and _near(float(footprint[2]), width*0.5+1.35) and _near(float(footprint[3]), front)):
		return false
	if not (_near(float(access[0]),door_x-0.95) and _near(float(access[1]),front)
		and _near(float(access[2]),door_x+0.95) and _near(float(access[3]),approach_front)):
		return false
	if not _near(float(plan["entrance_local"][0]),door_x): return false
	if not _near(float(plan["entrance_local"][2]),3.02): return false
	if not _near(float(plan["approach_local"][0]),door_x): return false
	if not _near(float(plan["approach_local"][2]),8.9 if archetype == "courtyard" else 5.05): return false
	if float(plan["lot_dimensions_m"][0])*0.5 < width*0.5+1.35: return false
	if float(plan["lot_dimensions_m"][1])*0.5 < approach_front: return false
	return true

static func build_one(parent: Node3D, plan: Dictionary) -> Dictionary:
	if not is_instance_valid(parent): return {"ok": false, "code": "invalid_parent"}
	if not is_plan_compatible(plan): return {"ok": false, "code": "unsupported_blueprint"}
	# A biblioteca original tem colisores e portas reais; sem substitui-la.
	var house: Node3D = Kit.build_house(parent, str(plan["palette"]), int(plan["width_m"]), int(plan["stories"]))
	house.name = "EXO_" + str(plan["lot_id"]).validate_node_name()
	house.global_position = _vector(plan["origin_world"])
	house.global_rotation = Vector3(0.0, float(plan["yaw_quadrants"]) * PI * 0.5, 0.0)
	house.add_to_group("exo_structures")
	house.add_to_group("exo_role_" + str(plan["role"]))
	house.set_meta("forja_plan", plan.duplicate(true))
	house.set_meta("forja_lot_id", plan["lot_id"])
	house.set_meta("forja_role", plan["role"])
	_add_anchor(house, "AnchorEntrance", plan["entrance_local"])
	_add_anchor(house, "AnchorGate", plan["gate_local"])
	_add_anchor(house, "AnchorApproach", plan["approach_local"])
	_add_anchor(house, "AnchorInterior", plan["interior_anchor_local"])
	_add_anchor(house, "AnchorNPC", plan["npc_anchor_local"])
	var decor_result: Dictionary = Details.apply(house, plan)
	if not bool(decor_result.get("ok", false)):
		house.free()
		return {"ok": false, "code": "detail_pass_failed"}
	house.set_meta("forja_detail_count", decor_result["count"])
	return {"ok": true, "node": house, "decor_count": decor_result["count"]}

static func build_batch(parent: Node3D, settlement_plan: Dictionary) -> Dictionary:
	if not is_instance_valid(parent): return {"ok": false, "code": "invalid_parent", "nodes": []}
	if not bool(settlement_plan.get("ok", false)) or not settlement_plan.get("rejections", []).is_empty():
		return {"ok": false, "code": "batch_not_approved", "nodes": []}
	var plans: Array = settlement_plan.get("plans", [])
	for plan in plans:
		if not (plan is Dictionary) or not is_plan_compatible(plan):
			return {"ok": false, "code": "invalid_plan_in_batch", "nodes": []}
	var nodes: Array = []
	for plan in plans:
		var r: Dictionary = build_one(parent, plan)
		if not r["ok"]:
			for node in nodes: node.free()
			return {"ok": false, "code": "instantiate_failed", "nodes": []}
		nodes.append(r["node"])
	return {"ok": true, "nodes": nodes, "count": nodes.size()}
