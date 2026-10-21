extends "res://genesis/region_scene.gd"
# Genesis owns terrain and lot ids; Forja owns modular geometry. No source plan is mutated.
var navigator: RefCounted
var blueprints: Array=[]
var build_errors: Array=[]
var assigned_slots: Array=[]
var monument_roots: Array=[]
var monument_portals: Array=[]
var monument_stations: Array=[]
var monument_build_summary: Array=[]
var urban_enabled := true # apresentação somente; desligar não altera saves nem as regiões
func integrate_perimeter() -> Dictionary:
	var report: Dictionary=preload("res://exo_core/adapters_architecture.gd").apply(self)
	set_meta("exo_architecture",report)
	return report

var station_points: Dictionary={}
var route_points: Dictionary={}
func build_lots() -> void:
	if data.spec.kind!="settlement":
		super.build_lots();_build_monuments();return
	if data.settlement_plan.get("status")!="ready":
		build_errors.append("genesis_plan_invalid");return
	var builder:RefCounted=preload("res://exo_city_forge/runtime/physical_builder.gd").new()
	for lot in data.lots:
		var house:Node3D=builder.build(self,lot.city_model)
		house.position.y=data.center_h-.28
		props.append(house)
		var occupancy:Dictionary=lot.city_model.duplicate(true);occupancy.stories=1;occupancy.width_m=float(lot.city_model.size[0]);blueprints.append(occupancy)
		var exterior:=Vector3(lot.door.x,data.height_at(lot.door)+.05,lot.door.y)
		station_points[lot.id]=exterior
		route_points[lot.id]=[exterior,exterior,Vector3(lot.street_point.x,data.height_at(lot.street_point)+.05,lot.street_point.y)]
		var job:String={"farmstead":"farmer","market":"merchant","inn":"merchant","smithy":"resident","herbalist":"healer","administration":"guild_agent","martial_school":"disciple","shrine":"master","warehouse":"courier"}.get(lot.function,"resident")
		assigned_slots.append({"id":lot.id,"role":job,"work_slot":lot.id,"home_slot":lot.id})
		preload("res://ground_shadow.gd").place(self,Vector3(lot.p.x,data.center_h+.025,lot.p.y),Vector2(lot.halfsize*2,lot.halfsize*2),.25)
	set_meta("city_forge_physical",{"owner":"city_forge_r4","buildings":props.size(),"blueprint":data.settlement_plan.city_forge_r4.blueprint_id})
	preload("res://exo_city_forge/runtime/pavement.gd").build(self)
	if has_meta("world_v4"):preload("res://convergence4/interiors.gd").build(self,get_meta("world_v4"))
	_build_monuments()

func prepare_population() -> void:
	if data.spec.kind!="settlement":return
	navigator=preload("res://convergence/streets.gd").new();navigator.build(data)
	for lot in data.lots:
		var road: Dictionary=data.settlement_roads[0]
		var a:=Vector3(road.a.x,0,road.a.y);var b:=Vector3(lot.street_point.x,0,lot.street_point.y)
		if navigator.route(a,b).is_empty():build_errors.append("disconnected_npc_street:"+str(lot.id))
	var square:=Vector3(0,data.height_at(Vector2.ZERO)+.05,0)
	route_points["@square"]=[square,square,square]
	preload("res://convergence/occupancy.gd").assign(self)
	preload("res://convergence4/city_teachers.gd").bind(self)
	_bind_verified_martial_occupancy()

# R9: Materialization creates an occupational slot, not a synthetic master actor.
# The official LivingWorld roster creates/persists the person using the accepted site.
func _bind_verified_martial_occupancy() -> void:
	if not bool(ProjectSettings.get_setting("exo_murim/r9/school_occupancy_enabled",true)):return
	if data.spec.kind!="settlement" or data.lots.is_empty() or navigator==null:return
	var Catalog=preload("res://exo_martial/styles/martial_catalog.gd")
	var Occupation=preload("res://convergence/martial_occupancy_r9.gd")
	var linked:Dictionary={}
	for plan in data.monumental_plans:
		if str(plan.get("kind","")) not in ["martial_medium","martial_grand"]:continue
		var site_id:String=str(plan.get("id",""))
		# Never introduce new teachers silently into a previously visited region.
		if bool(get_meta("r9_existing_visit",false)) and site_id not in get_meta("r9_existing_school_sites",[]):continue
		var exists:bool=false
		for built in monument_build_summary:
			if str(built.get("site_id",""))==site_id:exists=true;break
		if not exists:continue
		var master:Dictionary={};var gate:Dictionary={}
		for station in monument_stations:
			if str(station.get("site_id",""))!=site_id:continue
			if str(station.get("kind",""))=="master_station":master=station
			if str(station.get("kind",""))=="entrance_anchor":gate=station
		if master.is_empty() or gate.is_empty():continue
		var school_id:String=Occupation.school_for_site(str(data.atlas.seed),site_id,str(plan.get("school_id","")))
		if Catalog.school(school_id).is_empty():continue
		var site_route:Dictionary=Occupation.route_for_site(self,master,gate)
		if not bool(site_route.get("ok",false)):
			push_warning("R9 master site unoccupied, unsafe route: "+site_id+" "+str(site_route.get("reason","unknown")))
			continue
		var work_id:String="martial/"+site_id.sha256_text().substr(0,18)
		var home_id:String=str(site_route.get("home_slot",""))
		if not route_points.has(home_id):continue
		var points:Array=site_route.get("path",[])
		if points.size()<2:continue
		route_points[work_id]=points
		assigned_slots.append({"id":work_id,"role":"master","home_slot":home_id,"work_slot":work_id,
			"martial_site_id":site_id,"martial_school_id":school_id})
		linked[site_id]={"work_slot":work_id,"home_slot":home_id,"school_id":school_id,
			"station_id":str(master.get("station_id","")),"route_points":points.size()}
	set_meta("exo_r9_martial_occupancy",linked)
