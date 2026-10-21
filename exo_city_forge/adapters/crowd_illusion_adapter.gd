extends RefCounted
## Read-only contract with Crowd Illusion 01 candidate and R13 real RegionData.
## Called only AFTER official WorldGenesis has accepted/materialized streets and lots.
## Never creates NPCs, changes roster, writes saves, or replaces NPC System 02.
## Produces ONLY keys accepted by Crowd Illusion crowd_zones_schema.json.
const ROLES = {"residential":"resident","commerce":"merchant","commercial":"merchant", "martial":"disciple","artisan":"merchant", "mixed":"resident", "civic":"guard", "institutional":"guard", "administrative":"guard", "noble":"resident", "plaza":"traveler", "cultural":"traveler", "agricultural":"resident", "rural":"resident", "farmstead":"resident"}
const CAPACITY = {"resident":5,"merchant":8,"disciple":6,"guard":3,"traveler":4}
const META_KEY = "exo_city_forge_crowd_zones"
const META_INDEX = "exo_city_forge_crowd_area_index"
static func _safe_point(p: Vector2, lots: Array, stations: Dictionary, reservations: Array, gates: Array) -> bool:
 for lot in lots:
  if not lot is Dictionary:continue
  var center: Variant=lot.get("p",null)
  if center is Vector2 and p.distance_to(center)<maxf(3.0,float(lot.get("halfsize",5.5)))+1.7:return false
  var door: Variant=lot.get("door",null)
  if door is Vector2 and p.distance_to(door)<3.2:return false
  var access: Variant=lot.get("street_point",null)
  if door is Vector2 and access is Vector2:
   if p.distance_to(Geometry2D.get_closest_point_to_segment(p,door,access))<1.65:return false
 for sid in stations:
  var station: Variant=stations[sid]
  if station is Vector3 and p.distance_to(Vector2(station.x,station.z))<2.8:return false
 for reservation in reservations:
  if not reservation is Dictionary:continue
  if p.x>float(reservation.get("min_x",INF))-3.2 and p.x<float(reservation.get("max_x",-INF))+3.2 and p.y>float(reservation.get("min_z",INF))-3.2 and p.y<float(reservation.get("max_z",-INF))+3.2:return false
 for gate in gates:
  if gate is Dictionary and gate.get("p",null) is Vector2 and p.distance_to(gate.p)<7.0:return false
 return true
static func _identify_area(mid: Vector2,lots: Array) -> Dictionary:
 var best := INF
 var label := "residential"
 var building_function := "residence"
 var district_id := ""
 for lot in lots:
  if not lot is Dictionary:continue
  var position: Variant=lot.get("p",null)
  if not position is Vector2:continue
  var distance: float=position.distance_squared_to(mid)
  if distance<best:
   best=distance
   label=str(lot.get("district","residential"))
   building_function=str(lot.get("function","residence"))
   district_id=str(lot.get("city_forge_district_id",""))
 var role: String=str(ROLES.get(label,"resident"))
 if building_function in ["market","inn","herbalist","warehouse"]:role="merchant"
 elif building_function=="martial_school":role="disciple"
 elif building_function=="administration":role="guard"
 return {"district":label,"district_id":district_id,"role":role,"nearest_function":building_function,"ambient_scale":"rural" if label in ["agricultural","rural"] else "urban"}
static func _lane_safe(start: Vector2,end: Vector2,lots: Array,stations: Dictionary,reservations:Array,gates:Array) -> bool:
 var length: float=start.distance_to(end)
 if length<7.0:return false
 var samples: int=maxi(3,int(ceil(length/1.5)))
 for j in range(samples+1):
  if not _safe_point(start.lerp(end,float(j)/float(samples)),lots,stations,reservations,gates):return false
 return true
static func _slope_safe(data: RefCounted,start: Vector2,end: Vector2,maximum: float=.12) -> bool:
 var length: float=start.distance_to(end)
 if length<.001:return false
 var slices: int=maxi(2,int(ceil(length/1.5)))
 var previous_h: float=float(data.height_at(start))
 if not is_finite(previous_h):return false
 var previous_p: Vector2=start
 for i in range(1,slices+1):
  var p: Vector2=start.lerp(end,float(i)/float(slices))
  var h: float=float(data.height_at(p))
  if not is_finite(h):return false
  if absf(h-previous_h)/maxf(.001,p.distance_to(previous_p))>maximum:return false
  previous_h=h
  previous_p=p
 return true
