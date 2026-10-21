extends Node
## Fail-closed compatibility facade. Live transition is owned by host.
## R1's reparent/teleport prototype is NOT safe for C3's player/controller.
signal transition_requested(ticket: Dictionary)
var pending: bool = false

func enter(_player: Node3D, _exterior_root: Node3D, _staging_root: Node3D, _receipt: Dictionary, _isolated_origin: Vector3 = Vector3.ZERO) -> bool:
    push_warning("InteriorForge: prototype enter() disabled; use audited C3 transition bridge")
    return false

func leave() -> bool:
    return false

func request_transition(gate: Dictionary, ticket: Dictionary) -> bool:
    if pending or gate.get("ok", false) != true:
        return false
    if str(ticket.get("building_instance_id", "")) != str(gate.get("building_instance_id", "")):
        return false
    if str(ticket.get("return_anchor_id", "")).is_empty():
        return false
    pending = true
    transition_requested.emit(ticket.duplicate(true))
    return true

func host_acknowledge_transition() -> void:
    pending = false

func host_abort_transition() -> void:
    pending = false
