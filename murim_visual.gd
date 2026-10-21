extends SceneTree
const World=preload("res://main.gd")
const Wardrobe=preload("res://wardrobe.gd")
var w: Node3D
func _initialize() -> void:call_deferred("run")
func shot(label: String) -> void:
	await create_timer(.35,true,false,true).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://evidencias/"+label+".png")
	print("CAPTURE "+label)
func run() -> void:
	root.size=Vector2i(1536,960)
	w=World.new();w.load_on_start=false;w.save_path="user://visual07.json";w.settings_path="user://visual07.cfg"
	root.add_child(w);await process_frame
	w.graphics.select(2)
	w.flow.start_prologue();w.flow.begin_omen();w.flow.tick(8.1)
	for i in range(4):w.flow.advance_story()
	w.ui.creation_tab=1
	for i in range(3):
		w.ui.profile.style=i;w.ui.profile.robe=[1,3,2][i];w.ui.profile.weapon="sword";w.ui.profile.race=0
		w.ui.show_creator();w.ui.preview.rotation.y=-.35
		await shot("personagem-"+str(i))
	w.flow.create_character(w.ui.profile);w.ui.resume();w.simulation_enabled=false
	var d: Dictionary=w.journey.data
	d.stage=5;d.claimed=true;d.coins=100;d.lodging=true;d.rested=true;d.visits=[0,1,2];d.defeated=["road_blade","road_mage"]
	w.player.position=Vector3(0,.03,-26);w.flow.update_quest(.01);w.update_camera();w.ui.refresh();w.beacon.position=w.flow.RUIN_SURVEY+Vector3(0,.5,0)
	await shot("ruinas-objetivo")
	w.player.position=Vector3(0,.03,-30);w.flow.update_quest(.01);w.update_camera();w.ui.refresh();w.beacon.hide()
	await shot("ruinas-concluidas")
	w.ui.show_extra(false);w.ui.exo.open("audio");await shot("audio-referencias")
	w.audio_fx.shutdown();await create_timer(.2,true,false,true).timeout
	w.ui.exo.close_menu();w.queue_free();await process_frame;await process_frame
	w=null
	await create_timer(.35,true,false,true).timeout;quit()
