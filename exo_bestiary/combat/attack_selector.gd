extends RefCounted
static func select(profile: Dictionary, catalog, context: Dictionary) -> Dictionary:
    var d := float(context.get("distance",INF))
    var ready := bool(context.get("attack_ready",false))
    if not ready: return {}
    for id in profile.get("attacks",[]):
        var at: Dictionary = catalog.get_attack(str(id))
        if at.is_empty(): continue
        if str(at.get("kind")) in ["defend","evade","counter"]:continue
        if d <= float(at.get("range",0.0)) and bool(context.get("line_of_sight",false)):
            return at
    return {}
