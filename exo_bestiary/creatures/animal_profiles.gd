extends RefCounted
static func is_natural(profile: Dictionary) -> bool:
    return str(profile.get("category", "")) != "mystical" and not profile.is_empty()
static func interaction_tags(profile: Dictionary) -> Array:
    return ["ecology", "hunting", "resource", "mission", "narrative"] if not profile.is_empty() else []
