extends RefCounted
static func find(catalog: Dictionary,profile_id: String) -> Dictionary:
 for item in catalog.get("profiles",[]):
  if str(item.get("id",""))==profile_id:return item
 return {}
static func weight(profile: Dictionary,category: String) -> float:
 return maxf(0.0,float(profile.get("weights",{}).get(category,0)))
