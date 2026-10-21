extends RefCounted
## City Forge R2 uses its own service 'city_forge.plans'. This adapter never mutates city geometry.
static func preview_market(core: RefCounted, city_plan: Dictionary) -> Dictionary:
    if core == null or not core.services.has_service("economy"):
        return {"ok": false, "reason": "economy_service_absent"}
    if str(city_plan.get("status", "")) != "ready":
        return {"ok": false, "reason": "city_plan_not_ready"}
    var result: Variant = core.services.invoke("economy", "market_preview", [int(city_plan.get("region_id", -1)), city_plan])
    return result if result is Dictionary else {"ok": false, "reason": "economy_service_unavailable"}
