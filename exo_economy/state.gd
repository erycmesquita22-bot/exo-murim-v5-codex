extends RefCounted
## Additive save domain only. Does not duplicate balances or NPC/market inventories.
const MAX_RECEIPTS: int = 16384
const MAX_EVENTS: int = 128
const MAX_DAYS: int = 10000000

static func fresh(seed: String) -> Dictionary:
    return {"schema": 1, "seed": seed, "receipts": {}, "events": {}, "shops": {}}

static func valid(state: Variant) -> bool:
    if not state is Dictionary: return false
    if state.get("schema") != 1 or not state.get("seed") is String: return false
    if str(state.seed).length() > 100 or not state.get("receipts") is Dictionary or not state.get("events") is Dictionary: return false
    if state.receipts.size() > MAX_RECEIPTS or state.events.size() > MAX_EVENTS: return false
    if not state.get("shops", {}) is Dictionary or state.get("shops", {}).size() > 2048: return false
    for vendor_id in state.get("shops", {}):
        var shop: Variant = state.shops[vendor_id]
        if not vendor_id is String or str(vendor_id).is_empty() or not shop is Dictionary: return false
        if not _integer_between(shop.get("region_id", -1), 0, 87): return false
        if not _integer_between(shop.get("treasury_wen", -1), 0, 1000000000): return false
        if not _integer_between(shop.get("revision", -1), 0, 1000000000): return false
        if not shop.get("stock") is Dictionary or not shop.get("demand") is Dictionary: return false
        for good_id in shop.stock:
            if not good_id is String or not _integer_between(shop.stock[good_id], 0, 500): return false
        for good_id in shop.demand:
            if not good_id is String or not _integer_between(shop.demand[good_id], -500, 500): return false
    for receipt in state.receipts:
        if not receipt is String or str(receipt).is_empty() or str(receipt).length() > 128: return false
        if not state.receipts[receipt] is String or str(state.receipts[receipt]).length() != 64: return false
    for key in state.events:
        var event: Variant = state.events[key]
        if not key is String or not event is Dictionary: return false
        if str(key).length() > 128 or str(event.get("kind", "")).is_empty(): return false
        if not _integer_between(event.get("region_id", -1), 0, 87): return false
        if not _integer_between(event.get("day", -1), 0, MAX_DAYS): return false
        if not _integer_between(event.get("expires_day", -1), 0, MAX_DAYS): return false
        if not _integer_between(event.get("impact", -999), -100, 100): return false
        if int(event.day) > int(event.expires_day): return false
        if event.get("good_id", "") is not String: return false
    return true

static func _integer_between(v: Variant, minimum: int, maximum: int) -> bool:
    return (v is int or v is float) and is_finite(float(v)) and int(v) == v and int(v) >= minimum and int(v) <= maximum

static func ensure(save_data: Dictionary) -> bool:
    if not save_data.get("world") is Dictionary: return false
    var seed: String = str(save_data.world.get("seed", ""))
    if seed.is_empty(): return false
    if not save_data.has("exo_economy"):
        save_data["exo_economy"] = fresh(seed)
    # Additive R2->R5 compatibility: old saves acquire empty shop domain; never rewrite an on-disk save here.
    if save_data.exo_economy is Dictionary and not save_data.exo_economy.has("shops"):
        save_data.exo_economy["shops"] = {}
    return valid(save_data.exo_economy) and str(save_data.exo_economy.seed) == seed

static func impact_for(state: Dictionary, region_id: int, good_id: String, day: int) -> int:
    var result: int = 0
    for key in state.get("events", {}):
        var event: Dictionary = state.events[key]
        if int(event.get("region_id", -1)) != region_id: continue
        if day < int(event.get("day", 0)) or day > int(event.get("expires_day", -1)): continue
        var target: String = str(event.get("good_id", ""))
        if target == "*" or target == good_id:
            result += int(event.get("impact", 0))
    return clampi(result, -50, 75)

static func stage_event(state: Dictionary, event: Dictionary) -> Dictionary:
    var event_id: String = str(event.get("id", ""))
    if event_id.is_empty() or event_id.length() > 128: return {"ok": false, "reason": "invalid_id"}
    var fingerprint: String = JSON.stringify(event).sha256_text()
    if state.receipts.has(event_id):
        if str(state.receipts[event_id]) == fingerprint: return {"ok": true, "duplicate": true}
        return {"ok": false, "reason": "receipt_collision"}
    if state.receipts.size() >= MAX_RECEIPTS: return {"ok": false, "reason": "receipt_limit"}
    if state.events.size() >= MAX_EVENTS: return {"ok": false, "reason": "event_limit"}
    var candidate: Dictionary = state.duplicate(true)
    candidate.receipts[event_id] = fingerprint
    candidate.events[event_id] = event.duplicate(true)
    if not valid(candidate): return {"ok": false, "reason": "invalid_market_event"}
    state.clear()
    state.merge(candidate, true)
    return {"ok": true, "duplicate": false}

static func prune_expired(state: Dictionary, day: int) -> int:
    var removed: int = 0
    for key in state.get("events", {}).keys():
        if day > int(state.events[key].get("expires_day", MAX_DAYS)):
            state.events.erase(key)
            removed += 1
    return removed
