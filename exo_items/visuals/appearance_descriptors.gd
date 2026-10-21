extends RefCounted
const Catalog = preload("res://exo_items/catalog/item_catalog.gd")
const COLOR = {"common":"#B7A994","uncommon":"#45C87A","rare":"#3D9FFF","epic":"#A46BFF","legendary":"#F6C243","ancestral":"#F26B48"}
static func describe(item: Dictionary) -> Dictionary:
 var rarity: String = str(item.get("rarity_id", item.get("rarity", "common")))
 var canonical: Dictionary = {"Comum":"common", "Incomum":"uncommon", "Rara":"rare", "Épica":"epic"}
 rarity = str(canonical.get(rarity, rarity))
 var material: Dictionary = Catalog.material(str(item.get("material_id", "plain")))
 return {"model_override":null,"existing_base":item.get("base_id",item.get("ref","")),"family":item.get("family",""),"material_hint":material.get("visual", "natural"),"rarity_color":COLOR.get(rarity,COLOR.common),"particles_requested":false,"texture_origin":"EXO-approved-assets-only"}
