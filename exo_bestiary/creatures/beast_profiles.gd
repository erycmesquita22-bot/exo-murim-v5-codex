extends RefCounted
static func is_mystical(profile: Dictionary) -> bool:
    return str(profile.get("category", "")) == "mystical"
