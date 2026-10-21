extends RefCounted
const Equipment = preload("res://exo_items/catalog/equipment_catalog.gd")
# Descriptors only: do not equip until approved inventory slots exist.
static func planned(id: String) -> bool:
 return id in Equipment.equipment_ids("accessory")
