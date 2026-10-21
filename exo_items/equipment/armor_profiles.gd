extends RefCounted
const Equipment = preload("res://exo_items/catalog/equipment_catalog.gd")
# Descriptors only: current inventory has no armor slots.
static func planned(id: String) -> bool:
 return id in Equipment.equipment_ids("armor")
