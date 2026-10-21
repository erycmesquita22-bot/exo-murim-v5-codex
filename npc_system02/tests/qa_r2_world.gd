extends SceneTree
# Full engine traversal and basic patrol/saving gate. Must run with native Godot.
const Game=preload("res://convergence/game.gd")
var failed: Array=[]
var report: Array=[]
var checks:=0
func check(value: bool,label: String) -> void:
	checks+=1
	if not value:failed.append(label);push_error(label)
func _initialize() -> void:call_deferred("run")
func frames(count: int) -> void:
	for i in range(count):await physics_frame
func run() -> void:
	for seed in [101,816204]:
		var game:=Game.new();game.load_on_start=false;game.world_seed_override=seed
		game.save_path="user://npc02_r2_isolated_%d.json"%seed
		root.add_child(game);await process_frame
		game.flow.phase="creator"
		game.flow.create_character({"name":"NPC R2 QA","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0});game.ui.resume()
		check(game.ensure_atlas(),"atlas_%d"%seed)
		var rid:=78 if seed==101 else -1
		if rid<0:
			for spec in game.atlas.regions:
				if str(spec.kind)=="settlement":rid=int(spec.id);break
		if rid<0:
			check(false,"missing_settlement_%d"%seed);game.free();continue
		check(await game.change_region(rid),"open_%d_%d"%[seed,rid])
		if game.current_region!=rid:game.free();continue
		var ids: Dictionary={}
		for actor in game.residents:
			check(actor.identity.get("social_memory",null) is Dictionary,"social_schema_"+actor.identity.id)
			check(actor.identity.get("preferences",null) is Dictionary,"preferences_schema_"+actor.identity.id)
			ids[actor.identity.id]=actor
		check(game.residents.size()==ids.size(),"unique_actors_%d"%seed)
		game.extension().clock=6*90.0
		await frames(750)
		var guards:=0;var observed:=0
		for actor in game.residents:
			if actor.identity.role=="guard":guards+=1;observed+=actor.patrol_observations
		# A particular village may have no guards; don't invent a guard for QA.
		if guards>0:check(observed>0,"guard_observation_%d"%seed)
		check(game.save_progress(),"save_%d"%seed)
		report.append({"seed":seed,"region":rid,"npcs":ids.size(),"guards":guards,"observation_stops":observed,"director":game.npc_director.stats.duplicate(true),"memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC)})
		game.simulation_enabled=false
		if game.audio_fx!=null:game.audio_fx.shutdown()
		game.free();await process_frame
	var result: Dictionary={"suite":"npc_system02_r2_world","checks":checks,"failed":failed,"samples":report,"godot_version":Engine.get_version_info().get("string","")}
	print("EXO_NPC02_R2_WORLD ",JSON.stringify(result))
	var file:=FileAccess.open("user://npc02_r2_world.json",FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify(result,"\t"))
	quit(0 if failed.is_empty() else 1)
