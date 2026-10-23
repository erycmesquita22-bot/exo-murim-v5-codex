extends SceneTree
var failures: Array[String]=[]

func check(ok: bool, detail: String) -> void:
	if not ok:
		failures.append(detail)
		push_error("EXO_FOCUSED_QA_FAIL "+detail)
	else:
		print("EXO_FOCUSED_QA_PASS "+detail)

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var scene: Variant = load("res://genesis/region_scene.gd").new()
	root.add_child(scene)
	var data: Variant = load("res://genesis/region_data.gd").new()
	data.spec={"kind":"ruins","region_seed":"987654321","biome":"grassland","id":35}
	data.lots=[{"p":Vector2(0,0),"height":10.0,"yaw":0.0}]
	scene.data=data
	scene.build_lots()
	check(scene.props.size()==1,"ruin_count_one")
	# Every family must import, instantiate and expose a real mesh/material.
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://exo_ruin_library_01/manifest.json"))
	for item in manifest["assets"]:
		var path: String="res://exo_ruin_library_01/"+str(item["scene"])
		var prefab: PackedScene=load(path)
		check(prefab!=null,"prefab_load:"+str(item["id"]))
		if prefab==null:continue
		var node: Node3D=prefab.instantiate()
		root.add_child(node)
		var meshes_all:=node.find_children("*","MeshInstance3D",true,false)
		check(meshes_all.size()==1,"prefab_mesh:"+str(item["id"]))
		if meshes_all.size()==1:
			check(meshes_all[0].mesh!=null and meshes_all[0].mesh.get_surface_count()>0,"prefab_geometry:"+str(item["id"]))
		node.free()
	var ruin: Node3D=scene.props[0]
	check(ruin.get_child_count()==1,"ruin_single_family_root")
	check(ruin.get_child(0).has_meta("exo_ruin_family"),"ruin_has_family")
	var meshes:=ruin.find_children("*","MeshInstance3D",true,false)
	check(meshes.size()==1,"ruin_one_mesh")
	var bodies:=ruin.find_children("*","StaticBody3D",true,false)
	check(bodies.size()>=1,"ruin_has_physical_collision")
	check(not ruin.has_meta("exo_dungeon_location_id"),"ruin_not_false_dungeon")
	var selected: String=scene.choose_ruin_id("987654321",0,"grassland")
	check(selected==scene.choose_ruin_id("987654321",0,"grassland"),"ruin_deterministic")
	check(ResourceLoader.exists("res://exo_ruin_library_01/scenes/"+selected+".tscn"),"ruin_scene_path_exists")
	var actor = load("res://npc_system04/actor.gd").new()
	root.add_child(actor)
	actor.position=Vector3(0,0,0)
	actor.from_slot="home";actor.to_slot="home"
	actor.routes={"home>home":[Vector3.ZERO,Vector3.ZERO],"home>@square":[Vector3.ZERO,Vector3(4,0,0)]}
	actor.rig=Node3D.new();actor.add_child(actor.rig)
	check(actor.idle_facing_target().distance_to(Vector3(4,0,0))<.001,"npc_idle_faces_authorized_street")
	actor.face_point(Vector3(4,30,0),1.0)
	check(absf(angle_difference(actor.rig.rotation.y,-PI/2))<.02,"npc_yaw_ignores_vertical_offset")
	check(str(ProjectSettings.get_setting("application/run/main_scene"))=="res://main_menu_01/main_menu.tscn","main_menu_single_entrypoint")
	actor.free();scene.free()
	print("EXO_FOCUSED_QA_RESULTS ",JSON.stringify({"passed":failures.is_empty(),"failures":failures}))
	quit(0 if failures.is_empty() else 1)
