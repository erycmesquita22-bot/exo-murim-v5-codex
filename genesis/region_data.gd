extends RefCounted
const REGIONAL_VERSION=6
const Planner=preload("res://genesis/world_planner.gd")
const Monuments=preload("res://genesis/monument_reservations_r7.gd")
var worldgen_v4:bool=false
var worldgen_profile:Dictionary={}
var landmarks:Array=[]
var ridge_noise:=FastNoiseLite.new()
var atlas: Dictionary
var spec: Dictionary
var gates: Array=[]
var access_roads: Array=[]
var settlement_roads: Array=[]
var settlement_plan: Dictionary={}
var monumental_plans: Array=[]
var monumental_receipts: Array=[]
var monumental_rejections: Array=[]
var monumental_mode: String="none"
var lots: Array=[]
var plants: Array=[]
var rivers: Array=[]
var river_hub := Vector2(72,72)
var noise := FastNoiseLite.new()
var center_h: float
var half: float
var extent: float
var base_color: Color
const COLORS={"grassland":Color("4b6544"),"temperate_forest":Color("3a5140"),"bamboo_forest":Color("435c3f"),"dry_valley":Color("8a7950"),"wetland":Color("395552"),"rocky_highlands":Color("5b6467"),"alpine":Color("79888d"),"mixed_woodland":Color("515d42")}
func _init(w: Dictionary={},rid: int=0,pinned_monuments: Dictionary={}) -> void:
	if w.is_empty():return
	atlas=w;spec=w.regions[rid];extent=w.region_extent_m;half=extent*.5
	noise.seed=Planner.seed_mod(spec.region_seed,2147483647);noise.frequency=.012
	worldgen_v4=w.has("worldgen_v4") and spec.has("worldgen_v4")
	if not worldgen_v4:
		push_error("WorldGenesis V4 atlas required; legacy generation removed")
		return
	if worldgen_v4:
		worldgen_profile=spec.worldgen_v4.profile.duplicate(true)
		ridge_noise.seed=Planner.derive(spec.region_seed,"WG4/ridge")%2147483647;ridge_noise.frequency=.008;ridge_noise.fractal_octaves=3
		if spec.kind!="settlement":
			var angle:float=float(worldgen_profile.yaw)
			river_hub=Vector2(cos(angle),sin(angle))*(48.0+float(Planner.derive(spec.region_seed,"WG4/river")%30))
	center_h=8+25*spec.elevation
	base_color=COLORS[spec.biome]
	for e in spec.entrances:
		var port: Dictionary={}
		for p in w.portals:
			if p.id==e.gate_id:port=p;break
		gates.append({"id":e.gate_id,"neighbor":int(e.neighbor),"p":Vector2(e.xz[0],e.xz[1]),"height":float(port.height_m),"width":float(port.width_m),"palette":port.boundary_palette})
	# Macro edges become shared water contracts, separate from road gates.
	for edge in w.rivers_macro:
		if int(edge.from)!=rid and int(edge.to)!=rid:continue
		var neighbor: int=int(edge.to) if int(edge.from)==rid else int(edge.from)
		var other: Dictionary=w.regions[neighbor]
		var delta := Vector2(other.center[0]-spec.center[0],other.center[1]-spec.center[1])
		var axis := 0 if absf(delta.x)>=absf(delta.y) else 1
		var endpoint := Vector2.ZERO;endpoint[axis]=signf(delta[axis])*half
		endpoint[1-axis]=clampf(delta[1-axis]/absf(delta[axis])*100,-148,148)
		var shared_height: float=4+25*(spec.elevation+other.elevation)*.5
		rivers.append({"neighbor":neighbor,"p":endpoint,"height":shared_height,"hub_height":4+25*spec.elevation,"flow":edge.flow,"from":int(edge.from),"to":int(edge.to)})
	# R7 zoning precedes ordinary small-parcel allocation. Existing campaigns are pinned:
	# legacy visited regions never gain a new monument silently.
	if spec.kind!="settlement" and (not pinned_monuments.is_empty() or bool(ProjectSettings.get_setting("exo_murim/r7/monuments_enabled",true))):
		var zoning: Dictionary={}
		if not pinned_monuments.is_empty():zoning=pinned_monuments.duplicate(true)
		else:zoning=Monuments.plan_new(self)
		monumental_mode=str(zoning.get("mode","legacy"))
		if monumental_mode=="r7":
			monumental_plans=zoning.get("plans",[]).duplicate(true)
			monumental_receipts=zoning.get("receipts",[]).duplicate(true)
			monumental_rejections=zoning.get("rejections",[]).duplicate(true)
	# Settlement Genesis: functional parcels first, no asset instantiation here.
	var rng := RandomNumberGenerator.new();rng.seed=Planner.derive(spec.region_seed,"lots")
	if spec.kind=="settlement":
		settlement_plan=preload("res://exo_city_forge/adapters/physical_worldgen.gd").plan(self)
		if settlement_plan.get("status")=="ready":
			lots=settlement_plan.lots;settlement_roads=settlement_plan.streets
			var zoning:Dictionary=Monuments.plan_new(self)
			monumental_mode="r7";monumental_plans=zoning.plans;monumental_receipts=zoning.receipts;monumental_rejections=zoning.rejections
		else:push_warning("City Forge physical plan blocked: "+str(settlement_plan.get("errors",[])))
	else:
		# Legacy special-site pad placement remains independent of settlement generation.
		var count := 1
		var phase := rng.randf()*TAU
		for k in range(160):
			if lots.size()>=count:break
			var a := phase+k*2.39996323
			var p := Vector2(cos(a),sin(a))*(26+floorf(k/12.0)*9)
			var pad_size := 14.0 if spec.kind=="ruins" else (10.0 if spec.kind=="dungeon_approach" else 5.5)
			if road_distance(p)<pad_size+12 or river_distance(p)<pad_size+12:continue
			var protected_site:=false
			for monument in monumental_plans:
				var rect:Dictionary=monument["bounds"]
				if p.x+pad_size>float(rect.min_x) and p.x-pad_size<float(rect.max_x) and p.y+pad_size>float(rect.min_z) and p.y-pad_size<float(rect.max_z):protected_site=true;break
			if protected_site:continue
			var clear := true
			for lot in lots:
				if p.distance_to(lot.p)<pad_size+lot.halfsize+14:clear=false
				if lot.p.distance_to(Geometry2D.get_closest_point_to_segment(lot.p,Vector2.ZERO,p))<lot.halfsize+6:clear=false
			if not clear:continue
			lots.append({"p":p,"height":center_h,"yaw":atan2(-p.x,-p.y),"halfsize":pad_size})
			access_roads.append({"p":p,"height":center_h,"width":4.0})
	if worldgen_v4:landmarks=preload("res://genesis/v4/landmarks.gd").propose(self)
	var density := 190 if "forest" in spec.biome or spec.biome=="mixed_woodland" else 90
	if worldgen_v4:density=int(worldgen_profile.tree_budget)
	for k in range(density*4):
		if plants.size()>=density:break
		var p := Vector2(rng.randf_range(-half+8,half-8),rng.randf_range(-half+8,half-8))
		if road_distance(p)<12 or river_distance(p)<10 or p.length()<20 or pad_distance(p)<10:continue
		if worldgen_v4:
			if ridge_noise.get_noise_2d(p.x+721,p.y-235)<float(worldgen_profile.cluster_cut):continue
			var near_landmark:bool=false
			for point in landmarks:
				if p.distance_to(point.p)<5.0:near_landmark=true;break
			if near_landmark:continue
		var h := height_at(p)
		var slope := maxf(absf(height_at(p+Vector2(1,0))-h),absf(height_at(p+Vector2(0,1))-h))
		if slope>.35:continue
		plants.append({"p":p,"height":h,"yaw":rng.randf()*TAU,"scale":rng.randf_range(.8,1.3)})
