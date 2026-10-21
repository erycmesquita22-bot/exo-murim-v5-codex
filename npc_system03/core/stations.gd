extends RefCounted
# City emits candidate semantics. Only accepted WorldGenesis/host routes can authorize travel.
const ALLOWED := ["training_courtyard", "martial_hall", "master_station", "disciple_station",
	"guard_post", "patrol_waypoint", "market_stall", "workshop_station", "social_area",
	"gate_station", "home_station", "healer_station"]
const SEMANTIC_ROLES := {
	"merchant":["market_stall"], "guard":["guard_post", "patrol_waypoint", "gate_station"],
	"disciple":["training_courtyard", "disciple_station", "martial_hall"],
	"master":["master_station", "martial_hall", "training_courtyard"],
	"healer":["healer_station", "workshop_station"],
	"farmer":["workshop_station"], "resident":["workshop_station", "social_area"],
	"guild_agent":["martial_hall", "social_area"]}

static func valid_station(station: Variant) -> bool:
	if not station is Dictionary:
		return false
	if str(station.get("semantic", "")) not in ALLOWED:
		return false
	if str(station.get("id", "")).is_empty():
		return false
	if str(station.get("route_slot", "")).is_empty():
		return false
	if not bool(station.get("host_approved", false)) or not bool(station.get("navigable", false)):
		return false
	if str(station.get("host_owner", "")) not in ["WorldGenesis", "convergence/region"]:
		return false
	return true

static func route_verified(routes: Dictionary, from_slot: String, to_slot: String) -> bool:
	if from_slot.is_empty() or to_slot.is_empty():
		return false
	var route_key: String = from_slot + ">" + to_slot
	if not routes.has(route_key) or not routes[route_key] is Array:
		return false
	var path: Array = routes[route_key]
	if path.is_empty():
		return false
	for point in path:
		if not point is Vector3:
			return false
	return true

static func propose(person: Dictionary, semantic: String, context: Dictionary) -> Dictionary:
	var uid: String = str(person.get("id", ""))
	if semantic not in ALLOWED or uid.is_empty():
		return {"status":"BLOCKED","reason":"invalid_semantic_or_uid"}
	var role: String = str(person.get("role", "resident"))
	if semantic not in SEMANTIC_ROLES.get(role, ["social_area"]):
		return {"status":"BLOCKED","reason":"role_station_mismatch"}
	var stations: Array = context.get("accepted_stations", [])
	var routes: Dictionary = context.get("routes", {})
	var from_slot: String = str(context.get("current_slot", ""))
	var eligible: Array = []
	for item in stations:
		if not valid_station(item) or str(item.get("semantic", "")) != semantic:
			continue
		var slot: String = str(item.get("route_slot", ""))
		if route_verified(routes, from_slot, slot):
			eligible.append(item)
	if eligible.is_empty():
		return {"status":"BLOCKED","reason":"no_authorized_physical_route","npc_id":uid}
	eligible.sort_custom(func(a, b): return str(a.get("id", "")) < str(b.get("id", "")))
	var Stable = preload("res://npc_system03/core/stable.gd")
	var index: int = Stable.choose(str(context.get("seed", "0")), uid, "station:"+semantic, eligible.size())
	var selected: Dictionary = eligible[index]
	return {"status":"PROPOSED","npc_id":uid,"station_id":str(selected.get("id", "")),
		"route_slot":str(selected.get("route_slot", "")), "semantic":semantic,
		"owner":"WorldGenesis","host_accept_required":true,"committed":false}
