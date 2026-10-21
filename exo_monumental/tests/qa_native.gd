extends SceneTree
## COMANDO: godot --headless --editor --import; godot --headless -s res://exo_monumental/tests/qa_native.gd
## Executar em projeto LAB extraído OU cópia do módulo em projeto real EXO Core.
## QA real Godot preparado, NÃO executado neste ambiente (binário ausente).
const Planner = preload("res://exo_monumental/generation/planner.gd")
const Builder = preload("res://exo_monumental/runtime/builder.gd")
const Bridge = preload("res://exo_monumental/integration/dungeon_bridge.gd")
const Adapter = preload("res://exo_monumental/integration/exo_adapter.gd")
const Interiors = preload("res://exo_monumental/integration/interior_bridge.gd")
const Interior = preload("res://exo_monumental/scenes/hall_interior.tscn")
var checks: int = 0
var errors: Array = []

func _initialize() -> void:
	call_deferred("_run")

func _assert(ok: bool, description: String) -> void:
	checks += 1
	if not ok: errors.append(description)

func _request(kind: String, site: String, quadrant: int = 0) -> Dictionary:
	var size: Dictionary = Planner.footprint(kind)
	return {"world_id": "qa", "region_id": 26, "site_id": site, "kind": kind,
		"origin_world": [0.0, 0.0, 0.0], "yaw_quadrants": quadrant,
		"school_id": "exo_martial.school.seita_bambu",
		"site_width_m": Planner.footprint(kind, quadrant).get("required_site_width_m", 0.0) + 2,
		"site_depth_m": Planner.footprint(kind, quadrant).get("required_site_depth_m", 0.0) + 2,
		"approach_clear": true, "roads_clear": true, "rivers_clear": true,
		"walls_clear": true, "buildings_clear": true, "navigation_clear": true,
		"fluvial_gates_clear": true, "dungeon_entrances_clear": true, "terrain_clear": true,
		"terrain_corner_heights": [0.0, 0.0, 0.0, 0.0]}

func _run() -> void:
	var models: Array[String] = ["martial_medium", "martial_grand", "dungeon_school_ruin", "dungeon_cavern", "dungeon_tomb", "dungeon_fortress", "dungeon_hidden_temple", "dungeon_abyss", "temple_monumental", "fortress", "ancestral_ruins"]
	for kind in models:
		for seed_value in [101, 816204, 707, 18026]:
			var req: Dictionary = _request(kind, "stable_" + kind)
			var first: Dictionary = Planner.plan(seed_value, req)
			var second: Dictionary = Planner.plan(seed_value, req)
			_assert(bool(first.get("ok", false)), "plan_reject_" + kind)
			_assert(JSON.stringify(first) == JSON.stringify(second), "not_deterministic_" + kind)
			if not first.get("ok", false): continue
			var block: Dictionary = Planner.plan(seed_value, req, [first["bounds"]])
			_assert(not bool(block.get("ok", false)) and str(block.get("code", "")) == "reservation_conflict_occupied", "did_not_reject_overlap_" + kind)
			if kind.begins_with("dungeon_"):
				var d: Dictionary = Bridge.descriptor_from_plan(first)
				_assert(bool(d.get("ok", false)), "missing_dungeon_descriptor_" + kind)
	var area_test: Dictionary = _request("martial_medium", "area_test", 1)
	area_test["terrain_corner_heights"][2] = 2.5
	_assert(Planner.plan(101, area_test).get("code", "") == "requires_preexisting_terrace", "uneven_ground_accepted")
	var clear_req: Dictionary = _request("martial_medium", "road_conflict")
	clear_req["roads_clear"] = false
	_assert(Planner.plan(101, clear_req).get("code", "") == "not_verified_roads_clear", "road_conflict_accepted")
	for kind in models:
		for quadrant in [0, 1, 2, 3]:
			var rotated_req: Dictionary = _request(kind, "rotate_"+kind+"_"+str(quadrant), quadrant)
			var rotated_plan: Dictionary = Planner.plan(101, rotated_req)
			_assert(bool(rotated_plan.get("ok", false)), "rotated_reject_"+kind+"_"+str(quadrant))
			if bool(rotated_plan.get("ok", false)):
				_assert(rotated_plan["stations"].size() > 0, "stations_missing_"+kind)
	var orientation_probe: Dictionary = {"origin_world":[100.0,0.0,200.0],"yaw_quadrants":1}
	_assert(Adapter.local_to_world(orientation_probe,[2,0,5]).distance_to(Vector3(105,0,198)) < .001, "rotation_godot_y_90_inconsistent")
	orientation_probe["yaw_quadrants"] = 3
	_assert(Adapter.local_to_world(orientation_probe,[2,0,5]).distance_to(Vector3(95,0,202)) < .001, "rotation_godot_y_270_inconsistent")
	for flag in ["fluvial_gates_clear", "dungeon_entrances_clear", "terrain_clear", "rivers_clear", "roads_clear"]:
		var blocked: Dictionary = _request("martial_medium", "block_" + flag)
		blocked[flag] = false
		_assert(Planner.plan(101,blocked).get("code","") == "not_verified_" + flag, "unsafe_feature_accepted_"+flag)
	var parent: Node3D = Node3D.new(); root.add_child(parent)
	for kind in models:
		var a: Dictionary = Planner.plan(101, _request(kind, "build_" + kind))
		if not bool(a.get("ok", false)): continue
		var b: Dictionary = Builder.build(parent, a, {})
		_assert(not bool(b.get("ok", false)), "builder_must_not_run_without_reservation")
		var receipt: Dictionary = {"approved":true,"plan_id":a["id"],"site_id":a["site_id"],"bounds":a["bounds"].duplicate(true),"reservation_id":"qa-native","authority":"QA_LAB_ONLY","isolated_lab_only":true}
		b = Builder.build(parent, a, receipt)
		_assert(bool(b.get("ok", false)), "builder_failed_" + kind + "_" + str(b.get("code", "")))
		var invalid_receipt: Dictionary = receipt.duplicate(true)
		invalid_receipt["plan_id"] = "wrong-site"
		_assert(not bool(Builder.build(parent, a, invalid_receipt).get("ok", false)), "foreign_receipt_accepted_"+kind)
		if kind.begins_with("martial_"):
			_assert(bool(Interiors.from_plan(a).get("ok", false)), "martial_interior_missing_"+kind)
		if bool(b.get("ok", false)):
			_assert((b["node"] as Node3D).get_meta("exo_monument_id", "") == a["id"], "wrong_site_id_" + kind)
			_assert((b["node"] as Node3D).find_child("entrance_anchor", true, false) != null, "missing_entrance_anchor_"+kind)
			if kind.begins_with("martial_"):
				_assert((b["node"] as Node3D).find_child("master_station", true, false) != null, "missing_master_station_"+kind)
			(b["node"] as Node3D).free()
	for label in ["martial_hall", "grand_hall", "temple_sanctum", "fortress_command", "ruin_remains"]:
		var interior: Node3D = Interior.instantiate()
		interior.set("interior_id", label)
		root.add_child(interior)
		_assert(interior.find_child("InteriorReturn", true, false) != null, "no_return_marker_" + label)
		_assert(interior.find_child("MasterDais", true, false) != null, "no_dais_" + label)
		interior.free()
	parent.free()
	var output: Dictionary = {"type": "GodotNative", "checks": checks, "failures": errors, "status": "PASS" if errors.is_empty() else "FAIL"}
	print("EXO_MONUMENTAL_NATIVE_QA ", JSON.stringify(output))
	quit(0 if errors.is_empty() else 1)
