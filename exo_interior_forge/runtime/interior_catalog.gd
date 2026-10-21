extends RefCounted
## Pure read-only prefab selection. Persistence and access rights belong to the C3 host.
const Identity = preload("res://exo_interior_forge/runtime/interior_identity.gd")
const CATALOG_PATH: String = "res://exo_interior_forge/libraries/catalog.json"
const RECEIPT_SCHEMA: String = "exo.interior.selection.v2"

static func load_json(path: String) -> Dictionary:
    if not path.begins_with("res://exo_interior_forge/libraries/") or not path.ends_with(".json"):
        return {}
    if not FileAccess.file_exists(path):
        return {}
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {}
    var data: Variant = JSON.parse_string(file.get_as_text())
    return data if data is Dictionary else {}

static func get_catalog() -> Dictionary:
    return load_json(CATALOG_PATH)

static func load_prefab(prefab_id: String) -> Dictionary:
    for item in get_catalog().get("templates", []):
        if str(item.get("id", "")) == prefab_id:
            var result: Dictionary = load_json(str(item.get("path", "")))
            if str(result.get("id", "")) == prefab_id:
                return result
    return {}

static func deterministic_number(text_key: String) -> int:
    var value: int = 5381
    for i in range(text_key.length()):
        value = (value * 33 + text_key.unicode_at(i)) % 2147483647
    return value

static func candidate_templates(function_name: String, building_tags: Array = [], max_width_tiles: int = 0, max_depth_tiles: int = 0) -> Array[Dictionary]:
    var options: Array[Dictionary] = []
    for variant in get_catalog().get("templates", []):
        if str(variant.get("category", "")) != function_name:
            continue
        var w: int = int(variant.get("width_tiles", 0))
        var d: int = int(variant.get("depth_tiles", 0))
        if (max_width_tiles > 0 and w > max_width_tiles) or (max_depth_tiles > 0 and d > max_depth_tiles):
            continue
        options.append(variant)
    # Stable sorting independent of on-disk catalog order.
    options.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("id", "")) < str(b.get("id", "")))
    if building_tags.has("noble") or building_tags.has("clans"):
        var preferred: Array[Dictionary] = []
        for item in options:
            if str(item.get("style", "")) == "noble":
                preferred.append(item)
        if not preferred.is_empty():
            return preferred
    return options

static func receipt_valid(context: Dictionary, receipt: Dictionary, catalog: Dictionary = {}) -> bool:
    if str(receipt.get("schema", "")) != RECEIPT_SCHEMA or not Identity.consistent_receipt(context, receipt):
        return false
    if str(receipt.get("prefab_id", "")).is_empty() or str(receipt.get("catalog_version", "")).is_empty():
        return false
    if str(receipt.get("template_id", "")) != str(context.get("template_id", "")):
        return false
    var prefab: Dictionary = load_prefab(str(receipt.get("prefab_id", "")))
    if prefab.is_empty() or str(prefab.get("category", "")) != str(context.get("function", "")):
        return false
    # An authored prefab remains available even when the CURRENT catalog version changes.
    return true

static func select_or_reuse(context: Dictionary, existing_receipt: Dictionary = {}) -> Dictionary:
    var identity: Dictionary = Identity.canonical_context(context)
    if identity.is_empty() or str(context.get("function", "")).is_empty() or str(context.get("template_id", "")).is_empty():
        return {"ok": false, "code": "missing_identity_or_function"}
    if not existing_receipt.is_empty():
        if not receipt_valid(context, existing_receipt):
            return {"ok": false, "code": "conflicting_or_missing_saved_receipt"}
        return {"ok": true, "receipt": existing_receipt.duplicate(true), "reused": true}
    var tags: Array = context.get("tags", []) if context.get("tags", []) is Array else []
    var options: Array[Dictionary] = candidate_templates(str(context["function"]), tags, int(context.get("max_width_tiles", 0)), int(context.get("max_depth_tiles", 0)))
    if options.is_empty():
        return {"ok": false, "code": "no_compatible_authored_prefab"}
    var sorted_key: String = str(identity["building_instance_id"])
    var chosen: Dictionary = options[deterministic_number(sorted_key) % options.size()]
    var receipt: Dictionary = {
        "schema": RECEIPT_SCHEMA,
        "building_instance_id": identity["building_instance_id"],
        "template_id": str(context["template_id"]),
        "prefab_id": str(chosen["id"]),
        "catalog_version": str(get_catalog().get("version", "unknown")),
        "selection_key_sha256": str(identity["canonical_key"]).sha256_text(),
        "visited": false
    }
    return {"ok": true, "receipt": receipt, "reused": false}

static func entry_gate(context: Dictionary, building: Dictionary, receipt: Dictionary, authorization: Dictionary) -> Dictionary:
    if not receipt_valid(context, receipt):
        return {"ok": false, "code": "receipt_untrusted_or_missing"}
    # interior_slot=false blocks access EVEN IF a caller sets an override variable.
    # To unlock a residence, the City/World owner must issue a newly resolved,
    # authorized building instance view; this module NEVER mutates original templates.
    if building.get("interior_slot", false) != true:
        return {"ok": false, "code": "interior_slot_closed"}
    if authorization.get("allowed", false) != true or str(authorization.get("issuer", "")) not in ["city", "narrative", "school", "owner", "economy"]:
        return {"ok": false, "code": "host_authorization_missing"}
    if str(authorization.get("building_instance_id", "")) != str(receipt["building_instance_id"]):
        return {"ok": false, "code": "authorization_wrong_building"}
    # Caller MUST authenticate issuer via owner service (this Dictionary is not a signature).
    if authorization.get("verified_by_host", false) != true:
        return {"ok": false, "code": "host_verification_missing"}
    if str(context.get("region_id", "")) != str(context.get("active_region_id", "")):
        return {"ok": false, "code": "region_changed"}
    if str(context.get("exterior_door_id", "")).is_empty() or str(context.get("return_anchor_id", "")).is_empty():
        return {"ok": false, "code": "door_or_return_anchor_missing"}
    if not context.has("player_distance_m") or float(context["player_distance_m"]) > 3.0 or float(context["player_distance_m"]) < 0.0:
        return {"ok": false, "code": "player_not_at_door"}
    return {"ok": true, "code": "ready_for_host_transition", "prefab_id": str(receipt["prefab_id"]), "building_instance_id": str(receipt["building_instance_id"])}
