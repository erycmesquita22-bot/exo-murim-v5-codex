extends SceneTree
var failures:Array[String]=[]
func test(ok:bool,name:String)->void:
 if not ok:
  failures.append(name)
  push_error("EXO_REOPEN_FAIL "+name)
 else:print("EXO_REOPEN_PASS "+name)
func _initialize()->void:call_deferred("run")
func run()->void:
 var source_path: String="user://qa_resume_reopen_game.json"
 if FileAccess.file_exists(source_path):DirAccess.remove_absolute(ProjectSettings.globalize_path(source_path))
 var w: Node3D=load("res://convergence/game.gd").new()
 w.save_path=source_path
 w.world_seed_override=101
 w.load_on_start=false
 root.add_child(w)
 await process_frame
 w.flow.phase="adventure"
 w.journey.data.character={"name":"QA Reopen","race":0,"path":0,"robe":0,"hair":0,"skin":0,"style":0,"weapon":"sword","element":6}
 w.ui.boot()
 w.inventory.seed_profile()
 print("EXO_REOPEN_PRESAVE ",w.journey.valid(w.journey.data)," inv=",w.journey.valid_inventory(w.journey.data)," foundations=",w.journey.valid_foundations(w.journey.data)," character=",w.journey.valid_character(w.journey.data.character)," phase=",w.journey.data.phase," core=",w.exo_core.ready)
 print("EXO_REOPEN_GATE ",JSON.stringify({"dungeon":w._dungeon_inside(),"institutional":w._institutional_inside(),"visit":w.wg5_visit.inside(),"changing":w.changing_region,"flow":w.flow.phase,"atlas_ok":w.ensure_atlas(),"generation_failure":w.generation_failure,"current":w.current_region}))
 var ok:bool=await w.change_region(86, "")
 test(ok,"region_first_build")
 if not ok:
  print("EXO_REOPEN_FAILED_REGION ",w.generation_failure)
  quit(1);return
 print("EXO_REOPEN_REGION ",w.current_region," visited=",w.extension().get("visited",{}).size())
 test(w.current_region==86,"region_first_id")
 var service:Variant=w.active_region.get_meta("worldgen_v5_service",null)
 test(service!=null and is_instance_valid(service),"service_exists")
 if not is_instance_valid(service):quit(1);return
 var record:Dictionary={}
 for item in service.list_by_function(""):
  if bool(item.get("accessible",false)) and str(item.get("access_state",""))=="open" and int(item.get("enabled_floors",0))==1:
   record=item;break
 test(not record.is_empty(),"accessible_one_floor_business")
 if record.is_empty():quit(1);return
 var door: Array=record["exterior_door"]
 w.player.global_position=Vector3(float(door[0]),float(door[1]),float(door[2]))
 test(w.wg5_visit.try_interact(),"entry_real_shop")
 if not w.wg5_visit.inside():quit(1);return
 var saved_point:Vector3=w.player.global_position+Vector3(0.3,0,0)
 w.player.global_position=saved_point
 test(w.save_progress(),"save_while_inside")
 var stored:String=FileAccess.get_file_as_string(source_path)
 var decoded:Variant=JSON.parse_string(stored)
 test(decoded is Dictionary,"save_valid_json")
 if decoded is Dictionary:
  var sv:Dictionary=decoded.get("convergence",{}).get("worldgen_v5_visit",{})
  test(bool(sv.get("inside",false)),"saved_inside_flag")
  test(str(sv.get("building_id",""))==str(record.get("building_id","")),"saved_building_id")
 print("EXO_REOPEN_SAVED ",str(saved_point)," record=",record.get("building_id",""))
 w.free();paused=false
 await process_frame
 var reload:Node3D=load("res://convergence/game.gd").new()
 reload.save_path=source_path
 root.add_child(reload)
 test(reload.region_nodes.is_empty(),"legacy_village_not_constructed_during_resume")
 for i in range(300):
  await physics_frame
  if reload.current_region==86 and reload.wg5_visit.inside():break
 test(reload.current_region==86,"region_reopened")
 test(reload.wg5_visit.inside(),"same_interior_reopened")
 if reload.wg5_visit.inside():
  test(reload.player.global_position.distance_to(saved_point)<0.06,"same_precise_inside_position")
 test(not is_instance_valid(reload._resume_cover),"loading_cover_dismissed")
 test(not paused,"game_unpaused")
 print("EXO_REOPEN_INTERIOR_QA ",JSON.stringify({"passed":failures.is_empty(),"failures":failures,"region":reload.current_region,"inside":reload.wg5_visit.inside(),"position":str(reload.player.global_position),"expected":str(saved_point)}))
 test(reload.wg5_visit.portal.interrupt("qa_return_outside"),"exterior_recovered_for_second_save")
 reload.wg5_visit._restore_actor_visibility()
 var outside_position:Vector3=reload.player.position
 test(reload.save_progress(),"save_outside_same_region")
 reload.free();paused=false
 await process_frame
 var second_resume:Node3D=load("res://convergence/game.gd").new()
 second_resume.save_path=source_path
 root.add_child(second_resume)
 test(second_resume.region_nodes.is_empty(),"legacy_village_absent_on_exterior_resume")
 for i in range(300):
  await physics_frame
  if second_resume.current_region==86 and not is_instance_valid(second_resume._resume_cover):break
 test(second_resume.current_region==86,"outdoor_region_reopened")
 test(not second_resume.wg5_visit.inside(),"not_inside_after_outdoor_save")
 test(Vector2(second_resume.player.position.x,second_resume.player.position.z).distance_to(Vector2(outside_position.x,outside_position.z)) < 0.08,"exact_outdoor_xz_position")
 test(not is_instance_valid(second_resume._resume_cover),"outdoor_loading_cover_dismissed")
 print("EXO_REOPEN_GAME_QA ",JSON.stringify({"passed":failures.is_empty(),"failures":failures,"region":second_resume.current_region,"inside":second_resume.wg5_visit.inside(),"position":str(second_resume.player.position),"expected_outdoor":str(outside_position)}))
 second_resume.free()
 quit(0 if failures.is_empty() else 1)
