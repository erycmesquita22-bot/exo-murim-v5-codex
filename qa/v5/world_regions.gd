extends SceneTree
const Game=preload("res://convergence/game.gd")
var w: Node3D
var failures: Array=[]
var checks: Array=[]
var regions: Array=[]
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
    checks.append({"name":label,"pass":ok})
    if not ok: failures.append(label)
    print("REGION_CHECK ",label," ",ok)
func frames(n: int) -> void:
    for i in range(n): await physics_frame
func run() -> void:
    for seed_value in [101,707,816204]:
        w=Game.new();w.load_on_start=false;w.world_seed_override=seed_value
        w.save_path="user://v5-world-%d.json"%seed_value;w.settings_path="user://v5-world.cfg"
        root.add_child(w);await process_frame
        w.graphics.set_option("fps_limit",0)
        w.flow.phase="creator"
        check(w.flow.create_character({"name":"Region QA","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0,"weapon":"sword"},seed_value),"character_%d"%seed_value)
        w.ui.resume()
        for i in range(300):
            if w.current_region>=0 and not w.changing_region:break
            await physics_frame
        var ids: Array=[]
        for scale in ["village","town","city"]:
            for row in w.atlas.regions:
                if row.kind=="settlement" and row.settlement_scale==scale:ids.append(int(row.id));break
        for kind in ["wild","ruins","dungeon_approach"]:
            for row in w.atlas.regions:
                if row.kind==kind:ids.append(int(row.id));break
        for rid in ids:
            var start: int=Time.get_ticks_usec()
            var ok: bool=await w.change_region(rid)
            check(ok,"region_%d_%d:%s"%[seed_value,rid,w.generation_failure])
            if not ok: continue
            await frames(10)
            check(w.player.is_on_floor(),"spawn_floor_%d_%d"%[seed_value,rid])
            var data: Variant=w.active_region.data
            if data.spec.kind=="settlement":
                var service: Variant=w.active_region.get_meta("worldgen_v5_service")
                var original_houses: int=0
                for building in service.get_exterior_root().get_children():
                    var facade: MeshInstance3D=building.get_node_or_null("ForjaCompleteVisual")
                    var distant: MeshInstance3D=building.get_node_or_null("ForjaDistantLOD")
                    if facade!=null and distant!=null and building.get_meta("forja_house_template","")=="godot/modular_kit.gd:build_house/murim_blue/6/2":
                        original_houses+=1
                        check(facade.find_children("*","CollisionObject3D",true,false).is_empty() and building.find_children("*","StaticBody3D",true,false).size()==1,"single_collision_owner_"+str(building.name))
                check(original_houses==data.lots.size(),"original_forja_facades_%d_%d"%[seed_value,rid])
                var crowd_zones: Array=w.active_region.get_meta("exo_city_forge_crowd_zones",[])
                var capacity: int=0
                for zone in crowd_zones:capacity+=int(zone.capacity)
                var nearest_total: float=0.0
                for lot in data.lots:
                    var nearest: float=INF
                    for other in data.lots:
                        if lot.id!=other.id:nearest=minf(nearest,lot.p.distance_to(other.p))
                    if is_finite(nearest):nearest_total+=nearest
                regions.append({"seed":seed_value,"region":rid,"scale":data.spec.settlement_scale,"buildings":data.lots.size(),"compression":data.settlement_plan.city_forge_r4.compression,"mean_nearest_house_m":nearest_total/maxi(1,data.lots.size()),"verified_crowd_zones":crowd_zones.size(),"crowd_capacity_before_schedule":capacity})
                var linked: Dictionary=w.active_region.get_meta("exo_r9_martial_occupancy",{})
                var school_access:bool=true
                for site in data.monumental_plans:
                    if str(site.kind) in ["martial_medium","martial_grand"] and not linked.has(str(site.id)):school_access=false
                check(school_access,"all_martial_courtyards_have_physical_teacher_route_%d_%d"%[seed_value,rid])
                var blocked: Array=[]
                var crossed: int=0
                w.simulation_enabled=false
                for row in service.active_plan().buildings:
                    var p: Array=row.exterior_door
                    var door:=Vector3(p[0],p[1],p[2])
                    if not preload("res://convergence4/interiors.gd").clear_capsule(w.get_world_3d().direct_space_state,door):blocked.append(row.lot_id)
                    w.player.global_position=door;w.player.velocity=Vector3.ZERO
                    if w.wg5_visit.try_interact():
                        var room: Node3D=w.wg5_visit.portal.get("_interior")
                        w.player.global_position=room.get_node("InteriorExit").global_position
                        if w.wg5_visit.try_interact():crossed+=1
                check(blocked.is_empty(),"all_doors_capsule_%d_%d:%s"%[seed_value,rid,str(blocked)])
                check(crossed==data.lots.size(),"all_doors_enter_leave_%d_%d:%d"%[seed_value,rid,crossed])
                w.simulation_enabled=true
                check(w.residents.all(func(a):return a.setup_error.is_empty()),"npc_routes_%d_%d"%[seed_value,rid])
            regions.append({"seed":seed_value,"region":rid,"kind":data.spec.kind,"generation_validation_usec":Time.get_ticks_usec()-start})
        w.free();await process_frame
    var result: Dictionary={"checks":checks,"failures":failures,"regions":regions}
    print("V5_REGIONS_RESULT ",JSON.stringify(result))
    var f=FileAccess.open("user://v5-world-results.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));f.close()
    quit(0 if failures.is_empty() else 1)
