extends RefCounted
# Adapter to the PROPOSED Bridge 01 contract, not a claimed host API.
# Bridge owns which cue belongs to a skill/phase; VFX is visual-only.
var visual_service: Node3D
func _init(service: Node3D) -> void:
    visual_service = service
func on_authorized_av_cue(payload: Dictionary) -> Dictionary:
    if not is_instance_valid(visual_service) or not visual_service.has_method("consume_av_event"):
        return {"ok":false,"status":"BLOCKED","reason":"VFX_SERVICE_UNAVAILABLE"}
    return visual_service.consume_av_event(payload)
