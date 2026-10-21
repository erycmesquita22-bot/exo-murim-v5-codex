extends RefCounted
## Adapter de proposta, não patch no EXO Core. Reserva é autoridade do WorldGenesis.
const Planner = preload("res://exo_monumental/generation/planner.gd")
const Builder = preload("res://exo_monumental/runtime/builder.gd")

static func request_plan(world_seed: int, site: Dictionary, occupied_bounds: Array) -> Dictionary:
	# host converte seu RegionData (height_at, settlement_plan, gates, roads, rivers,
	# walls, lots) em checagens certificadas ANTES desta chamada.
	return Planner.plan(world_seed, site, occupied_bounds)

static func materialize(parent: Node3D, accepted_blueprint: Dictionary, reservation_receipt: Dictionary) -> Dictionary:
	return Builder.build(parent, accepted_blueprint, reservation_receipt)

static func list_semantic_anchors(plan: Dictionary) -> Dictionary:
	if not bool(plan.get("ok", false)): return {"ok": false, "code": "missing_plan"}
	return {"ok": true, "id": plan.get("id", ""), "kind": plan.get("kind", ""), "areas": plan.get("areas", []).duplicate(true), "paths": plan.get("paths", []).duplicate(true), "stations": plan.get("stations", []).duplicate(true), "entrance_local": plan.get("entrance_marker", []).duplicate(true), "return_local": plan.get("return_marker", []).duplicate(true)}

static func local_to_world(plan: Dictionary, local: Array) -> Vector3:
	# Godot Basis rotation_y(+PI/2): local +X points world -Z.
	# Return world positions consistent with Builder.root.rotation.y.
	var p: Array = plan["origin_world"]
	var x: float = float(local[0]); var z: float = float(local[2])
	match int(plan["yaw_quadrants"]):
		1: return Vector3(float(p[0]) + z, float(p[1]) + float(local[1]), float(p[2]) - x)
		2: return Vector3(float(p[0]) - x, float(p[1]) + float(local[1]), float(p[2]) - z)
		3: return Vector3(float(p[0]) - z, float(p[1]) + float(local[1]), float(p[2]) + x)
	return Vector3(float(p[0]) + x, float(p[1]) + float(local[1]), float(p[2]) + z)
