extends RefCounted
## Read-only authored library, 52 inherited R3 templates. No independent persistence.
const CATALOG: String = "res://exo_settlement_forge/libraries/catalog.json"
const BASE: String = "res://exo_settlement_forge/libraries/prefabs/"
static func _json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var f := FileAccess.open(path,FileAccess.READ)
    if f == null:
        return {}
    var value: Variant = JSON.parse_string(f.get_as_text())
    return value if value is Dictionary else {}
static func get_catalog() -> Dictionary:
    return _json(CATALOG)
static func get_prefab(template_id: String) -> Dictionary:
    # No arbitrary path traversal from untrusted/save data.
    for item in get_catalog().get("templates", []):
        if str(item.get("id", "")) == template_id:
            var path: String = str(item.get("path", ""))
            if not path.begins_with(BASE) or not path.ends_with(".json"):
                return {}
            var prefab: Dictionary = _json(path)
            if str(prefab.get("id", "")) == template_id:
                return prefab
    return {}
