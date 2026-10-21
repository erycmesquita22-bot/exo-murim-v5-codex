extends RefCounted
# CANDIDATE CONTRACT: passive consumer; this is NOT an existing EXO Core event type.
const CONTRACT_VERSION := "exo.vfx.events/1"
const PHASES := ["prepare", "draw", "launch", "impact", "recover", "interrupt"]
const QUALITIES := ["low", "medium", "high"]
static func validate(e: Dictionary) -> Dictionary:
    if e.get("contract_version", "") != CONTRACT_VERSION:
        return {"ok": false, "reason": "contract_version"}
    for key in ["cast_instance_id", "skill_id", "caster_entity_id", "cue_id", "vfx_id"]:
        if not e.get(key) is String or str(e.get(key)).is_empty() or str(e.get(key)).length() > 160:
            return {"ok": false, "reason": "missing_or_invalid_" + key}
    if not e.get("phase", "") in PHASES:
        return {"ok": false, "reason": "invalid_phase"}
    if not e.get("quality_profile", "medium") in QUALITIES:
        return {"ok": false, "reason": "invalid_quality"}
    if not e.get("visual_seed", 0) is int:
        return {"ok": false, "reason": "invalid_seed"}
    if not e.get("origin_xyz", []) is Array or e.get("origin_xyz", []).size() != 3:
        return {"ok": false, "reason": "invalid_origin"}
    if not e.get("direction_xyz", []) is Array or e.get("direction_xyz", []).size() != 3:
        return {"ok": false, "reason": "invalid_direction"}
    for component in e.get("origin_xyz", []) + e.get("direction_xyz", []):
        if not (component is int or component is float) or absf(float(component)) > 1000000.0:
            return {"ok": false, "reason": "invalid_vector_component"}
    if e.has("event_sequence") and (not e.event_sequence is int or int(e.event_sequence) < 0):
        return {"ok": false, "reason": "invalid_event_sequence"}
    return {"ok": true, "reason": "valid"}

static func vector3_from(a: Array) -> Vector3:
    return Vector3(float(a[0]), float(a[1]), float(a[2]))
