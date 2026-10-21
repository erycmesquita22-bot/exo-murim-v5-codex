extends RefCounted
## Core facade; materialized region service owns records/geometry, portal owns visits.
var core: RefCounted
func initialize(context: RefCounted) -> bool:
    core=context
    return core.services.register_service("settlement.forge", "settlement_forge", self, ["active_plan", "building", "visit_snapshot"], "1.0.1")
func _service() -> Variant:
    if core==null or not is_instance_valid(core.world.active_region): return null
    return core.world.active_region.get_meta("worldgen_v5_service") if core.world.active_region.has_meta("worldgen_v5_service") else null
func active_plan() -> Dictionary:
    var service: Variant=_service()
    return service.active_plan() if is_instance_valid(service) else {}
func building(id: String) -> Dictionary:
    var service: Variant=_service()
    return service.get_building(id) if is_instance_valid(service) else {}
func visit_snapshot() -> Dictionary:
    if core==null or core.world.wg5_visit==null: return {"inside":false}
    return core.world.wg5_visit.snapshot()
func shutdown() -> void:
    core=null
