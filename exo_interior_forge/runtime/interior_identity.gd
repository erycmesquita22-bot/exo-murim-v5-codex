extends RefCounted
## Stable world instance identity. No local IDs are persisted as canonical identities.
const SCHEMA: String = "exo.interior.instance.v2"

static func canonical_context(context: Dictionary) -> Dictionary:
    # String casting is confined to this boundary; never mutate host-owned IDs.
    var parts: PackedStringArray = PackedStringArray()
    for key in ["world_id", "world_seed", "region_id", "settlement_id", "lot_instance_id", "building_local_id"]:
        if not context.has(key) or str(context[key]).strip_edges().is_empty():
            return {}
        var value: String = str(context[key])
        parts.append(str(value.length()) + ":" + value)
    var canonical: String = SCHEMA + "|" + "|".join(parts)
    return {"schema": SCHEMA, "building_instance_id": "interior:" + canonical.sha256_text(), "canonical_key": canonical}

static func consistent_receipt(context: Dictionary, receipt: Dictionary) -> bool:
    var identity: Dictionary = canonical_context(context)
    if identity.is_empty():
        return false
    return str(receipt.get("building_instance_id", "")) == str(identity["building_instance_id"])
