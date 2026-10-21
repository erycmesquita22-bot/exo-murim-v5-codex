extends RefCounted
const Stations = preload("res://npc_system03/core/stations.gd")
const Stable = preload("res://npc_system03/core/stable.gd")
# Multi-stop patrol itinerary, advanced by host after *actual* waypoint arrival.
# No raw world coordinates, no bypass of official resident.gd navigation.
static func next_stop(person: Dictionary, previous: Dictionary, context: Dictionary) -> Dictionary:
	var uid: String = str(person.get("id", ""))
	if uid.is_empty() or str(person.get("role", "")) != "guard":
		return {"status":"BLOCKED","reason":"not_guard"}
	if bool(context.get("threat_active", false)):
		return {"status":"BLOCKED","reason":"threat_interrupts_patrol"}
	var available: Array = []
	for station in context.get("accepted_stations", []):
		if not Stations.valid_station(station):
			continue
		if str(station.get("semantic", "")) in ["patrol_waypoint", "guard_post", "gate_station"]:
			available.append(station)
	available.sort_custom(func(a, b): return str(a.get("id", "")) < str(b.get("id", "")))
	if available.size() < 3:
		return {"status":"BLOCKED","reason":"patrol_needs_three_physical_stops"}
	var first_index: int = Stable.choose(str(context.get("seed", "0")), uid, "patrol_start", available.size())
	var index: int = posmod(int(previous.get("next_index", first_index)), available.size())
	var target: Dictionary = available[index]
	var from_slot: String = str(context.get("current_slot", ""))
	var to_slot: String = str(target.get("route_slot", ""))
	if not Stations.route_verified(context.get("routes", {}), from_slot, to_slot):
		return {"status":"BLOCKED","reason":"patrol_route_not_proven"}
	if not bool(context.get("at_previous_stop", false)) and not previous.is_empty():
		return {"status":"BLOCKED","reason":"previous_stop_not_reached"}
	return {"status":"PROPOSED","npc_id":uid,"station_id":str(target.get("id", "")),
		"route_slot":to_slot,"observation_seconds":3.0 + float(index),
		"next_index":posmod(index + 1, available.size()),"owner":"living_world",
		"arrived_required_to_advance":true,"committed":false}
