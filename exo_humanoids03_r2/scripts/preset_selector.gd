extends RefCounted
## Deterministic actor identity: one selection per persistent spawn/creation event.
const CATALOG_PATH = "res://exo_humanoids03_r2/data/CATALOGO-VESTUARIO-MURIM.json"
static var _catalog_cache: Dictionary = {}

static func catalog() -> Dictionary:
    if _catalog_cache.is_empty() and FileAccess.file_exists(CATALOG_PATH):
        var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
        if parsed is Dictionary: _catalog_cache = parsed
    return _catalog_cache

static func fnv1a32(value: String) -> int:
    var hash_value: int = 2166136261
    for byte_value in value.to_utf8_buffer():
        hash_value = ((hash_value ^ int(byte_value)) * 16777619) & 0xFFFFFFFF
    return hash_value

static func choose(desc: Dictionary) -> Dictionary:
    var uid: String = str(desc.get("uid", ""))
    var role: String = str(desc.get("role", ""))
    var faction: String = str(desc.get("faction", "neutral"))
    if uid.is_empty(): return {}
    var data: Dictionary = catalog()
    var roles: Dictionary = data.get("roles", {})
    if not roles.has(role): return {}
    var options: Array = roles[role]
    if options.is_empty(): return {}
    var seed_text: String = str(desc.get("world_seed", ""))
    var region: String = str(desc.get("region_id", ""))
    var prestige: int = clampi(int(desc.get("prestige",0)),0,3)
    var key: String = "EXO/R2|"+seed_text+"|"+region+"|"+uid+"|"+role+"|"+faction+"|"+str(prestige)
    var chosen: String = str(options[fnv1a32(key) % options.size()])
    var presets: Dictionary = data.get("presets", {})
    var factions: Dictionary = data.get("factions", {})
    if not presets.has(chosen): return {}
    var style: Dictionary = presets[chosen].duplicate(true)
    var selected_faction: String = faction if factions.has(faction) else "neutral"
    style["palette"] = selected_faction
    if str(style.get("emblem","")) != "none": style["emblem"] = str(factions[selected_faction].get("emblem","neutral"))
    style["prestige"] = prestige
    var variants: Array = data.get("variants", ["a"])
    style["variant"] = variants[fnv1a32(key+"|variant") % variants.size()]
    # Save this complete object in the authority's existing save record; never roll again on frame updates.
    return {"schema":2,"uid":uid,"preset_id":chosen,"style":style,
        "source_role":role,"source_faction":faction,"source_region":region,
        "selection_key":"fnv1a32-v1","catalog_version":str(data.get("version",""))}

static func valid(selection: Dictionary) -> bool:
    var data: Dictionary = catalog()
    var presets: Dictionary = data.get("presets",{})
    var id: String = str(selection.get("preset_id",""))
    var style: Dictionary = selection.get("style",{})
    return int(selection.get("schema",0)) == 2 and not str(selection.get("uid","")).is_empty() \
        and presets.has(id) and style.get("robe", "") in data.get("modules",{}).get("robe",[]) \
        and style.get("palette","") in data.get("factions",{}).keys()
