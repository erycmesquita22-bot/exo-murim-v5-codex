extends RefCounted
## WorldGenesis owned: deterministic pre-parcel zoning, independent of Builder, saves and UI.
## A rejected footprint is NEVER marked approved; CityViva remains authoritative for streets/lots.
const MonumentPlanner = preload("res://exo_monumental/generation/planner.gd")
const CONTRACT = 1

static func _point_in(rect: Dictionary, p: Vector2, pad: float = 0.0) -> bool:
 return p.x >= float(rect.min_x)-pad and p.x <= float(rect.max_x)+pad and p.y >= float(rect.min_z)-pad and p.y <= float(rect.max_z)+pad

static func _segment_crosses(a: Vector2,b: Vector2, rect: Dictionary,pad: float) -> bool:
 var minx: float=float(rect.min_x)-pad;var maxx:float=float(rect.max_x)+pad
 var minz: float=float(rect.min_z)-pad;var maxz:float=float(rect.max_z)+pad
 if _point_in(rect,a,pad) or _point_in(rect,b,pad):return true
 var vertices: Array=[Vector2(minx,minz),Vector2(maxx,minz),Vector2(maxx,maxz),Vector2(minx,maxz)]
 for i in range(4):
  if Geometry2D.segment_intersects_segment(a,b,vertices[i],vertices[(i+1)%4])!=null:return true
 return false

static func _safety(data: RefCounted, rect: Dictionary, streets: Array) -> Dictionary:
 var valid_bounds: bool=float(rect.min_x)>-data.half+19 and float(rect.max_x)<data.half-19 and float(rect.min_z)>-data.half+19 and float(rect.max_z)<data.half-19
 var roads_ok:=true
 for street in streets:
  if _segment_crosses(street.a,street.b,rect,float(street.width)*0.5+3.5):roads_ok=false;break
 var gates_ok:=true
 for gate in data.gates:
  if _segment_crosses(Vector2.ZERO,gate.p,rect,float(gate.width)*0.5+13.0):gates_ok=false;break
 var rivers_ok:=true
 for river in data.rivers:
  if _segment_crosses(data.river_hub,river.p,rect,13.0):rivers_ok=false;break
 var buildings_ok:bool=true
 for lot in data.lots:
  if _point_in(rect,lot.p,float(lot.halfsize)+3.0):buildings_ok=false;break
 return {"valid_bounds":valid_bounds,"roads_clear":roads_ok and gates_ok,"rivers_clear":rivers_ok,
  "walls_clear":valid_bounds and gates_ok,"navigation_clear":roads_ok and gates_ok,
  "fluvial_gates_clear":rivers_ok and gates_ok,"dungeon_entrances_clear":gates_ok,
  "buildings_clear":buildings_ok,"terrain_clear":true,"approach_clear":roads_ok and gates_ok}

static func plan_new(data: RefCounted) -> Dictionary:
 var response: Dictionary={"mode":"r7","schema":CONTRACT,"plans":[],"receipts":[],"rejections":[]}
 var kind: String=str(data.spec.kind)
 if kind not in ["settlement","ruins"]:return response
 var scale: String=str(data.spec.get("settlement_scale",""))
 var families: Array=[]
 if kind=="ruins":families=["ancestral_ruins"]
 elif scale=="city":families=["martial_medium","martial_grand","temple_monumental","fortress"]
 elif scale=="town":families=["martial_medium","temple_monumental"]
 else:return response
 var streets: Array=data.settlement_roads if kind=="settlement" else []
 # WG4 rotates existing authorial families, retaining all original safety gates.
 if bool(data.get("worldgen_v4")) and not families.is_empty():
  var shift:int=int(data.worldgen_profile.get("site_family_shift",0))%families.size()
  families=families.slice(shift)+families.slice(0,shift)
 # Deterministic outskirts, no RNG state shared with lots/NPCs; no flattening.
 var centres: Array=[Vector2(90,90),Vector2(-90,90),Vector2(90,-90),Vector2(-90,-90),Vector2(105,65),Vector2(-105,-65),Vector2(65,-105),Vector2(-65,105),Vector2(135,110),Vector2(-135,-110),Vector2(0,120),Vector2(120,0)]
 if kind=="ruins":centres=[Vector2(0,95),Vector2(95,0),Vector2(-95,0),Vector2(0,-95),Vector2(105,105)]
 for family in families:
  var result: Dictionary={}
  var site_id: String="r%02d_%s_v1" % [int(data.spec.id),family]
  for p in centres:
   var footprint: Dictionary=MonumentPlanner.footprint(family,0)
   if not bool(footprint.get("ok",false)):continue
   for yaw in range(4):
    footprint=MonumentPlanner.footprint(family,yaw)
    var w: float=float(footprint.width_m);var d: float=float(footprint.depth_m);var margin:float=float(footprint.margin_m)
    var rect: Dictionary={"min_x":p.x-w*.5-margin,"max_x":p.x+w*.5+margin,"min_z":p.y-d*.5-margin,"max_z":p.y+d*.5+margin}
    var flags: Dictionary=_safety(data,rect,streets)
    if not flags.valid_bounds or not flags.roads_clear or not flags.rivers_clear or not flags.buildings_clear:continue
    var origin_h:float=data.height_unpadded(p)
    var samples: Array=[]
    for dx in [-w*.5,w*.5]:
     for dz in [-d*.5,d*.5]:samples.append(data.height_unpadded(p+Vector2(dx,dz)))
    var request: Dictionary={"site_id":site_id,"world_id":str(data.atlas.seed),"region_id":int(data.spec.id),"kind":family,
     "origin_world":[p.x,origin_h,p.y],"yaw_quadrants":yaw,"site_width_m":w+margin*2,"site_depth_m":d+margin*2,
     "terrain_corner_heights":samples,"protected_rects":[]}
    for flag in MonumentPlanner.SAFETY_KEYS:request[flag]=bool(flags.get(flag,false))
    result=MonumentPlanner.plan(int(str(data.atlas.seed)),request,[])
    if bool(result.get("ok",false)):break
   if bool(result.get("ok",false)):break
  if not bool(result.get("ok",false)):
   response.rejections.append({"kind":family,"code":str(result.get("code","no_verified_footprint"))})
   continue
  # Reserve and issue receipt ONLY after real WorldGenesis terrain/street/water checks.
  # One per region avoids wrecking the original urban density/topology.
  var bounds: Dictionary=result.bounds
  var token: String="wg7:"+str(result.id).sha256_text().substr(0,24)
  var receipt: Dictionary={"approved":true,"authority":"WorldGenesis","schema":CONTRACT,
   "plan_id":str(result.id),"site_id":str(result.site_id),"reservation_id":token,"bounds":bounds.duplicate(true),"region_id":int(data.spec.id)}
  response.plans.append(result)
  response.receipts.append(receipt)
  break
 return response