func resident_routes(person: Dictionary,people: Array=[]) -> Dictionary:
	var ids: Array=[str(person.home_slot),str(person.work_slot),"@square","@activity"]
	var stations: Dictionary={}
	for id in ids:
		if id=="@activity":continue
		var base: Vector3=route_points[id][0]
		if id=="@square":
			# Disperse the community across the existing street axis, not one tight group.
			var k: int=maxi(0,people.find(person))
			var street: Dictionary=data.settlement_roads[k%2]
			var direction: Vector2=(street.b-street.a).normalized()*(1.0 if k%4<2 else -1.0)
			var side:=Vector2(-direction.y,direction.x)
			var distance: float=2.5+float(k/4)*1.35
			var candidate: Vector2=Vector2(base.x,base.z)+direction*distance+side*(0.95 if k%2==0 else -0.95)
			stations[id]=Vector3(candidate.x,data.height_at(candidate)+.08,candidate.y)
		elif id.begins_with("martial/") and route_points.has(id):
			stations[id]=route_points[id][0]
		else:
			var members: Array=[]
			for p in people:
				if p.home_slot==id or p.work_slot==id:members.append(str(p.id))
			members.sort();var k: int=maxi(0,members.find(str(person.id)))
			var lot: Dictionary={}
			for parcel in data.lots:
				if parcel.id==id:lot=parcel;break
			# One facade-parallel row, with a clear doorway between both wings.
			# Use the actual facade yaw, not a diagonal vector to the nearest street.
			var forward:=Vector3(sin(lot.yaw),0,cos(lot.yaw))
			var side:=Vector3(forward.z,0,-forward.x)
			var lateral: float=(1.25+float(k/2)*1.5)*(1.0 if k%2==0 else -1.0)
			var candidate: Vector3=base+forward*.65+side*lateral
			var flat:=Vector2(candidate.x,candidate.z)
			candidate.y=data.height_at(flat)+.08
			stations[id]=candidate
	# Reuse each worker's distinct facade station for the external service POI.
	stations["@activity"]=stations[str(person.work_slot)]
	var result: Dictionary={}
	for a in ids:
		for b in ids:
			var from_actual: String=str(person.work_slot) if a=="@activity" else a
			var to_actual: String=str(person.work_slot) if b=="@activity" else b
			var path: Array=preload("res://convergence/occupancy.gd").commute(self,from_actual,to_actual)
			if path.size()<=1 and a!=b:continue # Never synthesize a teleport across unreachable endpoints.
			if path.is_empty():continue
			else:path.push_front(stations[a]);path.append(stations[b])
			result[a+">"+b]=path
	return result

# WorldGenesis has already issued an actual reservation receipt before this code runs.
# No proposed plan or QA_LAB_ONLY may materialize in the real game.
func _build_monuments() -> void:
	if not bool(ProjectSettings.get_setting("exo_murim/r7/monuments_enabled",true)):return
	var Builder=preload("res://exo_monumental/runtime/builder.gd")
	var Bridge=preload("res://exo_monumental/integration/interior_bridge.gd")
	var Spatial=preload("res://exo_monumental/integration/exo_adapter.gd")
	for index in range(data.monumental_plans.size()):
		var plan:Dictionary=data.monumental_plans[index]
		if index>=data.monumental_receipts.size():build_errors.append("r7_reservation_missing:"+str(plan.get("id","")));continue
		var receipt:Dictionary=data.monumental_receipts[index]
		if str(receipt.get("authority",""))!="WorldGenesis" or not Builder.validate_receipt(plan,receipt):
			build_errors.append("r7_reservation_unverified:"+str(plan.get("id","")));continue
		var result:Dictionary=Builder.build(self,plan,receipt)
		if not bool(result.get("ok",false)):
			build_errors.append("r7_monument_build_failed:"+str(result.get("code","unknown")));continue
		var root:Node3D=result.node
		monument_roots.append(root)
		# Only an actual built Jade school receives the original voxel circle.
		if not bool(get_meta("r9_existing_visit",false)) or str(plan.get("id","")) in get_meta("r9_existing_school_sites",[]):
			preload("res://convergence/martial_sites_r9.gd").install(root,plan,str(data.atlas.seed))
		monument_build_summary.append({"site_id":str(plan.id),"kind":str(plan.kind),"instances":int(result.instances),"stations":int(result.semantic_stations),"receipt_id":str(receipt.reservation_id)})
		var transitions:Dictionary=Bridge.from_plan(plan)
		if not bool(transitions.get("ok",false)):
			build_errors.append("r7_interior_portals:"+str(transitions.get("code","invalid")));continue
		for portal in transitions.portals:
			portal["region_id"]=int(data.spec.id)
			portal["site_id"]=str(plan.id)
			monument_portals.append(portal)
		for anchor in root.find_children("*","Marker3D",true,false):
			if not anchor.is_in_group("exo_monument_gameplay_station"):continue
			monument_stations.append({"site_id":str(plan.id),"station_id":str(anchor.get_meta("station_id","")),"kind":str(anchor.get_meta("station_kind","")),
					"capacity":int(anchor.get_meta("capacity",1)),"world_position":anchor.global_position})
