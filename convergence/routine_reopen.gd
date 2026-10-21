extends SceneTree
var w: Node3D
func _initialize():call_deferred("run")
func run():
	var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://convergence/routine_fixture012.json"))
	w=preload("res://convergence/game.gd").new();w.load_on_start=true;w.save_path="user://convergence012_routines.json";root.add_child(w)
	for i in range(800):
		await physics_frame
		if w.current_region>=0 and not w.changing_region:break
	var ok: bool=w.current_region==int(expected.current) and JSON.parse_string(JSON.stringify(w.journey.data.living_world.npcs))==expected.identities
	var ids: Dictionary={};var talks:=0
	for actor in w.residents:
		ids[actor.identity.id]=true;talks+=actor.talks
		if not expected.actors.has(actor.identity.id):ok=false
		elif actor.talks!=int(expected.actors[actor.identity.id].get("talks",0)):ok=false
	ok=ok and ids.size()==w.residents.size() and talks>0
	var result: Dictionary={"pass":ok,"region":w.current_region,"population":w.residents.size(),"unique_identities":ids.size(),"talks":talks,"valid_save":w.journey.valid(w.journey.data)}
	FileAccess.open("res://convergence/routine_reopen012.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"));print("ROUTINE_REOPEN ",JSON.stringify(result))
	w.simulation_enabled=false;w.audio_fx.shutdown();OS.delay_msec(120);w.free();await process_frame;quit(int(not ok))
