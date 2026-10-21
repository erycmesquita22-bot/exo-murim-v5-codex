extends SceneTree
const Catalog=preload("res://exo_bestiary/catalog/species_catalog.gd")
const VariantGen=preload("res://exo_bestiary/catalog/variant_generator.gd")
const AI=preload("res://exo_bestiary/ai/behavior_controller.gd")
const Selector=preload("res://exo_bestiary/ai/utility_selector.gd")
const Threat=preload("res://exo_bestiary/ai/threat_evaluator.gd")
const Group=preload("res://exo_bestiary/ai/group_coordinator.gd")
const Encounter=preload("res://exo_bestiary/ecology/encounter_planner.gd")
const Population=preload("res://exo_bestiary/ecology/population_planner.gd")
const Combat=preload("res://exo_bestiary/combat/combat_adapter.gd")
var passes:=0
var failures: Array[String]=[]
func _initialize() -> void:
    var c=Catalog.new()
    check(c.load_data(),"catalog_load")
    if failures.size()>0: _end();return
    var s: Dictionary=c.summary()
    check(s.species>=12 and s.humanoids>=8 and s.elites>=3 and s.bosses>=2,"catalog_minimums")
    var all: Array=c.list_profiles();var ids: Dictionary={}
    for p in all:
        check(not ids.has(p.id),"unique_"+str(p.id));ids[p.id]=true
    var wolf: Dictionary=c.get_profile("wolf")
    var seed_a: Dictionary=VariantGen.variant_for(wolf,101,"eco/r07/t02/m000/g0000")
    var seed_b: Dictionary=VariantGen.variant_for(wolf,101,"eco/r07/t02/m000/g0000")
    check(seed_a==seed_b,"variants_deterministic")
    check(seed_a != VariantGen.variant_for(wolf,102,"eco/r07/t02/m000/g0000"),"variants_seed_separated")
    var prey=AI.new();prey.configure(c.get_profile("deer"))
    var fleeing: Dictionary=prey.step({"hp_ratio":1.0,"predator_visible":true,"territory_exists":true,"target_visible":true,"distance":6},.25)
    check(fleeing.state=="FLEE","deer_flee")
    var boar=AI.new();boar.configure(c.get_profile("boar"))
    check(boar.step({"hp_ratio":1.0,"territory_exists":true,"target_visible":true,"intruding":false,"distance":4},.25).state=="OBSERVE","boar_observe")
    check(boar.step({"hp_ratio":1.0,"territory_exists":true,"target_visible":true,"intruding":true,"distance":4},.25).state!="OBSERVE","boar_intrusion")
    check(boar.step({"hp_ratio":1.0,"territory_exists":true,"outside_territory":true,"target_visible":true},.25).state=="RETURN_HOME","boar_leash")
    var elite: Dictionary=c.get_profile("elite_iron_guard")
    check(elite.get("base_id","")=="defensive_mercenary" and elite.get("combat_style","")=="defensive","elite_inheritance")
    var chief=AI.new();chief.configure(c.get_profile("boss_mountain_hermit"))
    check(chief.step({"hp_ratio":.3,"territory_exists":true,"target_visible":true,"intruding":true,"distance":2.2},.25).phase==1,"boss_phase_transition")
    var ranger=AI.new();ranger.configure(c.get_profile("bandit_archer"))
    var melee=AI.new();melee.configure(c.get_profile("bandit_swordsman"))
    var ctx: Dictionary={"hp_ratio":1.0,"territory_exists":true,"target_visible":true,"line_of_sight":true,"attack_ready":true,"distance":1.8}
    check(ranger.step(ctx,.5).intent != melee.step(ctx,.5).intent,"different_human_tactics")
    check(melee.step({"hp_ratio":0.0},.2).state=="DEFEATED","defeated_terminal")
    check(melee.step(ctx,.2).state=="DEFEATED","defeated_stays_terminal")
    check(Group.assign(["b","c","a"],Vector3.ZERO).size()==3,"group_positions")
    check(Group.leader_lost(["b","c","a"],"a")=="b","group_leader_loss")
    check(Population.evolve(50,60,.1,30)<=60,"population_capped")
    var sites: Array=[{"position":Vector3(2,0,3),"surface_valid":true,"visible":false,"protected":false},{"position":Vector3(3,0,4),"surface_valid":false,"visible":false,"protected":false}]
    check(Encounter.suggest(c,{"id":7,"biome":"forest"},sites,101,5).size()==1,"safe_spawn_filter")
    var adapter=Combat.new()
    check(adapter.request_attack("actor",c.get_attack("bite"),"victim").status=="BLOCKED","no_parallel_damage")
    check(Threat.should_flee(c.get_profile("deer"),{"predator_visible":true}),"threat_flee")
    _end()
func check(condition: bool,tag: String) -> void:
    if condition:passes+=1
    else: failures.append(tag)
func _end() -> void:
    print("EXO_BESTIARY_02_QA ",JSON.stringify({"passed":passes,"failures":failures,"status":"PASS" if failures.is_empty() else "FAIL"}))
    quit(0 if failures.is_empty() else 1)
