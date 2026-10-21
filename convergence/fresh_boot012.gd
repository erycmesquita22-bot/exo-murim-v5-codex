extends SceneTree
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1152,720)
	var path: String=ProjectSettings.get_setting("application/run/main_scene")
	var w: Node3D=load(path).instantiate();w.load_on_start=false;w.save_path="user://convergence012_fresh_boot.json";root.add_child(w)
	for i in range(12):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://convergence/evidence012/fresh-main-menu.png")
	var ok: bool=path=="res://convergence/game.tscn" and w.convergence_ready and w.flow.phase!="adventure"
	print("FRESH_BOOT012 ",ok," main_scene=",path," phase=",w.flow.phase)
	w.simulation_enabled=false;w.audio_fx.shutdown();OS.delay_msec(120);w.free();await process_frame;quit(int(not ok))
