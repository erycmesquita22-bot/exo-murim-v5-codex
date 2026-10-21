extends RefCounted
# Dynamic source lookup keeps City/Crowd/Library optional; proposals never install plugins.
const BRIDGE := "res://exo_world_library/integration/read_only_bridge.gd"
static func city_slots(area_snapshot: Dictionary) -> Dictionary:
	if str(area_snapshot.get("authority", "")) != "WorldGenesis":
		return {"status":"BLOCKED","reason":"missing_authority","accepted_stations":[]}
	if not bool(area_snapshot.get("physical_verified", false)):
		return {"status":"BLOCKED","reason":"not_physically_verified","accepted_stations":[]}
	var stations: Array = []
	var Stations = preload("res://npc_system03/core/stations.gd")
	for station in area_snapshot.get("stations", []):
		if Stations.valid_station(station):
			stations.append(station.duplicate(true))
	return {"status":"PROPOSED","accepted_stations":stations,"committed":false,
		"city_contract_version":str(area_snapshot.get("contract_version", "unknown"))}

static func crowd_constraints(real_npc_ids: Array, zone: Dictionary) -> Dictionary:
	if str(zone.get("owner", "")) != "exo_crowd_illusion":
		return {"status":"BLOCKED","reason":"unauthorized_zone"}
	if not bool(zone.get("approved", false)):
		return {"status":"BLOCKED","reason":"zone_not_approved"}
	var ids: Dictionary = {}
	for value in real_npc_ids:
		var uid: String = str(value)
		if uid.begins_with("npc/r"):
			ids[uid] = true
	return {"status":"PROPOSED","exclude_real_npc_ids":ids.keys(),
		"figurants_have_identity":false,"figurants_have_save":false,
		"min_door_clearance":float(zone.get("min_door_clearance", 2.0)),
		"max_visual_density":maxi(0,int(zone.get("capacity", 0))),"committed":false}

static func library_proposal(request: Dictionary) -> Dictionary:
	if not ResourceLoader.exists(BRIDGE):
		return {"status":"BLOCKED","reason":"library_not_installed","committed":false}
	var script: Variant = load(BRIDGE)
	if script == null:
		return {"status":"BLOCKED","reason":"library_unloadable","committed":false}
	var library_bridge: Variant = script.new()
	if not library_bridge.initialize():
		return {"status":"BLOCKED","reason":"library_initialization_failed","committed":false}
	var domain_list: Array = ["npc_archetype", "npc_motivation", "personality", "social_custom"]
	return library_bridge.catalog_preview("living_world", request, domain_list)