func road_distance(p: Vector2) -> float:
	var d := INF
	for g in gates+access_roads:d=minf(d,p.distance_to(Geometry2D.get_closest_point_to_segment(p,Vector2.ZERO,g.p)))
	for street in settlement_roads:d=minf(d,p.distance_to(Geometry2D.get_closest_point_to_segment(p,street.a,street.b)))
	return d
func gate_road_distance(p: Vector2) -> float:
	var d := INF
	for g in gates:d=minf(d,p.distance_to(Geometry2D.get_closest_point_to_segment(p,Vector2.ZERO,g.p)))
	return d
func river_distance(p: Vector2) -> float:
	var d := INF
	for r in rivers:d=minf(d,p.distance_to(Geometry2D.get_closest_point_to_segment(p,river_hub,r.p)))
	return d
func river_level(r: Dictionary,p: Vector2) -> float:
	var v: Vector2=r.p-river_hub
	return lerpf(r.hub_height,r.height,clampf((p-river_hub).dot(v)/v.length_squared(),0,1))
func pad_distance(p: Vector2) -> float:
	var d := INF
	for lot in lots:d=minf(d,p.distance_to(lot.p)-lot.halfsize)
	for monument in monumental_plans:
		var rect:Dictionary=monument["bounds"]
		var q:=Vector2(clampf(p.x,float(rect.min_x),float(rect.max_x)),clampf(p.y,float(rect.min_z),float(rect.max_z)))
		d=minf(d,p.distance_to(q))
	return d
