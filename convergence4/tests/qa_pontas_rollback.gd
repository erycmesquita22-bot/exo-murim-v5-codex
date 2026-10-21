extends SceneTree
const Game=preload("res://convergence/game.gd")
const Save=preload("res://journey_save.gd")
var w:Node3D
var failures:Array=[]
var checks:int=0
func check(ok:bool,label:String):
 checks+=1
 print("WORK_CHECK ",label," ",ok)
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
 Engine.max_fps=0
 var reopen:bool="--reopen" in OS.get_cmdline_user_args()
 w=Game.new();w.load_on_start=reopen;w.save_path="user://work_campaign.json";w.settings_path="user://work_campaign.cfg"
 root.add_child(w)
 await process_frame
 if reopen:
  check(w.journey.data.phase=="adventure" and w.exo_core.ready,"new_process_autoload_and_core")
  for frame in range(1600):
   await physics_frame
   if w.current_region==78 and not w.changing_region:break
  for frame in range(5):await physics_frame
  w.simulation_enabled=false
  check(w.martial_host_r8!=null,"martial_service_survives_reopen")
  check(w.current_region==78,"new_process_region")
  check(w.residents.size()>0,"new_process_population")
 else:
  w.flow.phase="creator"
  var profile:Dictionary={"name":"Work QA","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0,"weapon":"sword","outfit":0}
  check(w.flow.create_character(profile,101),"official_character_creation")
  for i in range(1600):
   await physics_frame
   if w.current_region>=0 and not w.changing_region:break
  w.simulation_enabled=false
  check(w.current_region>=0 and is_instance_valid(w.active_region),"procedural_campaign")
  check(w.generation_failure.is_empty(),"campaign_no_failure")
  var movement_start:Vector3=w.player.position
  w.simulation_enabled=true;Input.action_press("right")
  for frame in range(20):await physics_frame
  Input.action_release("right");w.simulation_enabled=false
  check(w.player.position.distance_to(movement_start)>.5,"player_moves_by_input")
  check(w.player.is_on_floor(),"player_supported_by_ground")
  check(await w.change_region(78),"travel_city78")
  w.simulation_enabled=false
  check(w.residents.size()>0,"population_city78")
  check(w.save_progress(),"campaign_save")
  var old_region:Node3D=w.active_region
  var old_ids:Array=w.residents.map(func(a):return a.get_instance_id())
  var old_position:Vector3=w.player.position
  var old_save:String=FileAccess.get_file_as_string(w.journey.path)
  var old_data:Dictionary=w.journey.data.duplicate(true)
  var real_path:String=w.journey.path
  w.journey.path="user://missing_work_parent/fail.json"
  check(not await w.change_region(14),"reject_failed_save")
  check(w.active_region==old_region and w.current_region==78,"failed_save_keeps_same_region")
  check(old_ids==w.residents.map(func(a):return a.get_instance_id()),"failed_save_keeps_same_actors")
  check(w.player.position.distance_to(old_position)<0.001,"failed_save_keeps_player")
  check(FileAccess.get_file_as_string(real_path)==old_save,"failed_save_keeps_disk")
  print("STATE_DIFF ",JSON.stringify(diff(old_data,w.journey.data)))
  check(w.journey.data==old_data,"failed_save_keeps_state")
  w.journey.path=real_path
  print("WORK_PORTALS ",w.active_region.monument_portals.size()," STATIONS ",w.active_region.monument_stations.size())
 for i in range(15):await physics_frame
 check(w.player.position.is_finite(),"player_finite")
 w.queue_free();await process_frame;await process_frame
 print("WORK_CAMPAIGN_RESULT ",JSON.stringify({"checks":checks,"failures":failures,"reopen":reopen}))
 quit(0 if failures.is_empty() else 1)

func diff(a:Variant,b:Variant,path:String="")->Array:
 var out:Array=[]
 if a is Dictionary and b is Dictionary:
  for key in a:
   if not b.has(key):out.append({"path":path+"/"+str(key),"missing":true})
   elif a[key]!=b[key]:out.append_array(diff(a[key],b[key],path+"/"+str(key)))
  for key in b:
   if not a.has(key):out.append({"path":path+"/"+str(key),"added":b[key]})
 elif a!=b:out.append({"path":path,"before":a,"after":b})
 return out
