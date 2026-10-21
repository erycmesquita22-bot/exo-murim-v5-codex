extends SceneTree
# Native Godot 4.6.2 / isolated save fixture. NOT executed in the packaging environment.
const Game=preload("res://convergence/game.gd")
const WorldClock=preload("res://ai_core/world_clock.gd")
var w: Variant
var failures: Array=[]
var checks:=0
var observations: Array=[]
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func frames(n: int) -> void:
	for i in range(n):await physics_frame
func run() -> void:
	for seed in [101,816204]:
		w=Game.new();w.load_on_start=false;w.world_seed_override=seed
		w.save_path="user://npc02_qa_isolated_%d.json"%seed
		root.add_child(w);await process_frame
		w.flow.phase="creator"
		w.flow.create_character({"name":"NPC QA 02","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0});w.ui.resume()
		check(w.ensure_atlas(),"atlas_seed_%d"%seed)
		var visits: Array=[]
		for spec in w.atlas.regions:
			if str(spec.kind)=="settlement":
				visits.append(int(spec.id))
				if visits.size()>=2:break
		for rid in visits:
			var opened: bool=await w.change_region(rid)
			check(opened,"open_seed_%d_region_%d"%[seed,rid])
			if not opened:continue
			var count: int=w.residents.size();var ids: Dictionary={}
			check(count>0,"population_seed_%d_region_%d"%[seed,rid])
			for actor in w.residents:
				ids[actor.identity.id]=true
				check(actor.identity.has("personality") and actor.identity.has("routine_offset"),"profile_%s"%actor.identity.id)
				check(actor.routes.has(actor.from_slot+">"+actor.to_slot),"route_%s"%actor.identity.id)
			check(ids.size()==count,"unique_ids_%d_%d"%[seed,rid])
			w.extension().clock=9*WorldClock.SECONDS_PER_HOUR
			var start_usecs:=Time.get_ticks_usec()
			await frames(480)
			var physics_ms: float=(Time.get_ticks_usec()-start_usecs)/1000.0
			var moved:=0;var stuck:=0
			for actor in w.residents:
				if actor.travelled>.5:moved+=1
				if actor.unreachable_count>3:stuck+=1
			check(moved>0,"scheduled_movement_%d_%d"%[seed,rid])
			check(stuck==0,"persistent_blocking_%d_%d"%[seed,rid])
			# Test the existing dialogue path without inventing a second dialogue system.
			var first: Variant=null
			for actor in w.residents:
				if actor.rig.visible:first=actor;break
			if first!=null:
				var before: int=first.talks
				w.player.position=first.position+Vector3(0,0,1.5)
				w.gate_cooldown=0;w.interaction_cooldown=0
				await frames(8);w.interact();await frames(3)
				check(first.talks>before,"dialogue_seed_%d_region_%d"%[seed,rid]);w.ui.resume()
			check(w.save_progress(),"save_seed_%d_region_%d"%[seed,rid])
			observations.append({"seed":seed,"region":rid,"population":count,"moved":moved,"blocked":stuck,"480_physics_frames_wall_ms":physics_ms,"memory_static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"director":w.npc_director.stats.duplicate(true)})
		if is_instance_valid(w):
			w.simulation_enabled=false
			if w.audio_fx!=null:w.audio_fx.shutdown()
			w.free()
		await process_frame
	var result: Dictionary={"checks":checks,"failures":failures,"observations":observations,"engine":Engine.get_version_info().get("string","")}
	print("EXO_NPC02_WORLD ",JSON.stringify(result))
	var file:=FileAccess.open("user://npc02_qa_world.json",FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify(result,"\t"))
	quit(0 if failures.is_empty() else 1)
