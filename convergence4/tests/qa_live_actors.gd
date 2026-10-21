extends SceneTree
var failures:Array=[]
var w:Node3D
func check(ok:bool,label:String):
 print("LIVE_CHECK ",label," ",ok)
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
 w=preload("res://convergence/game.gd").new();w.load_on_start=false;w.save_path="user://live_actors_v4.json";root.add_child(w);await process_frame
 w.flow.phase="creator";w.flow.create_character({"name":"QA atores","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0,"weapon":"sword","outfit":0},101)
 for i in range(1800):
  await physics_frame
  if w.current_region>=0 and not w.changing_region:break
 check(await w.change_region(78),"city_scene")
 w.ui.resume();w.simulation_enabled=true
 for i in range(3600):await physics_frame
 w.simulation_enabled=false
 var occupied:int=0
 for actor in w.residents:
  if str(actor.identity.role)!="master":continue
  var discovered:Dictionary=w.exo_core.instances.exo_martial.discover(str(actor.identity.id))
  if not discovered.get("ok",false):continue
  var near:Vector3=w.regional_spawn(w.active_region,actor.position+Vector3(1.5,0,0))
  if near.is_finite():w.player.position=near
  w.simulation_enabled=true
  for j in range(30):await physics_frame
  w.simulation_enabled=false
  print("LIVE_MASTER_STATE ",actor.identity.id," ",actor.position," ",actor.activity_name," ",actor.to_slot," visible ",actor.rig.visible," sheltered ",actor.sheltered)
  if not w.martial_host_r8._site_for(str(actor.identity.id),false).is_empty():occupied+=1
 check(occupied>0,"city_teacher_reached_physical_school")
 print("LIVE_TEACHERS_REACHED ",occupied)
 check(await w.change_region(0),"wild_scene")
 w.simulation_enabled=false
 var spawned:bool=false
 for site in w.ecology_director.sites:
  var at:=Vector3(site.p.x,site.y,site.p.y)
  for offset in [Vector3(0,0,30),Vector3(30,0,0),Vector3(0,0,-30),Vector3(-30,0,0)]:
   var safe:Vector3=w.regional_spawn(w.active_region,at+offset)
   if not safe.is_finite():continue
   w.player.position=safe;w.camera.position=safe+Vector3.UP*6;w.camera.look_at(safe+offset)
   w.ecology_director.timer=0;w.ecology_director.tick(1.0)
   if not w.ecology_director.active.is_empty():spawned=true;break
  if spawned:break
 check(spawned,"authorized_director_spawn")
 if spawned:
  var enemy:Node3D=w.ecology_director.active.values()[0]
  check(enemy is CharacterBody3D and enemy.hp>0 and enemy.collision_layer==4,"physical_enemy")
  var hp:int=enemy.hp
  check(enemy.hurt(1,Vector3.ZERO) and enemy.hp==hp-1,"combat_owner_enemy_damage")
  print("LIVE_ENEMY ",enemy.uid," ",enemy.kind," ",enemy.position)
 # Physical Bestiary adapter against combat status; no replacement AI or second director.
 var profiles:Array=w.exo_core.services.invoke("bestiary.catalog","list_profiles")
 var profile:Dictionary=w.exo_core.services.invoke("bestiary.catalog","get_profile",[str(profiles[0].id)]) if profiles[0] is Dictionary else w.exo_core.services.invoke("bestiary.catalog","get_profile",[str(profiles[0])])
 var fauna:CharacterBody3D=preload("res://exo_bestiary/integration/regional_fauna_actor.gd").new();w.add_child(fauna)
 fauna.setup_regional(w,"qa/fauna",profile,w.player.position+Vector3.FORWARD*2,0);fauna.set_meta("ecology_region",w.current_region)
 check(fauna.hp>0 and fauna.get_child_count()>0,"bestiary_physical_rig")
 check(fauna.hurt(1,Vector3.ZERO,1.0) and fauna.slow>0,"bestiary_combat_slow")
 fauna.apply_control(Vector3.ZERO,1.0);check(fauna.root_timer>0 and fauna.movement_multiplier()<1.0,"bestiary_control_contract")
 fauna.queue_free()
 check(w.save_progress(),"save_real_consumption")
 var consumed:Dictionary=w.activation_v4.state().get("consumed",{})
 print("LIVE_LIBRARY_CONSUMED ",JSON.stringify(consumed))
 print("LIVE_RESULT ",JSON.stringify({"failures":failures,"teachers_reached":occupied,"consumed":consumed.size()}))
 w.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)
