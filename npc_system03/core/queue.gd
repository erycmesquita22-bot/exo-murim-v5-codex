extends RefCounted
# Session-local reservation only. Owner must approve geometry; queue never owns saves.
var queues: Dictionary = {}
var serial: int = 0
var reserved_npcs: Dictionary = {}
const MAX_QUEUE := 16

func register_station(station: Dictionary) -> Dictionary:
	if str(station.get("id", "")).is_empty() or not bool(station.get("host_approved", false)):
		return {"status":"BLOCKED","reason":"unapproved_station"}
	if not bool(station.get("door_clear", false)) or not bool(station.get("navigable", false)):
		return {"status":"BLOCKED","reason":"unsafe_queue_geometry"}
	var count: int = clampi(int(station.get("capacity", 0)), 0, MAX_QUEUE)
	var queue_slots: Array = station.get("queue_route_slots", [])
	if count <= 0 or queue_slots.size() < count:
		return {"status":"BLOCKED","reason":"insufficient_verified_slots"}
	for index in range(count):
		if not queue_slots[index] is String or str(queue_slots[index]).is_empty():
			return {"status":"BLOCKED","reason":"invalid_queue_slot"}
	var station_id: String = str(station.get("id", ""))
	if queues.has(station_id):
		return {"status":"READY","station_id":station_id,"existing":true}
	queues[station_id] = {"capacity":count,"slots":queue_slots.slice(0, count), "waiting":[]}
	return {"status":"READY","station_id":station_id,"existing":false}

func request(station_id: String, npc_id: String) -> Dictionary:
	if not queues.has(station_id) or not npc_id.begins_with("npc/r"):
		return {"status":"BLOCKED","reason":"unknown_station_or_actor"}
	var record: Dictionary = queues[station_id]
	var waiting: Array = record.get("waiting", [])
	for i in range(waiting.size()):
		if str(waiting[i].get("npc_id", "")) == npc_id:
			return {"status":"PROPOSED","station_id":station_id,"npc_id":npc_id,
				"slot":str(record.slots[i]),"index":i,"duplicate":true,"committed":false}
	if reserved_npcs.has(npc_id) and str(reserved_npcs[npc_id]) != station_id:
		return {"status":"BLOCKED","reason":"already_queued_elsewhere"}
	if waiting.size() >= int(record.capacity):
		return {"status":"BLOCKED","reason":"queue_full"}
	serial += 1
	waiting.append({"npc_id":npc_id,"sequence":serial})
	reserved_npcs[npc_id] = station_id
	record["waiting"] = waiting
	queues[station_id] = record
	return {"status":"PROPOSED","station_id":station_id,"npc_id":npc_id,
		"slot":str(record.slots[waiting.size()-1]),"index":waiting.size()-1,
		"duplicate":false,"committed":false}

func release(station_id: String, npc_id: String) -> bool:
	if not queues.has(station_id):
		return false
	var record: Dictionary = queues[station_id]
	var waiting: Array = record.get("waiting", [])
	for i in range(waiting.size()):
		if str(waiting[i].get("npc_id", "")) == npc_id:
			waiting.remove_at(i)
			reserved_npcs.erase(npc_id)
			record["waiting"] = waiting
			queues[station_id] = record
			return true
	return false

func clear_region() -> void:
	queues.clear()
	reserved_npcs.clear()
	serial = 0

func status(station_id: String) -> Dictionary:
	if not queues.has(station_id):
		return {"status":"BLOCKED","reason":"unknown_station"}
	return queues[station_id].duplicate(true)
