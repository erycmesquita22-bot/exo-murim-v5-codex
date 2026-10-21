extends RefCounted
## EXO Harmonizacao02: consulta de caminho visual somente (dados; NÃO instancia combate/spawn).
const CATALOG_PATH := "res://exo_creature_harmonizacao02/data/CATALOGO-CRIATURAS-UNIFICADO.json"
static func get_visual(species_id: String, variant_source: String = "") -> Dictionary:
    if not FileAccess.file_exists(CATALOG_PATH):
        return {}
    var contents := FileAccess.get_file_as_string(CATALOG_PATH)
    var parsed: Variant = JSON.parse_string(contents)
    if typeof(parsed) != TYPE_DICTIONARY:
        return {}
    var species: Dictionary = parsed.get("assets_by_species", {})
    if not species.has(species_id):
        return {}
    var item: Dictionary = species[species_id]
    var chosen: Dictionary = item.get("recommended_variant", {})
    if variant_source != "":
        for entry in item.get("variants", []):
            if str(entry.get("source", "")) == variant_source:
                chosen = entry
                break
    if chosen.is_empty():
        return {}
    return {
        "species_id": species_id,
        "scene": str(chosen.get("scene", "")),
        "model": str(chosen.get("model", "")),
        "visual_only": true,
        "combat_authority": "Bestiary02",
    }
