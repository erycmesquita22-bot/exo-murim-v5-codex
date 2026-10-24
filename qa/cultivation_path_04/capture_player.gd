extends SceneTree
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
 var host = load("res://modules/village_npcs/VillageNPCs_V11.tscn").instantiate()
 root.add_child(host)
 await process_frame
 host.title_flow.visible=false;host.heart_menu.visible=false;host.heart_menu.has_session=true
 paused=false;host.enable_training_rival=false;host._sync_regions(true)
 for i in 12: await process_frame
 var p=host.cultivation_path
 p.reset_state(false)
 p.status.visible=false;p.hint.visible=false
 host.set_physics_process(false);p.set_physics_process(false)
 host.village_npcs.set_process(false);host.wildlife.set_process(false)
 host.hud.get_parent().visible=false
 for npc in host.village_npcs.residents.values(): npc.set_village_active(false)
 var marker: Node3D=host.village_npcs.cultivation_sites[0]
 host.actor.global_position=marker.global_position+Vector3(0,.15,0)
 var camera:=Camera3D.new();host.add_child(camera);camera.current=true;camera.fov=43
 var at: Vector3=host.actor.global_position+Vector3(0,1.4,0)
 camera.global_position=at+host.visual.global_basis.z*6.7+Vector3(0,1.0,0);camera.look_at(at)
 host.tree.active=false
 host.player.play("Idle")
 for i in 4: await process_frame
 root.get_viewport().get_texture().get_image().save_png("res://qa/cultivation_path_04/player_before.png")
 p.rank=1;p.stage=0;p._apply_bonuses()
 host.player.play("village_life/Circulate_Qi");host.player.seek(2.3,true)
 p.fx.update_fx(true,"circulate",.55,false,.1)
 for i in 4: await process_frame
 root.get_viewport().get_texture().get_image().save_png("res://qa/cultivation_path_04/player_cultivating.png")
 host.player.play("Idle");p.fx.update_fx(false,"off",0,false,0)
 for i in 4: await process_frame
 root.get_viewport().get_texture().get_image().save_png("res://qa/cultivation_path_04/player_after.png")
 print("CAPTURE player_before/player_cultivating/player_after fps=",Performance.get_monitor(Performance.TIME_FPS))
 quit()
