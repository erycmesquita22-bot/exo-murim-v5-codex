extends RefCounted
static func estimate(profile: Dictionary, regional_danger: int, group_size: int) -> float:
    var hp: float = float(profile.get("stats",{}).get("hp",70))
    return maxf(1.0, float(regional_danger) + hp/55.0 + float(maxi(0,group_size-1))*.6)
