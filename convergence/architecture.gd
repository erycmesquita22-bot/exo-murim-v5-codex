extends RefCounted
# Adapter version 2: preserve Genesis IDs, streets and terrain. Reserve extra
# geometry only after testing the entire rotated parcel against those contracts.
const Plan=preload("res://forja/forja_planner.gd")
const Kit=preload("res://godot/modular_kit.gd")
const FUNCTIONS={"residence":"dwelling","dwelling":"dwelling","farmstead":"dwelling","inn":"inn","smithy":"workshop","herbalist":"herbalist","market":"shop","shrine":"dwelling","warehouse":"dwelling","administration":"dwelling","martial_school":"dwelling"}
const TITLES={"residence":"Residência","farmstead":"Horta e moradia","inn":"Hospedaria","smithy":"Ferraria","herbalist":"Casa de medicina","market":"Mercado","shrine":"Santuário ancestral","warehouse":"Depósito de provisões","administration":"Administração","martial_school":"Escola marcial"}
static func transform_point(lot: Dictionary,p: Vector2) -> Vector2:
	return lot.p+Vector2(cos(lot.yaw)*p.x+sin(lot.yaw)*p.y,-sin(lot.yaw)*p.x+cos(lot.yaw)*p.y)
static func can_expand(data: RefCounted,lot: Dictionary) -> bool:
	# Expanded parcel is 10.9 x 19.2, offset 4.2m behind the original facade.
	# The old approach remains in place. Sampling includes road/river safety margins.
	for ix in range(12):
		for iz in range(21):
			var p:=transform_point(lot,Vector2(-5.45+float(ix)*10.9/11.0,-13.8+float(iz)*19.2/20.0))
			if absf(p.x)>data.half-12 or absf(p.y)>data.half-12:return false
			if absf(data.height_at(p)-float(lot.height))>.12:return false
			if data.road_distance(p)<3.9 or data.river_distance(p)<10:return false
			for other in data.lots:
				if other.id==lot.id:continue
				if p.distance_to(other.p)<float(other.halfsize)+1.8:return false
				if p.distance_to(Geometry2D.get_closest_point_to_segment(p,other.door,other.street_point))<1.6:return false
			for fixture in data.settlement_plan.fixtures:
				if p.distance_to(fixture.p)<float(fixture.halfsize)+2:return false
	return true
static func plan(data: RefCounted,lot: Dictionary) -> Dictionary:
	if not FUNCTIONS.has(lot.function):return {"ok":false,"code":"unmapped_function:"+str(lot.function)}
	var parcel: Dictionary={"id":lot.id,"center_x":0.0,"center_z":0.0,"ground_y":0.0,"width_m":10.8,"depth_m":10.8,"yaw_quadrants":0,"district":"city" if data.spec.settlement_scale=="city" else "village","role":FUNCTIONS[lot.function],"max_stories":2,"detail_profile":"medium","approach_clear":true,"terrain_samples_y":[0.0,0.0,0.0,0.0]}
	var expanded: bool=lot.function in ["martial_school","shrine"] and can_expand(data,lot)
	if expanded:parcel.width_m=10.9;parcel.depth_m=19.2;parcel.center_z=-4.2
	var outcome: Dictionary=Plan.plan_lot(preload("res://genesis/world_planner.gd").seed_mod(str(data.spec.region_seed),2147483647),parcel)
	if not outcome.ok:return outcome
	if expanded:
		var bp: Dictionary=outcome.plan
		bp.width_m=6;bp.archetype="courtyard";bp.stories=1
		bp.footprint_local_xz=[-4.35,-2.65,4.35,6.95];bp.access_local_xz=[-.95,6.95,.95,9.2]
		bp.entrance_local=[0.0,0.0,3.02];bp.gate_local=[0.0,0.0,6.2];bp.approach_local=[0.0,0.0,8.9]
		bp.interior_anchor_local=[0.0,.42,1.0];bp.npc_anchor_local=[-.5,0.0,3.7]
		bp.signature+="-reserved_courtyard_v2"
	outcome.plan["semantic_function"]=lot.function
	outcome.plan["composition"]="reserved_courtyard" if expanded else "compact_"+str(lot.function)
	outcome.plan["architecture_version"]=2
	return outcome
static func specialize(house: Node3D,bp: Dictionary) -> void:
	var root:=Node3D.new();root.name="FunctionalComposition";house.add_child(root)
	var pal: String=bp.palette
	var left: float=-float(bp.width_m)*.5+1.0
	var f: String=bp.semantic_function
	if f in ["martial_school","administration","shrine","warehouse","farmstead"] and bp.composition!="reserved_courtyard":house.get_node("ForjaDetails").free()
	var parts: Array=[]
	match f:
		"martial_school":parts=[["silk_vertical_banner",Vector3(left,2.3,2.6)],["paired_pillar_plinths",Vector3(left,0,3.5)],["stone_courtyard_paving_2m",Vector3(left,0,4.0)]]
		"administration":parts=[["silk_vertical_banner",Vector3(left,2.3,2.6)],["shop_hanging_sign",Vector3(left,2.7,2.6)],["merchant_counter_2m",Vector3(left,0,3.5)]]
		"shrine":parts=[["bronze_incense_burner",Vector3(left,0,3.8)],["stone_garden_lantern",Vector3(left,0,2.8)]]
		"warehouse":parts=[["grain_sack_stack",Vector3(left,0,3.4)],["timber_handcart",Vector3(left,0,4.3)]]
		"farmstead":parts=[["garden_bed_2x2",Vector3(left,0,3.6)],["cabbage_stage_3",Vector3(left-.4,.1,3.5)],["carrot_stage_3",Vector3(left+.4,.1,3.8)],["village_drying_lines",Vector3(left,0,2.6)]]
	for item in parts:Kit.place(root,item[0],item[1],0,pal,false)
	if f=="martial_school":
		# Wooden training post, with cross-arms; kept left of the accessible door corridor.
		for spec in [[Vector3(left,1,3.8),Vector3(.22,2,.22)],[Vector3(left,1.25,3.8),Vector3(1,.15,.15)]]:
			var mesh:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=spec[1];mesh.mesh=box;mesh.position=spec[0];var mat:=StandardMaterial3D.new();mat.albedo_color=Color("72523c");mesh.material_override=mat;root.add_child(mesh)
	if f=="martial_school" and bp.composition=="reserved_courtyard":Kit.place(root,"silk_vertical_banner",Vector3(-1.6,2.3,6.25),0,pal,false)
	var sign:=Label3D.new();sign.name="FunctionSign";sign.billboard=BaseMaterial3D.BILLBOARD_ENABLED;sign.text=TITLES.get(f,f);sign.position=Vector3(left,2.75,2.7);sign.font_size=30;sign.pixel_size=.012;sign.modulate=Color("ead9a5");root.add_child(sign)
	if f=="martial_school" and bp.composition=="reserved_courtyard":sign.position=Vector3(0,4.1,6.35);sign.text="ESCOLA MARCIAL";sign.font_size=36
	house.set_meta("semantic_function",f);house.set_meta("composition",bp.composition)
