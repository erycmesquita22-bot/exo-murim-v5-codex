extends SceneTree
## EXO Settlement Genesis 05 — engine-native synthetic geometry stress.
## Intended command (Godot 4.6.2): godot --headless --path . --script res://tests/settlement_extreme.gd -- 10000
## No assertions of engine execution until a real Godot log exists.
const Settlement = preload("res://genesis/settlements/settlement_planner.gd")
const SCALES = ["village", "town", "city"]
const BIOMES = ["grassland", "temperate_forest", "bamboo_forest", "dry_valley", "wetland", "rocky_highlands", "alpine", "mixed_woodland"]

class SyntheticTerrain:
	extends RefCounted
	var amplitude: float = 4.0
	var phase: float = 0.0
	var roughness: float = 1.0
	func height_at(p: Vector2) -> float:
		var h := 8.0 + amplitude * (0.68 * sin((p.x + phase) * 0.012 * roughness) * cos((p.y - phase) * 0.013 * roughness) + 0.32 * cos(p.x * 0.026 * roughness + phase) * sin(p.y * 0.018 * roughness + phase))
		if amplitude > 10.0:
			h += amplitude * exp(-pow((p.x - 148.48) / 45.0, 2.0)) * (0.7 + 0.3 * sin(p.y * 0.015))
		return h

static func random_border_point(rng: RandomNumberGenerator) -> Vector2:
	var axis := rng.randi_range(0, 1)
	var signum := -1.0 if rng.randi_range(0, 1) == 0 else 1.0
	var offset := rng.randf_range(-148.0, 148.0)
	return Vector2(254.0 * signum, offset) if axis == 0 else Vector2(offset, 254.0 * signum)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var count := clampi(int(args[0]), 1, 100000) if not args.is_empty() else 1000
	var summary := {"suite":"settlement_extreme_v05", "engine":Engine.get_version_info(), "cases":count, "ready":0, "explicit_invalid":0, "ready_by_scale":{}, "invalid_by_scale":{}, "reasons":{}, "validated_lots":0, "hard_failure_count":0, "first_hard_failures":[], "first_rejections":[]}
	var start := Time.get_ticks_msec()
	for i in range(count):
		var rng := RandomNumberGenerator.new()
		rng.seed = int(i) * 7919 + 198617
		var scale: String = SCALES[i % 3]
		var gates: Array = []
		for k in range(rng.randi_range(1, 4)):
			gates.append({"p":random_border_point(rng)})
		var rivers: Array = []
		for k in range(rng.randi_range(0, 3)):
			rivers.append({"p":random_border_point(rng)})
		var landscape := SyntheticTerrain.new()
		var biome: String = BIOMES[i % BIOMES.size()]
		landscape.amplitude = 52.0 if biome == "alpine" else 32.0 if biome == "rocky_highlands" else 4.0
		landscape.phase = rng.randf_range(-100.0, 100.0)
		if i % 11 == 0:
			landscape.amplitude = 0.0
		elif i % 11 == 1:
			landscape.amplitude = 52.0
		elif i % 11 == 2:
			landscape.amplitude = 30.0
		var spec := {"kind":"settlement", "id":i % 88, "region_seed":str(1000003 + i * 7919), "settlement_scale":scale}
		var plan_data: Dictionary = Settlement.plan(spec, gates, rivers, 256.0, Callable(landscape, "height_at"))
		if plan_data.get("status", "") != "ready":
			summary["explicit_invalid"] += 1
			summary["invalid_by_scale"][scale] = int(summary["invalid_by_scale"].get(scale, 0)) + 1
			for reason in plan_data.get("errors", []):
				summary["reasons"][str(reason).split(":")[0]] = int(summary["reasons"].get(str(reason).split(":")[0], 0)) + 1
			if summary["first_rejections"].size() < 20:
				summary["first_rejections"].append({"i":i, "seed":spec.region_seed, "scale":scale, "errors":plan_data.get("errors", [])})
			continue
		var issues: Array = Settlement.validate(plan_data, gates, rivers, 256.0)
		if plan_data["lots"].size() != int(plan_data["target"]):
			issues.append("silently_dropped_lots")
		if plan_data.get("fixtures", []).size() != 1:
			issues.append("missing_well")
		var contract: Dictionary = Settlement.export_contract(plan_data)
		var encoded := JSON.stringify(contract)
		var decoded = JSON.parse_string(encoded)
		if not (decoded is Dictionary) or decoded["lots"].size() != plan_data["lots"].size():
			issues.append("json_roundtrip")
		if i % 97 == 0:
			var rerun: Dictionary = Settlement.plan(spec, gates, rivers, 256.0, Callable(landscape, "height_at"))
			if JSON.stringify(Settlement.export_contract(rerun)) != encoded:
				issues.append("nondeterministic")
		if not issues.is_empty():
			summary["hard_failure_count"] += 1
			if summary["first_hard_failures"].size() < 20:
				summary["first_hard_failures"].append({"i":i, "seed":spec.region_seed, "scale":scale, "errors":issues})
		else:
			summary["ready"] += 1
			summary["validated_lots"] += plan_data["lots"].size()
			summary["ready_by_scale"][scale] = int(summary["ready_by_scale"].get(scale, 0)) + 1
	summary["elapsed_ms"] = Time.get_ticks_msec() - start
	print("SETTLEMENT_EXTREME_RESULT=" + JSON.stringify(summary))
	quit(0 if int(summary["hard_failure_count"]) == 0 else 1)
