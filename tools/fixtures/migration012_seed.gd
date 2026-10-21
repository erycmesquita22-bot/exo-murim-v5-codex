extends SceneTree
func _initialize():call_deferred("run")
func run():
	var w=preload("res://convergence/game.gd").new();w.load_on_start=false;w.world_seed_override=101;w.save_path="user://migration012.json";root.add_child(w);await process_frame
	w.flow.phase="creator";w.flow.create_character({"name":"Migration QA","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0});w.ui.resume()
	var ok: bool=await w.change_region(78)
	ok=ok and w.save_progress()
	FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE).store_string(JSON.stringify({"identities":w.journey.data.living_world.npcs,"atlas":w.atlas,"items":w.journey.data.items,"root_version":w.journey.data.version}))
	print("MIGRATION_C01_SOURCE ",ok," identities=",w.residents.size());w.simulation_enabled=false;w.audio_fx.shutdown();OS.delay_msec(120);w.free();quit(int(not ok))
