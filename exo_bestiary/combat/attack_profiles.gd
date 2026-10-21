extends RefCounted
static func valid_for(profile: Dictionary, attack: Dictionary) -> bool:
    return str(attack.get("id","")) in profile.get("attacks",[])