func height_unpadded(p: Vector2) -> float:
	# Exact flat output of the existing final blends: avoid noise on urban footsteps.
	if worldgen_v4 and ((spec.kind=="settlement" and p.length_squared()<=32400.0) or p.length_squared()<=256.0):return center_h
	var relief:float=float(worldgen_profile.relief)
	var h:float=center_h
	if worldgen_v4:
		relief=float(worldgen_profile.relief)
		var yaw:float=float(worldgen_profile.yaw)
		var q:=Vector2(p.x*cos(yaw)-p.y*sin(yaw),p.x*sin(yaw)+p.y*cos(yaw))
		var macro:float=ridge_noise.get_noise_2d(p.x,p.y)
		h=center_h+noise.get_noise_2d(p.x,p.y)*relief*.7+macro*relief*.24
		if spec.biome in ["rocky_highlands","alpine"]:
			var width:float=float(worldgen_profile.ridge_width)
			var ridge:float=exp(-pow((q.x-float(worldgen_profile.ridge_offset))/width,2))
			var secondary:float=exp(-pow((q.x+q.y*.38+85.0)/(width*.8),2))
			h+=relief*(ridge*.65+secondary*.28)*(.65+.35*(1.0-absf(macro)))
	for river in rivers:
		var d := p.distance_to(Geometry2D.get_closest_point_to_segment(p,river_hub,river.p))
		if d<9:
			var level := river_level(river,p)
			var inner:float=river_half_width(river)+.1 if worldgen_v4 and spec.kind!="settlement" else 2.8
			h=lerpf(level-1.3,maxf(h,level+1),smoothstep(inner,9,d))
	# Engineered settlement terrace. Keeps the complete civic street network and
	# all assigned parcels at one connected elevation; outer relief is preserved.
	if spec.kind=="settlement":h=lerpf(center_h,h,smoothstep(180,224,p.length()))
	# One weighted road surface prevents incompatible heights at shared trunks.
	var sum := 0.0;var weights := 0.0;var nearest := INF
	var shoulder:float=24.0 if worldgen_v4 and spec.kind!="settlement" and spec.biome in ["rocky_highlands","alpine"] else 14.0
	for g in gates+access_roads:
		var t := clampf(p.dot(g.p)/g.p.length_squared(),0,1)
		var d := p.distance_to(g.p*t);nearest=minf(nearest,d)
		if d<shoulder:
			var weight := pow(1-d/shoulder,2)
			# Flat touchdown for 12 m. Cubic ramps have zero derivative at the hub and gate.
			var ramp := smoothstep(180 if spec.kind=="settlement" else 32,maxf(181 if spec.kind=="settlement" else 33,g.p.length()-12),t*g.p.length())
			sum+=lerpf(center_h,g.height,ramp)*weight;weights+=weight
	if weights>0:h=lerpf(h,sum/weights,1-smoothstep(5,shoulder,nearest))
	h=lerpf(center_h,h,smoothstep(16,24,p.length()))
	return h
func terrain_height_at(p: Vector2) -> float:
	var h := _base_height_at(p)
	if spec.kind=="settlement" and pad_distance(p)>3.0:
		for river in rivers:
			var distance := p.distance_to(Geometry2D.get_closest_point_to_segment(p,river_hub,river.p))
			if distance<11.0:h=lerpf(river_level(river,p)-1.3,h,smoothstep(2.8,11.0,distance))
	return h
func height_at(p: Vector2) -> float:
	if spec.kind!="settlement" or rivers.is_empty():return _base_height_at(p)
	# Routes have an independent bridge floor; elsewhere the visible channel
	# and the analytic walking surface agree with the physical terrain.
	for road in settlement_roads:
		if p.distance_to(Geometry2D.get_closest_point_to_segment(p,road.a,road.b))<=float(road.width)*.5+.5:return _base_height_at(p)
	for gate in gates:
		if p.distance_to(Geometry2D.get_closest_point_to_segment(p,Vector2.ZERO,gate.p))<=float(gate.width)*.5+.5:return _base_height_at(p)
	return terrain_height_at(p)
