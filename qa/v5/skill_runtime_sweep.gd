extends SceneTree
const Game=preload("res://convergence/game.gd")
const Enemy=preload("res://enemy.gd")
const Catalog=preload("res://catalog.gd")
var w:Node3D
var checks:Array=[]
var failures:Array=[]
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
    checks.append({"name":label,"pass":ok})
    if not ok:failures.append(label)
    print("SKILL_CHECK ",label," ",ok)
func frames(n:int)->void:
    for i in range(n):await physics_frame
func run()->void:
    w=Game.new();w.load_on_start=false;w.world_seed_override=101
    w.save_path="user://skill-sweep.json";w.settings_path="user://skill-sweep.cfg"
    root.add_child(w);await process_frame
    var skill_summary:Dictionary=w.exo_core.services.invoke("skill_forge","summary")
    var skill_contract:Dictionary=w.exo_core.services.invoke("skill_forge","compatibility_status")
    check(int(skill_summary.get("legacy",-1))==16 and int(skill_summary.get("authorial_candidates",-1))==168,"skill_forge_catalog_counts_are_explicit")
    check(bool(skill_contract.get("generic_host_bound",false)),"player_authorial_combat_host_bound")
    var runtime_candidates:int=0
    var runtime_actions_covered:bool=true
    for skill in Catalog.SKILLS:
        if not skill.has("forge_id"):continue
        runtime_candidates+=1
        var candidate_plan:Dictionary=w.exo_core.services.invoke("skill_forge","plan",[str(skill.id),{"type":"player"}])
        if not bool(candidate_plan.get("ok",false)):runtime_actions_covered=false;continue
        for action in candidate_plan.actions:
            if str(action.op) not in ["damage","status","shield","heal"]:runtime_actions_covered=false
            if str(action.op)=="damage" and str(action.get("shape","")) not in ["circle","cone","line"]:runtime_actions_covered=false
            if str(action.op)=="status" and str(action.get("status","")) not in ["slow","stagger","root","knockback"]:runtime_actions_covered=false
    check(runtime_candidates==70,"seventy_authorial_skills_have_player_runtime_adapters")
    check(runtime_actions_covered,"all_seventy_authorial_plans_use_bound_effect_types")
    var hostile_attempt:Dictionary=w.exo_core.services.invoke("skill_forge","authorized_cast",["enemy/qa","exo.sf.fio_do_bambu"])
    check(not bool(hostile_attempt.get("committed",false)),"authorial_host_does_not_falsely_accept_enemy_cast")
    w.flow.phase="creator"
    w.flow.create_character({"name":"Skill QA","race":0,"path":0,"robe":1,"skin":0,"hair":0,"style":0,"weapon":"sword"},101)
    w.ui.resume()
    for i in range(400):
        if w.current_region>=0 and not w.changing_region:break
        await physics_frame
    var wild:int=-1
    for region in w.atlas.regions:
        if str(region.kind)=="wild" and str(region.biome)=="grassland":wild=int(region.id);break
    if wild<0:
        for region in w.atlas.regions:
            if str(region.kind)=="wild":wild=int(region.id);break
    check(wild>=0 and await w.change_region(wild),"wild_combat_region_loaded")
    w.ecology_director.detach()
    var anchor:Vector3=w.player.position
    check(anchor.is_finite(),"arrival_anchor_finite")
    w.player.position=anchor;w.player.velocity=Vector3.ZERO
    w.facing=Vector3.FORWARD;w.invulnerability=1000
    var dummy=Enemy.new();w.add_child(dummy)
    dummy.setup(w,"skill_sweep_target","blade",anchor+Vector3(0,0,-2))
    dummy.enabled=false;dummy.max_hp=9999;dummy.hp=9999;dummy.regional_mode=true
    w.enemies.append(dummy)
    for spec in Catalog.SKILLS:
        if str(spec.id).begins_with("exo.sf."):continue
        var id:String=str(spec.id)
        w.player.position=anchor;w.player.velocity=Vector3.ZERO;w.facing=Vector3.FORWARD
        await frames(3)
        dummy.position=anchor+Vector3(0,0,-2)
        dummy.hp=9999;dummy.visible=true;dummy.collision_layer=4
        w.techniques.configure([id]);w.techniques.reset();w.health=w.max_health-35
        w.attack_time=-1;w.roll_time=-1
        var hp_before:int=dummy.hp
        var health_before:int=w.health
        var position_before:Vector3=w.player.position
        var started:bool=w.techniques.cast(0)
        check(started,id+"_cast_authorized")
        if not started:continue
        var released:bool=false
        var physical:bool=false
        for i in range(190):
            await physics_frame
            if w.techniques.released:released=true
            match str(spec.kind):
                "cut","projectile":physical=physical or w.techniques.projectiles.size()>0
                "area","root","pull","repel","channel":physical=physical or dummy.hp<hp_before
                "dash":physical=physical or w.player.position.distance_to(position_before)>1.0
                "leap":physical=physical or w.techniques.landings>0
                "shield":physical=physical or w.techniques.shield>0
                "heal":physical=physical or w.health>health_before
                "trap":physical=physical or w.techniques.fields.size()>0
                "summon":physical=physical or w.techniques.summons.size()>0
            if released and physical and not w.techniques.busy():break
        check(released,id+"_released")
        check(physical,id+"_physical_effect")
        if str(spec.kind) in ["cut","projectile"]:
            check(dummy.hp<hp_before,id+"_hits_physical_target")
        if id=="bola_de_gelo":check(dummy.slow>0.0,"ice_projectile_applies_slow")
        if id=="nova_glacial":check(dummy.root_timer>0.0,"frost_burst_roots_target")
        w.techniques.reset()
    # Exercise the already-bound player host with a matching training state.
    # This fixture uses the real in-process permit, save and release path.
    var forge_id:String="exo.sf.sete_cortes_do_vento"
    var martial:Dictionary=w.journey.data.get("exo_martial",{})
    var learner:String=preload("res://exo_core/contracts/entity_contracts.gd").player_id(w.journey.data)
    var master:String="npc/r01/qa_master"
    martial.profiles[master]={"npc_id":master,"school_id":"exo_martial.school.seita_bambu","style_id":"exo_martial.style.sword_swift","temperament":"benevolente","power":20,"max_disciples":8,"techniques":[],"secondary_styles":[],"secret_technique_id":""}
    var training_key:String=preload("res://exo_martial/r2/engine_r2.gd").key(learner,master)
    martial.training[training_key]={"learner_id":learner,"master_id":master,"rank":3,"mastery":0,"practice":0,"lesson_goal":0,"completed_lessons":0,"phase":"ready","learned":{},"active":true,"lesson_id":"","r2":{"lesson_seq":0,"practice_done":0,"refusals":0,"observation_done":false,"exam_passed":false,"pending_unlock":"","outcome":"active","school_id":"exo_martial.school.seita_bambu","transfer_from":"","exam_history":{}}}
    w.journey.data["exo_martial"]=martial
    w.journey.data.journey_dynamic.progress.level=50
    if forge_id not in w.journey.data.known:w.journey.data.known.append(forge_id)
    if forge_id not in w.journey.data.learned:w.journey.data.learned.append(forge_id)
    w.journey.data.loadout[0]=forge_id
    check(w.save_progress(),"authorial_training_fixture_valid_for_real_save")
    w.techniques.configure(w.journey.data.loadout);w.techniques.reset()
    dummy.hp=9999;dummy.position=anchor+Vector3(0,0,-2)
    w.player.position=anchor;w.facing=Vector3.FORWARD;w.attack_time=-1;w.roll_time=-1
    var plan:Dictionary=w.exo_core.services.invoke("skill_forge","plan",[forge_id,{"type":"player"}])
    check(w.activation_v4.reason(plan).is_empty(),"trained_authorial_skill_passes_host_requirements")
    var authorial_started:bool=w.techniques.cast(0)
    check(authorial_started,"authorial_player_cast_committed_by_existing_host")
    for i in range(90):await physics_frame
    check(w.activation_v4.releases>0 and dummy.hp<9999,"authorial_player_skill_releases_and_hits")
    w.enemies.erase(dummy);dummy.free()
    print("V5_SKILL_RUNTIME_SWEEP ",JSON.stringify({"checks":checks,"failures":failures}))
    quit(0 if failures.is_empty() else 1)
