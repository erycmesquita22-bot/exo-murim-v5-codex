extends SceneTree
# Runtime scene test: --headless --path . --script res://qa0942_playable.gd
const Seed=preload("res://procedural/world_state.gd")
var failures: Array[String]=[]
func expect(ok: bool,label: String) -> void:
	if not ok:failures.append(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var scene: PackedScene=load("res://main.tscn")
	var game: Node3D=scene.instantiate()
	game.load_on_start=false
	game.save_path="user://qa0942_readonly_test.json"
	root.add_child(game)
	var worlds: Array=[]
	for seed_value in [101,202,303,404]:
		game.journey.data.world=Seed.create(seed_value,"world_test_0942")
		game.journey.data.world.landscape_version=2
		game.rebuild_region()
		var layout: Dictionary=game.get_meta("landscape_plan",{})
		var anchors: Dictionary=game.get_meta("village_services",{})
		expect(layout.get("version",0)==2,"Incorrect world version")
		expect(anchors.has("npc") and anchors.has("bed") and anchors.has("mat"),"Missing service anchors")
		expect(game.npc.position.distance_to(anchors.get("npc",Vector3.ZERO))<.01,"Guild NPC not placed at generated position")
		expect(game.flow.BED.distance_to(anchors.get("bed",Vector3.ZERO))<.01,"Bed interaction disconnected")
		expect(game.flow.MAT.distance_to(anchors.get("mat",Vector3.ZERO))<.01,"Meditation interaction disconnected")
		expect(game.exploration_sites.size()==3,"External biomes lost exploration landmarks")
		worlds.append(JSON.stringify({"sites":layout.sites,"homes":layout.houses}))
		game.rebuild_region()
		expect(layout==game.get_meta("landscape_plan",{}),"Region regenerated differently with the same seed")
	expect(worlds[0]!=worlds[1] and worlds[1]!=worlds[2],"Changing seeds did not move village")
	game.journey.data.world=Seed.create(6412,"world_test_legacy")
	game.journey.data.world.landscape_version=1
	game.rebuild_region()
	expect(int(game.get_meta("landscape_plan",{}).get("version",0))==1,"Legacy save lost original layout")
	if failures.is_empty():print("QA0942 SCENE PASS")
	else:
		for message in failures:push_error(message)
	quit(0 if failures.is_empty() else 1)
