extends RefCounted
# Diagnostics only; never modifies Core/AI/quests/equipment.
static func probe(core: RefCounted) -> Dictionary:
	if core == null: return {"ok": false, "reason": "core_not_bound"}
	var statuses: Dictionary = {}
	for id in ["combat", "persistence", "npcs", "inventory", "progression", "martial.catalog", "martial", "bestiary.combat", "exo_items", "quests"]:
		statuses[id] = bool(core.services.has_service(id))
	return {"ok": bool(statuses["combat"] and statuses["persistence"]), "service_readiness": statuses,
		"combat_authority": "existing_techniques_and_combat", "legacy_cast_path": "techniques.cast(index)",
		"npc_use": "host_only_with_actor_proof", "enemy_use": "host_only_with_actor_proof", "generic_cast_path": "requires_atomic_host_adapter",
		"progression_grant": "not_authorized_by_skill_forge", "save_domain": "none", "event_contracts_modified": false}
