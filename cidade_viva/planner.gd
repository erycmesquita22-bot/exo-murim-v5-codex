extends RefCounted
## Cidade Viva 01 — camada de urbanismo visual, determinista e sem estado persistente.
## O contrato de lotes, estradas, portas, NPCs, rios e muralhas permanece propriedade do EXO Core.
const VERSION := 2
const WorldPlanner = preload("res://genesis/world_planner.gd")
const MAX_VISUALS := {"village":24,"town":86,"city":180}
const Kit=preload("res://godot/modular_kit.gd")
const Architecture=preload("res://convergence/architecture.gd")
const COMMERCIAL := ["market","inn","smithy","herbalist","warehouse"]
const CIVIC := ["administration","shrine"]
const TRAINING := ["martial_school"]
const AGRICULTURAL := ["farmstead"]
const FOOTPRINTS := {
 "covered_market_stall":2.2,"tea_table_with_stools":1.5,"woven_market_baskets":.9,
 "smith_tool_rack":.75,"herb_drying_rack":1.1,"herbalist_medicine_jars":.7,
 "firewood_stack":1.0,"garden_bed_2x2":1.2,"stone_garden_lantern":.7,
 "public_timber_bench":1.1,"training_dummy":.9,"weapons_training_rack":1.1,
 "vegetable_field_4m":2.1,"rice_field_4m":2.1,"hay_cart":2.1,
 "timber_handcart":1.7,"village_notice_board":1.2,"street_lamp_post":.8,
 "tea_garden_bush":.9,"herbalist_garden_box":1.2,"grain_silo":2.0,
 "tree_orchard":3.0,"tree_broad_01":3.0,"bamboo_cluster_01":1.4,
 "open_pavilion_6m":5.0,"training_pavilion_6m":5.0,"temple_hall_8m":6.8
}

static func radius_for(asset_id: String) -> float:
 Kit.ensure()
 var bounds: Array=Kit.catalog.get(asset_id,{}).get("bounds",[])
 if bounds.size()!=2:return float(FOOTPRINTS.get(asset_id,1.0))
 var extent_x: float=maxf(absf(float(bounds[0][0])),absf(float(bounds[1][0])))
 var extent_z: float=maxf(absf(float(bounds[0][2])),absf(float(bounds[1][2])))
 return maxf(float(FOOTPRINTS.get(asset_id,1.0)),Vector2(extent_x,extent_z).length())

static func reservations(data: RefCounted) -> Array:
 var result: Array=[]
 for lot in data.lots:
  var expanded: bool=lot.function in ["martial_school","shrine"] and Architecture.can_expand(data,lot)
  result.append({"p":lot.p,"yaw":lot.yaw,"min":Vector2(-5.45,-13.8 if expanded else -5.45),"max":Vector2(5.45,5.45)})
  # Facade stations in two wings, including the extended courtyard approach.
  var approach: float=4.7
  var outcome: Dictionary=Architecture.plan(data,lot)
  if outcome.ok:approach=float(outcome.plan.approach_local[2])
  result.append({"p":lot.p,"yaw":lot.yaw,"min":Vector2(-5.3,approach-.1),"max":Vector2(5.3,approach+1.45)})
 return result

static func distance_to_reservation(p: Vector2,box: Dictionary) -> float:
 var local: Vector2=(p-box.p).rotated(float(box.yaw))
 return local.distance_to(local.clamp(box.min,box.max))

static func district_of(lot: Dictionary, scale: String,all_lots: Array=[]) -> String:
 var role: String=str(lot.get("function","residence"))
 if role in COMMERCIAL:return "commerce"
 if role in TRAINING:return "martial"
 if role in CIVIC:return "civic"
 if role in AGRICULTURAL:return "productive"
 if scale=="village":return "rural_homes"
 # Zona mista de influencia, sem reclassificar a profissão ou o proprietário.
 if scale in ["city","town"]:
  var commercial_distance:=INF
  var school_distance:=INF
  for neighbor in all_lots:
   if str(neighbor.id)==str(lot.id):continue
   var separation: float=(neighbor.p as Vector2).distance_to(lot.p)
   if str(neighbor.function) in COMMERCIAL:commercial_distance=minf(commercial_distance,separation)
   if str(neighbor.function) in TRAINING:school_distance=minf(school_distance,separation)
  if commercial_distance<34.0:return "mixed_commerce"
  if school_distance<26.0:return "martial_edge"
 return "residential"

static func _distance_to_segment(p: Vector2,a: Vector2,b: Vector2) -> float:
 return p.distance_to(Geometry2D.get_closest_point_to_segment(p,a,b))

