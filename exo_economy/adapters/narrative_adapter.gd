extends RefCounted
## The official R13 event bus has a CLOSED event-owner list. Market changes are a private,
## authenticated command; do NOT publish a fabricated economy_* event on the Core bus.
const ALLOWED: Dictionary = {
    "bandit_raid": {"good_id": "*", "impact": 20, "days": 3},
    "caravan_restored": {"good_id": "*", "impact": -8, "days": 2},
    "harvest_boom": {"good_id": "grain", "impact": -18, "days": 3},
    "flood": {"good_id": "rice", "impact": 25, "days": 4},
    "festival": {"good_id": "grain", "impact": 10, "days": 2},
    "herb_shortage": {"good_id": "herbs", "impact": 30, "days": 4},
    "mine_strike": {"good_id": "iron", "impact": 28, "days": 5}
}

static func canonical(request: Dictionary, current_day: int) -> Dictionary:
    var kind: String = str(request.get("kind", ""))
    var region_id: int = int(request.get("region_id", -1))
    var event_id: String = str(request.get("id", ""))
    if not ALLOWED.has(kind) or region_id < 0 or region_id >= 88 or event_id.is_empty() or event_id.length() > 128 or event_id.begins_with("trade/"):
        return {"ok": false, "reason": "invalid_narrative_signal"}
    if current_day < 0 or current_day > 9999990: return {"ok": false, "reason": "invalid_day"}
    var template: Dictionary = ALLOWED[kind]
    return {"ok": true, "id": event_id, "kind": kind, "region_id": region_id,
        "day": current_day, "expires_day": current_day + int(template.days),
        "good_id": str(template.good_id), "impact": int(template.impact)}
