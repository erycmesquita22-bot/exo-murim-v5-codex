extends RefCounted
# Compatível com a interface real de exo_core/service_registry.gd.
static func core_services_ready(core: RefCounted) -> bool:
    return core != null and core.services.has_service("regions") and core.services.has_service("combat")
static func attack_bridge_requirements() -> Array:
    return ["Execute validated weapon/technique via existing combat owner", "Preserve authority of enemy.gd and regional_ecology/rewards.gd", "Expose optional fauna mount/spawn hook to Regional Ecology"]