static func _safe(p: Vector2,r: float, data: RefCounted, placed: Array, ring: Array, reserved: Array=[]) -> bool:
 if absf(p.x)>float(data.half)-22.0-r or absf(p.y)>float(data.half)-22.0-r:return false
 for area in reserved:
  if distance_to_reservation(p,area)<r+.35:return false
 # Portas, estradas de acesso regional e trajetos das entradas das casas são imutáveis.
 for gate in data.gates:
  if _distance_to_segment(p,Vector2.ZERO,gate.p)<float(gate.width)*.5+r+3.0:return false
 for street in data.settlement_roads:
  if _distance_to_segment(p,street.a,street.b)<float(street.width)*.5+r+1.2:return false
 for river in data.rivers:
  if _distance_to_segment(p,data.river_hub,river.p)<r+12.0:return false
 for fixture in data.settlement_plan.get("fixtures",[]):
  if p.distance_to(fixture.p)<r+float(fixture.get("halfsize",2.5))+3.0:return false
  if _distance_to_segment(p,fixture.p,fixture.street_point)<r+1.6:return false
 for lot in data.lots:
  if p.distance_to(lot.p)<r+float(lot.halfsize)+.85:return false
  if _distance_to_segment(p,lot.door,lot.street_point)<r+1.7:return false
 # O muro foi calculado antes; elementos novos não podem ocupar sua faixa ou saídas.
 if not ring.is_empty():
  if not Geometry2D.is_point_in_polygon(p,PackedVector2Array(ring)):return false
  for i in range(ring.size()):
   if _distance_to_segment(p,ring[i],ring[(i+1)%ring.size()])<r+6.0:return false
 for item in placed:
  if p.distance_to(item.p)<r+float(item.radius)+.8:return false
 # Mostrares devem pousar no terreno já amostrado, sem flutuar sobre bordas.
 var center: float=float(data.height_at(p))
 for delta in [Vector2(r,0),Vector2(-r,0),Vector2(0,r),Vector2(0,-r)]:
  if absf(float(data.height_at(p+delta))-center)>.35:return false
 return true

static func _add(placed: Array,record: Dictionary, data: RefCounted,ring: Array,cap: int,reserved: Array=[]) -> bool:
 if placed.size()>=cap:return false
 var p: Vector2=record.p
 var radius: float=maxf(radius_for(str(record.asset_id)),float(record.get("terrain_radius",0.0)))
 if not _safe(p,radius,data,placed,ring,reserved):return false
 record["radius"]=radius
 record["y"]=float(data.height_at(p))
 placed.append(record)
 return true

