extends RefCounted
const Catalog=preload("res://exo_city_forge/runtime/city_registry.gd")
const Blueprint=preload("res://exo_city_forge/runtime/city_blueprint_selector.gd")
const District=preload("res://exo_city_forge/runtime/district_selector.gd")
const Diversity=preload("res://exo_city_forge/runtime/urban_diversity_controller.gd")
const Profile=preload("res://exo_city_forge/runtime/city_profile.gd")
const Population=preload("res://exo_city_forge/runtime/population_rules.gd")
const Validator=preload("res://exo_city_forge/runtime/urban_validator.gd")
static func _invalid(reason: String) -> Dictionary:
 return {"status":"invalid","errors":[reason],"sectors":[],"buildings":[],"streets":[]}
static func _safe_local_walkway(door: Vector2, target: Vector2, current_id: String, buildings: Array) -> bool:
 var distance: float=door.distance_to(target)
 if distance>20.0:return false
 var count: int=maxi(2,int(ceil(distance/0.75)))
 for j in range(count+1):
  var p: Vector2=door.lerp(target,float(j)/float(count))
  for other in buildings:
   if str(other.get("id",""))==current_id:continue
   var pos: Array=other.get("local_position",[])
   var dims: Array=other.get("size",[])
   if pos.size()!=2 or dims.size()!=2:continue
   # Conservative rotated AABB; 0.9m clearance for the preview walkway.
   var extent: float=maxf(float(dims[0]),float(dims[1]))*.5+.9
   if absf(p.x-float(pos[0]))<=extent and absf(p.y-float(pos[1]))<=extent:return false
 return true
static func _choose_access(building: Dictionary,district: Dictionary) -> Dictionary:
 var origin: Vector2=Vector2(float(building.local_position[0]),float(building.local_position[1]))
 var best: float=INF
 var chosen: Dictionary={}
 for yaw in [0.0, PI, PI*.5, -PI*.5]:
  var facing: Vector2=Vector2(sin(yaw),cos(yaw))
  var door: Vector2=origin+facing*(float(building.size[1])*.5+.55)
  for road in district.internal_streets:
   var a: Vector2=Vector2(float(road.a[0]),float(road.a[1]))
   var b: Vector2=Vector2(float(road.b[0]),float(road.b[1]))
   var nearest: Vector2=Geometry2D.get_closest_point_to_segment(door,a,b)
   if not _safe_local_walkway(door,nearest,str(building.id),district.buildings):continue
   var cost: float=door.distance_squared_to(nearest)
   if cost<best:
    best=cost
    chosen={"yaw":yaw,"door":[door.x,door.y],"street_point":[nearest.x,nearest.y],"distance":sqrt(cost)}
 return chosen
static func _crosses_rect(a: Vector2,b: Vector2,rect: Rect2) -> bool:
 if rect.has_point(a) or rect.has_point(b):return true
 var x0: float=rect.position.x
 var x1: float=rect.end.x
 var y0: float=rect.position.y
 var y1: float=rect.end.y
 var edges: Array=[ [Vector2(x0,y0),Vector2(x1,y0)], [Vector2(x1,y0),Vector2(x1,y1)],
  [Vector2(x1,y1),Vector2(x0,y1)], [Vector2(x0,y1),Vector2(x0,y0)] ]
 for side in edges:
  if Geometry2D.segment_intersects_segment(a,b,side[0],side[1])!=null:return true
 return false
