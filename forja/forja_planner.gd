extends RefCounted
## EXO FORJA 02. Planejamento puro, sem instanciar nodes ou alterar o World Genesis.
## Convenção: metros, Y para cima, porta na face +Z, rotação em quartos de volta.

const SCHEMA_VERSION = 2
const ALLOWED_ROLES = ["dwelling", "shop", "tea_house", "workshop", "herbalist", "inn"]
const DETAIL_PROFILES = ["low", "medium", "high"]
const ARCHETYPES = ["standard", "veranda", "courtyard", "merchant", "teahouse", "forge", "herb_shop", "inn"]
const PALETTES = ["ivory_charcoal", "ochre_terracotta", "gray_jade", "clay_slate", "cream_blue"]
const DISTRICTS = ["hamlet", "village", "city"]
const BUILD_WIDTHS = [4, 6, 8]
const SIDE_CLEARANCE_M = 1.45
const BACK_CLEARANCE_M = 0.95
const FRONT_APPROACH_M = 3.6
const MIN_DEPTH_M = 10.8  # 4 m de casa + beirais/escada + acesso livre
const MAX_GROUND_DEVIATION_M = 0.18
const MAX_BATCH_BUILDINGS = 32
const COURTYARD_DEPTH_MIN = 19.0
const COURTYARD_WIDTH_MIN = 10.9

static func _reject(code: String, lot_id: String = "") -> Dictionary:
	return {"ok": false, "code": code, "lot_id": lot_id}

static func _number(v: Variant) -> bool:
	return (typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT) and is_finite(float(v))

static func _hash_seed(world_seed: int, lot_id: String) -> int:
	# FNV-1a de 31 bits sobre lot_id; ordem de entrada dos lotes nao altera o sorteio.
	var h: int = 2166136261
	for index in range(lot_id.length()):
		h = ((h ^ lot_id.unicode_at(index)) * 16777619) & 0x7fffffff
	return (h ^ (world_seed & 0x7fffffff)) & 0x7fffffff

static func _xyz(x: float, y: float, z: float) -> Array:
	return [x, y, z]

static func _door_x(width: int) -> float:
	# Mesma formula da biblioteca aprovada: a porta fica no segmento central.
	var segments: int = int(float(width) * 0.5)
	return float(-width) * 0.5 + 1.0 + float(int(float(segments) * 0.5)) * 2.0

