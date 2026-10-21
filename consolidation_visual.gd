extends SceneTree
const World=preload("res://main.gd")
var w: Node3D
func _initialize() -> void:call_deferred("run")
func shot(label: String) -> void:
	await create_timer(.25,true,false,true).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/exo06-"+label+".png")
	if is_instance_valid(w.ui.preview_view):print("PORTRAIT ",label," ",w.ui.preview_view.size," MSAA=",w.ui.preview_view.msaa_3d)
	print("CAPTURE "+label)
func run() -> void:
	w=World.new();w.load_on_start=false;w.save_path="user://visual06.json";w.settings_path="user://visual06.cfg"
	root.add_child(w);await process_frame
	w.graphics.select(2);w.ui.show_hero()
	await shot("prologo")
	w.flow.start_prologue();w.flow.begin_omen();w.flow.tick(8.1)
	await shot("cronicas")
	for i in range(4):w.flow.advance_story()
	for step in range(3):
		w.ui.creation_tab=step;w.ui.show_creator();await shot("criacao-%d"%step)
	w.flow.create_character(w.ui.profile);w.ui.resume();w.simulation_enabled=false
	w.player.position=Vector3(1,.03,27);w.update_camera();w.ui.refresh()
	await shot("mundo-alto")
	w.ui.show_extra(false)
	for page in ["central","ficha","ativas","passivas","inventario","equipamento","classes","titulos","mapa","config","audio","hud","testes"]:
		w.ui.exo.open(page);await shot(page)
	w.ui.exo.close_menu();w.flow.begin_lab();w.equip_weapon("gauntlets")
	w.ui.show_extra(false);w.ui.exo.open("central")
	await shot("manoplas")
	w.ui.exo.close_menu();w.update_camera();w.ui.refresh()
	await shot("patio")
	w.ui.show_extra(false);w.ui.exo.open("central")
	w.ui.set_process(false)
	w.ui.exo.preview.pose(0,false,false,true)
	w.Arsenal.fist_pose(w.ui.exo.preview,0,.43)
	await shot("soco")
	# Physical window resized: portrait must follow actual pixels, not fixed 245px.
	root.size=Vector2i(1920,1080)
	await shot("janela-1080p")
	w.audio_fx.shutdown();await create_timer(.2,true,false,true).timeout
	w.queue_free();await process_frame;await process_frame;quit()