static func _fits_district(sector: Dictionary,district: Dictionary,arteries: Array) -> bool:
 var polygon:=PackedVector2Array()
 for v in sector.footprint:polygon.append(Vector2(float(v[0]),float(v[1])))
 if polygon.size()<3:return false
 var center: Vector2=Vector2(float(sector.center[0]),float(sector.center[1]))
 var nearby_arteries: Array=arteries.duplicate(true)
 var closest: Vector2=center
 var distance: float=INF
 for artery in arteries:
  var va: Vector2=Vector2(float(artery.a[0]),float(artery.a[1]))
  var vb: Vector2=Vector2(float(artery.b[0]),float(artery.b[1]))
  var q: Vector2=Geometry2D.get_closest_point_to_segment(center,va,vb)
  if q.distance_squared_to(center)<distance:distance=q.distance_squared_to(center);closest=q
 if distance>16.0:nearby_arteries.append({"a":[center.x,center.y],"b":[closest.x,closest.y],"width":2.6})
 for building in district.buildings:
  var pos: Vector2=center+Vector2(float(building.local_position[0]),float(building.local_position[1]))
  var ex: float=maxf(float(building.size[0]),float(building.size[1]))*.5+.15
  var bounds:=Rect2(pos-Vector2.ONE*ex,Vector2.ONE*ex*2.0)
  for corner in [bounds.position,Vector2(bounds.end.x,bounds.position.y),bounds.end,Vector2(bounds.position.x,bounds.end.y)]:
   if not Geometry2D.is_point_in_polygon(corner,polygon):return false
  for road in nearby_arteries:
   var clearance: float=maxf(0.0,float(road.get("width",4.0)))*.5+.65
   var outer:=Rect2(bounds.position-Vector2.ONE*clearance,bounds.size+Vector2.ONE*clearance*2.0)
   var va: Vector2=Vector2(float(road.a[0]),float(road.a[1]))
   var vb: Vector2=Vector2(float(road.b[0]),float(road.b[1]))
   if _crosses_rect(va,vb,outer):return false
 return true
static func _choose_feasible_district(seed_text: String,sector: Dictionary,arteries: Array,profile: Dictionary,catalog: Dictionary,scale: String,forced: String,previous_id: String,remaining_capacity: int) -> Dictionary:
 var eligible_by_category: Dictionary={}
 var ordered: Array=catalog.get("districts",[]).duplicate(true)
 ordered.sort_custom(func(a,b):return str(a.get("id",""))<str(b.get("id","")))
 for district in ordered:
  var category: String=str(district.get("category",""))
  if not forced.is_empty() and category!=forced:continue
  if scale not in district.get("allowed_scales",["town","city"]):continue
  if district.get("buildings",[]).size()>remaining_capacity:continue
  if not _fits_district(sector,district,arteries):continue
  if float(profile.get("weights",{}).get(category,0.0))<=0.0 and forced.is_empty():continue
  if not eligible_by_category.has(category):eligible_by_category[category]=[]
  eligible_by_category[category].append(district)
 if eligible_by_category.is_empty():return {}
 var categories: Array=eligible_by_category.keys()
 categories.sort()
 var total_weight: int=0
 for category in categories:total_weight+=maxi(1,int(round(float(profile.get("weights",{}).get(category,1))*100.0)))
 if total_weight<=0:return {}
 var key: String="CF04|"+seed_text+"|"+str(sector.get("id",""))+"|"+str(scale)
 var ticket: int=key.sha256_text().substr(0,8).hex_to_int()%total_weight
 var selected: String=str(categories[0])
 for category in categories:
  ticket-=maxi(1,int(round(float(profile.get("weights",{}).get(category,1))*100.0)))
  if ticket<0:selected=str(category);break
 var variants: Array=eligible_by_category[selected]
 var distinct: Array=[]
 for candidate in variants:
  if str(candidate.get("id",""))!=previous_id:distinct.append(candidate)
 if not distinct.is_empty():variants=distinct
 return variants[(key+"|"+selected+"|variant").sha256_text().substr(0,8).hex_to_int()%variants.size()]

