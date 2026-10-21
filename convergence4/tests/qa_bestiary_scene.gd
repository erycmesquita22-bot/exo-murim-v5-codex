extends SceneTree
var w:Node3D
var failures:Array=[]
func check(ok:bool,label:String):
 print("BEST_SCENE_CHECK ",label," ",ok)
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
 w=preload("res://convergence/game.gd").new();w.load_on_start="--reopen" in OS.get_cmdline_user_args();w.save_path="user://bestiary03_scene.json";root.add_child(w);await process_frame
 check(w.exo_core.ready,"boot_updated_module")
 if not w.exo_core.ready:quit(1);return
 check(w.exo_core.services.has_service("bestiary.tactics"),"tactics_service")
 if "--reopen" in OS.get_cmdline_user_args():
  for i in range(1800):
   await physics_frame
   if w.current_region>=0 and not w.changing_region:break
  check(w.current_region==0 and w.active_region.data.worldgen_v4,"reload_after_tactics")
  print("BEST_SCENE_REOPEN_RESULT ",JSON.stringify({"failures":failures}))
  w.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1);return
 w.flow.phase="creator";w.flow.create_character({"name":"Bestiario03 QA","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0,"weapon":"sword","outfit":0},101)
 for i in range(1800):
  await physics_frame
  if w.current_region>=0 and not w.changing_region:break
 check(await w.change_region(0),"wild_physical_scene")
 w.ui.resume();w.simulation_enabled=false
 var original:Array=w.enemies.duplicate()
 w.player.position=Vector3(0,w.active_region.data.center_h+.08,0)
 for count in [1,4,8]:
  w.enemies.clear();w.health=100;w.invulnerability=0
  var actors:Array=[]
  for i in range(count):
   var a:CharacterBody3D=preload("res://enemy.gd").new();w.add_child(a)
   var angle:float=TAU*float(i)/float(count)
   var at:Vector3=w.player.position+Vector3(cos(angle),0,sin(angle))*1.9
   a.setup(w,"qa/bestiary03/"+str(count)+"/"+str(i),"blade",at);a.configure_regional(30,1);a.cooldown=0;a.set_meta("bestiary03_profile","hostile_wanderer")
   actors.append(a);w.enemies.append(a)
  await physics_frame;await physics_frame
  var before:int=w.bestiary_v4.accepted
  for a in actors:a.begin_attack((w.player.position-a.position).normalized(),1.9)
  var winding:int=0
  for a in actors:
   if a.attack_time>=0:winding+=1
  check(winding>0 and winding<=2,"physical_attack_cap_"+str(count))
  var hp:int=w.health
  var peak:int=winding
  for tick in range(90):
   for a in actors:a.step(1.0/60.0)
   await physics_frame
   var count_winding:int=0
   for a in actors:
    if a.attack_time>=0:count_winding+=1
   peak=maxi(peak,count_winding)
  check(peak<=2,"simultaneous_cap_entire_window_"+str(count))
  check(w.health<hp,"authorized_player_damage_"+str(count))
  check(w.bestiary_v4.accepted>before,"real_tactic_consumed_"+str(count))
  print("BEST_SCENE_GROUP ",count," accepted ",w.bestiary_v4.accepted-before," health ",w.health," winding_initial ",winding)
  for a in actors:a.queue_free()
  await physics_frame
 w.enemies.assign(original)
 check(w.save_progress(),"save_after_tactics")
 print("BEST_SCENE_RESULT ",JSON.stringify({"failures":failures,"accepted":w.bestiary_v4.accepted,"releases":w.bestiary_v4.released,"coverage":"physical actors 1x1,1x4,1x8; fixture positions; existing Combat executor"}))
 w.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)
