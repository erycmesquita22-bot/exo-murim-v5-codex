extends RefCounted
## Bridge for EXO Crowd Illusion 01 R2: reads merchant activity, never creates NPCs or manages actor ownership.
const Market = preload("res://exo_economy/market.gd")
const State = preload("res://exo_economy/state.gd")

static func market_signal(spec: Dictionary, plan: Dictionary, state: Dictionary, day: int, time_hour: int, area: Dictionary = {}) -> Dictionary:
    var profile: Dictionary = Market.profile(spec, plan)
    if not bool(profile.get("ok", false)): return {"ok": false, "reason": "invalid_profile"}
    var category: String = str(area.get("category", area.get("role", "")))
    var merchant_factor: float = clampf(float(profile.prosperity_percent) / 100.0, 0.65, 1.12)
    if category in ["commercial", "commerce", "artisan", "merchant"]: merchant_factor *= 1.07
    var shortage: int = State.impact_for(state, int(profile.region_id), "grain", day)
    if shortage >= 20: merchant_factor *= 0.82
    var active_hours: bool = time_hour >= 7 and time_hour < 20
    return {"ok": true, "region_id": int(profile.region_id), "market_activity": clampf(merchant_factor, 0.45, 1.25),
        "active_hours": active_hours, "scarcity": shortage >= 20, "source": "economy_read_only",
        "real_npcs_created": 0, "transactional_actors_created": 0}

static func adjust_zones(spec: Dictionary, plan: Dictionary, state: Dictionary, zones: Array, area_index: Dictionary, day: int, time_hour: int) -> Dictionary:
    var result: Array = []
    if zones.size() > 256: return {"ok": false, "reason": "excessive_zones"}
    for zone in zones:
        if not zone is Dictionary: return {"ok": false, "reason": "invalid_zone"}
        var output: Dictionary = zone.duplicate(true)
        var role: String = str(zone.get("role", ""))
        if role == "merchant":
            var area: Variant = area_index.get(str(zone.get("id", "")), {})
            var s: Dictionary = market_signal(spec, plan, state, day, time_hour, area if area is Dictionary else {})
            if not bool(s.get("ok", false)): return s
            # Original Ghost owns its own night schedule. We only change an economic weight.
            var factor: float = float(s.market_activity)
            output["capacity"] = clampi(int(round(float(zone.get("capacity", 0)) * factor)), 0, 60)
        result.append(output)
    return {"ok": true, "zones": result, "zone_count": result.size(), "source": "exo_economy/1", "owner": "crowd_illusion"}
