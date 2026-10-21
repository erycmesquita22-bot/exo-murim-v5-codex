extends RefCounted
static func describe(item: Dictionary) -> Dictionary:
 # Pricing belongs to the future economy owner, not this module.
 return {"family":item.get("family",item.get("kind","")),"material_id":item.get("material_id",""),"rarity":item.get("rarity_id",item.get("rarity","")),"quality":item.get("quality",0),"origin":item.get("origin",item.get("generation",{}).get("source","")),"quoted_price":null}
