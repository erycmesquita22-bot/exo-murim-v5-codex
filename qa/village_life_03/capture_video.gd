extends SceneTree
func _initialize() -> void: call_deferred("record")
func record() -> void:
 var host = load("res://modules/village_npcs/VillageNPCs_V11.tscn").instantiate()
 root.add_child(host)
 await process_frame
 host.title_flow.visible = false
 host.heart_menu.visible = false
 host.heart_menu.has_session = true
 paused = false
 host.enable_training_rival = false
 host._sync_regions(true)
 host.village_npcs.reset_all()
 host.climate.set_weather("night")
 for i in 15: await process_frame
 var master = host.village_npcs.residents["estate_master_weak"]
 host.set_physics_process(false)
 host.village_npcs.set_process(false)
 host.wildlife.set_process(false)
 host.climate.set_process(false)
 host.actor.visible = false
 host.hud.get_parent().visible = false
 for npc in host.village_npcs.residents.values():
  npc.set_village_active(true)
  npc.set_physics_process(false)
  npc.plate.visible = false
  if npc.badge_background != null: npc.badge_background.visible = false
  if npc.health_fill != null: npc.health_fill.visible = false
 host.actor.global_position = master.body.global_position+Vector3(0,0,3)
 var camera := Camera3D.new()
 host.add_child(camera)
 camera.current = true
 camera.fov = 48
 var at: Vector3 = master.body.global_position+Vector3(0,1.45,0)
 camera.global_position = at+master.visual.global_basis.z*7.4+Vector3(0,1.35,0)
 camera.look_at(at)
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://qa/village_life_03/video_frames"))
 for frame in 132:
  var time := float(frame)/12.0
  var stage := ""
  var clip := ""
  var local := 0.0
  var duration := 1.0
  if time < 2:
   stage="gather";clip="Gather_Qi";local=time;duration=2.0
  elif time < 7:
   stage="circulate";clip="Circulate_Qi";local=time-2;duration=5.0
  elif time < 8.8:
   stage="release";clip="Release_Qi";local=time-7;duration=1.8
  else:
   stage="settle";clip="Cultivate";local=time-8.8;duration=2.2
  master.state = "CULTIVATE"
  master.cultivation_stage = stage
  master.cultivation_progress = local/duration
  master.animator.play("village_life/"+clip,0)
  master.animator.seek(local,true)
  master.animator.pause()
  master.qi_orbit.update_fx(true,stage,local/duration,true,1.0/12.0)
  await process_frame
  root.get_viewport().get_texture().get_image().save_png("res://qa/village_life_03/video_frames/%03d.png" % frame)
 print("VIDEO_FRAMES 132")
 quit()
