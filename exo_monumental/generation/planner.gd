extends RefCounted
## Forja Monumental 04 — planejamento puro; NUNCA altera WorldGenesis/estado de save.
## Entradas +Z; unidades em metros, Y para cima. Mesmo site+seed => mesmo plano.
const LAYOUTS_PATH: String = "res://exo_monumental/catalog/layouts.json"
const SCHOOL_STYLES_PATH: String = "res://exo_monumental/catalog/school_styles.json"
const CONTRACT_VERSION: int = 5
const SAFETY_KEYS: Array[String] = ["approach_clear", "roads_clear", "rivers_clear", "walls_clear", "buildings_clear", "navigation_clear", "fluvial_gates_clear", "dungeon_entrances_clear", "terrain_clear"]

static func _reject(code: String, site_id: String = "") -> Dictionary:
	return {"ok": false, "code": code, "site_id": site_id}

static func _is_num(x: Variant) -> bool:
	return typeof(x) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(x))

static func _catalog() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(LAYOUTS_PATH))
	if parsed is Dictionary: return parsed.get("layouts", {})
	return {}

static func _fnv31(value: String) -> int:
	var hash_value: int = 2166136261
	for i in range(value.length()):
		hash_value = ((hash_value ^ value.unicode_at(i)) * 16777619) & 0x7fffffff
	return hash_value

static func footprint(kind: String, yaw_quadrants: int = 0) -> Dictionary:
	var all_layouts: Dictionary = _catalog()
	if not all_layouts.has(kind): return _reject("unknown_kind")
	var s: Array = all_layouts[kind].get("size_m", [])
	if yaw_quadrants not in [0,1,2,3]: return _reject("invalid_quadrant")
	var swapped: bool = yaw_quadrants % 2 == 1
	var margin: float = float(all_layouts[kind].get("reservation_margin_m", 5.0))
	return {"ok": true, "width_m": float(s[1] if swapped else s[0]), "depth_m": float(s[0] if swapped else s[1]), "margin_m": margin, "required_site_width_m": float(s[1] if swapped else s[0]) + margin * 2.0, "required_site_depth_m": float(s[0] if swapped else s[1]) + margin * 2.0}

static func _rect(origin: Array, w: float, d: float, yaw: int, margin: float) -> Dictionary:
	var rw: float = d if yaw % 2 == 1 else w
	var rd: float = w if yaw % 2 == 1 else d
	return {"min_x": float(origin[0]) - rw * 0.5 - margin,
		"max_x": float(origin[0]) + rw * 0.5 + margin,
		"min_z": float(origin[2]) - rd * 0.5 - margin,
		"max_z": float(origin[2]) + rd * 0.5 + margin}

static func _overlap(a: Dictionary, b: Dictionary) -> bool:
	return float(a["min_x"]) < float(b["max_x"]) - 0.001 and float(a["max_x"]) > float(b["min_x"]) + 0.001 and float(a["min_z"]) < float(b["max_z"]) - 0.001 and float(a["max_z"]) > float(b["min_z"]) + 0.001

