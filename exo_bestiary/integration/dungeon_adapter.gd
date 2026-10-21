extends RefCounted
static func descriptors(profiles: Array, environment: String, max_units: int) -> Array:
    var out: Array=[]
    for profile in profiles:
        if environment in profile.get("biomes",[]) and out.size()<max_units:
            out.append({"profile_id":profile.id,"owner":"dungeon_genesis","needs_spawn_position":true})
    return out