static func compose(request: Dictionary) -> Dictionary:
 if bool(request.get("blocked_r7_contract",false)):return _invalid("untrusted_r7_contract:"+str(request.get("reason","unknown")))
 if str(request.get("kind",""))!="settlement":return _invalid("not_a_settlement")
 if str(request.get("mode","authored_modular"))!="authored_modular":return _invalid("not_authored_mode")
 if str(request.get("settlement_scale","")) not in ["city","town","village"]:return _invalid("unsupported_scale")
 if int(request.get("region_id",-1))<0 or int(request.get("region_id",-1))>=88:return _invalid("region_outside_88")
 var supplied_gates: Variant=request.get("gates",[])
 if not supplied_gates is Array or supplied_gates.is_empty():return _invalid("no_real_region_gates")
 for entry in supplied_gates:
  if not entry is Array or entry.size()!=2:return _invalid("invalid_gate_descriptor")
  if not is_finite(float(entry[0])) or not is_finite(float(entry[1])):return _invalid("nonfinite_gate")
 var supplied_rivers: Variant=request.get("rivers",[])
 if not supplied_rivers is Array:return _invalid("invalid_rivers")
 for item in supplied_rivers:
  if not item is Dictionary or not item.get("p",null) is Array or item.p.size()!=2:return _invalid("invalid_river_descriptor")
  if not is_finite(float(item.p[0])) or not is_finite(float(item.p[1])):return _invalid("nonfinite_river")
 var supplied_reservations: Variant=request.get("monument_reservations",[])
 if not supplied_reservations is Array:return _invalid("invalid_reservations")
 for rect in supplied_reservations:
  if not rect is Dictionary:return _invalid("invalid_r7_bounds")
  for key in ["min_x","max_x","min_z","max_z"]:
   if not rect.has(key) or not is_finite(float(rect.get(key,INF))):return _invalid("untrusted_r7_bounds")
  if float(rect.min_x)>=float(rect.max_x) or float(rect.min_z)>=float(rect.max_z):return _invalid("inverted_r7_bounds")
 var catalog: Dictionary=Catalog.catalog()
 var profile: Dictionary=Profile.find(catalog,str(request.get("profile_id","rich_commercial_city")))
 if profile.is_empty():return _invalid("unknown_profile")
 var scale: String=str(request.get("settlement_scale","city"))
 if scale not in profile.get("allowed_scales",["village","town","city"]):return _invalid("profile_incompatible_with_scale")
 var blueprint: Dictionary=Blueprint.select(request,catalog)
 if blueprint.is_empty():return _invalid("blueprint_unavailable")
 var available_extent: float=float(request.get("half_extent",0))
 if not is_finite(available_extent) or available_extent<=0:return _invalid("invalid_region_extent")
 if float(blueprint.get("half_extent",9999))+8.0>available_extent:return _invalid("insufficient_region_area")
 var seed_text: String=str(request.get("region_seed","0"))+"|region="+str(request.get("region_id",-1))
 var sectors: Array=[];var buildings: Array=[]
 var prev: String=""
 var forced_martial: int=mini(blueprint.sectors.size(),maxi(0,int(request.get("schools",0))))
 var sector_index: int=0
 var max_properties: int=10 if scale=="village" else 26 if scale=="town" else 48
 var minimum_per_sector: Array=[]
 var all_districts: Array=catalog.get("districts",[])
 for idx in range(blueprint.sectors.size()):
  var next_sector: Dictionary=blueprint.sectors[idx]
  var min_required: int=99999
  for candidate in all_districts:
   var category: String=str(candidate.get("category",""))
   if idx<forced_martial and category!="martial":continue
   if idx>=forced_martial and float(profile.get("weights",{}).get(category,0.0))<=0.0:continue
   if scale not in candidate.get("allowed_scales",["town","city"]):continue
   if _fits_district(next_sector,candidate,blueprint.streets):min_required=mini(min_required,candidate.get("buildings",[]).size())
  if min_required>=99999:return _invalid("no_feasible_layout_for_sector:"+str(next_sector.id))
  minimum_per_sector.append(min_required)
 var total_minimum: int=0
 for count in minimum_per_sector:total_minimum+=int(count)
 if total_minimum>max_properties:return _invalid("blueprint_exceeds_host_lot_capacity:"+str(total_minimum)+"/"+str(max_properties))
 var added_properties: int=0
 for sector in blueprint.sectors:
  var enforced: String="martial" if sector_index<forced_martial else ""
  sector_index+=1
  var future_minimum: int=0
  for j in range(sector_index,minimum_per_sector.size()):future_minimum+=int(minimum_per_sector[j])
  var affordable: int=max_properties-added_properties-future_minimum
  if affordable<int(minimum_per_sector[sector_index-1]):return _invalid("host_scale_capacity_exhausted:"+str(sector.id))
  var district: Dictionary=_choose_feasible_district(seed_text,sector,blueprint.streets,profile,catalog,scale,enforced,prev,affordable)
  if district.is_empty():return _invalid("no_compatible_district:"+str(sector.id)+":"+enforced+":capacity="+str(affordable))
  added_properties+=district.get("buildings",[]).size()
  prev=str(district.id)
  var bounds: Dictionary={"min_x":INF,"max_x":-INF,"min_z":INF,"max_z":-INF}
  for point in sector.footprint:
   bounds.min_x=minf(float(bounds.min_x),float(point[0]));bounds.max_x=maxf(float(bounds.max_x),float(point[0]))
   bounds.min_z=minf(float(bounds.min_z),float(point[1]));bounds.max_z=maxf(float(bounds.max_z),float(point[1]))
  var s: Dictionary={"id":str(sector.id),"center":sector.center,"footprint":sector.footprint,"bounds":bounds,"district_id":str(district.id),"category":str(district.category),"internal_streets":district.internal_streets,"connectors":sector.connectors,"zone":sector.zone}
  sectors.append(s)
  for building in district.buildings:
   var local: Array=building.local_position
   var at: Array=[float(sector.center[0])+float(local[0]),float(sector.center[1])+float(local[1])]
   # Plan a collision-safe access to an internal street (not just an inward facing direction).
   var access: Dictionary=_choose_access(building,district)
   if access.is_empty():return _invalid("no_safe_door_route:"+str(building.id))
   var yaw: float=float(access.yaw)
   var local_door: Array=access.door
   var local_near: Array=access.street_point
   var door: Vector2=Vector2(float(sector.center[0])+float(local_door[0]),float(sector.center[1])+float(local_door[1]))
   var near: Vector2=Vector2(float(sector.center[0])+float(local_near[0]),float(sector.center[1])+float(local_near[1]))
   buildings.append({"id":"cf/r%d/%s/%s"%[int(request.region_id),str(sector.id).get_file(),str(building.id).get_file()],"sector_id":str(sector.id),"district_id":str(district.id),"function":str(building.function),"archetype":str(building.get("archetype","generic")),"structure_details":building.get("structure_details",[]),"p":at,"size":building.size,"height":float(building.height),"yaw":yaw,"door":[door.x,door.y],"street_point":[near.x,near.y],"interior_slot":bool(building.interior_slot),"door_facing":"inner","collision":true,"entry_status":"reserved_not_tested"})
 # Connect each sector's inner circulation to the nearest approved main route in the AUTHORIAL preview.
 # These spurs are NOT substituted into official WorldGenesis streets until host validation.
 var preview_streets: Array=blueprint.streets.duplicate(true)
 for sector in sectors:
  var origin: Vector2=Vector2(float(sector.center[0]),float(sector.center[1]))
  var best: float=INF
  var nearest: Vector2=origin
  for arterial in blueprint.streets:
   var ra: Vector2=Vector2(float(arterial.a[0]),float(arterial.a[1]))
   var rb: Vector2=Vector2(float(arterial.b[0]),float(arterial.b[1]))
   var station: Vector2=Geometry2D.get_closest_point_to_segment(origin,ra,rb)
   var gap: float=origin.distance_squared_to(station)
   if gap<best:best=gap;nearest=station
  if best>16.0:
   preview_streets.append({"a":[origin.x,origin.y],"b":[nearest.x,nearest.y],"width":2.6,"kind":"district_connector"})
 var result: Dictionary={"status":"ready","version":"0.4.0","mode":"authored_modular","region_id":int(request.region_id),"region_seed":seed_text,"blueprint_id":str(blueprint.id),"profile_id":str(profile.id),"settlement_scale":scale,"half_extent":float(request.half_extent),"gates":request.gates,"rivers":request.get("rivers",[]),"river_hub":request.get("river_hub",[72,72]),"monument_reservations":request.get("monument_reservations",[]),"wall":bool(blueprint.wall),"blueprint_half_extent":float(blueprint.half_extent),"streets":preview_streets,"sectors":sectors,"buildings":buildings,"landmarks":[],"errors":[],"metrics":{"buildings":buildings.size(),"properties":buildings.size(),"npc_created":0,"quest_created":0,"host_max_lots":max_properties,"unmaterialized_preview":true}}
 result["society"]=Population.propose(request,profile,sectors)
 # Discretionary urban geometry is rejected on actual R7 footprint collisions.
 var check: Dictionary=Validator.validate(result)
 if not check.ok:result.status="invalid";result.errors=check.errors
 result["validation"]=check
 return result
