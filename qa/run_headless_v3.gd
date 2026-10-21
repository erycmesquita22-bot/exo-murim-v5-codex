extends SceneTree
## Rodar apos importar os GLB: godot --headless --path . --script res://qa/run_headless_v3.gd
const Fort = preload("res://forja/fortification_planner.gd")
const FortBuilder = preload("res://forja/fortification_builder.gd")
const Civic = preload("res://forja/civic_planner.gd")
const CivicBuilder = preload("res://forja/civic_builder.gd")
const Kit = preload("res://godot/modular_kit.gd")
const Compound = preload("res://forja/compound_assembler.gd")
const Green = preload("res://forja/green_buffer_v3.gd")
const Adapter = preload("res://forja/genesis_adapter_v3.gd")
var passed: int = 0
var failed: Array[String] = []
func _initialize() -> void: call_deferred("run_tests")
func verify(ok: bool, title: String) -> void:
	if ok: passed += 1
	else:
		failed.append(title)
		push_error("FORJA03_TEST " + title)
func parcel(id: String, role: String, yaw: int = 0) -> Dictionary:
	return {"id":id,"center_x":0.0,"center_z":0.0,"ground_y":0.0,
		"width_m":32.0,"depth_m":36.0,"yaw_quadrants":yaw,
		"terrain_samples_y":[0.0,0.0,0.0,0.0],"approach_clear":true,
		"role":role,"style":"stone","detail_profile":"medium"}
