extends SceneTree
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
 var scene: PackedScene = load("res://modules/village_npcs/VillageNPCs_V11.tscn")
 var host = scene.instantiate()
 root.add_child(host)
 await process_frame
 host.title_flow.visible = false
 host.heart_menu.visible = false
 host.heart_menu.has_session = true
 paused = false
 host.enable_training_rival = false
 host._sync_regions(true)
 host.village_npcs.reset_all()
 for i in 22: await process_frame
 print("RENDER_FPS ",Performance.get_monitor(Performance.TIME_FPS))
 var master = host.village_npcs.residents["estate_master_weak"]
 host.set_physics_process(false)
 host.village_npcs.set_process(false)
 host.wildlife.set_process(false)
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
 var shots = [
  {"name":"qi_day_gather","time":1.0,"stage":"gather","clip":"Gather_Qi","duration":2.0,"night":false},
  {"name":"qi_day_circulate","time":4.0,"stage":"circulate","clip":"Circulate_Qi","duration":5.0,"night":false},
  {"name":"qi_day_release","time":7.65,"stage":"release","clip":"Release_Qi","duration":1.8,"night":false},
  {"name":"qi_night_circulate","time":4.0,"stage":"circulate","clip":"Circulate_Qi","duration":5.0,"night":true},
  {"name":"qi_night_release","time":7.65,"stage":"release","clip":"Release_Qi","duration":1.8,"night":true}]
 for shot in shots:
  host.climate.set_weather("night" if shot.night else "clear")
  master.state = "CULTIVATE"
  master.cultivation_stage = shot.stage
  var local_time: float = float(shot.time) if shot.stage == "gather" else (float(shot.time)-2.0 if shot.stage == "circulate" else float(shot.time)-7.0)
  var fraction: float = local_time/float(shot.duration)
  master.cultivation_progress = fraction
  master.animator.play("village_life/"+str(shot.clip),.0)
  master.animator.seek(local_time,true)
  master.qi_orbit.update_fx(true,str(shot.stage),fraction,bool(shot.night),.24)
  for i in 4: await process_frame
  var img := root.get_viewport().get_texture().get_image()
  img.save_png("res://qa/village_life_03/%s.png" % shot.name)
  print("CAPTURED ",shot.name," power=",master.qi_orbit.distortion_power()," shader=",host.cultivation_distortion.cover.visible)
 host.climate.set_process(false)
 master.animator.pause()
 host.cultivation_distortion.set_process(false)
 host.cultivation_distortion.cover.visible = true
 await process_frame
 root.get_viewport().get_texture().get_image().save_png("res://qa/village_life_03/distortion_on.png")
 host.cultivation_distortion.cover.visible = false
 await process_frame
 root.get_viewport().get_texture().get_image().save_png("res://qa/village_life_03/distortion_off.png")
 print("CAPTURED distortion comparison")
 quit()
