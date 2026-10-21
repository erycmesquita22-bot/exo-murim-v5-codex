extends SceneTree
## REQUER Godot 4.7.2. Importar GLBs primeiro usando --editor --import.
const Planner = preload("res://forja/forja_planner.gd")
const Builder = preload("res://forja/forja_builder.gd")
const Kit = preload("res://godot/modular_kit.gd")
const Plaza = preload("res://forja/plaza_furnisher.gd")
var passed: int = 0
var failed: Array = []
var sampled_lots: int = 0
var built_houses: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed.append(label)
		push_error("FORJA_QA " + label)

func _lot(id: String, x: float, z: float, district: String = "village", role: String = "auto", profile: String = "medium") -> Dictionary:
	return {"id":id, "center_x":x, "center_z":z, "ground_y":0.0,
		"width_m":13.0, "depth_m":20.0, "yaw_quadrants":0,
		"district":district, "role":role, "max_stories":2,
		"detail_profile":profile,
		"terrain_samples_y":[0.0,0.0,0.0,0.0], "approach_clear":true}

func _check_plan(p: Dictionary, id: String) -> void:
	_check(p["schema_version"] == 2 and p["width_m"] in [4,6,8] and p["stories"] in [1,2],id+"_schema")
	_check(p["archetype"] in Planner.ARCHETYPES and p["detail_profile"] in Planner.DETAIL_PROFILES,id+"_archetype")
	var footprint: Array = p["footprint_local_xz"]
	var access: Array = p["access_local_xz"]
	var dims: Array = p["lot_dimensions_m"]
	_check(footprint[0] >= -float(dims[0])*0.5-0.0001 and footprint[2] <= float(dims[0])*0.5+0.0001,id+"_width")
	_check(access[3] <= float(dims[1])*0.5+0.0001 and footprint[1] >= -float(dims[1])*0.5-0.0001,id+"_depth")
	_check(p["entrance_local"][0] == p["approach_local"][0],id+"_access_aligned")
	_check(Builder.is_plan_compatible(p),id+"_builder_accepts")
	if p["archetype"] == "courtyard":
		_check(p["width_m"] == 6 and float(p["approach_local"][2]) >= 8.5,id+"_courtyard")