func run_tests() -> void:
	var roles: Array[String] = Civic.ROLES
	for seed in range(800):
		for role in roles:
			var p: Dictionary = parcel("site_%d_%s" % [seed,role],role,seed%4)
			var a: Dictionary = Civic.plan_civic(seed,p)
			var b: Dictionary = Civic.plan_civic(seed,p)
			verify(a["ok"] and a==b,"repeat_civic_"+str(seed)+role)
			if a["ok"]:verify(Civic.compatible(a["plan"]),"compatible_civic_"+str(seed)+role)
	for seed in range(800):
		var p: Dictionary = parcel("wall_%d" % seed,"",seed%4)
		p["style"] = Fort.STYLES[seed%3]
		p["back_gate"] = seed%2==0
		var a: Dictionary = Fort.plan_fort(seed,p)
		var b: Dictionary = Fort.plan_fort(seed,p)
		verify(a["ok"] and a==b,"repeat_wall_"+str(seed))
		if a["ok"]:verify(Fort.compatible(a["plan"]),"compatible_wall_"+str(seed))
	var negatives: Array[String] = ["approach_clear","width_m","terrain_samples_y","yaw_quadrants","style"]
	var f: Dictionary = parcel("reject_f","",0)
	for k in negatives:
		var bad: Dictionary = f.duplicate(true)
		match k:
			"approach_clear":bad[k]=false
			"width_m":bad[k]=23.0
			"terrain_samples_y":bad[k]=[0.0,0.0,.5,0.0]
			"yaw_quadrants":bad[k]=7
			"style":bad[k]="glass"
		verify(not Fort.plan_fort(1,bad)["ok"],"bad_fort_"+k)
	var c: Dictionary = parcel("reject_c","sect_hall")
	for k in ["approach_clear","width_m","role","terrain_samples_y","detail_profile"]:
		var bad: Dictionary = c.duplicate(true)
		match k:
			"approach_clear":bad[k]=false
			"width_m":bad[k]=10.0
			"role":bad[k]="dragon_palace"
			"terrain_samples_y":bad[k]=[0.0,.4,0.0,0.0]
			"detail_profile":bad[k]="ultra"
		verify(not Civic.plan_civic(1,bad)["ok"],"bad_civic_"+k)
	var root3d := Node3D.new()
	root.add_child(root3d)
	for role in roles:
		var p: Dictionary = Civic.plan_civic(212,parcel("built_"+role,role))
		verify(p["ok"],"plan_real_"+role)
		if p["ok"]:
			var built: Dictionary = CivicBuilder.build(root3d,p["plan"])
			verify(bool(built.get("ok",false)),"build_real_"+role)
			if built["ok"]:
				verify(built["node"].has_node("AnchorEntrance") and built["node"].has_node("AnchorNPC"),"anchors_"+role)
				built["node"].free()
	for style in Fort.STYLES:
		var lot: Dictionary = parcel("fort_"+style,"")
		lot["style"] = style
		var p: Dictionary = Fort.plan_fort(213,lot)
		verify(p["ok"],"plan_wall_"+style)
		if p["ok"]:
			var built: Dictionary = FortBuilder.build(root3d,p["plan"])
			verify(bool(built.get("ok",false)),"built_wall_"+style)
			if built["ok"]:
				verify(built["node"].has_node("AnchorGate") and built["node"].has_node("AnchorInside"),"anchors_wall_"+style)
				built["node"].free()
	var tampered: Dictionary = Civic.plan_civic(42,parcel("tamper","sect_hall"))["plan"].duplicate(true)
	tampered["pieces"][0]["local_pos"][2] = 1000.0
	verify(not Civic.compatible(tampered),"reject_changed_civic")
	var wall: Dictionary = Fort.plan_fort(42,parcel("tamper_wall",""))["plan"].duplicate(true)
	wall["segments"][0]["pos"][0] = 1000.0
	verify(not Fort.compatible(wall),"reject_changed_wall")
	# Composite and green strip are separate workflows; validate both before publishing.
	var cp: Dictionary = parcel("compound_headless","sect_hall")
	cp["style"] = "auto"
	var packed: Dictionary = Compound.plan_compound(12,cp)
	verify(packed["ok"],"compound_plan")
	if packed["ok"]:
		var combo: Dictionary = Compound.build_compound(root3d,packed)
		verify(bool(combo.get("ok",false)),"compound_build")
		if combo["ok"]:combo["node"].free()
	for seed in range(400):
		var greenlot: Dictionary = parcel("green_"+str(seed),"")
		greenlot["road_clear"] = true
		greenlot["density"] = .75
		greenlot["biome"] = ["mixed","bamboo","pine","orchard"][seed%4]
		var pa: Dictionary = Green.plan(seed,greenlot)
		var pb: Dictionary = Green.plan(seed,greenlot)
		verify(pa["ok"] and pa==pb,"roadside_determinism_"+str(seed))
		if pa["ok"]:
			verify(Green.compatible(pa["plan"]),"roadside_compatible_"+str(seed))
			for item in pa["plan"]["entries"]:
				verify(absf(float(item["local_pos"][0]))>4.0,"roadside_corridor_"+str(seed))
	var gp: Dictionary = parcel("green_real","")
	gp["road_clear"] = true
	gp["density"] = 1.0
	var real: Dictionary = Green.plan(123,gp)
	if real["ok"]:
		var built_green: Dictionary = Green.build(root3d,real)
		verify(built_green["ok"],"roadside_instantiates")
		if built_green["ok"]:built_green["node"].free()
	var allsites: Array = []
	var at0: Dictionary = parcel("site_0","sect_hall")
	at0["center_x"] = -60.0
	var at1: Dictionary = parcel("site_1","temple")
	at1["center_x"] = 0.0
	var at2: Dictionary = parcel("site_2","")
	at2["center_x"] = 60.0
	at2["road_clear"] = true
	allsites.append({"kind":"compound","parcel":at0})
	allsites.append({"kind":"civic","parcel":at1})
	allsites.append({"kind":"green","parcel":at2})
	var planned_sites: Dictionary = Adapter.plan_sites(565,allsites)
	verify(planned_sites["ok"] and planned_sites.get("count",0)==3,"adapter_three_plans")
	if planned_sites["ok"]:
		var all_built: Dictionary = Adapter.build_sites(root3d,planned_sites)
		verify(all_built["ok"] and all_built.get("count",0)==3,"adapter_three_builds")
		if all_built["ok"]:
			for item in all_built["nodes"]: item.free()
		var modified: Dictionary = planned_sites.duplicate(true)
		modified["blueprints"][0]["blueprint"]["civic"]["pieces"][0]["local_pos"][0]=123.0
		verify(not Adapter.build_sites(root3d,modified)["ok"],"reject_adapter_modified_blueprint")
	var overlapping: Array = allsites.duplicate(true)
	overlapping[2]["parcel"]["center_x"] = 0.0
	verify(not Adapter.plan_sites(565,overlapping)["ok"],"reject_adapter_overlap")
	var repeated: Array = allsites.duplicate(true)
	repeated[2]["parcel"]["id"] = "site_0"
	verify(not Adapter.plan_sites(565,repeated)["ok"],"reject_adapter_duplicate_id")
	var output: Dictionary = {"passed":passed,"failed":failed,"engine":Engine.get_version_info().get("string", ""),"civic_roles":roles.size(),"new_assets":42}
	var file := FileAccess.open("res://qa/last_headless_result_v3.json",FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(output,"  "))
		file.close()
	print("FORJA03_FINAL ",JSON.stringify(output))
	quit(0 if failed.is_empty() else 1)
