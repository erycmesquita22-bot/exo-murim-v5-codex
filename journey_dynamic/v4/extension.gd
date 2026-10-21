extends RefCounted
const Schema=preload("res://journey_dynamic/v4/schema.gd")
const Compiler=preload("res://journey_dynamic/v4/compiler.gd")
const Gate=preload("res://journey_dynamic/v4/physical_gate.gd")
# One quest manager: V4 is an additive, read-mostly capability of quest_manager.gd.
static func fresh() -> Dictionary:return Schema.fresh()
static func valid_storage(v: Variant) -> bool:return Schema.valid_storage(v)
static func inspect(legacy: Dictionary) -> Dictionary:
    var stored: Variant=legacy.get("v4",null)
    return {"status":"PROPOSAL_ONLY" if stored==null or Schema.valid_storage(stored) else "INVALID_STORAGE",
        "legacy_active":legacy.get("quests",{}).size(),"legacy_rewarded":legacy.get("rewarded",{}).size(),
        "v4_present":stored!=null,"reason":"narrative_story_commit_API_not_proven"}
static func preview(world: Object,record: Dictionary,context: Dictionary) -> Dictionary:
    var version: String=str(context.get("catalog_version",""))
    var compiled: Dictionary=Compiler.compile_story(record,version)
    if not bool(compiled.get("ok",false)):return compiled
    var locator: Variant=context.get("locator",null)
    if not (locator is Dictionary):return {"ok":false,"status":"BLOCKED","reason":"physical_locator_missing","definition":compiled.definition}
    var probe: Dictionary=Gate.verify(world,locator)
    if not bool(probe.get("ok",false)):return {"ok":false,"status":"BLOCKED","reason":probe.get("reason","physical_validation_failed"),"definition":compiled.definition}
    var worldid: String=str(context.get("world_id",""))
    var playerid: String=str(context.get("player_uid",""))
    var slot: String=str(context.get("slot","0"))
    if worldid.is_empty() or playerid.is_empty() or slot.length()>32:return {"ok":false,"status":"BLOCKED","reason":"identity_incomplete"}
    var stable_id: String="j02/"+(worldid+"|"+playerid+"|"+str(record.id)+"|"+slot).sha256_text().substr(0,32)
    return {"ok":true,"status":"PROPOSAL_ONLY","instance_id":stable_id,"story_id":str(record.id),"catalog_version":version,
        "locator":locator.duplicate(true),"physical_probe":probe,"definition":compiled.definition,"requires_narrative_authority":true,"acceptance_authorized":false,"committed":false}
static func request_accept(_world: Object,_proposal: Dictionary) -> Dictionary:
    # A registered Narrative/SaveCoordinator transaction API is required.
    # It is ABSENT for R4 story_arcs in the audited C3 Work candidate.
    return {"ok":false,"status":"BLOCKED","reason":"narrative_story_commit_API_not_proven","committed":false}
static func request_choice(_world: Object,_instance: Dictionary,_choice_id: String) -> Dictionary:
    return {"ok":false,"status":"BLOCKED","reason":"narrative_choice_commit_API_not_proven","committed":false}
static func request_reward(_world: Object,_instance: Dictionary) -> Dictionary:
    return {"ok":false,"status":"BLOCKED","reason":"atomic_reward_owner_contract_not_bound","committed":false}
