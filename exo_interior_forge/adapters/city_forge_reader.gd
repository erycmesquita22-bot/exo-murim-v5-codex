extends RefCounted
## City R3 read-only normalization; R4 mapping is deliberately version-gated.
const Catalog = preload("res://exo_interior_forge/runtime/interior_catalog.gd")

static func candidate_for_building(world_context: Dictionary, city_building: Dictionary, district: Dictionary, saved_receipt: Dictionary = {}) -> Dictionary:
    var context: Dictionary = world_context.duplicate(true)
    # Never use a reused district template ID as a global building ID.
    for key in ["lot_instance_id", "building_local_id", "world_id", "world_seed", "region_id", "settlement_id"]:
        if not context.has(key):
            return {"ok": false, "code": "missing_" + key}
    context["function"] = str(city_building.get("function", ""))
    context["template_id"] = str(city_building.get("id", ""))
    context["tags"] = district.get("tags", [])
    return Catalog.select_or_reuse(context, saved_receipt)
