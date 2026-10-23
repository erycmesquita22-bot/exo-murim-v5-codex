extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var holder := Node3D.new()
	root.add_child(holder)
	var r := preload("res://exo_settlement_forge/runtime/house_baker_ac.gd").get_house()
	if r.is_empty():
		push_error("AC house bake empty");quit(2);return
	var rec := {"accessible":true,"dimensions":[11.0,5.8,9.0],"position":[0,0,0],"yaw":0.0,"building_id":"test_01","function":"inn"}
	var house: Node3D = preload("res://exo_settlement_forge/runtime/architecture_builder.gd").build(holder,rec)
	var bodies: int = 0
	var meshes: int = 0
	for n in house.find_children("*","StaticBody3D",true,false):bodies+=1
	for n in house.find_children("*","MeshInstance3D",true,false):meshes+=1
	var output := {"triangles":r.triangles,"materials_baked":r.materials_baked,"meshes":meshes,"bodies":bodies,"children":house.get_child_count(),"door":house.get_node_or_null("ExteriorDoor")!=null,"exit":house.get_node_or_null("ReturnExterior")!=null}
	print("EXO_AC_FINAL ",JSON.stringify(output))
	if meshes!=2 or bodies!=1 or not output.door or not output.exit:quit(4);return
	quit(0)
