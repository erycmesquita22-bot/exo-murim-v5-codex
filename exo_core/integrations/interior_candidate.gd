extends RefCounted
const Bridge = preload("res://exo_interior_forge/adapters/c3_work_bridge.gd")
func initialize(host: RefCounted) -> bool:
    return host.services.register_service("interior_forge.candidates", "interior_forge", self, ["prepare_interior"], "1.0.0")
func prepare_interior(context: Dictionary, building: Dictionary, receipt: Dictionary, authorization: Dictionary) -> Dictionary:
    return Bridge.prepare(context, building, receipt, authorization)
func shutdown() -> void:
    pass
