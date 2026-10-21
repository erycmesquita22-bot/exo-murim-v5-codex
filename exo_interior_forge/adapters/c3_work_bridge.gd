extends RefCounted
## Pure transition ticket. Host integration is BLOCKED until real doorway anchors,
## scene lifecycle, host save-owner and controller are supplied by game integrator.
const Catalog = preload("res://exo_interior_forge/runtime/interior_catalog.gd")
const SCHEMA: String = "exo.interior.transition_ticket.v1"

static func prepare(context: Dictionary, building: Dictionary, receipt: Dictionary, authorization: Dictionary) -> Dictionary:
    var gate: Dictionary = Catalog.entry_gate(context, building, receipt, authorization)
    if not gate.get("ok", false):
        return gate
    return {"ok": true, "ticket": {
        "schema": SCHEMA,
        "building_instance_id": str(receipt["building_instance_id"]),
        "prefab_id": str(receipt["prefab_id"]),
        "exterior_door_id": str(context["exterior_door_id"]),
        "return_anchor_id": str(context["return_anchor_id"]),
        "world_id": str(context["world_id"]),
        "region_id": str(context["region_id"]),
        "host_transition_required": true,
        "host_save_owner_required": true
    }}
