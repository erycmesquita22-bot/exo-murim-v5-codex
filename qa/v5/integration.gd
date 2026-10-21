extends SceneTree
const Game=preload("res://convergence/game.gd")
var failures: Array[String]=[]
var checks: Array=[]
var w: Node3D
func _initialize() -> void:
    call_deferred("run")
func check(ok: bool, label: String) -> void:
    checks.append({"name":label,"pass":ok})
    print("V5_CHECK ",label," ",ok)
    if not ok: failures.append(label)
func frames(n: int) -> void:
    for i in range(n): await physics_frame
func run() -> void:
    w=Game.new();w.load_on_start=false;w.world_seed_override=101
    w.save_path="user://v5-integration.json";w.settings_path="user://v5-integration.cfg"
    root.add_child(w);await process_frame
    check(w.exo_core!=null and w.exo_core.errors.is_empty(),"core_boot")
    check(w.exo_core.services.has_service("npc04.runtime"),"npc04_core_service")
    w.flow.phase="creator"
    check(w.flow.create_character({"name":"V5 QA","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0,"weapon":"sword"},101),"create_character_world")
    w.ui.resume();await frames(5)
    for i in range(300):
        if w.current_region>=0 and not w.changing_region:break
        await physics_frame
    check(w.current_region>=0,"automatic_campaign_entry")
    check(w.exo_core.services.has_service("worldgen.v5") and w.exo_core.services.has_service("settlement.forge"),"world_settlement_core_services")
    check(w.ensure_atlas(),"atlas")
    check(w.atlas.regions.size()==88,"88_regions")
    var rid: int=w.starting_region()
    var ok: bool=await w.change_region(rid)
    check(ok,"travel_settlement:"+w.generation_failure)
    if ok:
        await frames(8)
        check(w.active_region.has_meta("worldgen_v5_service"),"wg5_settlement_mounted")
        check(not w.residents.is_empty(),"physical_npcs")
        var invalid: int=0
        for a in w.residents:
            if a.setup_error!="":invalid+=1
        check(invalid==0,"npc04_setup")
        var service: Variant=w.active_region.get_meta("worldgen_v5_service")
        var plan: Dictionary=service.active_plan()
        check(plan.buildings.size()==w.active_region.data.lots.size(),"one_building_per_lot")
        var associated: int=0
        for building in plan.buildings:associated+=building.get("resident_ids",[]).size()
        check(associated>0,"settlement_livingworld_roster_index")
        var handoff: Dictionary=w.exo_core.services.invoke("worldgen.v5","settlement_handoff")
        check(handoff.get("ok",false) and handoff.get("npc04_bound",false),"worldgen_npc04_handoff_bound")
        var actor_snapshot: Dictionary=w.exo_core.services.invoke("npc04.runtime","actor_snapshot",[str(w.residents[0].identity.id)])
        check(actor_snapshot.get("npc04_schema",0)==1,"core_npc_snapshot_contract")
        var row: Dictionary=plan.buildings[0]
        var door: Array=row.exterior_door
        w.player.position=Vector3(door[0],door[1],door[2]);w.player.velocity=Vector3.ZERO
        w.simulation_enabled=false
        await frames(2)
        check(w.wg5_visit.try_interact(),"door_enter")
        check(w.wg5_visit.inside(),"interior_active")
        w.simulation_enabled=true
        await frames(90)
        check(w.wg5_visit.inside() and w.player.position.x>9900 and w.player.is_on_floor(),"interior_real_physics")
        w.simulation_enabled=false
        check(w.save_progress(),"save_inside")
        var saved: Dictionary=w.wg5_visit.snapshot()
        if w.wg5_visit.inside():
            var room: Node3D=w.wg5_visit.portal.get("_interior")
            w.player.global_position=room.get_node("InteriorExit").global_position
            check(w.wg5_visit.try_interact(),"door_leave")
            check(not w.wg5_visit.inside(),"exterior_restored")
            check(w.wg5_visit.restore_saved_visit(saved),"interior_restore_from_core")
            if w.wg5_visit.inside():
                room=w.wg5_visit.portal.get("_interior")
                w.player.global_position=room.get_node("InteriorExit").global_position
                check(w.wg5_visit.try_interact(),"restored_door_leave")
        w.player.global_position=Vector3(door[0],door[1],door[2])
        check(w.wg5_visit.try_interact(),"reenter_for_death_recovery")
        w.player.global_position=Vector3(10000,-25,10000)
        await frames(3)
        check(w.wg5_visit.inside() and w.player.global_position.y>0,"void_automatic_recovery")
        var unsafe_save: Dictionary=w.wg5_visit.snapshot()
        unsafe_save.player_position=[10000,-25,10000]
        check(w.wg5_visit.interrupt("qa_void_save"),"void_save_exit")
        check(w.wg5_visit.restore_saved_visit(unsafe_save) and w.player.global_position.y>0,"void_save_restores_safe_spawn")
        w.player.global_position=Vector3(10000,-25,10000)
        w.resume_checkpoint()
        check(not w.wg5_visit.inside() and w.active_region.visible and w.active_region.process_mode!=Node.PROCESS_MODE_DISABLED and w.player.global_position.x<9900,"laboratory_checkpoint_exits_void_interior")
        w.player.global_position=Vector3(door[0],door[1],door[2])
        check(w.wg5_visit.try_interact(),"reenter_after_manual_rescue")
        w.invulnerability=0.0;w.techniques.shield=0.0
        var health_before: int=w.health
        check(not w.damage_player(w.max_health+100) and w.health==health_before,"settlement_safe_zone_damage_refused")
        w.on_fatal_dungeon_damage()
        check(not w.wg5_visit.inside() and w.active_region.visible,"host_interruption_exterior_recovery")
        w.health=w.max_health;w.ui.resume();w.resume_checkpoint()
        w.simulation_enabled=true
        w.player.position=Vector3(0,w.active_region.data.center_h+.2,0)
        await frames(180)
        var moved: int=0
        for a in w.residents:
            if a.travelled>.1:moved+=1
        check(moved>0,"npc04_physical_movement")
        check(w.save_progress(),"core_save")
        var load_save=preload("res://journey_save.gd").new(w.save_path,101)
        check(load_save.load_progress(),"fresh_save_reader")
        check(int(load_save.data.get("convergence",{}).get("current",-1))==rid,"persist_region")
        check(load_save.data.character.name=="V5 QA","persist_character")
    var saved_region: int=w.current_region
    w.free();await process_frame
    w=Game.new();w.save_path="user://v5-integration.json";w.settings_path="user://v5-integration.cfg"
    root.add_child(w);await process_frame
    for i in range(300):
        if w.current_region>=0 and not w.changing_region:break
        await physics_frame
    check(w.current_region==saved_region,"world_reopen_region")
    check(w.journey.data.character.name=="V5 QA","world_reopen_character")
    check(not w.residents.is_empty(),"world_reopen_npcs")
    w.new_journey()
    check(w.exo_core.ready and w.exo_core.events.save==w.journey,"new_campaign_core_rebind")
    w.flow.phase="creator"
    check(w.flow.create_character({"name":"Second V5","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0,"weapon":"sword"},707),"second_seed_character")
    w.ui.resume()
    for i in range(300):
        if w.current_region>=0 and not w.changing_region:break
        await physics_frame
    check(str(w.atlas.seed)=="707" and w.current_region>=0,"second_seed_materialized")
    var report: Dictionary={"checks":checks,"failures":failures,"engine":Engine.get_version_info()}
    var f=FileAccess.open("user://v5-integration-results.json",FileAccess.WRITE)
    f.store_string(JSON.stringify(report,"  "));f.close()
    print("V5_INTEGRATION_RESULT ",JSON.stringify(report))
    w.free();await process_frame
    quit(0 if failures.is_empty() else 1)
