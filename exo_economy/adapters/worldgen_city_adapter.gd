extends RefCounted
## Read-only R13 WorldGenesis and R2 City Forge bridge. Only their official owners place terrain, streets and lots.
const Market = preload("res://exo_economy/market.gd")

static func region_from_atlas(atlas: Dictionary, region_id: int) -> Dictionary:
    var regions: Variant = atlas.get("regions", [])
    if not regions is Array or region_id < 0 or region_id >= regions.size() or region_id >= 88: return {}
    var candidate: Variant = regions[region_id]
    if not candidate is Dictionary or int(candidate.get("id", -1)) != region_id: return {}
    if not Market.valid_region(candidate): return {}
    return candidate.duplicate(true)

static func export_city(plan: Dictionary, spec: Dictionary) -> Dictionary:
    # Same public R2 format as city_forge.plans.export_city_plan(). No invented APIs.
    if str(plan.get("status", "")) != "ready": return {}
    if int(plan.get("region_id", -1)) != int(spec.get("id", -2)): return {}
    if not plan.get("sectors", null) is Array or not plan.get("buildings", null) is Array: return {}
    for sector in plan.sectors:
        if not sector is Dictionary or not sector.get("category") is String: return {}
    return plan.duplicate(true)

static func profile_from_region(region: Node3D) -> Dictionary:
    if not is_instance_valid(region): return {"ok": false, "reason": "region_missing"}
    var data: Variant = region.get("data")
    if data == null: return {"ok": false, "reason": "region_data_missing"}
    var spec: Variant = data.get("spec")
    if not spec is Dictionary: return {"ok": false, "reason": "spec_missing"}
    var candidate: Variant = region.get_meta("exo_city_forge_economy_plan", {})
    var plan: Dictionary = export_city(candidate, spec) if candidate is Dictionary else {}
    return Market.profile(spec, plan)
