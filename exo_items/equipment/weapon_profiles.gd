extends RefCounted
const Equipment = preload("res://exo_items/catalog/equipment_catalog.gd")
static func known(id: String) -> bool:
 return id in Equipment.equipment_ids("weapon")
