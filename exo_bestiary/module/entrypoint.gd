extends RefCounted
const Catalog=preload("res://exo_bestiary/catalog/species_catalog.gd")
const Behavior=preload("res://exo_bestiary/ai/behavior_controller.gd")
const Encounters=preload("res://exo_bestiary/ecology/encounter_planner.gd")
const Tactics=preload("res://exo_bestiary/v3/group_tactics.gd")
const CombatBrain=preload("res://exo_bestiary/v3/combat_brain.gd")
const SkillBridge=preload("res://exo_bestiary/v3/skill_bridge.gd")
const AnimationTiming=preload("res://exo_bestiary/v3/animation_timing.gd")
var core: RefCounted
var catalog
func initialize(context) -> bool:
    core=context
    catalog=Catalog.new()
    if not catalog.load_data():return false
    if not context.services.register_service("bestiary.catalog","bestiary",self,["get_profile","list_profiles","summary"]):return false
    if not context.services.register_service("bestiary.ai","bestiary",self,["new_controller"]):return false
    if not context.services.register_service("bestiary.encounters","bestiary",self,["suggest"]):return false
    if not context.services.register_service("bestiary.combat","bestiary",self,["attack_profile"]):return false
    if not context.services.register_service("bestiary.tactics","bestiary",self,["plan_group","plan_actor","skill_suggestions","timing_preview","compatibility_status"],"3.0.0"):return false
    return true
func get_profile(id: String) -> Dictionary:return catalog.get_profile(id)
func list_profiles(category: String = "") -> Array:return catalog.list_profiles(category)
func summary() -> Dictionary:return catalog.summary()
func new_controller(id: String) -> RefCounted:
    var p: Dictionary=catalog.get_profile(id)
    if p.is_empty():return null
    var ai: RefCounted=Behavior.new(); ai.configure(p);return ai
func suggest(region: Dictionary, candidates: Array, seed: int, max_new: int=2) -> Array:
    return Encounters.suggest(catalog,region,candidates,seed,max_new)
func attack_profile(id: String) -> Dictionary:
    if catalog==null:return {}
    var attack: Dictionary=catalog.get_attack(id)
    if attack.is_empty():return {}
    # O catálogo só descreve ataque/alcance; dano tem autoridade limitada no host.
    var damage: Dictionary={"kick":4,"headbutt":6,"charge":9,"tusk_charge":10,"paw_slam":12,"bite":7,"lunge":8,"pounce":11,"quick_bite":5,"short_slash":7,"spear_thrust":8}
    attack["damage"]=int(damage.get(id,5))
    return attack
func shutdown() -> void:
    catalog=null;core=null

# V3: API consultiva adicionada sem alterar os endpoints antigos do Bestiário 02.
func plan_group(request: Dictionary) -> Dictionary:
    if catalog == null:return {"status":"BLOCKED","reason":"catalog_not_loaded","committed":false}
    return Tactics.propose(request,catalog)
func plan_actor(profile_id: String, snapshot: Dictionary, order: Dictionary = {}) -> Dictionary:
    if catalog == null:return {"status":"BLOCKED","reason":"catalog_not_loaded","committed":false}
    return CombatBrain.decide(catalog.get_profile(profile_id),catalog,snapshot,order)
func skill_suggestions(profile_id: String, actor: Dictionary, candidate_ids: Array) -> Dictionary:
    if catalog == null:return {"status":"BLOCKED","reason":"catalog_not_loaded","committed":false}
    return SkillBridge.suggest(core,catalog.get_profile(profile_id),actor,candidate_ids)
func timing_preview(profile_id: String) -> Dictionary:
    if catalog == null:return {"status":"BLOCKED","reason":"catalog_not_loaded"}
    return AnimationTiming.preview(catalog.get_profile(profile_id))
func compatibility_status() -> Dictionary:
    var available: Dictionary={}
    for service in ["bestiary.catalog","bestiary.combat","skill_forge","npc03.agenda","content.library","city_forge.plans","creatures.visuals"]:
        available[service]=core != null and core.services != null and core.services.has_service(service)
    return {"module":"bestiary","version":"3.0.0","status":"PROPOSAL_ONLY",
        "schema_version":3,"services":available,"physical_enemy_hook":"PENDING_HOST_OPT_IN",
        "damage_owner":"combat","spawn_owner":"regional_ecology",
        "save_owner":"JourneySave/SaveCoordinator","writes_save":false,"creates_actors":false,
        "converts_crowd_to_enemy":false,"committed":false}
