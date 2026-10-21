extends RefCounted
## Forja 03: pequenas construcoes comunitarias por lotes previamente reservados pelo Genesis.
## Acesso frontal +Z; nao escava/aterra e nao determina as estradas.
const SCHEMA_VERSION: int = 3
const ROLES: Array[String] = ["sect_hall", "temple", "guild_hall", "martial_school", "granary", "farmstead"]
const DETAIL: Array[String] = ["low", "medium", "high"]
const DIMENSIONS: Dictionary = {
	"sect_hall": [24.0, 26.0], "temple": [24.0, 26.0],
	"guild_hall": [24.0, 26.0], "martial_school": [24.0, 26.0],
	"granary": [20.0, 24.0], "farmstead": [26.0, 30.0]}
const BUILDINGS: Dictionary = {"sect_hall":"sect_hall_8m", "temple":"temple_hall_8m", "guild_hall":"guild_hall_8m", "martial_school":"sect_hall_8m", "granary":"granary_6m", "farmstead":"granary_6m"}

static func reject(code: String) -> Dictionary: return {"ok": false, "code": code}
static func number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value))
static func validate(parcel: Dictionary) -> String:
	if str(parcel.get("id", "")).is_empty() or str(parcel.get("id", "")).length() > 100: return "invalid_site_id"
	for k in ["center_x", "center_z", "ground_y", "width_m", "depth_m"]:
		if not parcel.has(k) or not number(parcel[k]): return "invalid_" + k
	var role: String = str(parcel.get("role", ""))
	if role not in ROLES: return "unsupported_civic_role"
	var dimensions: Array = DIMENSIONS[role]
	if float(parcel["width_m"]) < dimensions[0] or float(parcel["depth_m"]) < dimensions[1]: return "civic_site_too_small"
	if float(parcel["width_m"]) > 128.0 or float(parcel["depth_m"]) > 128.0: return "site_too_large"
	if not bool(parcel.get("approach_clear", false)): return "approach_unverified"
	var yaw: Variant = parcel.get("yaw_quadrants", 0)
	if typeof(yaw) != TYPE_INT or int(yaw) not in [0,1,2,3]: return "bad_orientation"
	var profile: String = str(parcel.get("detail_profile", "medium"))
	if profile not in DETAIL: return "bad_detail_profile"
	var samples: Variant = parcel.get("terrain_samples_y",[])
	if not (samples is Array) or samples.size() != 4: return "four_terrain_samples_required"
	for v in samples:
		if not number(v) or absf(float(v) - float(parcel["ground_y"])) > .18: return "civic_ground_not_flat"
	return ""

static func _piece(id: String, x: float, z: float, yaw: int = 0, solid: bool = false) -> Dictionary:
	return {"asset":id, "local_pos":[x,0.0,z], "yaw_quadrants":yaw, "solid":solid}

static func plan_civic(world_seed: int, parcel: Dictionary) -> Dictionary:
	var error: String = validate(parcel)
	if not error.is_empty(): return reject(error)
	var role: String = str(parcel["role"])
	var profile: String = str(parcel.get("detail_profile","medium"))
	var rng := RandomNumberGenerator.new()
	var normalized_seed: int = world_seed
	rng.seed = normalized_seed ^ int(str(str(parcel["id"]) + ":" + role).hash() & 0x7fffffff)
	var main_asset: String = str(BUILDINGS[role])
	var main_z: float = -6.0 if role in ["granary", "farmstead"] else -5.0
	var main_front: float = 3.6 if role in ["granary", "farmstead"] else 4.4
	var parts: Array[Dictionary] = [_piece(main_asset,0.0,main_z,0,true)]
	match role:
		"sect_hall":
			parts.append(_piece("martial_training_yard_6m",0.0,4.0))
			parts.append(_piece("clan_banner_pair",0.0,0.0))
			parts.append(_piece("stone_lion_statue",-6.7,2.4,0,true))
			parts.append(_piece("stone_lion_statue",6.7,2.4,0,true))
			if profile != "low": parts.append(_piece("dojo_bell",-6.7,6.5,0,true))
		"temple":
			parts.append(_piece("temple_altar",0.0,-6.5,0,true))
			parts.append(_piece("temple_stela",-6.5,3.0,0,true))
			parts.append(_piece("temple_stela",6.5,3.0,0,true))
			if profile != "low": parts.append(_piece("patrol_brazier",-6.5,6.5,0,true))
		"guild_hall":
			parts.append(_piece("clan_banner_pair",0.0,0.0))
			parts.append(_piece("village_notice_board",-6.0,3.0,0,true))
			if profile != "low": parts.append(_piece("street_signpost",6.0,4.0,0,true))
		"martial_school":
			parts.append(_piece("martial_training_yard_6m",0.0,4.0))
			parts.append(_piece("training_dummy",-5.4,4.0,0,true))
			parts.append(_piece("training_dummy",5.4,4.0,0,true))
			parts.append(_piece("weapons_training_rack",-5.6,7.7,0,true))
			if profile == "high": parts.append(_piece("dojo_bell",5.6,7.7,0,true))
		"granary":
			parts.append(_piece("grain_silo",-6.2,-5.0,0,true))
			parts.append(_piece("hay_cart",6.2,2.5,0,true))
			if profile != "low": parts.append(_piece("water_trough",-6.0,5.0,0,true))
		"farmstead":
			parts.append(_piece("rice_field_4m",-5.5,2.0))
			parts.append(_piece("vegetable_field_4m",5.5,2.0))
			parts.append(_piece("farm_gate_4m",0.0,10.0))
			parts.append(_piece("irrigation_channel_2m",-5.5,5.0))
			parts.append(_piece("water_trough",5.5,7.0,0,true))
			if profile != "low": parts.append(_piece("hay_cart",-5.5,8.0,0,true))
	# Ornamentation outside central access, seeded independently of house planner.
	if profile == "high" and role not in ["farmstead", "martial_school"]:
		parts.append(_piece("street_lamp_post",8.0 if rng.randi_range(0,1)==0 else -8.0,7.2,0,true))
	var door_z: float = main_z + main_front
	var plans: Dictionary = {"schema_version":SCHEMA_VERSION,"kind":"exo_civic_site",
		"site_id":str(parcel["id"]),"role":role,"world_seed":normalized_seed,
		"origin_world":[float(parcel["center_x"]),float(parcel["ground_y"]),float(parcel["center_z"])],
		"yaw_quadrants":int(parcel.get("yaw_quadrants",0)),
		"dimensions_m":[float(parcel["width_m"]),float(parcel["depth_m"])],
		"detail_profile":profile,"entrance_local":[0.0,0.0,door_z],
		"approach_local":[0.0,0.0,float(parcel["depth_m"])/2.0-2.0],
		"npc_local":[3.5,0.0,door_z + 1.0],
		"activity_local":[0.0,0.0,4.0 if role in ["martial_school","sect_hall"] else 3.0],
		"pieces":parts,"source_parcel":parcel.duplicate(true),
		"signature":str(normalized_seed,":",parcel["id"],":",role,":",profile)}
	return {"ok":true,"plan":plans}

static func compatible(plan: Dictionary) -> bool:
	if str(plan.get("kind", "")) != "exo_civic_site" or int(plan.get("schema_version",-1)) != SCHEMA_VERSION: return false
	if typeof(plan.get("world_seed",null)) != TYPE_INT or not (plan.get("source_parcel",null) is Dictionary): return false
	var expected: Dictionary = plan_civic(int(plan["world_seed"]), plan["source_parcel"])
	return bool(expected.get("ok",false)) and expected["plan"] == plan
