extends RefCounted
const Validator = preload("res://exo_skill_forge/runtime/validator.gd")
const PATH := "res://exo_skill_forge/data/"
var entries: Dictionary = {}
var refs: Dictionary = {}
var issues: Array[String] = []
var loaded: bool = false

static func read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path): return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))

static func index_of(items: Array) -> Dictionary:
	var result: Dictionary = {}
	for item in items:
		if item is Dictionary and item.get("id") is String: result[str(item["id"])] = item
	return result

func initialize() -> bool:
	entries.clear()
	issues.clear()
	loaded = false
	var legacy: Variant = read_json(PATH + "legacy_bindings.json")
	var authorial: Variant = read_json(PATH + "authorial.json")
	var existing: Variant = read_json("res://data/skills.json")
	var styles: Variant = read_json("res://exo_martial/data/styles.json")
	var schools: Variant = read_json("res://exo_martial/data/schools.json")
	var weapons: Variant = read_json("res://data/weapons.json")
	var tdata: Variant = read_json(PATH + "templates.json")
	if not (legacy is Array and authorial is Array and existing is Array and styles is Array and schools is Array and weapons is Array and tdata is Dictionary):
		issues.append("source_catalog_unavailable")
		return false
	var template_list: Variant = tdata.get("templates", [])
	if not template_list is Array:
		issues.append("bad_template_catalog")
		return false
	var styles_idx: Dictionary = index_of(styles)
	var schools_idx: Dictionary = index_of(schools)
	var known_core: Dictionary = index_of(existing)
	var template_idx: Dictionary = index_of(template_list)
	var poses: Dictionary = {}
	var weapon_ids: Dictionary = {}
	for weapon in weapons:
		if weapon is Dictionary:
			poses[str(weapon.get("pose", ""))] = true
			weapon_ids[str(weapon.get("id", ""))] = str(weapon.get("pose", ""))
	if legacy.size() != known_core.size(): issues.append("legacy_catalog_cardinality_changed")
	for item in legacy + authorial:
		if not item is Dictionary:
			issues.append("bad_record")
			continue
		var spec: Dictionary = item.duplicate(true)
		var id: String = str(spec.get("id", ""))
		if entries.has(id):
			issues.append("duplicate_id:" + id)
			continue
		for error in Validator.verify(spec, styles_idx, schools_idx, poses, template_idx, weapon_ids): issues.append(id + ":" + error)
		if str(spec.get("source", "")) == "legacy":
			var original: Dictionary = known_core.get(id, {})
			if original.is_empty():
				issues.append("legacy_id_missing:" + id)
			else:
				var b: Dictionary = spec.get("balance", {})
				for pair in [{"field":"mana", "mirror":"qi"}, {"field":"stamina", "mirror":"stamina"}, {"field":"damage", "mirror":"damage"}, {"field":"cooldown", "mirror":"cooldown"}, {"field":"cast", "mirror":"cast_time"}, {"field":"release", "mirror":"release_time"}]:
					if absf(float(original.get(pair["field"], -999)) - float(b.get(pair["mirror"], -998))) > 0.00001: issues.append("legacy_drift:" + id + ":" + str(pair["field"]))
				if str(original.get("kind", "")) != str(spec.get("template", "")): issues.append("legacy_kind_drift:" + id)
				if str(original.get("name", "")) != str(spec.get("name", "")): issues.append("legacy_name_drift:" + id)
		entries[id] = spec
	refs = {"styles": styles_idx, "schools": schools_idx, "templates": template_idx, "poses": poses, "weapon_ids": weapon_ids}
	loaded = issues.is_empty()
	if not loaded: entries.clear()
	return loaded

func get_skill(id: String) -> Dictionary:
	return entries.get(id, {}).duplicate(true)

func query(filters: Dictionary = {}) -> Array:
	var out: Array = []
	for id in entries.keys():
		var spec: Dictionary = entries[id]
		var tags: Dictionary = spec["tags"]
		if filters.has("source") and filters["source"] != spec["source"]: continue
		if filters.has("template") and filters["template"] != spec["template"]: continue
		if filters.has("inspiration_origin") and filters["inspiration_origin"] != tags.get("inspiration_origin", ""): continue
		if filters.has("power_family") and filters["power_family"] != tags.get("power_family", ""): continue
		if filters.has("combat_role") and filters["combat_role"] != tags.get("combat_role", ""): continue
		if filters.has("rarity_tier") and filters["rarity_tier"] != tags.get("rarity_tier", -1): continue
		if filters.has("combo_role") and filters["combo_role"] != tags.get("combo_role", ""): continue
		if filters.has("world_tag") and filters["world_tag"] not in tags.get("world_tags", []): continue
		if filters.has("weapon_id") and filters["weapon_id"] not in tags["weapon_ids"]: continue
		if filters.has("weapon_pose") and filters["weapon_pose"] not in tags["weapon_poses"]: continue
		if filters.has("style") and filters["style"] not in tags["styles"]: continue
		if filters.has("school") and filters["school"] not in tags["schools"]: continue
		if filters.has("actor_type") and filters["actor_type"] not in tags["actor_types"]: continue
		if filters.has("max_level") and int(tags["min_level"]) > int(filters["max_level"]): continue
		if filters.has("min_level") and int(tags["min_level"]) < int(filters["min_level"]): continue
		out.append(spec.duplicate(true))
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a["id"]) < str(b["id"]))
	return out

func summary() -> Dictionary:
	var legacy_count := 0
	var proposed_count := 0
	for record in entries.values():
		if record["source"] == "legacy": legacy_count += 1
		else: proposed_count += 1
	return {"ok": loaded, "total": entries.size(), "legacy": legacy_count, "authorial_candidates": proposed_count, "r2_candidates": query({"source": "authorial", "world_tag": "authorial"}).size(), "styles": refs.get("styles", {}).size(), "schools": refs.get("schools", {}).size(), "issues": issues.duplicate()}
