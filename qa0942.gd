extends SceneTree
# Godot: --headless --path . --script res://qa0942.gd
const Seed=preload("res://procedural/world_state.gd")
const Plan=preload("res://world/biome_plan.gd")
var errors: Array[String]=[]
func check(ok: bool,label: String) -> void:
	if not ok:errors.append(label)
func _initialize() -> void:
	var unique: Dictionary={}
	var kinds: Dictionary={}
	var patterns: Dictionary={}
	for seed_value in range(600):
		var world_data: Dictionary=Seed.create(seed_value,"world_test_0942")
		world_data.landscape_version=2
		var a: Dictionary=Plan.create(world_data)
		var b: Dictionary=Plan.create(world_data.duplicate(true))
		check(Plan.safe_layout(a),"Invalid layout "+str(seed_value))
		check(a==b,"Layout changed after same seed "+str(seed_value))
		check(a.version==2,"Wrong generation version")
		var signature: String=JSON.stringify({"sites":a.sites,"homes":a.houses,"pattern":a.pattern})
		unique[signature]=true
		kinds[a.kind]=true
		patterns[a.pattern]=true
		var expected: int=2 if a.kind=="empobrecida" else 4 if a.kind=="comum" else 8 if a.kind=="prospera" else 6
		check(a.houses.size()==expected,"Incorrect house count "+str(seed_value))
		for role in ["guild","inn","training"]:
			check(a.sites.has(role),"Missing service "+role)
		for role in ["npc","bed","mat","camp","board"]:
			check(a.anchors.has(role),"Missing anchor "+role)
	check(unique.size()>400,"Village arrangement lacks seed diversity")
	check(kinds.size()==4,"One or more birthplace tiers missing")
	check(patterns.size()==4,"One or more road templates missing")
	var legacy: Dictionary=Seed.create(6412,"world_legacy_094")
	legacy.landscape_version=1
	check(Plan.create(legacy).version==1,"Legacy world layout changed")
	if errors.is_empty():
		print("QA0942 PASS: 600 seeds, 4 profiles, 4 street patterns, legacy layout retained")
	else:
		for msg in errors:push_error(msg)
	quit(0 if errors.is_empty() else 1)
