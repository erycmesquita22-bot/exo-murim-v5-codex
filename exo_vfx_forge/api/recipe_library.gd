extends RefCounted
const VALID_FAMILIES := ["slash", "impact", "dash", "teleport", "ice", "thunder", "meteor", "beam", "snare", "crown"]
var recipes: Dictionary = {}
var errors: Array[String] = []
func load_directory(base: String = "res://exo_vfx_forge/recipes") -> int:
    recipes.clear()
    errors.clear()
    var directory: DirAccess = DirAccess.open(base)
    if directory == null:
        errors.append("MISSING_RECIPES_DIR:" + base)
        return 0
    directory.list_dir_begin()
    while true:
        var name: String = directory.get_next()
        if name.is_empty():
            break
        if directory.current_is_dir() or not name.ends_with(".json"):
            continue
        var path: String = base.path_join(name)
        var file: FileAccess = FileAccess.open(path, FileAccess.READ)
        if file == null:
            errors.append("UNREADABLE:" + path)
            continue
        var data: Variant = JSON.parse_string(file.get_as_text())
        if not data is Dictionary:
            errors.append("BAD_JSON:" + path)
            continue
        var check: Dictionary = validate(data)
        if not check.ok:
            errors.append("INVALID:" + path + ":" + str(check.reason))
            continue
        var rid: String = str(data.vfx_id)
        if recipes.has(rid):
            errors.append("DUPLICATE_ID:" + rid)
            continue
        recipes[rid] = data
    directory.list_dir_end()
    return recipes.size()

static func validate(r: Dictionary) -> Dictionary:
    for key in ["vfx_id", "version", "family", "tags", "asset_origin", "license_state", "quality_profiles", "geometry_passes", "sprite_passes", "particle_passes", "shader_params", "timing", "anchor", "orientation_policy", "random_seed_policy", "cleanup", "fallback", "preview"]:
        if not r.has(key):
            return {"ok": false, "reason": "missing_" + key}
    if not r.vfx_id is String or not str(r.vfx_id).begins_with("vfx."):
        return {"ok": false, "reason": "invalid_id"}
    if not str(r.family) in VALID_FAMILIES:
        return {"ok": false, "reason": "invalid_family"}
    if not r.timing is Dictionary or float(r.timing.get("duration", 0.0)) <= 0.0 or float(r.timing.get("duration", 0.0)) > 15.0:
        return {"ok": false, "reason": "invalid_duration"}
    if not r.get("quality_profiles") is Dictionary:
        return {"ok": false, "reason": "quality_profiles"}
    if not r.quality_profiles.has("low") or not r.quality_profiles.has("medium") or not r.quality_profiles.has("high"):
        return {"ok": false, "reason": "quality_missing"}
    if not r.license_state == "ORIGINAL_PROJECT":
        return {"ok": false, "reason": "unverified_license"}
    return {"ok": true, "reason": "valid"}

func get_recipe(id: String) -> Dictionary:
    return recipes.get(id, {})
