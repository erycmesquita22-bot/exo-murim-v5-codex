extends RefCounted
# Declarative executor registry: implemented means authoritative event is known,
# not that a story/objective was instantiated or a runtime hook was wired.
const AVAILABLE={
    "visit_region":{"owner":"world","event":"region_entered","scope":"real_atlas"},
    "talk_npc":{"owner":"living_world","event":"npc_interacted","scope":"persistent_npc_uid"},
    "defeat_enemy":{"owner":"combat","event":"enemy_defeated","scope":"real_generation"},
    "collect_item":{"owner":"inventory","event":"item_collected","scope":"materialized_receipt"}
}
const WAITING={
    "enter_interior":"interior_owner_checkpoint_missing",
    "inspect_evidence":"evidence_verification_contract_missing",
    "confirm_rumor":"narrative_fact_commit_contract_missing",
    "deliver_item":"inventory_transaction_contract_missing_for_v4",
    "buy_or_sell":"economy_r5_transaction_service_not_wired",
    "escort_npc":"escort_ai_event_contract_missing",
    "defend_route":"route_escort_proof_missing",
    "martial_exam":"martial_master_evaluation_contract_missing",
    "dungeon_artifact":"dungeon_item_receipt_binding_missing_for_v4",
    "branch_decision":"narrative_story_commit_contract_missing"
}
static func info(type_id: String) -> Dictionary:
    if AVAILABLE.has(type_id):
        var detail: Dictionary=AVAILABLE[type_id].duplicate(true)
        detail.status="EVENT_CONTRACT_KNOWN_NOT_WIRED"
        return detail
    return {"status":"BLOCKED","reason":str(WAITING.get(type_id,"unknown_objective_type"))}
