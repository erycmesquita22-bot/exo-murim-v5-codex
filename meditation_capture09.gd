extends SceneTree
# Camera-only override for inspecting the real controller/pose; default game camera unchanged.
class InspectionWorld:
	extends "res://main.gd"
	func update_camera() -> void:
		camera.position=player.position+Vector3(16,12,-21)
		camera.look_at(player.position+Vector3.UP*.8)
var w: Node3D
func _initialize() -> void:call_deferred("run")
func frames(n: int) -> void:
	for i in range(n):await process_frame
func shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://evidencias/"+n+".png")
func tap() -> void:
	Input.action_press("interact");await frames(2);Input.action_release("interact")
func run() -> void:
	root.size=Vector2i(960,600)
	w=InspectionWorld.new();w.load_on_start=false;w.save_path="user://medcapture09.json";w.settings_path="user://medcapture09.cfg";root.add_child(w);await process_frame
	w.flow.phase="creator";w.flow.create_character({"name":"Mestre errante","race":0,"path":0,"robe":0,"hair":0,"skin":0,"style":0});w.ui.resume();w.graphics.select(2);w.graphics.shake_enabled=false
	for a in w.enemies:a.enabled=false
	w.player.position=w.flow.MAT+Vector3(.8,.1,0);w.player.velocity=Vector3.ZERO;w.camera.size=5.8
	await frames(20);await shot("personagem09-final");await tap();await frames(55);await shot("meditacao09-final")
	print("MED_CAPTURE seated=",w.flow.meditating," pose=",w.activity.blend," position=",w.player.position," support=",w.activity.support_y)
	await frames(25);await tap();await frames(25);await shot("meditacao09-retorno")
	print("MED_CAPTURE standing=",not w.activity.locked()," position=",w.player.position)
	await frames(15);w.audio_fx.shutdown();w.queue_free();await frames(3);quit()
