extends RefCounted
## Forja 03: planejamento deterministico e conservador de cercados retangulares PLANOS.
## Nao cria muralhas seguindo o relevo inteiro de uma cidade. Isso requer Genesis.
const SCHEMA_VERSION: int = 3
const STYLES: Array[String] = ["stone", "wood", "battlement"]
const MAX_SLOTS: int = 250
const TERRAIN_TOLERANCE: float = 0.18

static func fail(code: String) -> Dictionary:
	return {"ok": false, "code": code}

static func number(value: Variant) -> bool:
	return (typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT) and is_finite(float(value))

static func verified(parcel: Dictionary) -> String:
	if str(parcel.get("id", "")).is_empty() or str(parcel.get("id", "")).length() > 100: return "invalid_id"
	for k in ["center_x", "center_z", "ground_y", "width_m", "depth_m"]:
		if not parcel.has(k) or not number(parcel[k]): return "invalid_" + k
	for axis in ["width_m", "depth_m"]:
		var size: float = float(parcel[axis])
		if size < 24.0 or size > 100.0 or absf(size - roundf(size / 2.0) * 2.0) > .0001: return "unsupported_even_footprint"
	if not bool(parcel.get("approach_clear", false)): return "entry_not_verified"
	var yaw: Variant = parcel.get("yaw_quadrants", 0)
	if typeof(yaw) != TYPE_INT or int(yaw) not in [0, 1, 2, 3]: return "invalid_orientation"
	var style: String = str(parcel.get("style", "stone"))
	if style not in STYLES and style != "auto": return "invalid_style"
	var samples: Variant = parcel.get("terrain_samples_y", [])
	if not (samples is Array) or samples.size() != 4: return "four_samples_required"
	for v in samples:
		if not number(v) or absf(float(v) - float(parcel["ground_y"])) > TERRAIN_TOLERANCE:
			return "site_not_level"
	return ""

static func _slot(asset: String, x: float, z: float, yaw: int, solid: bool = true) -> Dictionary:
	return {"asset": asset, "pos": [x, 0.0, z], "yaw_quadrants": yaw, "solid": solid}

static func plan_fort(world_seed: int, parcel: Dictionary) -> Dictionary:
	var err: String = verified(parcel)
	if not err.is_empty(): return fail(err)
	var w: float = float(parcel["width_m"]) - 4.0
	var d: float = float(parcel["depth_m"]) - 4.0
	var hw: float = w * .5
	var hd: float = d * .5
	var style: String = str(parcel.get("style", "stone"))
	if style == "auto":
		var rng := RandomNumberGenerator.new()
		rng.seed = world_seed ^ (int(str(parcel["id"]).hash()) << 1)
		style = STYLES[rng.randi_range(0,STYLES.size()-1)]
	var wall: String = "city_wall_battlement_2m" if style == "battlement" else "city_wall_" + style + "_2m"
	var material: String = "stone" if style == "battlement" else style
	var result: Array[Dictionary] = []
	var positions: Array[float] = []
	var steps: int = int(w / 2.0) - 2
	for i in range(steps): positions.append(-hw + 3.0 + float(i) * 2.0)
	# 3 celulas contiguas (6 metros), sem ocupar o eixo do portao.
	var gate_center_i: int = int(positions.size() / 2)
	var gate_x: float = positions[gate_center_i]
	for x in positions:
		result.append(_slot(wall, x, -hd + 1.0, 0))
		if absf(x - gate_x) > 2.01:
			result.append(_slot(wall, x, hd - 1.0, 0))
	result.append(_slot("gate_" + material + "_6m", gate_x, hd - 1.0, 0))
	if bool(parcel.get("back_gate", false)):
		var filtered: Array[Dictionary] = []
		for r in result:
			if str(r["asset"]) == wall and absf(float(r["pos"][2]) + hd - 1.0) <= .01 and absf(float(r["pos"][0]) - gate_x) <= 2.01:
				continue
			filtered.append(r)
		result = filtered
		result.append(_slot("gate_" + material + "_6m", gate_x, -hd + 1.0, 2))
	var step_z: int = int(d / 2.0) - 2
	for i in range(step_z):
		var z: float = -hd + 3.0 + float(i) * 2.0
		result.append(_slot(wall, -hw + 1.0, z, 1))
		result.append(_slot(wall, hw - 1.0, z, 1))
	for x in [-hw + 1.0, hw - 1.0]:
		for z in [-hd + 1.0, hd - 1.0]:
			result.append(_slot("wall_corner_" + material, x, z, 0))
	if bool(parcel.get("towers", true)):
		for x in [-hw + 3.0, hw - 3.0]:
			for z in [-hd + 3.0, hd - 3.0]:
				result.append(_slot("watchtower_" + material + "_4m", x, z, 0))
	if result.size() > MAX_SLOTS: return fail("too_many_segments")
	var seed: int = world_seed
	var saved_parcel: Dictionary = parcel.duplicate(true)
	return {"ok": true, "plan": {"schema_version": SCHEMA_VERSION, "kind": "exo_fortification",
		"site_id": str(parcel["id"]), "world_seed": seed, "style": style,
		"origin_world": [float(parcel["center_x"]), float(parcel["ground_y"]), float(parcel["center_z"])],
		"yaw_quadrants": int(parcel.get("yaw_quadrants", 0)), "outer_dimensions_m": [float(parcel["width_m"]), float(parcel["depth_m"])],
		"gate_local": [gate_x, 0.0, hd - 1.0], "approach_local": [gate_x, 0.0, hd + 1.0],
		"inner_local": [gate_x, 0.0, hd - 4.0], "segments": result,
		"source_parcel": saved_parcel, "signature": str(seed, ":", parcel["id"], ":", style, ":", int(w), "x", int(d))}}

static func compatible(plan: Dictionary) -> bool:
	if int(plan.get("schema_version", -1)) != SCHEMA_VERSION or str(plan.get("kind", "")) != "exo_fortification": return false
	if not (plan.get("source_parcel", null) is Dictionary) or typeof(plan.get("world_seed", null)) != TYPE_INT: return false
	var expected: Dictionary = plan_fort(int(plan["world_seed"]), plan["source_parcel"])
	return bool(expected.get("ok", false)) and expected["plan"] == plan
