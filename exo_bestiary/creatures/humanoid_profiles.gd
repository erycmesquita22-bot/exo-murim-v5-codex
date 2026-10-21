extends RefCounted
static func compatible_weapon(profile: Dictionary, equipped_family: String) -> bool:
    return equipped_family == str(profile.get("weapon_family", ""))