static func inspect_region(region: Node3D,max_zones: int=10) -> Dictionary:
 if not is_instance_valid(region):return {"ok":false,"reason":"missing_region","zones":[]}
 var data: Variant=region.get("data")
 if data==null or not data is RefCounted:return {"ok":false,"reason":"missing_official_region_data","zones":[]}
 var spec: Dictionary=data.get("spec")
 if str(spec.get("kind",""))!="settlement" or str(spec.get("settlement_scale","")) not in ["village","town","city"]:
  return {"ok":false,"reason":"non_urban_region","zones":[]}
 var official: Dictionary=data.get("settlement_plan")
 if str(official.get("status",""))!="ready":return {"ok":false,"reason":"official_settlement_not_ready","zones":[]}
 if str(spec.get("settlement_scale",""))=="village":max_zones=mini(max_zones,3)
 var roads: Array=data.get("settlement_roads")
 var lots: Array=data.get("lots")
 if roads.is_empty() or lots.is_empty():return {"ok":false,"reason":"official_roads_or_lots_missing","zones":[]}
 var stations: Dictionary=region.get("station_points")
 # R7 source may be empty or different semantic shape. Approved footprints use receipts.
 var candidate_receipts: Array=data.get("monumental_receipts")
 var plans: Array=data.get("monumental_plans")
 var rectangles: Array=[]
 for receipt in candidate_receipts:
  if not receipt is Dictionary:continue
  if not bool(receipt.get("approved",false)):continue
  var bounds: Variant=receipt.get("bounds",null)
  if bounds is Dictionary and bounds.has("min_x") and bounds.has("max_x") and bounds.has("min_z") and bounds.has("max_z"):
   rectangles.append(bounds)
 # An accepted R7 monument without a readable footprint must block ghost lanes, not be ignored.
 if plans.size()>0 and rectangles.size()<plans.size():
  return {"ok":false,"reason":"r7_reservation_bounds_unavailable","zones":[]}
 var gates: Array=data.get("gates")
 var candidates: Array=[]
 var details: Dictionary={}
 for ri in range(roads.size()):
  var road: Variant=roads[ri]
  if not road is Dictionary:continue
  var a: Variant=road.get("a",null)
  var b: Variant=road.get("b",null)
  if not (a is Vector2 and b is Vector2):continue
  var length: float=a.distance_to(b)
  var width: float=float(road.get("width",5.0))
  if length<14.0 or width<4.0:continue
  var dir: Vector2=(b-a).normalized()
  var normal: Vector2=Vector2(-dir.y,dir.x)
  # Stay INSIDE accepted street carriageway to avoid occupying unverified sidewalks.
  var offset: float=minf(2.6,maxf(0.0,width*.5-1.3))
  var chunks: int=clampi(int(ceil(length/22.0)),1,12)
  for i in range(chunks):
   var begin: Vector2=a.lerp(b,(float(i)+0.13)/float(chunks))
   var end: Vector2=a.lerp(b,(float(i)+0.87)/float(chunks))
   var mid: Vector2=(begin+end)*.5
   var area: Dictionary=_identify_area(mid,lots)
   for side in [-1.0,1.0]:
    var p0: Vector2=begin+normal*offset*side
    var p1: Vector2=end+normal*offset*side
    if not _lane_safe(p0,p1,lots,stations,rectangles,gates):continue
    if not _slope_safe(data,p0,p1):continue
    var h0: float=float(data.height_at(p0))
    var h1: float=float(data.height_at(p1))
    var slope: float=absf(h1-h0)/maxf(.001,p0.distance_to(p1))
    if not is_finite(h0) or not is_finite(h1) or slope>.12:continue
    var role: String=str(area.role)
    var zone_id: String="cf/r%d/road%03d/seg%02d/side%d"%[int(spec.get("id",-1)),ri,i,1 if side>0 else 0]
    var zone: Dictionary={"id":zone_id,"points":[[p0.x,h0+.07,p0.y],[p1.x,h1+.07,p1.y]],"capacity":mini(2,int(CAPACITY.get(role,4))) if str(spec.get("settlement_scale",""))=="village" else int(CAPACITY.get(role,4)),"role":role,"activity":"walk","lateral":0.12,"safety_radius":3.2}
    if role in ["disciple","guard"]:zone["activity"]="observe" if role=="guard" else "walk"
    candidates.append({"zone":zone,"area":area,"priority":int(CAPACITY.get(role,4))*10+int(p0.distance_to(p1))})
    details[zone_id]=area
 candidates.sort_custom(func(l,r):return l.priority>r.priority if l.priority!=r.priority else str(l.zone.id)<str(r.zone.id))
 var zones: Array=[]
 var area_index: Dictionary={}
 for c in candidates:
  if zones.size()>=clampi(max_zones,0,16):break
  zones.append(c.zone)
  area_index[str(c.zone.id)]=c.area
 return {"ok":not zones.is_empty(),"reason":"ready" if not zones.is_empty() else "no_safe_street_lanes", "source":"official_worldgen_r13","zones":zones,"area_index":area_index,"candidates":candidates.size(),"rejected":maxi(0,roads.size()*2-zones.size()),"owner":"WorldGenesis","npc_created":0}
static func publish_after_build(region: Node3D,enabled: bool=false,max_zones: int=10) -> Dictionary:
 if not is_instance_valid(region):return {"ok":false,"reason":"missing_region"}
 # Scene metadata is ephemeral. Every attach must clear stale zones, even on failure.
 if region.has_meta(META_KEY):region.remove_meta(META_KEY)
 if region.has_meta(META_INDEX):region.remove_meta(META_INDEX)
 if not enabled:return {"ok":false,"reason":"explicit_opt_in_required"}
 var civic: Variant=region.get_meta("cidade_viva",{})
 if not civic is Dictionary or not bool(civic.get("rendered",false)):
  return {"ok":false,"reason":"cidade_viva_not_rendered"}
 var computed: Dictionary=inspect_region(region,max_zones)
 if bool(computed.get("ok",false)):
  region.set_meta(META_KEY,computed.zones)
  region.set_meta(META_INDEX,computed.area_index)
 return computed
static func detach(region: Node3D) -> void:
 if not is_instance_valid(region):return
 if region.has_meta(META_KEY):region.remove_meta(META_KEY)
 if region.has_meta(META_INDEX):region.remove_meta(META_INDEX)
