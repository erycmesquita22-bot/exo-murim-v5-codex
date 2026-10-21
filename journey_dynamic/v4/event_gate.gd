extends RefCounted
# C3 EXO Core event contracts are authoritative: no second event bus.
const CoreEvents=preload("res://exo_core/contracts/event_contracts.gd")
const KNOWN=["region_entered","npc_interacted","enemy_defeated","item_collected","narrative_decision"]
static func inspect(event: Dictionary, expected_world_id: String) -> Dictionary:
    if not CoreEvents.valid(event):return {"ok":false,"reason":"core_contract_rejected"}
    if str(event.get("type","")) not in KNOWN:return {"ok":false,"reason":"not_journey_consumable"}
    if str(expected_world_id).is_empty():return {"ok":false,"reason":"world_id_missing"}
    # Core v1 does not have world_id in the event; the trusted subscriber must attach it.
    if str(event.get("world_id",""))!=expected_world_id:return {"ok":false,"reason":"world_scope_not_bound"}
    var t: String=str(event.type)
    if t=="npc_interacted" and str(event.context.get("npc_id","")).is_empty():return {"ok":false,"reason":"target_npc_missing"}
    if t=="enemy_defeated" and str(event.context.get("enemy_uid","")).is_empty():return {"ok":false,"reason":"kill_proof_missing"}
    if t=="item_collected" and (str(event.context.get("source","")).is_empty() or not event.context.get("items") is Array):return {"ok":false,"reason":"item_receipt_incomplete"}
    if t=="narrative_decision":return {"ok":false,"reason":"catalog_arc_owner_commit_not_registered"}
    return {"ok":true,"status":"CORE_EVENT_ELIGIBLE","event_id":str(event.id),"event_type":t}
