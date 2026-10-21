extends RefCounted
# Generates declarative execution plans ONLY. No HP/Qi/inventory/cooldown mutations.
const PHASE_ORDER := ["prepare", "release", "impact", "tick", "expire", "cancel"]

static func compose(spec: Dictionary, actor: Dictionary = {}) -> Dictionary:
	if spec.is_empty(): return {"ok": false, "reason": "skill_not_found"}
	var tags: Dictionary = spec.get("tags", {})
	var balance: Dictionary = spec.get("balance", {})
	if not str(actor.get("type", "player")) in tags.get("actor_types", []): return {"ok": false, "reason": "actor_type_incompatible"}
	if actor.has("weapon_pose") and not tags.get("weapon_poses", []).is_empty() and str(actor["weapon_pose"]) not in tags["weapon_poses"]: return {"ok": false, "reason": "weapon_incompatible"}
	if actor.has("level") and int(actor["level"]) < int(tags.get("min_level", 1)): return {"ok": false, "reason": "level_incompatible"}
	var actions: Array = []
	for effect in spec.get("effects", []):
		var e: Dictionary = effect.duplicate(true)
		e["skill_id"] = str(spec["id"])
		e["base_damage"] = float(balance.get("damage", 0)) * float(e.get("coefficient", 1.0))
		e["range"] = float(balance.get("range", 0))
		e["radius"] = float(balance.get("radius", 0))
		e["cone_degrees"] = float(balance.get("cone_degrees", 0))
		actions.append(e)
	var presentation: Dictionary = spec.get("presentation", {}).duplicate(true)
	var unbound: Array = []
	for name in ["audio", "vfx"]:
		for cue in presentation.get(name, []):
			if str(cue.get("binding", "")) == "requires_binding": unbound.append(str(cue.get("key", "")))
	var animation: Dictionary = presentation.get("animation", {})
	if str(animation.get("binding", "")) == "requires_binding": unbound.append(str(animation.get("key", "")))
	return {"ok": true, "skill_id": str(spec["id"]), "source": str(spec["source"]), "executor": str(spec["executor"]), "actor": actor.duplicate(true),
		"template": str(spec["template"]), "requirements": tags.duplicate(true), "cost": {"qi": float(balance.get("qi", 0)), "stamina": float(balance.get("stamina", 0))},
		"cooldown": float(balance.get("cooldown", 0)), "cast_time": float(balance.get("cast_time", 0)), "release_time": float(balance.get("release_time", 0)),
		"actions": actions, "presentation": presentation, "unbound_media": unbound, "stages": PHASE_ORDER.duplicate()}
