extends SceneTree
var failed: Array=[]
func assert_ok(ok: bool, label: String) -> void:
    if not ok:
        failed.append(label);push_error("EXO_EXIT_REPRO_FAIL "+label)
    else:print("EXO_EXIT_REPRO_PASS "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
    var path: String="user://qa_round2_interior_exit.json"
    if FileAccess.file_exists(path):DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    var w:Node3D=load("res://convergence/game.gd").new();w.save_path=path;w.world_seed_override=101;w.load_on_start=false;root.add_child(w)
    await process_frame
    w.flow.phase="adventure";w.journey.data.character={"name":"QA Exit","race":0,"path":0,"robe":0,"hair":0,"skin":0,"style":0,"weapon":"sword","element":6}
    w.ui.boot();w.inventory.seed_profile()
    var ok:bool=await w.change_region(86, "")
    assert_ok(ok,"region_build")
    var service:Variant=w.active_region.get_meta("worldgen_v5_service")
    var selected: Dictionary={}
    for item in service.list_by_function(""):
        if bool(item.get("accessible",false)) and str(item.get("access_state",""))=="open" and int(item.get("enabled_floors",0))==1:
            selected=item;break
    assert_ok(not selected.is_empty(),"building_available")
    if selected.is_empty():quit(1);return
    var door: Array=selected["exterior_door"]
    w.player.global_position=Vector3(float(door[0]),float(door[1]),float(door[2]))
    assert_ok(w.wg5_visit.try_interact(),"entry")
    w.player.global_position+=Vector3(0.3,0,0)
    assert_ok(w.save_progress(),"save_inside")
    w.free();paused=false;await process_frame
    var reload:Node3D=load("res://convergence/game.gd").new();reload.save_path=path;root.add_child(reload)
    for i in range(300):
        await physics_frame
        if reload.current_region==86 and reload.wg5_visit.inside() and not reload._resume_pending:break
    assert_ok(reload.wg5_visit.inside(),"interior_restored")
    for i in range(12):await physics_frame
    var room:Node3D=reload.wg5_visit.portal._interior
    var mark:Marker3D=room.get_node("InteriorExit")
    print("EXO_EXIT_STATE ",JSON.stringify({"paused":paused,"is_on_floor":reload.player.is_on_floor(),"distance":reload.player.global_position.distance_to(mark.global_position),"hint":reload.interaction_hint(),"gate_cooldown":reload.gate_cooldown,"interaction_cooldown":reload.interaction_cooldown,"position":str(reload.player.global_position)}))
    # Send actual game action; do not bypass input handler or interaction guards.
    Input.action_press("interact")
    for i in range(4): await physics_frame
    Input.action_release("interact")
    print("EXO_EXIT_AFTER ",JSON.stringify({"inside":reload.wg5_visit.inside(),"feedback":reload.feedback,"hint":reload.interaction_hint()}))
    assert_ok(not reload.wg5_visit.inside(),"leave_through_game_interact_after_reopen")
    var saved: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
    var visit: Dictionary=saved.get("convergence",{}).get("worldgen_v5_visit",{}) if saved is Dictionary else {}
    assert_ok(not bool(visit.get("inside",true)),"exit_saved_on_disk")
    var return_point: Vector3=reload.player.global_position
    reload.free();paused=false
    await process_frame
    var another:Node3D=load("res://convergence/game.gd").new();another.save_path=path;root.add_child(another)
    for i in range(300):
        await physics_frame
        if another.current_region==86 and not another._resume_pending:break
    assert_ok(another.current_region==86,"outside_region_restored_after_exit")
    assert_ok(not another.wg5_visit.inside(),"outside_after_reboot")
    assert_ok(another.player.global_position.distance_to(return_point)<1.0,"outside_return_position_restored")
    another.free();paused=false
    print("EXO_EXIT_REPRO_RESULT ",JSON.stringify({"passed":failed.is_empty(),"failures":failed}))
    quit(0 if failed.is_empty() else 1)
