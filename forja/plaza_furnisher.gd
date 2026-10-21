extends RefCounted
## EXO Forja 02 — pracas e mobiliario. Nao gera ruas, rotas ou terreno.
## O Genesis fornece parcela plana, reservada e sem sobreposicoes.
const Kit = preload("res://godot/modular_kit.gd")
const Planner = preload("res://forja/forja_planner.gd")
const Details = preload("res://forja/detail_pass.gd")
const PLAZA_ROLES = ["hamlet_square", "market_square"]
const EXTRA_PROPS = ["stone_garden_lantern", "public_timber_bench", "timber_handcart", "village_drying_lines", "bamboo_planter_box", "woven_market_baskets", "herb_drying_rack", "village_grain_millstone"]
const SAFE_CORRIDOR_HALF_WIDTH = 2.0

static func _valid_number(v: Variant) -> bool:
	return (typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT) and is_finite(float(v))

static func plan_plaza(seed_value: int, parcel: Dictionary) -> Dictionary:
	var id: String = str(parcel.get("id", ""))
	if id.is_empty(): return {"ok":false, "code":"missing_plaza_id"}
	for k in ["center_x","center_z","ground_y","width_m","depth_m"]:
		if not parcel.has(k) or not _valid_number(parcel[k]): return {"ok":false,"code":"invalid_"+k}
	var width: float = float(parcel["width_m"])
	var depth: float = float(parcel["depth_m"])
	if width < 18.0 or depth < 14.0 or width > 256.0 or depth > 256.0:
		return {"ok":false,"code":"plaza_outside_supported_size"}
	var role: String = str(parcel.get("role","market_square"))
	if role not in PLAZA_ROLES: return {"ok":false,"code":"unsupported_plaza_role"}
	var yaw: Variant = parcel.get("yaw_quadrants",0)
	if typeof(yaw) != TYPE_INT or int(yaw) not in [0,1,2,3]: return {"ok":false,"code":"invalid_yaw"}
	if not bool(parcel.get("approach_clear",false)):return {"ok":false,"code":"approach_unverified"}
	var samples: Variant = parcel.get("terrain_samples_y",[])
	if not (samples is Array) or samples.size() != 4: return {"ok":false,"code":"plaza_needs_four_terrain_samples"}
	for value in samples:
		if not _valid_number(value) or absf(float(value)-float(parcel["ground_y"]))>0.18:
			return {"ok":false,"code":"plaza_terrain_not_level"}
	var rng := RandomNumberGenerator.new()
	rng.seed = Planner._hash_seed(seed_value,"plaza:"+id)
	var px: float = width*0.5-3.4
	var z_dist: float = minf(depth*0.5-3.0,4.4)
	var zslots: Array = [-z_dist,0.0,z_dist]
	var entries: Array = []
	for side in [-1,1]:
		for slot in range(3):
			var asset: String = str(EXTRA_PROPS[rng.randi_range(0,EXTRA_PROPS.size()-1)])
			if side == -1 and slot == 0: asset = "village_water_well"
			elif side == 1 and slot == 0: asset = "covered_market_stall" if role == "market_square" else "public_timber_bench"
			entries.append({"asset":asset,"local_pos":[float(side)*px,0.0,float(zslots[slot])],"yaw_quadrants":int(rng.randi_range(0,3))})
	return {"ok":true,"plan":{
		"schema_version":2,"kind":"murim_plaza","id":id,"world_seed":seed_value,
		"role":role,"yaw_quadrants":int(yaw),
		"origin_world":[float(parcel["center_x"]),float(parcel["ground_y"]),float(parcel["center_z"])],
		"dimensions_m":[width,depth],"corridor_half_width_m":SAFE_CORRIDOR_HALF_WIDTH,
		"furnishings":entries,"signature":str(Planner._hash_seed(seed_value,"plaza:"+id))
	}}

static func _position(coords: Array) -> Vector3:
	return Vector3(float(coords[0]),float(coords[1]),float(coords[2]))

