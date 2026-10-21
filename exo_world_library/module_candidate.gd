extends RefCounted
# Entirely OPTIONAL entrypoint, registered only if host integrator explicitly opts in.
const ReadOnly = preload("res://exo_world_library/integration/read_only_bridge.gd")
var bridge: Variant = null
func initialize(host) -> bool:
    if host == null or not host.services.has_method("register_service"):
        return false
    bridge = ReadOnly.new()
    if not bridge.initialize():
        return false
    return bool(host.services.register_service("content.library","world_content_library",self,["catalog_status","preview"],"0.4.0"))
func catalog_status() -> Dictionary:
    if bridge == null:
        return {"status":"BLOCKED","reason":"bridge_missing","committed":false}
    return bridge.library.catalog_status()
func preview(owner_id: String,context: Dictionary,domains: Array) -> Dictionary:
    if bridge == null:
        return {"status":"BLOCKED","reason":"bridge_missing","committed":false}
    return bridge.catalog_preview(owner_id,context,domains)
func shutdown() -> void:
    bridge = null
