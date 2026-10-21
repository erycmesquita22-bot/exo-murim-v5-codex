extends RefCounted
static func profile_for(id: String, catalog) -> Dictionary:
    return catalog.humans.get(id, {}).duplicate(true)
static func physical_role(profile: Dictionary) -> String:
    # Apenas ponte de compatibilidade; NÃO representa variedade física completa.
    return "mage" if str(profile.get("combat_style", "")) in ["ranged","technique"] else "blade"