static func plan(world_seed: int, request: Dictionary, reservations: Array = []) -> Dictionary:
	var site_id: String = str(request.get("site_id", ""))
	if site_id.is_empty() or site_id.length() > 100: return _reject("invalid_site_id", site_id)
	var world_id: String = str(request.get("world_id", ""))
	if world_id.is_empty(): return _reject("missing_world_id", site_id)
	var region_id: Variant = request.get("region_id", null)
	if typeof(region_id) != TYPE_INT or int(region_id) < 0 or int(region_id) >= 88: return _reject("invalid_region", site_id)
	var kind: String = str(request.get("kind", ""))
	var layouts: Dictionary = _catalog()
	if not layouts.has(kind): return _reject("kind_not_cataloged", site_id)
	var layout: Dictionary = layouts[kind]
	var origin: Variant = request.get("origin_world", null)
	if not (origin is Array) or origin.size() != 3: return _reject("invalid_origin", site_id)
	for v in origin:
		if not _is_num(v): return _reject("origin_not_finite", site_id)
	var yaw_v: Variant = request.get("yaw_quadrants", null)
	if typeof(yaw_v) != TYPE_INT or int(yaw_v) not in [0, 1, 2, 3]: return _reject("invalid_quadrant", site_id)
	var yaw: int = int(yaw_v)
	var size: Array = layout["size_m"]
	if not _is_num(request.get("site_width_m")) or not _is_num(request.get("site_depth_m")):
		return _reject("missing_site_dimensions", site_id)
	var rotated_width: float = float(size[1] if yaw % 2 == 1 else size[0])
	var rotated_depth: float = float(size[0] if yaw % 2 == 1 else size[1])
	var margin: float = float(layout.get("reservation_margin_m", 5.0))
	if float(request["site_width_m"]) < rotated_width + 2.0 * margin or float(request["site_depth_m"]) < rotated_depth + 2.0 * margin:
		return _reject("site_too_small", site_id)
	for safety in SAFETY_KEYS:
		if request.get(safety, false) != true: return _reject("not_verified_" + safety, site_id)
	var height_samples: Variant = request.get("terrain_corner_heights", null)
	if not (height_samples is Array) or height_samples.size() != 4: return _reject("terrain_samples_required", site_id)
	for sample in height_samples:
		if not _is_num(sample): return _reject("invalid_terrain_height", site_id)
		if absf(float(sample) - float(origin[1])) > 0.45: return _reject("requires_preexisting_terrace", site_id)
	var rect: Dictionary = _rect(origin, float(size[0]), float(size[1]), yaw, margin)
	var protected: Variant = request.get("protected_rects", [])
	if not (protected is Array): return _reject("protected_rects_not_array", site_id)
	for occupied in reservations + protected:
		if not (occupied is Dictionary): return _reject("invalid_protected_rect", site_id)
		for k in ["min_x", "max_x", "min_z", "max_z"]:
			if not _is_num(occupied.get(k)): return _reject("invalid_protected_rect", site_id)
		if float(occupied["min_x"]) >= float(occupied["max_x"]) or float(occupied["min_z"]) >= float(occupied["max_z"]): return _reject("invalid_protected_rect", site_id)
		if _overlap(rect, occupied): return _reject("reservation_conflict_" + str(occupied.get("type", "occupied")), site_id)
	var school_id: String = str(request.get("school_id", ""))
	var style_data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SCHOOL_STYLES_PATH))
	var school_styles: Dictionary = {}
	if style_data is Dictionary: school_styles = style_data.get("mapping", {})
	if kind.begins_with("martial_") and not school_id.is_empty() and not school_styles.has(school_id):
		return _reject("unknown_martial_school_id", site_id)
	var visual_profile: Dictionary = {}
	if kind.begins_with("martial_") and school_styles.has(school_id):
		visual_profile = school_styles[school_id].duplicate(true)
	var salt: String = str(world_seed) + "|" + world_id + "|" + str(region_id) + "|" + site_id + "|" + kind + "|" + school_id
	var rng := RandomNumberGenerator.new()
	rng.seed = _fnv31(salt)
	var mirrored: bool = rng.randi_range(0, 1) == 1
	var variant: int = rng.randi_range(0, 2)
	var pieces: Array = []
	for raw in layout["assets"]:
		var item: Dictionary = raw.duplicate(true)
		if str(item.get("role", "")) in ["grand_gate", "martial_gate"] or (str(item.get("asset", "")) == "martial_gate" and kind.begins_with("martial_")):
			item["asset"] = str(visual_profile.get("preferred_gate", item["asset"]))
		if mirrored:
			item["x"] = -float(item["x"])
			item["yaw"] = (4 - int(item.get("yaw", 0))) % 4
		# Limited procedural shifts only for decorative props, never doors or structural components.
		if str(item.get("role", "")) == "lighting":
			item["z"] = float(item["z"]) + float(variant - 1) * 0.6
		pieces.append(item)
	var areas: Array = layout["areas"].duplicate(true)
	var paths: Array = layout["paths"].duplicate(true)
	var stations: Array = layout.get("stations", []).duplicate(true)
	if mirrored:
		for area in areas: area["center"][0] = -float(area["center"][0])
		for p in paths:
			for point in p["points"]: point[0] = -float(point[0])
		for station in stations: station["local"][0] = -float(station["local"][0])
	var id: String = world_id + ":" + str(world_seed) + ":r" + str(region_id) + ":" + site_id
	var entry: Array = layout.get("door_marker", [0.0, 0.0, -13.0])
	return {"ok": true, "schema": CONTRACT_VERSION, "state": "PROPOSED_NOT_RESERVED",
		"id": id, "site_id": site_id, "world_seed": world_seed, "region_id": region_id,
		"kind": kind, "world_id": world_id, "school_id": school_id, "school_visual_style": visual_profile,
		"origin_world": origin.duplicate(), "yaw_quadrants": yaw, "bounds": rect,
		"size_m": size.duplicate(), "mirrored": mirrored, "variant": variant,
		"instances": pieces, "areas": areas, "paths": paths, "stations": stations,
		"reservation_margin_m": margin, "approach_corridor": layout["approach_corridor"].duplicate(true),
		"entrance_marker": entry.duplicate(), "return_marker": layout["return"].duplicate(),
		"dungeon_family": str(layout.get("dungeon_family", "")),
		"entrance_local_kind": str(layout.get("entrance_local_kind", "")),
		"approval_owner": "WorldGenesis/CidadeViva external reservation authority"}

static func plan_batch(world_seed: int, requests: Array, already_reserved: Array = []) -> Dictionary:
	if requests.size() > 24: return _reject("batch_over_limit")
	var seen: Dictionary = {}
	var staging: Array = already_reserved.duplicate(true)
	var proposed: Array = []
	for entry in requests:
		if not (entry is Dictionary): return _reject("invalid_request")
		var id: String = str(entry.get("site_id", ""))
		if seen.has(id): return _reject("duplicate_site_id", id)
		seen[id] = true
		var result: Dictionary = plan(world_seed, entry, staging)
		if not bool(result.get("ok", false)):
			return {"ok": false, "code": str(result.get("code", "unknown")), "site_id": id, "index": proposed.size(), "plans": []}
		proposed.append(result)
		staging.append(result["bounds"])
	return {"ok": true, "plans": proposed, "reservation_requests": staging.slice(already_reserved.size())}
