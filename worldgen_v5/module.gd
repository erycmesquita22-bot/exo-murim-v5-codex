extends RefCounted
## Core exposes the single world/region owner. No second generator or save writer.
var core: RefCounted
func initialize(context: RefCounted) -> bool:
    core=context
    return core.services.register_service("worldgen.v5", "worldgen_v5", self, ["atlas_status", "settlement_handoff"], "5.0.1")
func atlas_status() -> Dictionary:
    if core==null or core.world.atlas.is_empty(): return {"ok":false,"error":"atlas_not_loaded"}
    return preload("res://worldgen_v5/runtime/atlas_gate.gd").validate(core.world.atlas)
func settlement_handoff() -> Dictionary:
    return preload("res://worldgen_v5/runtime/settlement_handoff.gd").station_manifest(core.world.active_region)
func shutdown() -> void:
    core=null
