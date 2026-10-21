extends RefCounted
## Interface de passagem: cenas concretas Forja 04, transição gerida pelo Core/serviço aprovado.
## EXO Dungeon 02 transition_service.gd suporta apenas dungeons; NÃO reutilizar às cegas
## para prédios. Integrador deve adicionar rota de interior ao serviço compartilhado.
const ExteriorAdapter = preload("res://exo_monumental/integration/exo_adapter.gd")
const INTERIOR_SCENE: String = "res://exo_monumental/scenes/hall_interior.tscn"
const SUPPORTED: Array[String] = ["martial_hall", "grand_hall", "temple_sanctum", "fortress_command", "ruin_remains"]

static func from_plan(plan: Dictionary) -> Dictionary:
	if not bool(plan.get("ok", false)): return {"ok":false,"code":"plan_invalid"}
	var portals: Array = []
	for item in plan.get("instances", []):
		if not item.has("interior"): continue
		var kind: String = str(item["interior"])
		if kind not in SUPPORTED: return {"ok":false,"code":"interior_id_unhandled"}
		var front: float = 9.2 if kind in ["grand_hall", "fortress_command"] else (6.7 if kind == "temple_sanctum" else 6.4)
		var facing: int = int(item.get("yaw", 0))
		# Rotate the piece-local door BEFORE applying the complex's world yaw.
		var dx: float=0.0;var dz: float=front
		match posmod(facing,4):
			1:dx=front;dz=0.0
			2:dx=0.0;dz=-front
			3:dx=-front;dz=0.0
		var v: Array=[float(item["x"])+dx,float(item.get("y",0.0))+0.55,float(item["z"])+dz]
		var direction: Vector2=Vector2(dx,dz).normalized()
		var v_return: Array=[v[0]+direction.x*3.5,v[1],v[2]+direction.y*3.5]
		portals.append({"interior_id":kind,"scene_path":INTERIOR_SCENE,
			"persistent_id":str(plan["id"])+":interior:"+kind,
			"entrance_world":ExteriorAdapter.local_to_world(plan,v),
			"return_world":ExteriorAdapter.local_to_world(plan,v_return),
			"return_requires_ground_snap_and_capsule_check":true,
			"interior_entry_local":[0.0,0.4,7.7 if kind in ["grand_hall", "fortress_command"] else (5.2 if kind == "temple_sanctum" else 4.7)],
			"ownership":"Convergence R7 host, single JourneySave"})
	return {"ok":true,"site_id":str(plan["id"]),"portals":portals,
		"warning":"Do not call dungeon transition_service.enter() for an institutional hall without a specific host integration"}