static func plan(data: RefCounted,fortification: Dictionary={}) -> Dictionary:
 var empty := {"status":"skipped","version":VERSION,"visuals":[],"districts":{},"activity_pois":{},"metrics":{},"reason":"not_settlement"}
 if str(data.spec.get("kind",""))!="settlement":return empty
 if data.settlement_plan.get("status","")!="ready":
  empty["reason"]="settlement_not_ready";return empty
 var scale: String=str(data.spec.get("settlement_scale","village"))
 if not MAX_VISUALS.has(scale):empty["reason"]="unknown_scale";return empty
 var ring: Array=[]
 if scale=="city":
  if str(fortification.get("status",""))!="ready":
   empty["reason"]="city_wall_not_ready";return empty
  ring=fortification.get("plan",fortification).get("polygon",[])
  if ring.size()<3:empty["reason"]="missing_perimeter_polygon";return empty
 var cap: int=int(MAX_VISUALS[scale])
 var reserved: Array=reservations(data)
 var placed: Array=[]
 var district_map: Dictionary={}
 var activities: Dictionary={}
 var ordered: Array=data.lots.duplicate()
 ordered.sort_custom(func(a,b):return str(a.id)<str(b.id))
 for lot in ordered:
  var district: String=district_of(lot,scale,ordered)
  district_map[district]=int(district_map.get(district,0))+1
  # Um POI associado a uma identidade EXISTENTE — nunca nasce um morador extra.
  activities[str(lot.id)]={"function":str(lot.function),"district":district,"lot_id":str(lot.id),"point":lot.street_point}
  var rng:=RandomNumberGenerator.new()
  rng.seed=WorldPlanner.derive(str(data.spec.region_seed),"cidade_viva01/"+str(lot.id))
  var front:=Vector2(sin(float(lot.yaw)),cos(float(lot.yaw)))
  var side:=Vector2(front.y,-front.x)
  var choices: Array=[]
  match district:
   "commerce":choices=["covered_market_stall","woven_market_baskets","tea_table_with_stools"] if lot.function in ["market","inn"] else ["timber_handcart","smith_tool_rack","firewood_stack"] if lot.function=="smithy" else ["herb_drying_rack","herbalist_garden_box","herbalist_medicine_jars"] if lot.function=="herbalist" else ["woven_market_baskets","timber_handcart","covered_market_stall"]
   "martial":choices=["training_dummy","weapons_training_rack","training_dummy"]
   "civic":choices=["village_notice_board","stone_garden_lantern","public_timber_bench"]
   "productive":choices=["vegetable_field_4m","hay_cart","firewood_stack"]
   "mixed_commerce":choices=["woven_market_baskets","tea_table_with_stools","garden_bed_2x2"]
   "martial_edge":choices=["training_dummy","garden_bed_2x2","tea_garden_bush"]
   _:choices=["garden_bed_2x2","firewood_stack","tea_garden_bush","public_timber_bench"]
  # Preferir anexos junto à própria casa; rota frontal permanece livre.
  var sides: Array=[1.0,-1.0]
  if rng.randi_range(0,1)==1:sides.reverse()
  var local_budget: int=3 if district in ["commerce","martial"] else 2 if scale!="village" else 1
  var accepted_for_lot:=0
  for sign_value in sides:
   for attempt in range(7):
    if placed.size()>=cap or accepted_for_lot>=local_budget:break
    var asset_id: String=str(choices[(attempt+rng.randi_range(0,choices.size()-1))%choices.size()])
    var radius: float=radius_for(asset_id)
    var pos: Vector2=lot.p+side*sign_value*(6.0+radius+float(attempt%3)*1.8)+front*(-3.0+float(attempt/3)*3.4)
    var record: Dictionary={"asset_id":asset_id,"p":pos,"yaw":float(lot.yaw),"lot_id":str(lot.id),"district":district,"purpose":"annex"}
    if _add(placed,record,data,ring,cap,reserved):
     accepted_for_lot+=1
     if district not in ["commerce","martial"]:break
  # Pequenos objetos nas laterais, nunca diretamente na soleira.
  if rng.randf() < (0.86 if district=="commerce" else 0.64 if district in ["civic","martial"] else 0.38):
   var detail: String="woven_market_baskets" if district=="commerce" else "training_dummy" if district=="martial" else "stone_garden_lantern" if district=="civic" else "firewood_stack" if district=="productive" else "woven_market_baskets" if district=="mixed_commerce" else "tea_garden_bush"
   var q: Vector2=lot.p+front*6.3+side*(5.2 if rng.randf()<.5 else -5.2)
   _add(placed,{"asset_id":detail,"p":q,"yaw":float(lot.yaw),"lot_id":str(lot.id),"district":district,"purpose":"front_detail"},data,ring,cap,reserved)
 # As praças recebem vida sem engarrafar cruzamentos ou o poço.
 if data.settlement_roads.is_empty():cap=placed.size()
 var cap_civic: int=0 if data.settlement_roads.is_empty() else 3 if scale=="city" else 2 if scale=="town" else 1
 for k in range(cap_civic):
  var road: Dictionary=data.settlement_roads[k%data.settlement_roads.size()]
  var tangent: Vector2=(road.b-road.a).normalized()
  var normal:=Vector2(-tangent.y,tangent.x)
  var p: Vector2=(road.a+road.b)*.5 + tangent*float(7+9*k) + normal*float(14+2*k)*(1.0 if k%2==0 else -1.0)
  _add(placed,{"asset_id":"village_notice_board" if k==0 else "street_lamp_post","p":p,"yaw":atan2(tangent.x,tangent.y),"lot_id":"@public","district":"civic","purpose":"public_poi"},data,ring,cap,reserved)
 # Distribute lighting along existing frontages before spending the remaining garden budget.
 var light_budget: int=12 if scale=="city" else 5 if scale=="town" else 2
 var lights:=0
 for index in range(0,ordered.size(),3):
  if lights>=light_budget:break
  var lot: Dictionary=ordered[index]
  var forward:=Vector2(sin(float(lot.yaw)),cos(float(lot.yaw)))
  var lateral:=Vector2(forward.y,-forward.x)
  for attempt in range(6):
   var pos: Vector2=lot.p+forward*(6.8+float(attempt/2)*1.5)+lateral*(7.4 if attempt%2==0 else -7.4)
   if _add(placed,{"asset_id":"stone_garden_lantern","p":pos,"yaw":float(lot.yaw),"lot_id":str(lot.id),"district":"civic","purpose":"street_lighting"},data,ring,cap,reserved):
    lights+=1;break
 # Productive gardens and shaded yards fill safe rear land, rather than traffic lanes.
 for lot in ordered:
  var front:=Vector2(sin(float(lot.yaw)),cos(float(lot.yaw)))
  var side:=Vector2(front.y,-front.x)
  var role: String=str(lot.function)
  var landscaping: Array=["tree_orchard","vegetable_field_4m"] if role in ["residence","farmstead"] else ["bamboo_cluster_01","tea_garden_bush"]
  if role=="martial_school":landscaping=["training_pavilion_6m","bamboo_cluster_01"]
  elif role=="shrine":landscaping=["temple_hall_8m","tree_broad_01"]
  elif role in ["inn","administration"]:landscaping=["open_pavilion_6m","tree_broad_01"]
  elif role=="herbalist":landscaping=["herbalist_garden_box","tree_orchard"]
  for asset_id in landscaping:
   for attempt in range(8):
    var pos: Vector2=lot.p-front*(12.0+float(attempt/3)*4.0)+side*(float(attempt%3)-1.0)*6.0
    var terrain_radius: float=4.2 if str(asset_id).begins_with("tree_") else 2.3 if asset_id=="bamboo_cluster_01" else 0.0
    if _add(placed,{"asset_id":asset_id,"p":pos,"yaw":float(lot.yaw),"lot_id":str(lot.id),"district":district_of(lot,scale,ordered),"purpose":"productive_garden" if role in ["farmstead","herbalist"] else "shaded_courtyard","terrain_radius":terrain_radius},data,ring,cap,reserved):break
 # Market-front sidewalks form small groups, with all shared street paths reserved.
 if scale!="village":
  for road in data.settlement_roads:
   if str(road.get("kind",""))!="market_street":continue
   var direction: Vector2=(road.b-road.a).normalized()
   var normal:=Vector2(-direction.y,direction.x)
   var length: float=(road.b-road.a).length()
   for i in range(1,int(length/12.0)):
    for sign_value in [-1.0,1.0]:
     var pos: Vector2=road.a+direction*float(i)*12.0+normal*sign_value*(float(road.width)*.5+5.0)
     _add(placed,{"asset_id":"covered_market_stall" if i%3!=0 else "tea_table_with_stools","p":pos,"yaw":atan2(-normal.x*sign_value,-normal.y*sign_value),"lot_id":"@public","district":"commerce","purpose":"market_front"},data,ring,cap,reserved)
 var street_profiles: Dictionary={}
 for street in data.settlement_roads:
  var kind: String=str(street.get("kind","secondary"))
  street_profiles[kind]=int(street_profiles.get(kind,0))+1
 var stats: Dictionary={"district_lots":district_map,"street_profiles":street_profiles,"visuals":placed.size(),"max_visuals":cap,"original_lots":data.lots.size(),"roads_unchanged":true,"existing_pois":activities.size(),"has_river":not data.rivers.is_empty()}
 return {"status":"ready","version":VERSION,"visuals":placed,"districts":district_map,"activity_pois":activities,"metrics":stats,"reason":""}

static func validate(plan_data: Dictionary,data: RefCounted,fortification: Dictionary={}) -> Array:
 var issues: Array=[]
 if plan_data.get("status","")!="ready":return ["not_ready:"+str(plan_data.get("reason",""))]
 var scale: String=str(data.spec.get("settlement_scale","village"))
 if plan_data.visuals.size()>int(MAX_VISUALS[scale]):issues.append("visual_budget")
 var ring: Array=fortification.get("plan",fortification).get("polygon",[]) if scale=="city" else []
 var reserved: Array=reservations(data)
 var accepted: Array=[]
 for obj in plan_data.visuals:
  if not FOOTPRINTS.has(str(obj.asset_id)):issues.append("unknown_asset:"+str(obj.asset_id))
  if not _safe(obj.p,float(obj.radius),data,accepted,ring,reserved):issues.append("unsafe:"+str(obj.lot_id)+"/"+str(obj.asset_id))
  if float(obj.radius)+.001<radius_for(str(obj.asset_id)):issues.append("undersized_footprint:"+str(obj.asset_id))
  accepted.append(obj)
 for lot in data.lots:
  if not plan_data.activity_pois.has(str(lot.id)):issues.append("missing_poi:"+str(lot.id))
 return issues
