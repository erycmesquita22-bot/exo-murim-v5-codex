extends RefCounted
## The 88-region travel graph is read directly from R13 atlas.regions[id].entrances.
## No transport simulation, new streets, caravans or money are spawned here.
const WorldCity = preload("res://exo_economy/adapters/worldgen_city_adapter.gd")
const State = preload("res://exo_economy/state.gd")

static func links(atlas: Dictionary, region_id: int, economy_state: Dictionary, day: int) -> Dictionary:
    var spec: Dictionary = WorldCity.region_from_atlas(atlas, region_id)
    if spec.is_empty(): return {"ok": false, "reason": "official_worldgen_region_unavailable"}
    var neighbors: Array = []
    var seen: Dictionary = {}
    for exit in spec.get("entrances", []):
        if not exit is Dictionary: continue
        var neighbor_id: int = int(exit.get("neighbor", -1))
        if neighbor_id < 0 or neighbor_id >= 88 or seen.has(neighbor_id): continue
        var neighbor: Dictionary = WorldCity.region_from_atlas(atlas, neighbor_id)
        if neighbor.is_empty(): continue
        seen[neighbor_id] = true
        var exposure: int = State.impact_for(economy_state, region_id, "grain", day)
        var danger: String = "high" if exposure >= 20 else "normal"
        neighbors.append({"region_id": neighbor_id, "biome": str(neighbor.get("biome", "")),
            "settlement": str(neighbor.get("kind", "")) == "settlement", "risk": danger,
            "gate_id": str(exit.get("gate_id", "")), "source": "worldgen_v3_entrances"})
    neighbors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.region_id) < int(b.region_id))
    return {"ok": true, "region_id": region_id, "connections": neighbors,
        "connected_region_count": neighbors.size(), "real_caravans_spawned": 0,
        "trade_routes_constructed": 0, "read_only": true}
