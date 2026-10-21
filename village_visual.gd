extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	root.size=Vector2i(1536,960)
	var w: Node3D=load("res://main.gd").new();w.load_on_start=false;w.save_path="user://visual08b.json";w.settings_path="user://visual08b.cfg";root.add_child(w)
	await process_frame;w.graphics.select(2);w.flow.start_prologue();w.flow.begin_omen();w.flow.tick(8.1)
	for i in range(4):w.flow.advance_story()
	w.flow.create_character(w.ui.profile);w.ui.resume();w.simulation_enabled=false;w.player.position=Vector3(0,.03,27);w.update_camera();w.ui.refresh()
	await create_timer(.5,true,false,true).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://evidencias/vila-alto.png")
	print("VILLAGE CAPTURE")
	w.audio_fx.shutdown();await create_timer(.25,true,false,true).timeout;w.queue_free();await process_frame;await process_frame
	await create_timer(.35,true,false,true).timeout;quit()
