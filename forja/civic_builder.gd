extends RefCounted
const Planner = preload("res://forja/civic_planner.gd")
const Kit = preload("res://godot/modular_kit.gd")

static func _vec(v: Array) -> Vector3: return Vector3(float(v[0]),float(v[1]),float(v[2]))
static func _box(root: Node3D, center: Vector3, dimensions: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = "FunctionalObstacle"
	root.add_child(body)
	var coll := CollisionShape3D.new()
	body.add_child(coll)
	var shape := BoxShape3D.new()
	shape.size = dimensions
	coll.shape = shape
	coll.position = center

static func _hall_collisions(node: Node3D, span: float, depth: float) -> void:
	# 4 paredes com abertura real 2.3 m na face frontal (+Z).
	_box(node,Vector3(0,1.5,-depth*.5),Vector3(span,3.0,.24))
	for side in [-1.0,1.0]:
		_box(node,Vector3(side*span*.5,1.5,0),Vector3(.24,3.0,depth))
		_box(node,Vector3(side*(span*.25+.575),1.5,depth*.5),Vector3(span*.5-1.15,3,.24))
	_box(node,Vector3(0,2.85,depth*.5),Vector3(2.3,.5,.24))

static func build(parent: Node3D, plan: Dictionary) -> Dictionary:
	if not is_instance_valid(parent): return {"ok":false,"code":"invalid_parent"}
	if not Planner.compatible(plan): return {"ok":false,"code":"unverified_or_modified_blueprint"}
	Kit.ensure()
	for item in plan["pieces"]:
		if not Kit.catalog.has(item["asset"]):return {"ok":false,"code":"missing_catalog_asset"}
	var root := Node3D.new()
	root.name = ("Civic_" + str(plan["site_id"])).validate_node_name()
	parent.add_child(root)
	root.global_position = _vec(plan["origin_world"])
	root.global_rotation = Vector3(0.0, PI*.5*float(plan["yaw_quadrants"]), 0.0)
	root.add_to_group("exo_civic_sites")
	root.add_to_group("exo_role_"+str(plan["role"]))
	root.set_meta("forja_civic_plan",plan.duplicate(true))
	for item in plan["pieces"]:
		var id: String = str(item["asset"])
		var piece: Node3D = Kit.place(root,id,_vec(item["local_pos"]),float(item["yaw_quadrants"])*PI*.5,"",false)
		if id in ["sect_hall_8m","temple_hall_8m","guild_hall_8m"]:
			_hall_collisions(piece,8.0,7.0)
		elif id == "granary_6m": _hall_collisions(piece,6.0,5.0)
		elif id == "grain_silo": _box(piece,Vector3(0,1.55,0),Vector3(2.8,3.1,2.8))
		elif bool(item["solid"]):
			var bounds: Array = Kit.catalog[id]["bounds"]
			var mn: Vector3 = _vec(bounds[0])
			var mx: Vector3 = _vec(bounds[1])
			var size: Vector3 = mx - mn
			_box(piece,(mn+mx)*.5,size)
	for entry in [["AnchorEntrance",plan["entrance_local"]],["AnchorApproach",plan["approach_local"]],
		["AnchorNPC",plan["npc_local"]],["AnchorActivity",plan["activity_local"]]]:
		var anchor := Marker3D.new()
		anchor.name = entry[0]
		root.add_child(anchor)
		anchor.position = _vec(entry[1])
	return {"ok":true,"node":root,"count":plan["pieces"].size()}
