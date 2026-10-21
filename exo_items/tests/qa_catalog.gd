extends RefCounted
# Optional source-level sanity checks run by qa_native.gd.
const Catalog = preload("res://exo_items/catalog/item_catalog.gd")
static func stats() -> Dictionary:
 return {"weapon_definitions":Catalog.profiles.weapon.size(),"rarity_definitions":Catalog.rarities.size(),"affix_definitions":Catalog.affixes.size(),"planned_armor":Catalog.profiles.armor.size(),"planned_accessory":Catalog.profiles.accessory.size()}
