extends SceneTree
var failures:Array=[]
func check(ok:bool,label:String):
 print("REOPEN_CHECK ",label," ",ok)
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
 var w:Node3D=preload("res://convergence/game.gd").new();w.load_on_start=true;w.save_path="user://capture_day_v4.json";root.add_child(w);await process_frame
 for i in range(1800):
  await physics_frame
  if w.current_region>=0 and not w.changing_region:break
 w.simulation_enabled=false
 check(w.current_region==78,"region78_restored")
 check(w._institutional_inside(),"interior_forge_visit_restored")
 if w._institutional_inside():
  check(w.institutional_portal.get("source")=="interior_forge_r2","restored_same_owner")
  check(preload("res://convergence4/interiors.gd").clear_capsule(w.get_world_3d().direct_space_state,w.player.position),"restored_capsule_clear")
  var marker_name:String="InteriorExit" if w.institutional_portal.get("source")=="interior_forge_r2" else "InteriorReturn"
  var marker:Node3D=w.institutional_root.get_node_or_null(marker_name) as Node3D
  check(is_instance_valid(marker),"return_marker_after_reload")
  if is_instance_valid(marker):
   w.player.global_position=marker.global_position+Vector3(0.0,0.0,-4.0)
   check(not w._exit_institutional_interior().get("ok",true),"remote_exit_rejected_after_reload")
   w.player.global_position=marker.global_position
   check(w._near_institutional_exit(),"exit_proximity_after_reload")
   check(w._exit_institutional_interior().get("ok",false),"return_to_exterior")
 check(w.active_region.data.settlement_plan.owner=="city_forge_r4","city_owner_after_reload")
 check(w.active_region.data.worldgen_v4,"wg4_after_reload")
 print("REOPEN_RESULT ",JSON.stringify({"failures":failures}))
 w.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)
