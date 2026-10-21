extends RefCounted
## Plantio independente de uma faixa plana com eixo de circulacao norte-sul reservado.
## Usa GLBs ja aprovados, nao altera o terreno do Genesis.
const Kit = preload("res://godot/modular_kit.gd")
const Planner = preload("res://forja/forja_planner.gd")
const BIOMES: Dictionary = {
	"mixed": ["tree_broad_01", "tree_broad_02", "tree_pine_01", "tree_willow"],
	"bamboo": ["bamboo_cluster_01", "bamboo_cluster_02"],
	"orchard": ["tree_orchard", "tree_broad_01"],
	"pine": ["tree_pine_01", "tree_pine_02"]}
const TOLERANCE: float = .18

static func valid_number(x: Variant) -> bool:
	return typeof(x) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(x))

static func plan(seed_value: int, parcel: Dictionary) -> Dictionary:
	var id: String = str(parcel.get("id", ""))
	if id.is_empty() or id.length()>100:return {"ok":false,"code":"invalid_id"}
	for key in ["center_x","center_z","ground_y","width_m","depth_m"]:
		if not parcel.has(key) or not valid_number(parcel[key]):return {"ok":false,"code":"invalid_"+key}
	var w: float = float(parcel["width_m"])
	var d: float = float(parcel["depth_m"])
	if w<16.0 or d<16.0 or w>120.0 or d>120.0:return {"ok":false,"code":"invalid_green_strip_size"}
	var yaw: Variant = parcel.get("yaw_quadrants",0)
	if typeof(yaw)!=TYPE_INT or int(yaw) not in [0,1,2,3]:return {"ok":false,"code":"invalid_yaw"}
	var biome: String = str(parcel.get("biome","mixed"))
	if not BIOMES.has(biome):return {"ok":false,"code":"unsupported_biome"}
	var density: Variant = parcel.get("density",.6)
	if not valid_number(density) or float(density)<0.0 or float(density)>1.0:return {"ok":false,"code":"invalid_density"}
	var samples: Variant = parcel.get("terrain_samples_y",[])
	if not (samples is Array) or samples.size()!=4:return {"ok":false,"code":"terrain_not_verified"}
	for y in samples:
		if not valid_number(y) or absf(float(y)-float(parcel["ground_y"])) > TOLERANCE:return {"ok":false,"code":"uneven_green_strip"}
	if not bool(parcel.get("road_clear",false)):return {"ok":false,"code":"road_clearance_not_verified"}
	var rng := RandomNumberGenerator.new()
	rng.seed = (seed_value ^ (seed_value >> 31)) ^ Planner._hash_seed(seed_value,"green:"+id)
	var n: int = int(floorf((d-6.0)/6.5))+1
	var entries: Array[Dictionary] = []
	for side in [-1.0,1.0]:
		for i in range(n):
			if rng.randf() > float(density):continue
			var x: float = side*(w*.5-2.45)
			var z: float = -d*.5+3.1+float(i)*6.5
			var group: Array = BIOMES[biome]
			entries.append({"asset":str(group[rng.randi_range(0,group.size()-1)]),
				"local_pos":[x,0.0,z],"yaw_quadrants":rng.randi_range(0,3)})
	return {"ok":true,"plan":{"schema_version":3,"kind":"exo_green_buffer", "id":id,
		"seed":seed_value,"biome":biome,"source_parcel":parcel.duplicate(true),
		"origin_world":[float(parcel["center_x"]),float(parcel["ground_y"]),float(parcel["center_z"])],
		"yaw_quadrants":int(yaw), "road_half_width_m":2.5,"canopy_reserve_m":2.15,
		"entries":entries}}

static func compatible(green: Dictionary) -> bool:
	if int(green.get("schema_version",-1))!=3 or str(green.get("kind",""))!="exo_green_buffer":return false
	if not (green.get("source_parcel",null) is Dictionary) or typeof(green.get("seed",null))!=TYPE_INT:return false
	var canonical: Dictionary = plan(int(green["seed"]),green["source_parcel"])
	return bool(canonical.get("ok",false)) and canonical["plan"] == green

static func build(parent: Node3D, planned: Dictionary) -> Dictionary:
	if not is_instance_valid(parent) or not bool(planned.get("ok",false)):return {"ok":false,"code":"invalid_parent_or_plan"}
	var p: Dictionary = planned.get("plan",{})
	if not compatible(p):return {"ok":false,"code":"invalid_blueprint"}
	Kit.ensure()
	for item in p["entries"]:
		if not Kit.catalog.has(item["asset"]):return {"ok":false,"code":"missing_asset"}
	var root_node := Node3D.new()
	root_node.name = ("Roadside_"+str(p["id"])).validate_node_name()
	parent.add_child(root_node)
	root_node.global_position = Vector3(float(p["origin_world"][0]),float(p["origin_world"][1]),float(p["origin_world"][2]))
	root_node.global_rotation = Vector3(0.0, float(p["yaw_quadrants"])*PI*.5, 0.0)
	root_node.add_to_group("exo_roadside_nature")
	for item in p["entries"]:
		var coords: Array = item["local_pos"]
		var n: Node3D = Kit.place(root_node,str(item["asset"]),Vector3(float(coords[0]),float(coords[1]),float(coords[2])),float(item["yaw_quadrants"])*PI*.5,"",false)
		# Colisao economica somente para troncos grandes; bambus seguem a regra da biblioteca herdada.
		if str(item["asset"]).begins_with("tree_"):
			var body := StaticBody3D.new()
			n.add_child(body)
			var collision := CollisionShape3D.new()
			body.add_child(collision)
			var box := BoxShape3D.new()
			box.size = Vector3(.65,2.0,.65)
			collision.shape = box
			collision.position = Vector3(0,1,0)
	return {"ok":true,"node":root_node,"count":p["entries"].size()}
