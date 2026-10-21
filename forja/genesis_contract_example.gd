extends RefCounted
## EXEMPLO DE ADAPTADOR. Nenhum script do Genesis e modificado.
const Planner = preload("res://forja/forja_planner.gd")
const Builder = preload("res://forja/forja_builder.gd")

static func make_lot(lot_id: String, center: Vector3, width_m: float, depth_m: float, rotation_quadrants: int, district: String, height_samples: Array, role: String = "auto") -> Dictionary:
	return {
		"id": lot_id,
		"center_x": center.x, "center_z": center.z, "ground_y": center.y,
		"width_m": width_m, "depth_m": depth_m,
		"yaw_quadrants": rotation_quadrants,
		"district": district,
		"role": role,
		"max_stories": 2,
		"terrain_samples_y": height_samples,
		"approach_clear": true
	}

static func build_from_approved_lots(parent: Node3D, world_seed: int, lots: Array) -> Dictionary:
	var result: Dictionary = Planner.plan_settlement(world_seed, lots, true)
	if not result["ok"]:
		return {"ok": false, "phase": "planning", "errors": result.get("rejections", []), "code": result.get("code", "")}
	var built: Dictionary = Builder.build_batch(parent, result)
	if not built["ok"]:
		return {"ok": false, "phase": "building", "code": built.get("code", "")}
	return {"ok": true, "count": built["count"], "nodes": built["nodes"], "plans": result["plans"]}
