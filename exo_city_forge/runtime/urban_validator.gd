extends RefCounted
static func _collision(b: Dictionary,reservation: Dictionary,padding: float=2.0) -> bool:
 var lo_x: float=float(reservation.get("min_x",INF))-padding
 var hi_x: float=float(reservation.get("max_x",-INF))+padding
 var lo_z: float=float(reservation.get("min_z",INF))-padding
 var hi_z: float=float(reservation.get("max_z",-INF))+padding
 return float(b.get("max_x",0))>lo_x and float(b.get("min_x",0))<hi_x and float(b.get("max_z",0))>lo_z and float(b.get("min_z",0))<hi_z
static func validate(plan: Dictionary) -> Dictionary:
 var errors: Array=[]
 if str(plan.get("status",""))!="ready":return {"ok":false,"errors":plan.get("errors",["not_ready"])}
 var seen: Dictionary={}
 var extent: float=float(plan.get("half_extent",0))
 var reserves: Array=plan.get("monument_reservations",[])
 for sector in plan.get("sectors",[]):
  var id: String=str(sector.get("id",""))
  if seen.has(id):errors.append("duplicate_sector:"+id)
  seen[id]=true
  var b: Dictionary=sector.get("bounds",{})
  if absf(float(b.get("min_x",0)))>extent-8 or absf(float(b.get("max_x",0)))>extent-8 or absf(float(b.get("min_z",0)))>extent-8 or absf(float(b.get("max_z",0)))>extent-8:errors.append("outside_region:"+id)
  for reservation in reserves:
   if _collision(b,reservation):errors.append("monument_conflict:"+id)
  var hub_data: Array=plan.get("river_hub",[72,72])
  var hub: Vector2=Vector2(float(hub_data[0]),float(hub_data[1]))
  var midpoint: Vector2=Vector2((float(b.min_x)+float(b.max_x))*.5,(float(b.min_z)+float(b.max_z))*.5)
  var radius: float=Vector2(float(b.max_x)-float(b.min_x),float(b.max_z)-float(b.min_z)).length()*.5+10.0
  for river in plan.get("rivers",[]):
   var to: Array=river.get("p",[])
   if to.size()!=2:errors.append("invalid_river_descriptor");continue
   var nearest: Vector2=Geometry2D.get_closest_point_to_segment(midpoint,hub,Vector2(float(to[0]),float(to[1])))
   if midpoint.distance_to(nearest)<radius:errors.append("river_conflict:"+id)
 var bs: Array=plan.get("buildings",[])
 for building in bs:
  var id: String=str(building.get("id",""))
  if seen.has(id):errors.append("duplicate_building:"+id)
  seen[id]=true
 for i in range(plan.get("sectors",[]).size()):
  var a: Dictionary=plan.sectors[i].bounds
  for j in range(i+1,plan.sectors.size()):
   var b: Dictionary=plan.sectors[j].bounds
   if float(a.max_x)>float(b.min_x)+0.1 and float(a.min_x)<float(b.max_x)-0.1 and float(a.max_z)>float(b.min_z)+0.1 and float(a.min_z)<float(b.max_z)-0.1:errors.append("sector_overlap:%d:%d"%[i,j])
 if plan.get("streets",[]).size()<2:errors.append("main_streets_missing")
 if bs.is_empty():errors.append("no_buildings")
 return {"ok":errors.is_empty(),"errors":errors,"sectors":plan.get("sectors",[]).size(),"buildings":bs.size(),"checked_reservations":reserves.size()}
