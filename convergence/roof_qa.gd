extends SceneTree
func _initialize():call_deferred("run")
func frames(n: int):
	for i in range(n):await physics_frame
func run():
	var w=preload("res://convergence/game.gd").new();w.load_on_start=false;w.world_seed_override=101;w.save_path="user://qa012_roof.json";root.add_child(w);await process_frame
	w.flow.phase="creator";w.flow.create_character({"name":"Roof QA","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0});w.ui.resume()
	var ok: bool=await w.change_region(78);var checked:=0
	for i in [0,5]:
		var house: Node3D=w.active_region.props[i].get_child(0);var entrance: Vector3=house.get_node("AnchorEntrance").position
		# Controlled position isolates roof occlusion; full door walking is a separate suite.
		w.player.position=house.to_global(Vector3(entrance.x,.5,0));w.player.velocity=Vector3.ZERO;await frames(12)
		var roof: Node3D=house.get_node("StaticRoofVisual")
		var grounded: bool=w.player.is_on_floor();var hidden: bool=not roof.visible
		w.player.position=house.to_global(Vector3(0,.1,15));w.player.velocity=Vector3.ZERO;await frames(4)
		var restored: bool=roof.visible
		ok=ok and grounded and hidden and restored;checked+=3;print("ROOF_CASE ",i," grounded=",grounded," hidden=",hidden," restored=",restored)
	print("ROOF012 ",ok," checks=",checked);w.simulation_enabled=false;w.audio_fx.shutdown();OS.delay_msec(120);w.free();quit(int(not ok))