static func plan_lot(world_seed: int, lot: Dictionary) -> Dictionary:
	var lot_id: String = str(lot.get("id", ""))
	if lot_id.is_empty(): return _reject("missing_lot_id")
	if lot_id.length() > 100: return _reject("lot_id_too_long")
	for k in ["center_x", "center_z", "ground_y", "width_m", "depth_m"]:
		if not lot.has(k) or not _number(lot[k]): return _reject("invalid_or_missing_" + k, lot_id)
	var lot_w: float = float(lot["width_m"])
	var lot_d: float = float(lot["depth_m"])
	if lot_w <= 0.0 or lot_d <= 0.0 or lot_w > 256.0 or lot_d > 256.0: return _reject("invalid_lot_dimensions", lot_id)
	if lot_d < MIN_DEPTH_M: return _reject("lot_too_shallow_for_safe_entry", lot_id)
	if not bool(lot.get("approach_clear", false)): return _reject("approach_not_verified", lot_id)
	var yaw_value: Variant = lot.get("yaw_quadrants", 0)
	if typeof(yaw_value) != TYPE_INT or int(yaw_value) not in [0, 1, 2, 3]:
		return _reject("yaw_requires_quadrant_0_3", lot_id)
	var district: String = str(lot.get("district", "village"))
	if district not in DISTRICTS: return _reject("unsupported_district", lot_id)
	var grade: Variant = lot.get("terrain_samples_y", [])
	if not (grade is Array): return _reject("invalid_terrain_samples", lot_id)
	if grade.size() != 4:
		if not grade.is_empty(): return _reject("terrain_samples_must_be_four", lot_id)
		if not bool(lot.get("flat_verified", false)):
			return _reject("terrain_validation_missing", lot_id)
	else:
		for y in grade:
			if not _number(y): return _reject("invalid_terrain_samples", lot_id)
			if absf(float(y) - float(lot["ground_y"])) > MAX_GROUND_DEVIATION_M:
				return _reject("terrain_too_uneven", lot_id)
	var role: String = str(lot.get("role", "auto"))
	var rng := RandomNumberGenerator.new()
	rng.seed = _hash_seed(world_seed, lot_id)
	if role == "auto":
		var roles: Array = ["dwelling", "dwelling", "dwelling", "workshop", "shop"]
		if district == "city":
			roles = ["dwelling", "shop", "tea_house", "workshop", "herbalist", "dwelling"]
			if typeof(lot.get("max_stories", 2)) == TYPE_INT and int(lot.get("max_stories", 2)) == 2 and lot_w >= 8.9:
				roles.append("inn")
		role = str(roles[rng.randi_range(0, roles.size() - 1)])
	if role not in ALLOWED_ROLES: return _reject("unsupported_role_model", lot_id)
	var profile: String = str(lot.get("detail_profile", "medium"))
	if profile not in DETAIL_PROFILES: return _reject("invalid_detail_profile", lot_id)
	var candidates: Array[int] = []
	for candidate_width in BUILD_WIDTHS:
		if float(candidate_width) + SIDE_CLEARANCE_M * 2.0 <= lot_w and (role != "inn" or candidate_width >= 6):
			candidates.append(candidate_width)
	if candidates.is_empty(): return _reject("lot_too_narrow_for_role", lot_id)
	var max_story_val: Variant = lot.get("max_stories", 2)
	if typeof(max_story_val) != TYPE_INT or int(max_story_val) not in [1, 2]:
		return _reject("unsupported_max_stories", lot_id)
	var max_stories: int = int(max_story_val)
	var preferred: Variant = lot.get("preferred_stories", 0)
	if typeof(preferred) != TYPE_INT or int(preferred) not in [0, 1, 2]:
		return _reject("unsupported_preferred_stories", lot_id)
	if int(preferred) > max_stories: return _reject("stories_exceed_limit", lot_id)
	var width: int = candidates[rng.randi_range(0, candidates.size() - 1)]
	var stories: int = max_stories if (district == "city" and rng.randf() < 0.75) else 1
	if int(preferred) > 0: stories = int(preferred)
	if role == "inn":
		if max_stories < 2: return _reject("inn_requires_two_stories", lot_id)
		if int(preferred) == 1: return _reject("inn_requires_two_stories", lot_id)
		stories = 2
	var archetype: String = "standard"
	match role:
		"shop": archetype = "merchant"
		"tea_house": archetype = "teahouse"
		"workshop": archetype = "forge"
		"herbalist": archetype = "herb_shop"
		"inn": archetype = "inn"
		"dwelling":
			if width == 6 and lot_w >= COURTYARD_WIDTH_MIN and lot_d >= COURTYARD_DEPTH_MIN and rng.randf() < 0.55:
				archetype = "courtyard"
			elif rng.randf() < 0.60:
				archetype = "veranda"
	var palette: String = PALETTES[rng.randi_range(0, PALETTES.size() - 1)]
	var door_x: float = _door_x(width)
	# Dimensoes conservadoras: beiral, adorno lateral, varanda e degraus inclusos.
	var body_left: float = -float(width) * 0.5 - 1.35
	var body_right: float = float(width) * 0.5 + 1.35
	var body_back: float = -2.65
	var body_front: float = 4.95
	var access_front: float = 5.35
	if archetype == "courtyard":
		body_front = 6.95
		access_front = 9.20
	# Nao criar uma casa cuja entrada ficaria fora do lote.
	if maxf(absf(body_left), absf(body_right)) > lot_w * 0.5:
		return _reject("building_body_outside_lot", lot_id)
	if maxf(absf(body_back), access_front) > lot_d * 0.5:
		return _reject("entry_access_outside_lot", lot_id)
	var position: Array = _xyz(float(lot["center_x"]), float(lot["ground_y"]), float(lot["center_z"]))
	return {"ok": true, "plan": {
		"schema_version": SCHEMA_VERSION,
		"lot_id": lot_id, "world_seed": world_seed,
		"type": "murim_gable_house", "role": role, "district": district,
		"archetype": archetype, "detail_profile": profile,
		"decor_seed": _hash_seed(world_seed ^ 0x3141592, lot_id + ":detail"),
		"width_m": width, "depth_m": 4, "stories": stories,
		"palette": palette, "yaw_quadrants": int(yaw_value),
		"origin_world": position,
		"footprint_local_xz": [body_left, body_back, body_right, body_front],
		"access_local_xz": [door_x - 0.95, body_front, door_x + 0.95, access_front],
		"entrance_local": _xyz(door_x, 0.0, 3.02),
		"gate_local": _xyz(door_x, 0.0, 6.2) if archetype == "courtyard" else _xyz(door_x, 0.0, 3.02),
		"approach_local": _xyz(door_x, 0.0, 8.9 if archetype == "courtyard" else 5.05),
		"interior_anchor_local": _xyz(door_x, 0.42, 1.0),
		"npc_anchor_local": _xyz(door_x - 1.5 if door_x > 0.0 else door_x + 1.5, 0.0, 3.7),
		"lot_dimensions_m": [lot_w, lot_d],
		"signature": str(_hash_seed(world_seed, lot_id), "-", width, "-", stories, "-", role, "-", archetype, "-", palette)
	}}

