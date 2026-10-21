extends SceneTree
var w: Node3D
func _initialize() -> void:call_deferred("run")
func frames(n: int) -> void:
	for i in range(n):await process_frame
func shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://evidencias/"+n+".png")
func run() -> void:
	root.size=Vector2i(960,600)
	w=load("res://main.gd").new();w.load_on_start=false;w.save_path="user://comparison09.json";w.settings_path="user://comparison09.cfg";root.add_child(w);await process_frame
	w.flow.phase="creator";w.flow.create_character({"name":"Referência","race":0,"path":0,"robe":0,"hair":0,"skin":0,"style":0});w.ui.resume();w.graphics.select(2);w.graphics.shake_enabled=false
	for a in w.enemies:a.enabled=false
	w.player.position=Vector3(6,.03,23);w.player.velocity=Vector3.ZERO;await frames(15)
	w.simulation_enabled=false;w.camera.size=5.8;w.camera.position=w.player.position+Vector3(16,12,-21);w.camera.look_at(w.player.position+Vector3.UP);await frames(3);await shot("comparativo-personagem")
	w.simulation_enabled=true;w.player.position=Vector3(0,.03,28);w.camera.size=34;await frames(15);await shot("comparativo-vila")
	w.audio_fx.shutdown();w.queue_free();await frames(4);quit()
