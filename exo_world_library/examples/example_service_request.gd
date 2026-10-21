extends RefCounted
const Bridge = preload("res://exo_world_library/integration/read_only_bridge.gd")

static func preview_npc_for_region() -> Dictionary:
    var bridge: Variant = Bridge.new()
    if not bridge.initialize():
        return {"status":"BLOCKED", "reason":bridge.last_error}
    # world_id, seed and region_id MUST come from the current authoritative campaign.
    var context: Dictionary = {
        "world_id":"demo-only", "seed":101, "region_id":78,
        "biome":"bamboo_forest", "settlement_type":"town", "player_tier":1,
        "tags":["martial", "sect", "river_access"], "flags":[]
    }
    return bridge.catalog_preview("living_world", context,
        ["npc_archetype", "npc_background", "personality", "npc_motivation", "name_family", "name_given"])