static func _aabb(lot: Dictionary) -> Array:
	var cx: float = float(lot["center_x"])
	var cz: float = float(lot["center_z"])
	var hw: float = float(lot["width_m"]) * 0.5
	var hd: float = float(lot["depth_m"]) * 0.5
	if int(lot.get("yaw_quadrants", 0)) % 2 == 1:
		var old_hw: float = hw
		hw = hd
		hd = old_hw
	return [cx-hw, cz-hd, cx+hw, cz+hd]

static func _intersect(a: Array, b: Array) -> bool:
	return a[0] < b[2] - 0.001 and a[2] > b[0] + 0.001 and a[1] < b[3] - 0.001 and a[3] > b[1] + 0.001

static func plan_settlement(world_seed: int, lots: Array, require_all: bool = true) -> Dictionary:
	# Planejamento atomico: quando require_all, uma falha resulta em zero casas para instanciar.
	if lots.size() > MAX_BATCH_BUILDINGS:
		return {"ok": false, "code": "batch_over_capacity", "plans": [], "rejections": []}
	var accepted: Array = []
	var rejections: Array = []
	var seen: Dictionary = {}
	var accepted_bounds: Array = []
	for index in range(lots.size()):
		var candidate: Variant = lots[index]
		if not (candidate is Dictionary):
			rejections.append({"index": index, "code": "lot_not_dictionary"})
			continue
		var lot: Dictionary = candidate
		var id: String = str(lot.get("id", ""))
		if seen.has(id) and not id.is_empty():
			rejections.append({"index": index, "lot_id": id, "code": "duplicate_lot_id"})
			continue
		seen[id] = true
		var r: Dictionary = plan_lot(world_seed, lot)
		if not r["ok"]:
			rejections.append({"index": index, "lot_id": id, "code": r["code"]})
			continue
		var rectangle: Array = _aabb(lot)
		var conflict := false
		for previous in accepted_bounds:
			if _intersect(rectangle, previous):
				conflict = true
				break
		if conflict:
			rejections.append({"index": index, "lot_id": id, "code": "overlapping_lots"})
		else:
			accepted.append(r["plan"])
			accepted_bounds.append(rectangle)
	if require_all and not rejections.is_empty():
		return {"ok": false, "code": "atomic_batch_rejected", "plans": [], "rejections": rejections,
			"accepted_if_partial": accepted.size()}
	return {"ok": not accepted.is_empty() or lots.is_empty(), "code": "ok", "plans": accepted, "rejections": rejections}
