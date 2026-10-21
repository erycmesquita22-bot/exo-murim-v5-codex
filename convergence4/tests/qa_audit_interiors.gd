extends SceneTree
var failures:Array=[]
var w:Node3D
const SAVE="user://audit_interiors.json"
func capture_path(file_name:String)->String:
 var directory:String=OS.get_environment("EXO_AUDIT_CAPTURE_DIR")
 if directory.is_empty():directory="user://audit-captures"
 DirAccess.make_dir_recursive_absolute(directory)
 return directory.path_join(file_name)
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 print("AUDIT_INTERIOR_CHECK ",label," ",ok)
 if not ok:failures.append(label)
func finish():
 print("AUDIT_INTERIOR_RESULT ",JSON.stringify({"mode":OS.get_cmdline_user_args(),"failures":failures}))
 w.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)
func run():
 var reopening:bool="reopen" in OS.get_cmdline_user_args()
 w=preload("res://convergence/game.gd").new();w.load_on_start=reopening;w.save_path=SAVE;root.add_child(w);await process_frame
 if not reopening:
  w.flow.phase="creator";check(w.flow.create_character({"name":"Audit interior","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0,"weapon":"sword","outfit":0},101),"new_campaign")
 for i in range(1800):
  await physics_frame
  if w.current_region>=0 and not w.changing_region:break
 w.ui.resume();w.simulation_enabled=false
 if reopening:
  check(w.current_region==78,"region_reopened")
  check(w._institutional_inside(),"interior_reopened_new_process")
  if not w._institutional_inside():await finish();return
  var disk:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
  var saved:Array=disk.convergence.monumental_r7.active_interior.interior_position
  check(w.player.global_position.distance_to(Vector3(saved[0],saved[1],saved[2]))<.15,"saved_internal_position_restored")
  var marker:Node3D=w.institutional_root.get_node("InteriorExit")
  w.player.global_position=marker.global_position+Vector3(0,0,-4)
  check(not w._exit_institutional_interior().get("ok",true),"remote_exit_refused_after_reopen")
  w.player.global_position=marker.global_position
  check(w._exit_institutional_interior().get("ok",false),"exit_after_reopen")
  check(not w._institutional_inside(),"interior_closed_after_reopen")
  await finish();return
 check(await w.change_region(78),"city78")
 w.simulation_enabled=false
 var portals:Array=[]
 for p in w.active_region.monument_portals:
  if p.get("source")=="interior_forge_r2":portals.append(p)
 check(portals.size()>0,"physical_portal")
 if portals.is_empty():await finish();return
 var p:Dictionary=portals[0]
 for i in range(10):
  w.player.position=p.entrance_world
  check(w._enter_institutional_interior(p).get("ok",false),"entry_cycle_"+str(i))
  if not w._institutional_inside():await finish();return
  w.player.global_position=w.institutional_root.get_node("InteriorExit").global_position
  check(w._exit_institutional_interior().get("ok",false),"exit_cycle_"+str(i))
 var room:Node3D=p.prepared_root
 var cutaways:int=0
 for part in room.get_children():
  if part.get_meta("cutaway",false):
   cutaways+=1
   check(not part.visible and part.find_children("*","CollisionShape3D",true,false).size()>0,"cutaway_preserves_collision_"+str(cutaways))
 check(cutaways>0,"authored_facade_cutaway")
 var transform_before:Transform3D=room.transform
 room.position+=Vector3(13,5,7);room.rotation.y+=PI/2
 await physics_frame;await physics_frame
 w.player.position=p.entrance_world
 check(w._enter_institutional_interior(p).get("ok",false),"entry_transformed_room")
 var entry:Array=p.interior_entry_local
 var expected:Vector3=room.to_global(Vector3(entry[0],entry[1],entry[2]))
 check(w.player.global_position.distance_to(expected)<.01,"transformed_entry_position")
 w.player.global_position=room.global_position-Vector3(0,15,0)
 w._physics_process(.01)
 check(w.player.global_position.distance_to(expected)<.01,"transformed_fall_recovery")
 w.player.global_position=room.get_node("InteriorExit").global_position
 check(w._exit_institutional_interior().get("ok",false),"transformed_exit")
 room.transform=transform_before
 await physics_frame;await physics_frame
 w.player.position=p.entrance_world
 check(w._enter_institutional_interior(p).get("ok",false),"autosave_entry")
 w.player.global_position+=Vector3(0,0,-.25)
 w.techniques.mana=47.0;w.autosave_time=19.99
 w._physics_process(.02)
 var disk:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
 check(is_equal_approx(float(disk.convergence.r10_energy.qi),47.0),"interior_autosave_disk_energy")
 check(not disk.convergence.monumental_r7.active_interior.is_empty(),"interior_autosave_keeps_visit")
 var snapshot:Dictionary=w.journey.data.duplicate(true)
 var observed:Dictionary=w.exo_core.observed.duplicate(true)
 w.flow.lab_mode=true;w.techniques.mana=41;check(w.save_progress(),"lab_save_noop_returns_true")
 check(w.journey.data==snapshot and w.exo_core.observed==observed,"lab_no_prep_or_commit")
 w.flow.lab_mode=false
 check(w.save_progress(),"final_interior_fixture_saved")
 if "capture" in OS.get_cmdline_user_args():
  w.camera.size=22
  w.camera.global_position=w.player.global_position+Vector3(14,18,14)
  w.camera.look_at(w.player.global_position)
  for i in range(8):await process_frame
  await RenderingServer.frame_post_draw
  check(root.get_texture().get_image().save_png(capture_path("interior-final.png"))==OK,"interior_capture")
 await finish()
