extends RefCounted
static func danger(context: Dictionary) -> float:
    var allies := maxi(0,int(context.get("allies",0)))
    var hp_ratio := clampf(float(context.get("hp_ratio",1.0)),0.0,1.0)
    var opponent := maxf(0.0,float(context.get("target_power",1.0)))
    return opponent * (1.0 + (1.0-hp_ratio)*1.4) / (1.0 + float(allies)*0.25)
static func should_flee(profile: Dictionary, context: Dictionary) -> bool:
    var kind: String = str(profile.get("behavior", ""))
    if kind == "prey": return bool(context.get("predator_visible",false)) or bool(context.get("target_threat",false))
    if bool(context.get("cornered",false)): return false
    if kind == "territorial" and float(context.get("hp_ratio",1.0)) > 0.18: return false
    return float(context.get("hp_ratio",1.0)) < (1.0-float(profile.get("morale",.48))) * 0.65 and danger(context) >= .8
