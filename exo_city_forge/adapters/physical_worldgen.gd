extends RefCounted
## City Forge owns authored districts/buildings/streets. WorldGenesis approves placement.
const Composer=preload("res://exo_city_forge/runtime/city_composer.gd")
const Registry=preload("res://exo_city_forge/runtime/city_registry.gd")
const Host=preload("res://exo_city_forge/adapters/worldgen_city_adapter.gd")
static func vec(a:Array)->Vector2:return Vector2(float(a[0]),float(a[1]))
static func point(p:Vector2,angle:float,offset:Vector2,scale:float)->Vector2:return p.rotated(angle)*scale+offset
static func plan(data:RefCounted)->Dictionary:
 var scale_name:String=str(data.spec.settlement_scale)
 var profile:String="rural_farming_village" if scale_name=="village" else "agrarian_trade_town" if scale_name=="town" else "rich_commercial_city"
 var req:Dictionary=Host.request_from_region(data,profile)
 if req.get("blocked_r7_contract",false):return {"status":"invalid","errors":["r7_contract"]}
 # Composition is local. All deferred world constraints are validated BELOW, never authorized here.
 req.rivers=[];req.monument_reservations=[]
 var catalog:Dictionary=Registry.catalog()
 var blueprints:Array=catalog.blueprints.duplicate();blueprints.sort_custom(func(a,b):return str(a.id)<str(b.id))
 var seed:int=preload("res://genesis/world_planner.gd").derive(data.spec.region_seed,"CityR4/physical")
 for bi in range(blueprints.size()):
  var bp:Dictionary=blueprints[(bi+seed%blueprints.size())%blueprints.size()]
  if scale_name not in bp.allowed_scales:continue
  req.blueprint_id=bp.id
  var composed:Dictionary=Composer.compose(req)
  if composed.get("status")!="ready":continue
  for compactness in [.62,.72,.82,1.0]:
   for shift in [Vector2.ZERO,Vector2(-64,-64),Vector2(64,-64),Vector2(-64,64),Vector2(64,64),Vector2(-96,0),Vector2(96,0),Vector2(0,-96),Vector2(0,96),Vector2(-110,-110),Vector2(110,-110),Vector2(-110,110),Vector2(110,110)]:
    for quarter in range(12):
     var angle:float=TAU*float((quarter+seed%12)%12)/12.0
     var result:Dictionary=adapt_plan(data,composed,angle,shift,float(compactness))
     if validate(data,result).is_empty():return fill_neighborhoods(data,result)
     if shift==Vector2.ZERO and quarter==0:
      var fitted:Dictionary=fit_frontages(data,result)
      if fitted.get("status")=="ready":return fill_neighborhoods(data,fitted)
 return {"status":"invalid","errors":["city_forge_no_safe_world_placement"],"lots":[],"streets":[],"fixtures":[]}
