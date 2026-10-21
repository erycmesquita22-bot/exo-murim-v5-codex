extends RefCounted
static func select(request: Dictionary,catalog: Dictionary) -> Dictionary:
 var items: Array=catalog.get("blueprints",[]).duplicate(true)
 items.sort_custom(func(a,b):return str(a.id)<str(b.id))
 var want: String=str(request.get("blueprint_id",""))
 if not want.is_empty():
  for item in items:
   if str(item.id)==want and str(request.get("settlement_scale","")) in item.get("allowed_scales",[]) and float(item.get("half_extent",INF))+8.0<=float(request.get("half_extent",0)):return item
  return {}
 var eligible: Array=[]
 for item in items:
  if float(item.get("half_extent",INF))<=float(request.get("half_extent",0))-8.0 and str(request.get("settlement_scale","")) in item.get("allowed_scales",[]):eligible.append(item)
 if eligible.is_empty():return {}
 var key: String="CF01|%s|%s|blueprint"%[str(request.get("region_seed","0")),str(request.get("region_id",-1))]
 return eligible[key.sha256_text().substr(0,8).hex_to_int()%eligible.size()]
