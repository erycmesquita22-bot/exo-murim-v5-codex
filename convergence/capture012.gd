extends SceneTree
var w: Node3D
func _initialize():call_deferred("run")
func shot(label: String):
	w.ui.refresh()
	for i in range(3):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://convergence/evidence012/"+label+".png");print("SHOT ",label)
func focus(p: Vector3):
	w.player.position=p;w.player.velocity=Vector3.ZERO;w.camera.size=15;w.update_camera()
func run():
	DirAccess.make_dir_recursive_absolute("res://convergence/evidence012");root.size=Vector2i(1152,720)
	w=load("res://convergence/game.gd").new();w.load_on_start=false;w.world_seed_override=101;w.save_path="user://convergence012_capture.json";root.add_child(w);await process_frame
	await shot("00-inicio")
	w.graphics.select(1);w.flow.phase="creator";w.flow.create_character({"name":"Eryc","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0});w.ui.resume()
	var selections: Array=[["101",86,"aldeia"],["707",10,"vila"],["101",78,"cidade"],["101",61,"relevo"]]
	if "city" in OS.get_cmdline_user_args():selections=[["101",78,"cidade"]]
	for spec in selections:
		if w.current_region>=0:w.return_home()
		w.atlas.clear();w.extension().atlas_seed=spec[0];w.extension().erase("atlas")
		if not await w.change_region(spec[1]):push_error(w.generation_failure);quit(1);return
		for enemy in w.enemies:enemy.enabled=false
		for i in range(60):await physics_frame
		w.simulation_enabled=false
		var r: Node3D=w.active_region
		if r.data.spec.kind=="settlement":
			focus(r.station_points[r.data.lots[0].id]+Vector3(0,0,1));await shot(str(spec[2])+"-jogador")
			for f in (["martial_school","shrine","smithy","herbalist","market","administration","warehouse"] if spec[2]=="cidade" else ["farmstead"] if spec[2]=="aldeia" else ["inn"]):
				for lot in r.data.lots:
					if lot.function==f:focus(r.station_points[lot.id]+Vector3(0,0,1));await shot(str(spec[2])+"-"+f);break
			focus(w.residents[0].position+Vector3(0,0,1));await shot(str(spec[2])+"-moradores")
		else:focus(Vector3(0,r.data.center_h+.08,0));await shot(str(spec[2])+"-jogador")
		var center:=Vector3(0,r.data.center_h,0);w.camera.size=170 if r.data.spec.kind=="settlement" else 100;w.camera.position=center+Vector3(90,120,105);w.camera.look_at(center);await shot(str(spec[2])+"-panorama")
		w.simulation_enabled=true
	w.set_paused(false);w.simulation_enabled=false;w.audio_fx.shutdown();OS.delay_msec(120);w.free();quit()
