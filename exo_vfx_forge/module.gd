extends RefCounted
# EXO Core module candidate, registers a visual-only service.
# Audio/VFX Bridge 01 executable and trusted issuer are NOT part of this module.
const ServiceNode = preload("res://exo_vfx_forge/runtime/vfx_service.gd")
var core: RefCounted
var service: Node3D
var authorized_proof: Callable = Callable()
var active: bool = false

func initialize(context: RefCounted) -> bool:
    if context == null or not is_instance_valid(context.world):
        return false
    core = context
    service = ServiceNode.new()
    service.name = "EXO_VFX_Forge_03_VisualService"
    core.world.add_child(service)
    if not core.services.register_service("exo_vfx_forge","exo_vfx_forge",self,["capabilities","bind_trusted_bridge","receive_authorized_cue","cancel_cast"],"1.0.0"):
        core.world.remove_child(service)
        service.queue_free()
        service = null
        core = null
        return false
    active = true
    return true

func bind_trusted_bridge(proof: Callable, explicit_bindings: Dictionary) -> bool:
    # IN-PROCESS-only proposed gate; Bridge must prove source authority, not mere JSON.
    if not active or not proof.is_valid() or not authorized_proof.is_null():
        return false
    for skill_id in explicit_bindings:
        if not explicit_bindings[skill_id] is Array:
            return false
    authorized_proof = proof
    for skill_id in explicit_bindings:
        service.call("approve_binding",str(skill_id),explicit_bindings[skill_id])
    return true

func receive_authorized_cue(payload: Dictionary) -> Dictionary:
    if not active or not authorized_proof.is_valid():
        return {"ok":false,"status":"BLOCKED","reason":"AV_BRIDGE_NOT_AUTHORIZED"}
    var proof: Variant = authorized_proof.call(payload)
    if proof != true:
        return {"ok":false,"status":"BLOCKED","reason":"INVALID_HOST_PROOF"}
    return service.call("consume_av_event",payload)

func cancel_cast(cast_id: String) -> void:
    # Only for already authorized cast IDs. Host must call from its own lifecycle.
    if active and is_instance_valid(service):
        service.call("cancel_cast",cast_id)

func capabilities() -> Dictionary:
    return {"version":"1.0.0","visual_only":true,"bridge_bound":authorized_proof.is_valid(),"compatibility_target":"Godot 4.6.2 / Compatibility","native_verification":"NOT_RUN"}

func shutdown() -> void:
    active = false
    authorized_proof = Callable()
    if is_instance_valid(service):
        service.call("clear_all")
        if service.get_parent()!=null:
            service.get_parent().remove_child(service)
        service.queue_free()
    service = null
    core = null
