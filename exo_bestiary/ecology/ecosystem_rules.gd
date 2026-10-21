extends RefCounted
static func habitat_matches(profile: Dictionary, data: Dictionary) -> bool:
    var biome: String = str(data.get("biome",""))
    return biome in profile.get("biomes",[])
static func prey_of(predator: Dictionary, prey: Dictionary) -> bool:
    return str(predator.get("diet",""))=="carnivore" and str(prey.get("diet",""))=="herbivore" and str(predator.get("id","")) != str(prey.get("id",""))
static func simulation_tier(distance: float, region_loaded: bool) -> int:
    return 3 if not region_loaded else 1 if distance < 45.0 else 2
