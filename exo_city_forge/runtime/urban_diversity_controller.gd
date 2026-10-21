extends RefCounted
## Stateless repeatability: rejects back-to-back duplicates when alternatives exist.
static func adjust(district: Dictionary,previous_id: String,region_seed: String,sector_id: String,profile: Dictionary,catalog: Dictionary,settlement_scale: String="city") -> Dictionary:
 if str(district.get("id",""))!=previous_id:return district
 var variants: Array=[]
 for item in catalog.get("districts",[]):
  if str(item.get("category",""))==str(district.get("category","")) and str(item.get("id",""))!=previous_id and settlement_scale in item.get("allowed_scales",["town","city"]):variants.append(item)
 if variants.is_empty():return district
 variants.sort_custom(func(a,b):return str(a.id)<str(b.id))
 var hash_value: String=(region_seed+"|"+sector_id+"|diversity").sha256_text()
 return variants[hash_value.substr(0,8).hex_to_int()%variants.size()]
