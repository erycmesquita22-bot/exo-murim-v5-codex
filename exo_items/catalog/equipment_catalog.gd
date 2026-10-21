extends RefCounted
const Catalog = preload("res://exo_items/catalog/item_catalog.gd")
static func equipment_ids(family: String) -> Array:
 if family not in ["weapon", "armor", "accessory"]: return []
 var ids: Array = Catalog.profiles.get(family, {}).keys()
 ids.sort()
 return ids
static func is_legacy_weapon(id: String) -> bool:
 return bool(Catalog.base("weapon", id).get("legacy", false))
