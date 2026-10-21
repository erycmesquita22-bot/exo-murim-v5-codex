extends RefCounted
const Catalog = preload("res://exo_items/catalog/item_catalog.gd")
static func valid_for(family: String, id: String) -> bool:
 return family in Catalog.material(id).get("families", [])
static func candidates(family: String) -> Array:
 var result: Array = []
 for m in Catalog.materials:
  if family in m.families: result.append(m.duplicate(true))
 return result
