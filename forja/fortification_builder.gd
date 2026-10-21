extends RefCounted
const Planner = preload("res://forja/fortification_planner.gd")
const Kit = preload("res://godot/modular_kit.gd")

static func _vec(a: Array) -> Vector3: return Vector3(float(a[0]),float(a[1]),float(a[2]))

static func _box(node: Node3D, center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = "FortWallCollider"
	node.add_child(body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	shape.position = center

static func build(parent: Node3D, plan: Dictionary) -> Dictionary:
	if not is_instance_valid(parent): return {"ok":false,"code":"invalid_parent"}
	if not Planner.compatible(plan): return {"ok":false,"code":"unverified_or_modified_blueprint"}
	Kit.ensure()
	for spec in plan["segments"]:
		if not Kit.catalog.has(spec["asset"]): return {"ok":false,"code":"asset_missing"}
	var root := Node3D.new()
	root.name = ("Fort_" + str(plan["site_id"])).validate_node_name()
	parent.add_child(root)
	root.global_position = _vec(plan["origin_world"])
	root.global_rotation = Vector3(0.0, float(plan["yaw_quadrants"]) * PI * .5, 0.0)
	root.set_meta("forja_fort_plan",plan.duplicate(true))
	root.add_to_group("exo_fortifications")
	var count: int = 0
	for spec in plan["segments"]:
		var id: String = str(spec["asset"])
		var pos: Array = spec["pos"]
		var part: Node3D = Kit.place(root,id,_vec(pos),float(spec["yaw_quadrants"])*PI*.5,"",false)
		if id.begins_with("city_wall_"):
			_box(part,Vector3(0,1.5,0),Vector3(2.0,3,.50))
		elif id.begins_with("wall_corner_"):
			_box(part,Vector3(0,1.5,0),Vector3(1.95,3,1.95))
		elif id.begins_with("watchtower_"):
			_box(part,Vector3(0,1.9,0),Vector3(4.0,3.8,4.0))
		elif id.begins_with("gate_"):
			# Sem colisor central: o jogador pode atravessar o portal.
			for side in [-1.0, 1.0]: _box(part,Vector3(side*2.54,2.3,0),Vector3(.9,4.6,.9))
		count += 1
	for marker in [["AnchorGate",plan["gate_local"]],["AnchorApproach",plan["approach_local"]],["AnchorInside",plan["inner_local"]]]:
		var anchor := Marker3D.new()
		anchor.name = marker[0]
		root.add_child(anchor)
		anchor.position = _vec(marker[1])
	return {"ok":true,"node":root,"segments":count}