func _base_height_at(p: Vector2) -> float:
	var h := height_unpadded(p)
	for lot in lots:
		var q: Vector2 = (p-lot.p).abs()-Vector2.ONE*lot.halfsize
		var d := maxf(q.x,q.y)
		if d<3:h=lerpf(lot.height,h,smoothstep(0,3,d))
	return h
func boundary_weights(p: Vector2) -> Color:
	var nearest := INF;var selected := -1
	for index in range(gates.size()):
		var d: float=p.distance_to(gates[index].p)
		if d<nearest:nearest=d;selected=index
	var weights := Color(0,0,0,0)
	if selected>=0:weights[selected]=.5*(1-smoothstep(12,float(worldgen_profile.blend_m) if worldgen_v4 else 48.0,nearest))
	return weights
func color_at(p: Vector2) -> Color:
	var c := base_color
	for g in gates:
		var other: String=g.palette.b if g.palette.a==spec.biome else g.palette.a
		var distance := p.distance_to(g.p)
		c=c.lerp(COLORS[other],.5*(1-smoothstep(12,float(worldgen_profile.blend_m) if worldgen_v4 else 48.0,distance)))
	return c
func validate() -> Array:
	var errors: Array=[]
	if gates.is_empty():errors.append("no_gates")
	for g in gates:
		if absf(height_at(g.p)-g.height)>.001:errors.append("gate_height")
		var perpendicular: Vector2=Vector2(-g.p.y,g.p.x).normalized()
		# Verify the usable road corridor, rather than sampling outside narrow decks.
		var corridor_half:float=minf(3.5,maxf(0.0,float(g.width)*.5-.4))
		for side in [-1,0,1]:
			var prev := height_at(perpendicular*side*corridor_half)
			for k in range(1,257):
				var p: Vector2=g.p*k/256.0+perpendicular*side*corridor_half
				var h := height_at(p)
				if not is_finite(h):errors.append("nonfinite")
				if absf(h-prev)/(g.p.length()/256.0)>.65:errors.append("road_grade")
				prev=h
	for river in rivers:
		var upstream: float=atlas.regions[river.from].elevation
		var downstream: float=atlas.regions[river.to].elevation
		if upstream<=downstream:errors.append("uphill_water")
		var center_level: float=river.hub_height
		if river.from==int(spec.id) and center_level<river.height:errors.append("uphill_outlet")
		if river.to==int(spec.id) and center_level>river.height:errors.append("uphill_inlet")
	for lot in lots:
		for dx in [-float(lot.halfsize),0.0,float(lot.halfsize)]:
			for dz in [-float(lot.halfsize),0.0,float(lot.halfsize)]:
				if absf(height_at(lot.p+Vector2(dx,dz))-lot.height)>.001:errors.append("foundation")
		if spec.kind!="settlement" and gate_road_distance(lot.p)<lot.halfsize+12.0:errors.append("lot_on_gate_road")
	if spec.kind=="settlement":
		errors.append_array(preload("res://exo_city_forge/adapters/physical_worldgen.gd").validate(self,settlement_plan))
	if lots.is_empty():errors.append("no_lots")
	for plant in plants:
		if not is_finite(plant.height) or road_distance(plant.p)<12:errors.append("plant")
	return errors
func digest() -> String:
	var samples: Array=[]
	for z in range(-256,257,8):
		for x in range(-256,257,8):samples.append(snappedf(height_at(Vector2(x,z)),.00001))
	return JSON.stringify([spec.region_seed,samples,lots,plants,rivers,access_roads,settlement_roads,{"owner":"city_forge_r4","blueprint":settlement_plan.get("city_forge_r4",{}).get("blueprint_id","")} if spec.kind=="settlement" else {}]).sha256_text()

func river_half_width(river:Dictionary)->float:
	if not worldgen_v4 or spec.kind=="settlement":return 2.7
	return clampf(2.15+log(1.0+maxf(0.0,float(river.get("flow",1.0))))*.16,2.2,3.25)
func handoff_point(gate:Dictionary)->Vector2:
	if not worldgen_v4 or spec.kind=="settlement":return gate.p
	return gate.p*float(atlas.worldgen_v4.handoff_ratio)
