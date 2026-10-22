extends SceneTree
const Game=preload("res://convergence/game.gd")
const Enemy=preload("res://enemy.gd")
const Territory=preload("res://regional_ecology/territories.gd")
const Atlas=preload("res://genesis/world_planner.gd")
const Data=preload("res://genesis/region_data.gd")
const Perimeter=preload("res://fortifications/planner.gd")
var w:Node3D
var checks:Array=[]
var failures:Array=[]
func _initialize()->void:call_deferred("run")
func check(ok:bool,name_value:String)->void:
    print("MURIM_CHECK ",name_value," ",ok);checks.append({"name":name_value,"pass":ok})
    if not ok:failures.append(name_value)
func frames(n:int)->void:
    for i in range(n):await physics_frame
func ground(p:Vector3)->Vector3:return w.regional_spawn(w.active_region,p)
func run()->void:
    for pair in [[101,14],[707,7],[816204,32]]:
        var raw:Dictionary=Atlas.read_atlas("res://genesis/atlas_seed_"+str(pair[0])+".json") if int(pair[0]) in [101,816204] else Atlas.plan(str(pair[0]))
        var atlas:Dictionary=preload("res://genesis/v4/world_plan.gd").decorate(raw,"qa-world")
        var data=Data.new(atlas,int(pair[1]))
        var plan:Dictionary=Perimeter.plan_region(data)
        check(plan.status=="ready","city_perimeter_ready_"+str(pair))
        var protected:bool=true
        var polygon:=PackedVector2Array(plan.get("polygon",[]))
        for site in data.monumental_plans:
            var b:Dictionary=site.bounds
            for x in [float(b.min_x),float(b.max_x)]:
                for z in [float(b.min_z),float(b.max_z)]:
                    if not Geometry2D.is_point_in_polygon(Vector2(x,z),polygon):protected=false
        check(protected,"whole_courtyards_inside_city_ring_"+str(pair))
    w=Game.new();w.load_on_start=false;w.world_seed_override=101
    w.save_path="user://murim-behavior.json";w.settings_path="user://murim-behavior.cfg"
    root.add_child(w);await process_frame
    check(w.exo_core.instances.has("exo_skill_forge"),"skill_forge_catalog_and_host_still_bound")
    w.flow.phase="creator";w.flow.create_character({"name":"Murim QA","race":0,"path":0,"robe":1,"skin":0,"hair":0,"style":0,"weapon":"sword"},101);w.ui.resume()
    for i in range(400):
        if w.current_region>=0 and not w.changing_region:break
        await physics_frame
    check(await w.change_region(14),"city_reported_in_screenshot_loaded")
    var route_checked:int=0
    var entrance_checked:int=0
    var approach_ok:bool=true
    for site in w.active_region.data.monumental_plans:

        var master:Dictionary={};var gate:Dictionary={}
        for station in w.active_region.monument_stations:
            if str(station.get("site_id",""))!=str(site.id):continue
            if str(station.kind)=="master_station":master=station
            if str(station.kind)=="entrance_anchor":gate=station
        if gate.is_empty():approach_ok=false;continue
        entrance_checked+=1
        if master.is_empty():
            var nearest:Vector3=Vector3.INF
            for road in w.active_region.route_points.values():
                if nearest==Vector3.INF or road[-1].distance_squared_to(gate.world_position)<nearest.distance_squared_to(gate.world_position):nearest=road[-1]
            var access:Array=preload("res://convergence/martial_occupancy_r9.gd").physical_approach(w.active_region,nearest,gate.world_position)
            approach_ok=approach_ok and not access.is_empty()
            print("MURIM_MONUMENT_GATE ",site.kind," ",not access.is_empty())
            continue
        var path:Dictionary=preload("res://convergence/martial_occupancy_r9.gd").route_for_site(w.active_region,master,gate)
        print("MURIM_COURTYARD_APPROACH ",site.id," ",path.get("ok",false)," ",path.get("reason",""))
        approach_ok=approach_ok and bool(path.get("ok",false));route_checked+=1
    check(entrance_checked>0 and approach_ok,"physical_street_to_monument_gate_route")
    print("MURIM_GATE_COUNTS ",entrance_checked," master_routes ",route_checked)
    var wild:int=-1
    for region in w.atlas.regions:
        if str(region.kind)=="wild" and str(region.biome) in ["temperate_forest","mixed_woodland"]:wild=int(region.id);break
    check(wild>=0 and await w.change_region(wild),"forest_region_loaded_for_wildlife")
    w.ecology_director.detach()
    var wolf:Dictionary=w.exo_core.services.invoke("bestiary.catalog","get_profile",["wolf"])
    var sites:Array=Territory.build_fauna(w.active_region.data,"101",[wolf],[])
    check(sites.size()>2 and sites.all(func(site):return int(site.group_size)>=3),"planner_sparse_wolf_packs_minimum_three")
    var wolf_spawned:bool=false
    var site_point:=Vector3.ZERO
    for site in sites:
        site_point=Vector3(site.p.x,site.y,site.p.y)
        var anchor:Vector3=ground(site_point+Vector3(30,0,30))
        if not anchor.is_finite():continue
        w.player.position=anchor;w.player.velocity=Vector3.ZERO
        w.camera.position=anchor+Vector3(0,12,0);w.camera.look_at(anchor+Vector3(50,0,50))
        w.ecology_director.region_id=w.current_region;w.ecology_director.sites=[site];w.ecology_director.timer=0
        w.ecology_director.tick(1.0)
        if w.ecology_director.active.size()>=3:wolf_spawned=true;break
    check(wolf_spawned,"three_real_wolves_spawned_atomically_offscreen")
    var starts:Dictionary={}
    for actor in w.ecology_director.active.values():starts[actor.uid]=actor.position
    w.invulnerability=1000
    await frames(210)
    var wildlife_moved:bool=false
    for actor in w.ecology_director.active.values():
        if starts.has(actor.uid) and actor.position.distance_to(starts[actor.uid])>.25:wildlife_moved=true
    check(wildlife_moved,"physical_animals_wander_in_field")
    w.ecology_director.detach()
    var anchor:Vector3=ground(site_point)
    w.player.position=anchor;w.player.velocity=Vector3.ZERO
    var ranged:Node3D
    var flanker:Node3D
    var initial_ranged:float=0
    var flank_start:=Vector3.ZERO
    var tactical_actors:Array=[]
    for index in range(3):
        var actor=Enemy.new();w.add_child(actor)
        var point:Vector3=ground(anchor+[Vector3(2.5,0,0),Vector3(0,0,5),Vector3(-3,0,-2)][index])
        actor.setup(w,"murim_tactic_"+str(index),"blade",point);actor.configure_regional(35,1)
        actor.set_meta("bestiary03_profile",["bandit_archer","dagger_raider","bandit_swordsman"][index])
        preload("res://wardrobe.gd").apply(actor.rig,{"race":0,"robe":3,"skin":0,"hair":0,"weapon":["bow","twin_daggers","sword"][index]})
        actor.cooldown=.3;actor.interest_seconds=12
        w.enemies.append(actor);tactical_actors.append(actor)
        if index==0:ranged=actor;initial_ranged=actor.position.distance_to(w.player.position)
        if index==1:flanker=actor;flank_start=actor.position
    var attack_cap:bool=true
    var ranged_distance:float=initial_ranged
    for frame in range(420):
        await physics_frame
        var winding:int=0
        for actor in tactical_actors:
            if actor.attack_time>=0:winding+=1
        if winding>2:attack_cap=false
        if frame==100:ranged_distance=ranged.position.distance_to(w.player.position)
    check(ranged_distance>initial_ranged+1.0,"archer_physically_retreats_to_keep_range")
    check(flanker.position.distance_to(flank_start)>1.0 and flanker.has_meta("tactical_destination"),"flanker_moves_to_assigned_side")
    check(attack_cap,"group_maximum_two_simultaneous_attackers")
    check(w.bestiary_v4.accepted>0 and w.bestiary_v4.released>0,"catalog_tactics_execute_real_attacks")
    check(ranged.strikes>0,"archer_fires_physical_projectiles")
    var trained_blades:bool=false
    for actor in tactical_actors:
        if not actor.skills_used.is_empty():trained_blades=true
    check(trained_blades,"ordinary_blade_enemy_releases_existing_catalog_skill")
    for actor in tactical_actors:w.enemies.erase(actor);actor.free()
    var mage=Enemy.new();w.add_child(mage)
    mage.setup(w,"murim_skill_mage","mage",ground(anchor+Vector3(0,0,4)))
    mage.configure_regional(35,1);mage.cooldown=0.0;mage.interest_seconds=12.0
    w.enemies.append(mage)
    var catalog_projectiles:int=0
    for frame in range(450):
        await physics_frame
        for shot in w.hostile_shots:
            if str(shot.get("skill_id",""))=="dardo_arcano":catalog_projectiles+=1
    check("dardo_arcano" in mage.skills_used,"ordinary_mage_releases_existing_qi_skill")
    check(catalog_projectiles>0,"ordinary_mage_skill_launches_physical_projectile")
    w.enemies.erase(mage);mage.free()
    w.combat.clear_hostile_shots()
    w.invulnerability=0;w.health=w.max_health
    var blocker:=StaticBody3D.new();blocker.collision_layer=4
    var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(.3,2.5,3.0);shape.shape=box;blocker.add_child(shape)
    w.add_child(blocker);blocker.position=w.player.position+Vector3(1.5,1.25,0)
    await frames(2)
    var hp_before:int=w.health
    w.combat.enemy_orb(w.player.position+Vector3(3,1,0),Vector3.LEFT,8,{"family":"arrow","speed":13.0})
    await frames(40)
    check(w.health==hp_before,"physical_arrow_blocked_by_city_collision_layer")
    check(not w.can_hit(w.player.position+Vector3(3,0,0),w.player.position,Vector3.LEFT,4,-1),"melee_and_skill_los_respect_solid_wall")
    blocker.free();await frames(2)
    w.combat.enemy_orb(w.player.position+Vector3(3,1,0),Vector3.LEFT,8,{"family":"arrow","speed":13.0})
    await frames(40)
    check(w.health<hp_before,"physical_arrow_hits_unobstructed_player")
    w.invulnerability=1000
    w.player.velocity=Vector3.ZERO
    var before:Vector3=w.player.position
    Input.action_press("right");Input.action_press("attack")
    await frames(75)
    Input.action_release("attack");Input.action_release("right")
    check(w.player.position.distance_to(before)>1.6,"player_moves_during_held_attack_combos")
    w.free();await frames(10)
    w=Game.new();w.load_on_start=false;w.world_seed_override=707
    w.save_path="user://murim-prologue.json";w.settings_path="user://murim-prologue.cfg"
    root.add_child(w);await process_frame
    w.journey.data.hero=0;w.flow.start_prologue()
    var sounds:int=w.audio_fx.played
    var max_effects:int=0
    var guardian_seen:bool=false
    var trap_seen:bool=false
    var channel_seen:bool=false
    var leap_seen:bool=false
    var pressure_player_max:int=0
    for frame in range(900):
        await physics_frame
        max_effects=maxi(max_effects,w.effects.size())
        var targeting_player:int=0
        for actor in w.flow.actors:
            if actor.victim==w.player:targeting_player+=1
            if is_instance_valid(actor.guardian):guardian_seen=true
            if not actor.fields.is_empty():trap_seen=true
            if actor.channel_left>0:channel_seen=true
            if actor.position.y>0.65:leap_seen=true
        pressure_player_max=maxi(pressure_player_max,targeting_player)
    var skills:int=0;var moving:int=0;var shots:int=0
    for actor in w.flow.actors:
        skills+=actor.skills_released;shots+=actor.projectiles_released
        if actor.travelled>3.0:moving+=1
    check(w.flow.actors.size()==11,"prologue_eleven_opponents_plus_player")
    check(moving>=8,"prologue_actors_reposition_in_real_physics")
    check(pressure_player_max>=3,"prologue_rotates_pressure_toward_player")
    check(skills>=12,"prologue_uses_hero_catalog_skills")
    check(shots>0,"prologue_has_moving_projectiles")
    check(guardian_seen,"prologue_summons_physical_guardian")
    check(trap_seen,"prologue_persistent_trap_fields")
    check(channel_seen,"prologue_channel_releases_projectile_sequence")
    check(leap_seen,"prologue_leap_moves_actor_off_ground")
    check(max_effects>5 and w.vfx_host_v5.emitted>0,"prologue_existing_vfx_bridge_emits_effects")
    check(w.audio_fx.played>sounds+5,"prologue_plays_existing_combat_and_skill_audio")
    print("MURIM_BATTLE_METRICS ",JSON.stringify({"skills":skills,"actors_moving":moving,"projectiles":shots,"effects_peak":max_effects,"audio_events":w.audio_fx.played-sounds,"vfx_emitted":w.vfx_host_v5.emitted,"vfx_rejected":w.vfx_host_v5.rejected}))
    w.free();await frames(10)
    print("V5_MURIM_FIELD_COMBAT ",JSON.stringify({"checks":checks,"failures":failures}))
    quit(0 if failures.is_empty() else 1)