static func adapt_plan(data:RefCounted,source:Dictionary,angle:float,shift:Vector2,compression:float)->Dictionary:
 var roads:Array=[];var lots:Array=[];var sectors:Array=[]
 var building_scale:float=1.0
 for r in source.streets:
  roads.append({"a":point(vec(r.a),angle,shift,compression),"b":point(vec(r.b),angle,shift,compression),"width":maxf(2.6,float(r.width)*building_scale),"kind":str(r.get("kind","city")),"surface":"stone"})
 for sector in source.sectors:
  var center:Vector2=point(vec(sector.center),angle,shift,compression)
  var info:Dictionary=sector.duplicate(true);info.center=[center.x,center.y];sectors.append(info)
  for r in sector.internal_streets:
   roads.append({"a":point(vec(sector.center)+vec(r.a),angle,shift,compression),"b":point(vec(sector.center)+vec(r.b),angle,shift,compression),"width":maxf(2.6,float(r.get("width",3.0))*building_scale),"kind":"district","surface":"dirt" if str(sector.category) in ["rural","agricultural"] else "stone"})
 # Connect district streets to the authored arterial graph before fitting buildings.
 for local_road in roads.duplicate():
  if local_road.kind!="district":continue
  var best_gap:float=INF;var from:Vector2=local_road.a;var target:Vector2=from
  for end in [local_road.a,local_road.b]:
   for arterial in roads:
    if arterial.kind in ["district","district_connector","quarter_access"]:continue
    var q:Vector2=Geometry2D.get_closest_point_to_segment(end,arterial.a,arterial.b)
    if end.distance_squared_to(q)<best_gap:best_gap=end.distance_squared_to(q);from=end;target=q
  if best_gap>.01:roads.append({"a":from,"b":target,"width":2.6,"kind":"quarter_access","surface":"stone"})
 for gate in data.gates:roads.append({"a":Vector2.ZERO,"b":gate.p,"width":float(gate.width),"kind":"gate","surface":"stone"})
 # A single accepted connector ties the authored city into the external region road graph.
 var nearest:Vector2=Vector2.ZERO;var best:float=INF
 for road in roads:
  if road.kind=="gate":continue
  var q:Vector2=Geometry2D.get_closest_point_to_segment(Vector2.ZERO,road.a,road.b)
  if q.length_squared()<best:best=q.length_squared();nearest=q
 if best>1.0:roads.append({"a":Vector2.ZERO,"b":nearest,"width":4.0,"kind":"arrival","surface":"stone"})
 for b in source.buildings:
  var p:Vector2=point(vec(b.p),angle,shift,compression)
  var yaw:float=float(b.yaw)-angle
  var toward:=Vector2(sin(yaw),cos(yaw))
  var door:Vector2=p+toward*(float(b.size[1])*building_scale*.5+.8)
  var street:Vector2=door;var distance:float=INF
  for r in roads:
   var q:Vector2=Geometry2D.get_closest_point_to_segment(door,r.a,r.b)
   if q.distance_squared_to(door)<distance:distance=q.distance_squared_to(door);street=q
  var model:Dictionary=b.duplicate(true);model.p=[p.x,p.y];model.yaw=yaw;model.size=[float(b.size[0])*building_scale,float(b.size[1])*building_scale]
  lots.append({"id":str(b.id),"p":p,"height":data.center_h,"yaw":yaw,"halfsize":maxf(float(model.size[0]),float(model.size[1]))*.5+.8,"door":door,"street_point":street,"frontage":sqrt(distance),"terrain_spread":0.0,"terraced":true,"function":str(b.function),"form":"city_forge","district":str(b.district_id),"city_model":model,"city_forge_r4":{"district_id":str(b.district_id),"authorized_state":"planned_worldgen_validation","host_geometry_verified":false}})
 return {"status":"ready","version":7,"owner":"city_forge_r4","scale":data.spec.settlement_scale,"region_id":int(data.spec.id),"target":lots.size(),"lots":lots,"streets":roads,"fixtures":[],"errors":[],"city_forge_r4":{"semantic_only":false,"blueprint_id":source.blueprint_id,"profile_id":source.profile_id,"compression":compression,"shift":[shift.x,shift.y],"rotation":angle,"sectors":sectors}}
static func validate(data:RefCounted,p:Dictionary)->Array:
 var errors:Array=[]
 if p.get("status")!="ready":return p.get("errors",["not_ready"])
 for lot in p.lots:
  var at:Vector2=lot.p;var radius:float=float(lot.halfsize)
  if absf(at.x)+radius>data.half-12 or absf(at.y)+radius>data.half-12:errors.append("bounds");break
  if data.river_distance(at)<radius+5.0:errors.append("river");break
  for monument in data.monumental_plans:
   var r:Dictionary=monument.bounds
   if at.x+radius>float(r.min_x)-2 and at.x-radius<float(r.max_x)+2 and at.y+radius>float(r.min_z)-2 and at.y-radius<float(r.max_z)+2:errors.append("monument");break
  for road in p.streets:
   if at.distance_to(Geometry2D.get_closest_point_to_segment(at,road.a,road.b))<radius+float(road.width)*.5+.35:errors.append("road");break
  for other in p.lots:
   if str(other.id)<=str(lot.id):continue
   if at.distance_to(other.p)<radius+float(other.halfsize)+.5:errors.append("overlap");break
  if lot.door.distance_to(lot.street_point)>25:errors.append("door_access")
  if not errors.is_empty():break
 return errors