func _run() -> void:
	var roles: Array = ["dwelling", "shop", "tea_house", "workshop", "herbalist", "inn", "auto"]
	var profiles: Array = ["low", "medium", "high"]
	for seed in range(1000):
		for n in range(12):
			var id: String = "seed_%d_%d" % [seed,n]
			var l: Dictionary = _lot(id,float(n*25),float((n%2)*27),"city" if n%2 == 0 else "village",str(roles[n%roles.size()]),str(profiles[n%profiles.size()]))
			l["yaw_quadrants"] = n%4
			var a: Dictionary = Planner.plan_lot(seed,l)
			var b: Dictionary = Planner.plan_lot(seed,l)
			_check(a == b,id+"_determinism")
			_check(a["ok"] and b["ok"],id+"_valid")
			if a["ok"]: _check_plan(a["plan"],id)
			sampled_lots += 1
	var rejects: Array = []
	var t: Dictionary = _lot("broken",0,0)
	t["width_m"] = 4.0
	rejects.append(t)
	t = _lot("broken",0,0);t["approach_clear"] = false; rejects.append(t)
	t = _lot("broken",0,0);t["terrain_samples_y"] = [0.0,0.0,0.24,0.0];rejects.append(t)
	t = _lot("broken",0,0);t.erase("terrain_samples_y");rejects.append(t)
	t = _lot("broken",0,0);t["terrain_samples_y"] = [0.0,0.0];t["flat_verified"] = true;rejects.append(t)
	t = _lot("broken",0,0);t["role"] = "temple";rejects.append(t)
	t = _lot("broken",0,0);t["detail_profile"] = "cinematic";rejects.append(t)
	t = _lot("broken",0,0);t["yaw_quadrants"] = 1.5;rejects.append(t)
	t = _lot("broken",0,0);t["depth_m"] = 10.0;rejects.append(t)
	t = _lot("broken",0,0);t["id"] = "";rejects.append(t)
	t = _lot("broken",0,0);t["max_stories"] = 1;t["role"] = "inn";rejects.append(t)
	t = _lot("broken",0,0);t["preferred_stories"] = 1;t["role"] = "inn";rejects.append(t)
	t = _lot("broken",0,0);t["width_m"] = INF;rejects.append(t)
	t = _lot("broken",0,0);t["ground_y"] = NAN;rejects.append(t)
	for i in range(rejects.size()):
		_check(not Planner.plan_lot(151,rejects[i])["ok"],"reject_%d" % i)
	var lots: Array = []
	for i in range(32): lots.append(_lot("complete_%02d" % i,float(i*25),0.0))
	var batch: Dictionary = Planner.plan_settlement(99,lots,true)
	_check(batch["ok"] and batch["plans"].size() == 32,"batch_capacity_32")
	lots.append(_lot("overflow",900.0,0.0))
	_check(not Planner.plan_settlement(99,lots,true)["ok"],"reject_33")
	lots.pop_back()
	var reversed_lots: Array = lots.duplicate(true)
	reversed_lots.reverse()
	var reversed_batch: Dictionary = Planner.plan_settlement(99,reversed_lots,true)
	var signs: Dictionary = {}
	for p in batch["plans"]: signs[p["lot_id"]] = p["signature"]
	for p in reversed_batch["plans"]:
		_check(p["signature"] == signs[p["lot_id"]],"independent_order_"+str(p["lot_id"]))
	var overlapping: Array = [_lot("sameplace1",0,0),_lot("sameplace2",0,0)]
	var rejected: Dictionary = Planner.plan_settlement(15,overlapping,true)
	_check(not rejected["ok"] and rejected["plans"].is_empty(),"atomic_reject_overlap")
	var duplicated: Array = [_lot("duplicate",0,0),_lot("duplicate",30,0)]
	rejected = Planner.plan_settlement(15,duplicated,true)
	_check(not rejected["ok"] and rejected["plans"].is_empty(),"atomic_reject_duplicate")
	# Teste de instanciação real: seis funções, três perfis, yaw 0..3.
	var parent := Node3D.new()
	root.add_child(parent)
	for j in range(6):
		var lot: Dictionary = _lot("built_%d" % j,float(j*25),float((j%2)*27),"city",str(roles[j]),str(profiles[j%3]))
		lot["yaw_quadrants"] = j%4
		var p: Dictionary = Planner.plan_lot(4567,lot)
		_check(p["ok"],"actual_plan_%d" % j)
		if p["ok"]:
			var built: Dictionary = Builder.build_one(parent,p["plan"])
			_check(built["ok"],"build_real_%d" % j)
			if built["ok"]:
				var house: Node3D = built["node"]
				built_houses += 1
				_check(house.has_node("AnchorEntrance") and house.has_node("AnchorGate") and house.has_node("AnchorApproach") and house.has_node("AnchorNPC"),"anchors_%d" % j)
				_check(house.has_node("ForjaDetails") and house.get_meta("forja_detail_count", -1) >= 1,"decor_present_%d" % j)
				_check(house.get_meta("forja_plan",{}).get("signature","") == p["plan"]["signature"],"meta_%d" % j)
				house.free()
	# Determinação/custo de batch de 4 casas.
	var sample_batch: Array = []
	for k in range(4): sample_batch.append(_lot("settle_%d" % k,float(k*25),10.0,"village",str(roles[k]),"low"))
	var four: Dictionary = Planner.plan_settlement(58,sample_batch,true)
	var result: Dictionary = Builder.build_batch(parent,four)
	_check(result["ok"] and result.get("count",0) == 4,"batch_four_real")
	if result["ok"]:
		built_houses += 4
		for node in result["nodes"]: node.free()
	var empty_attempt: Dictionary = Builder.build_batch(parent,rejected)
	_check(not empty_attempt["ok"] and empty_attempt["nodes"].is_empty(),"reject_batch_no_side_effect")
	var valid_plan: Dictionary = Planner.plan_lot(4567,_lot("tampered",0.0,0.0))["plan"]
	var forged: Dictionary = valid_plan.duplicate(true)
	forged["footprint_local_xz"][3] = 999.0
	_check(not Builder.is_plan_compatible(forged),"reject_tampered_footprint")
	forged = valid_plan.duplicate(true)
	forged["archetype"] = "courtyard"
	_check(not Builder.is_plan_compatible(forged),"reject_tampered_archetype")
	forged = valid_plan.duplicate(true)
	forged["detail_profile"] = "cinematic"
	_check(not Builder.is_plan_compatible(forged),"reject_tampered_profile")
	var plaza_input: Dictionary = {"id":"headless_plaza","center_x":0.0,"center_z":0.0,"ground_y":0.0,
		"width_m":22.0,"depth_m":18.0,"yaw_quadrants":0,"role":"market_square",
		"terrain_samples_y":[0.0,0.0,0.0,0.0],"approach_clear":true}
	for n in range(1000):
		var pl_a: Dictionary = Plaza.plan_plaza(n,plaza_input)
		var pl_b: Dictionary = Plaza.plan_plaza(n,plaza_input)
		_check(pl_a == pl_b and pl_a["ok"],"plaza_determinism_%d" % n)
		if pl_a["ok"]:
			var objects: Array = pl_a["plan"]["furnishings"]
			_check(objects.size()==6,"plaza_six_slots_%d" % n)
			for item in objects:
				_check(absf(float(item["local_pos"][0]))>4.0,"plaza_corridor_free_%d" % n)
	var plaza_plan: Dictionary = Plaza.plan_plaza(443,plaza_input)
	var built_plaza: Dictionary = Plaza.build_plaza(parent,plaza_plan)
	_check(built_plaza["ok"] and built_plaza.get("count",0)==6,"plaza_six_real_props")
	if built_plaza["ok"]:
		_check(built_plaza["node"].has_node("AnchorPlazaCenter") and built_plaza["node"].has_node("AnchorRoadNorth"),"plaza_anchors")
		built_plaza["node"].free()
	var modified_plaza: Dictionary = plaza_plan.duplicate(true)
	modified_plaza["plan"]["furnishings"][1]["local_pos"][0] = 0.0
	_check(not Plaza.build_plaza(parent,modified_plaza)["ok"],"reject_tampered_plaza_slot")
	var hamlet_input: Dictionary = plaza_input.duplicate(true)
	hamlet_input["role"] = "hamlet_square"
	var hamlet_plan: Dictionary = Plaza.plan_plaza(443,hamlet_input)
	_check(hamlet_plan["ok"] and hamlet_plan["plan"]["furnishings"][3]["asset"] == "public_timber_bench","hamlet_vs_market_distinct")
	plaza_input["terrain_samples_y"] = [0.0,0.5,0.0,0.0]
	_check(not Plaza.plan_plaza(443,plaza_input)["ok"],"reject_uneven_plaza")
	var summary := {"passed":passed,"failed":failed.size(),"failed_cases":failed,
		"sampled_lots":sampled_lots,"instantiated_buildings":built_houses,
		"engine":Engine.get_version_info().get("string", ""),"schema_version":2}
	var f := FileAccess.open("res://qa/last_headless_result_v2.json",FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(summary,"  "))
		f.close()
	print("FORJA_QA_V2_FINAL ",JSON.stringify(summary))
	quit(0 if failed.is_empty() else 1)
