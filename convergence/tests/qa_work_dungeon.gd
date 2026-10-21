extends SceneTree
const Game=preload("res://convergence/game.gd")
var w:Node3D
var failures:Array=[]
func check(ok:bool,label:String):
 print("DUNGEON_CHECK ",label," ",ok)
 if not ok:failures.append(label)
func settle():
 for i in range(30):
  await physics_frame
  w.player.velocity=Vector3(0,-6,0);w.player.move_and_slide();w.player.apply_floor_snap()
func _initialize():call_deferred("run")
func run():
 Engine.max_fps=0
 var reopen:bool="--reopen" in OS.get_cmdline_user_args()
 w=Game.new();w.load_on_start=reopen;w.save_path="user://work_dungeon.json";w.settings_path="user://work_dungeon.cfg";root.add_child(w);await process_frame
 if reopen:
  check(w.journey.data.phase=="adventure" and w.exo_core.ready,"new_process_autoload_and_core")
  for frame in range(1600):
   await physics_frame
   if w.current_region==10 and not w.changing_region:break
  for frame in range(5):await physics_frame
  w.simulation_enabled=false
  check(w.martial_host_r8!=null,"martial_service_survives_reopen")
  check(w.current_region==10 and not w._dungeon_inside(),"recovery_exterior")
  check(w.exo_core.services.invoke("dungeons","recover_visit_context").is_empty(),"recovery_visit_cleared")
  check(w.regional_spawn(w.active_region,w.player.position).is_finite(),"recovery_safe_floor")
 else:
  w.flow.phase="creator"
  check(w.flow.create_character({"name":"Dungeon QA","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0,"weapon":"sword","outfit":0},101),"create")
  for i in range(1600):
   await physics_frame
   if w.current_region>=0 and not w.changing_region:break
  check(await w.change_region(10),"approach_region")
  w.simulation_enabled=false
  for i in range(3):await physics_frame
  var entrance:Dictionary={}
  for holder in w.active_region.props:
   if holder.has_meta("exo_dungeon_location_id"):
    w.player.global_position=holder.to_global(Vector3(0,1.2,3))
    entrance=w._near_dungeon_entrance();break
  check(not entrance.is_empty(),"registered_exterior_entrance")
  if not entrance.is_empty():
   var player_id:int=w.player.get_instance_id()
   await settle()
   w.gate_cooldown=0;w.interaction_cooldown=0;w.interact()
   check(w._dungeon_inside(),"E_entry")
   check(w.player.get_instance_id()==player_id,"same_player")
   var module=w.exo_core.instances.dungeon_genesis
   await settle()
   check(w.player.is_on_floor(),"interior_ground")
   await settle()
   w.gate_cooldown=0;w.interaction_cooldown=0;w.interact()
   check(not w._dungeon_inside(),"E_exit")
   await settle()
   w.gate_cooldown=0;w.interaction_cooldown=0;w.interact()
   check(w._dungeon_inside(),"E_reentry")
   check(w.save_progress(),"save_inside")
 w.queue_free();await process_frame;await process_frame
 print("DUNGEON_RESULT ",JSON.stringify({"failures":failures,"reopen":reopen}))
 quit(0 if failures.is_empty() else 1)
