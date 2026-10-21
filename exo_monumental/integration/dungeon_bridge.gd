extends RefCounted
## Compatibilidade de payload com exo_dungeon/integration/world_adapter.gd.
## NAO gera, instancia nem altera interiores/dungeons.
const Adapter = preload("res://exo_monumental/integration/exo_adapter.gd")
const ACCEPTED_FAMILIES: Array[String] = ["ruins", "cavern", "temple", "sect_hideout", "mine", "tomb"]

static func descriptor_from_plan(plan: Dictionary, floors: int = 1, difficulty: int = 1) -> Dictionary:
	if not bool(plan.get("ok", false)) or str(plan.get("dungeon_family", "")).is_empty(): return {"ok": false, "code": "not_dungeon_entrance"}
	var family: String = str(plan["dungeon_family"])
	if family not in ACCEPTED_FAMILIES: return {"ok": false, "code": "not_supported_by_dungeon02"}
	if floors < 1 or difficulty < 1: return {"ok": false, "code": "invalid_difficulty_or_floors"}
	var data: Dictionary = {"world_id": plan["world_id"], "world_seed": str(plan["world_seed"]), "region_id": plan["region_id"], "location_id": plan["id"], "family": family, "floors": floors, "rooms_per_floor": 11, "difficulty": difficulty}
	return {"ok": true, "dungeon_descriptor": data, "exterior_theme": plan["kind"], "entry_world": Adapter.local_to_world(plan, plan["entrance_marker"]), "return_world": Adapter.local_to_world(plan, plan["return_marker"]), "interaction_radius_m": 2.0, "approach_width_m": 5.0, "exterior_site_id": plan["id"], "contract": "Dungeon Genesis 02 world_adapter descriptor"}