static func fit_frontages(data:RefCounted,source:Dictionary)->Dictionary:
 # Retain authored buildings/functions. Fit rejected parcels to the SAME City Forge street graph.
 var result:Dictionary=source.duplicate(true)
 var pending:Array=result.lots;result.lots=[]
 for lot in pending:
  result.lots.append(lot)
  if validate(data,result).is_empty():continue
  result.lots.pop_back()
  var found:bool=false
  var original:Vector2=lot.p
  var streets:Array=result.streets.duplicate()
  streets.sort_custom(func(a,b):return original.distance_squared_to((a.a+a.b)*.5)<original.distance_squared_to((b.a+b.b)*.5))
  for road in streets:
   var along:Vector2=(road.b-road.a).normalized();var side:=Vector2(-along.y,along.x)
   var size:Array=lot.city_model.size
   var clearance:float=float(lot.halfsize)+float(road.width)*.5+1.25
   for step in range(1,16):
    for sign_side in [-1.0,1.0]:
     var p:Vector2=road.a.lerp(road.b,float(step)/16.0)+side*clearance*sign_side
     if p.length()>172.0:continue
     var facing:Vector2=-side*sign_side
     var yaw:float=atan2(facing.x,facing.y)
     lot.p=p;lot.yaw=yaw;lot.door=p+facing*(float(size[1])*.5+.8)
     lot.street_point=Geometry2D.get_closest_point_to_segment(lot.door,road.a,road.b)
     lot.frontage=lot.door.distance_to(lot.street_point)
     lot.city_model.p=[p.x,p.y];lot.city_model.yaw=yaw
     result.lots.append(lot)
     if validate(data,result).is_empty():found=true;break
     result.lots.pop_back()
    if found:break
   if found:break
  if not found:return {"status":"invalid","errors":["city_frontage_fit_failed"]}
 result.city_forge_r4["frontage_fit"]=true
 return result

static func fill_neighborhoods(data:RefCounted,source:Dictionary)->Dictionary:
 # Infill belongs to the same approved City Forge plan, never a second builder.
 var result:Dictionary=source.duplicate(true)
 var scale_name:String=str(data.spec.settlement_scale)
 var target:int=12 if scale_name=="village" else 32 if scale_name=="town" else 64
 var roads:Array=result.streets.duplicate()
 roads.sort_custom(func(a,b):
  var rank_a:int=int(str(a.kind)!="district");var rank_b:int=int(str(b.kind)!="district")
  return rank_a<rank_b if rank_a!=rank_b else ((a.a+a.b)*.5).length_squared()<((b.a+b.b)*.5).length_squared())
 for road in roads:
  if result.lots.size()>=target:break
  if str(road.kind) in ["gate","arrival"]:continue
  var along:Vector2=(road.b-road.a).normalized()
  var side:=Vector2(-along.y,along.x)
  var count:int=int(road.a.distance_to(road.b)/4.0)
  for step in range(1,count):
   for sign_side in [-1.0,1.0]:
    if result.lots.size()>=target:break
    var at:Vector2=road.a+along*float(step)*4.0+side*sign_side*(3.8+float(road.width)*.5+.65)
    var facing:Vector2=-side*sign_side
    var door:Vector2=at+facing*3.8
    var street:Vector2=Geometry2D.get_closest_point_to_segment(door,road.a,road.b)
    var id:String="cf/r%d/infill/%03d"%[int(data.spec.id),result.lots.size()]
    var model:Dictionary={"id":id,"size":[6.0,6.0],"stories":2,"function":"residence","archetype":"forja_house","p":[at.x,at.y],"yaw":atan2(facing.x,facing.y)}
    var lot:Dictionary={"id":id,"p":at,"height":data.center_h,"yaw":model.yaw,"halfsize":3.8,"door":door,"street_point":street,"frontage":door.distance_to(street),"terrain_spread":0.0,"terraced":true,"function":"residence","form":"city_forge","district":"residential_infill","city_model":model,"city_forge_r4":{"district_id":"residential_infill","authorized_state":"planned_worldgen_validation","host_geometry_verified":false}}
    result.lots.append(lot)
    if not validate(data,result).is_empty():result.lots.pop_back()
 result.target=result.lots.size()
 result.city_forge_r4["infill_target"]=target
 result.city_forge_r4["infill_actual"]=result.lots.size()-source.lots.size()
 return result
