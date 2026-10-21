extends SceneTree
func _initialize():call_deferred("run")
func run():
	var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://convergence/migration_fixture012.json"))
	var w=preload("res://convergence/game.gd").new();w.load_on_start=true;w.save_path="user://migration012.json";root.add_child(w)
	for i in range(800):
		await physics_frame
		if w.current_region>=0 and not w.changing_region:break
	var ok: bool=w.current_region==78 and w.journey.valid(w.journey.data) and w.residents.size()==65
	var preserved:=0
	for id in expected.identities:
		if not w.journey.data.living_world.npcs.has(id):ok=false;continue
		var actual: Dictionary=w.journey.data.living_world.npcs[id];var old: Dictionary=expected.identities[id]
		for key in ["id","name","display_name","prefix","suffix","role","appearance","attributes","level","faction"]:
			if JSON.parse_string(JSON.stringify(actual[key]))!=old[key]:ok=false
		preserved+=1
	ok=ok and JSON.parse_string(JSON.stringify(w.atlas))==expected.atlas and JSON.parse_string(JSON.stringify(w.journey.data.items))==expected.items and w.journey.data.version==expected.root_version
	var result: Dictionary={"pass":ok,"original_identities_preserved":preserved,"current_population":w.residents.size(),"graph_preserved":JSON.parse_string(JSON.stringify(w.atlas))==expected.atlas,"save_valid":w.journey.valid(w.journey.data)}
	FileAccess.open("res://convergence/migration_result012.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"));print("MIGRATION012 ",JSON.stringify(result));w.simulation_enabled=false;w.audio_fx.shutdown();OS.delay_msec(120);w.free();quit(int(not ok))
