extends RefCounted
const Legacy = preload("res://inventory.gd")
const Planned = preload("res://exo_items/balance/stat_validator.gd")
static func legacy(item: Variant) -> bool:
 return item is Dictionary and Legacy.valid_item(item)
static func descriptor(item: Variant) -> bool:
 return Planned.valid_descriptor(item)