static func build_plaza(parent: Node3D, planned: Dictionary) -> Dictionary:
	if not is_instance_valid(parent) or not bool(planned.get("ok",false)):
		return {"ok":false,"code":"invalid_parent_or_plan"}
	var plan: Dictionary = planned.get("plan",{})
	if int(plan.get("schema_version",-1)) != 2 or str(plan.get("kind","")) != "murim_plaza":
		return {"ok":false,"code":"unsupported_plaza_schema"}
	if str(plan.get("role","")) not in PLAZA_ROLES: return {"ok":false,"code":"invalid_plaza_role"}
	var rot: Variant = plan.get("yaw_quadrants",-1)
	if typeof(rot) != TYPE_INT or int(rot) not in [0,1,2,3]: return {"ok":false,"code":"invalid_plaza_orientation"}
	var dimensions: Variant = plan.get("dimensions_m",[])
	if not (dimensions is Array) or dimensions.size()!=2: return {"ok":false,"code":"invalid_plaza_dimensions"}
	if not _valid_number(dimensions[0]) or not _valid_number(dimensions[1]): return {"ok":false,"code":"invalid_plaza_dimensions"}
	var width: float = float(dimensions[0])
	var depth: float = float(dimensions[1])
	if width < 18.0 or depth < 14.0 or width>256.0 or depth>256.0: return {"ok":false,"code":"invalid_plaza_dimensions"}
	var origin: Variant = plan.get("origin_world",[])
	if not (origin is Array) or origin.size()!=3: return {"ok":false,"code":"invalid_plaza_origin"}
	for v in origin:
		if not _valid_number(v): return {"ok":false,"code":"invalid_plaza_origin"}
	var entries: Array = plan.get("furnishings",[])
	if entries.size()!=6: return {"ok":false,"code":"invalid_plaza_slots"}
	Kit.ensure()
	var candidate_assets: Array = EXTRA_PROPS.duplicate()
	candidate_assets.append_array(["village_water_well","covered_market_stall"])
	var xdist: float = width*0.5-3.4
	var zdist: float = minf(depth*0.5-3.0,4.4)
	for index in range(entries.size()):
		var item: Variant = entries[index]
		if not (item is Dictionary): return {"ok":false,"code":"invalid_plaza_slot"}
		var name: String = str(item.get("asset",""))
		if name not in candidate_assets or not Kit.catalog.has(name): return {"ok":false,"code":"asset_not_catalogued"}
		if index==0 and name!="village_water_well": return {"ok":false,"code":"missing_well"}
		if index==3 and name!=("covered_market_stall" if str(plan["role"])=="market_square" else "public_timber_bench"):
			return {"ok":false,"code":"missing_required_plaza_feature"}
		var orientation: Variant = item.get("yaw_quadrants",-1)
		if typeof(orientation)!=TYPE_INT or int(orientation) not in [0,1,2,3]:return {"ok":false,"code":"invalid_prop_rotation"}
		var coords: Variant = item.get("local_pos",[])
		if not (coords is Array) or coords.size()!=3:return {"ok":false,"code":"invalid_prop_location"}
		for v in coords:
			if not _valid_number(v):return {"ok":false,"code":"invalid_prop_location"}
		var expected_x: float = -xdist if index<3 else xdist
		var expected_z: float = -zdist if index%3==0 else 0.0 if index%3==1 else zdist
		if absf(float(coords[0])-expected_x)>0.001 or absf(float(coords[1]))>0.001 or absf(float(coords[2])-expected_z)>0.001:
			return {"ok":false,"code":"out_of_reserved_slot"}
	var root_node := Node3D.new()
	root_node.name = "EXO_Plaza_"+str(plan["id"]).validate_node_name()
	parent.add_child(root_node)
	root_node.global_position = _position(plan["origin_world"])
	root_node.global_rotation = Vector3(0.0, float(plan["yaw_quadrants"])*PI*.5, 0.0)
	root_node.add_to_group("exo_public_spaces")
	root_node.set_meta("forja_plaza_plan",plan.duplicate(true))
	for i in range(entries.size()):
		var item: Dictionary = entries[i]
		var asset: String = str(item["asset"])
		var placed: Node3D = Kit.place(root_node,asset,_position(item["local_pos"]),float(item["yaw_quadrants"])*PI*.5,"",false)
		if asset == "village_water_well": Details._solid(placed,Vector3(0,.65,0),Vector3(1.8,1.3,1.8))
		if asset == "covered_market_stall":
			Details._solid(placed,Vector3(0,.85,0),Vector3(2.2,1.70,1.25))
		var marker := Marker3D.new()
		marker.name = "AnchorVendor"+str(i).pad_zeros(2)
		root_node.add_child(marker)
		marker.position = _position(item["local_pos"]) + Vector3(0,0,1.2)
	for spec in [["AnchorRoadNorth",Vector3(0,0,-float(plan["dimensions_m"][1])*.5)],
		["AnchorRoadSouth",Vector3(0,0,float(plan["dimensions_m"][1])*.5)],
		["AnchorPlazaCenter",Vector3.ZERO]]:
		var marker := Marker3D.new()
		marker.name = str(spec[0])
		root_node.add_child(marker)
		marker.position = spec[1]
	return {"ok":true,"node":root_node,"count":entries.size()}
