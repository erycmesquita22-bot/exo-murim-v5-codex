extends RefCounted
# Existing EXO-Murim techniques.gd is the SOLE runtime authority for legacy casts.
static func cast(world: Node3D, id: String) -> Dictionary:
	if not is_instance_valid(world) or world.techniques == null or world.cultivation == null or world.journey == null:
		return {"ok": false, "reason": "host_not_ready"}
	if not world.journey.data.get("learned", []).has(id): return {"ok": false, "reason": "not_learned"}
	if not world.journey.data.get("loadout", []).has(id): return {"ok": false, "reason": "not_equipped"}
	var index: int = -1
	for i in range(world.techniques.DATA.size()):
		if str(world.techniques.DATA[i].get("id", "")) == id: index = i
	if index < 0: return {"ok": false, "reason": "not_in_runtime_loadout"}
	# Calls the same cast(index) used by the game's original controls.
	# Host owns lock checks, Qi/stamina, cooldown, damage, audio, VFX and mastery.
	return {"ok": bool(world.techniques.cast(index)), "reason": "host_cast"}
