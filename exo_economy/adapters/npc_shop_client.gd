extends RefCounted
## LivingWorld/NPC System remains the authority for real merchants and shops.
## This is an invocation client, never a new NPC writer or merchant spawner.
static func readonly_quote(core: RefCounted, region_id: int, good_id: String, side: String, qty: int, approved_city_plan: Dictionary = {}) -> Dictionary:
    if core == null or not core.services.has_service("economy"):
        return {"ok": false, "reason": "economy_service_absent"}
    var request: Dictionary = {"region_id": region_id, "good_id": good_id, "side": side,
        "quantity": qty, "city_plan": approved_city_plan}
    var outcome: Variant = core.services.invoke("economy", "quote_request", [request])
    return outcome if outcome is Dictionary else {"ok": false, "reason": "economy_quote_unavailable"}
