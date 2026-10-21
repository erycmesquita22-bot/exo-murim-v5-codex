extends RefCounted
## Documentacao executavel ilustrativa: não modificar enemy.gd, Core, IA nem spawn.
const VisualCatalog = preload("res://exo_creature_harmonizacao02/integration/visual_catalog.gd")
static func visual_scene_for_bestiary_species(species_id: String) -> PackedScene:
    var visual := VisualCatalog.get_visual(species_id)
    if visual.is_empty():
        return null
    var packed := load(visual["scene"])
    if packed is PackedScene:
        return packed
    return null
