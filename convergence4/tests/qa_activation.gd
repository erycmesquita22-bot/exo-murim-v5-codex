extends SceneTree
var w:Node3D
var failures:Array=[]
func check(ok:bool,label:String):
 print("ACTIVATION_CHECK ",label," ",ok)
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
 w=preload("res://convergence/game.gd").new();w.load_on_start=false;w.save_path="user://activation.json";root.add_child(w);await process_frame
 check(w.exo_core.ready,"boot")
 if not w.exo_core.ready:quit(1);return
 w.flow.phase="creator";check(w.flow.create_character({"name":"V4 QA","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0,"weapon":"sword","outfit":0},101),"creator")
 for i in range(1800):
  await physics_frame
  if w.current_region>=0 and not w.changing_region:break
 check(w.current_region>=0,"new_world")
 check(await w.change_region(78),"city78")
 if w.current_region!=78:print("ACTIVATION_RESULT ",JSON.stringify({"failures":failures,"generation":w.generation_failure}));quit(1);return
 check(w.active_region.get_meta("city_forge_physical",{}).get("buildings",0)>0,"city_physical")
 w.ui.resume();w.simulation_enabled=true
 for i in range(120):await physics_frame
 var used:int=0
 for actor in w.residents:used+=int(actor.get_meta("npc03_accepted",0))
 check(used>0,"npc03_actual_decisions")
 var crowd:Dictionary=w.exo_core.services.invoke("crowd.illusion","status")
 check(int(crowd.get("ghosts",0))>0,"crowd_renderers_attached")
 print("ACTIVATION_CROWD ",JSON.stringify(crowd))
 print("ACTIVATION_GEOMETRY ",JSON.stringify(w.active_region.get_meta("v4_crowd_check",{}))," ",JSON.stringify(w.active_region.get_meta("v4_crowd_attach",{})))
 var masters:int=0
 for actor in w.residents:
  if str(actor.identity.role)=="master" and str(actor.identity.get("martial_site_id","")).begins_with("cf/"):
   masters+=1
   var found:Dictionary=w.exo_core.instances.exo_martial.discover(str(actor.identity.id))
   check(found.get("ok",false),"city_teacher_profile/"+str(actor.identity.id))
 check(masters>0,"physical_city_teacher_occupations")
 print("ACTIVATION_MASTERS ",masters)
 print("ACTIVATION_CITY ",w.active_region.get_meta("city_forge_physical",{})," npcs ",w.residents.size()," npc03 ",used)
 print("ACTIVATION_RESULT ",JSON.stringify({"failures":failures,"npc03_decisions":used}))
 w.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)
