extends RefCounted
const Profile=preload("res://exo_city_forge/runtime/city_profile.gd")
static func choose(region_seed: String,sector_id: String,profile: Dictionary,catalog: Dictionary,force_category: String="",settlement_scale: String="city") -> Dictionary:
 var candidates: Array=catalog.get("districts",[]).duplicate(true)
 candidates.sort_custom(func(a,b):return str(a.id)<str(b.id))
 var categories: Array=profile.get("weights",{}).keys()
 categories.sort()
 var total: int=0
 for cat in categories:total+=maxi(0,int(Profile.weight(profile,str(cat))*100.0))
 if total==0:return {}
 var key: String="CF01|%s|%s|district"%[region_seed,sector_id]
 var ticket: int=key.sha256_text().substr(0,8).hex_to_int()%total
 var chosen: String=""
 for cat in categories:
  ticket-=maxi(0,int(Profile.weight(profile,str(cat))*100.0))
  if ticket<0:chosen=str(cat);break
 if not force_category.is_empty():chosen=force_category
 var pool: Array=[]
 for d in candidates:
  if str(d.get("category",""))==chosen and settlement_scale in d.get("allowed_scales",["town","city"]):pool.append(d)
 if pool.is_empty():return {}
 return pool[(key+"|variant").sha256_text().substr(0,8).hex_to_int()%pool.size()]
