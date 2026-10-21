extends SceneTree
# Run: godot --headless --path . --script res://qa0944.gd
# Physically walks in a generated village, in training, then back in the village.
# Dedicated QA save, no change to the player's own data.
const Seed=preload("res://procedural/world_state.gd")
var failures: Array[String]=[]

func expect(ok: bool,reason: String) -> void:
	if not ok:
		failures.append(reason)
		push_error("QA0944: "+reason)

func _initialize() -> void:
	call_deferred("run")

func step_frames(count: int) -> void:
	for n in range(count):
		await physics_frame

func walk(game: Variant,action: String,frames: int) -> float:
	var initial: Vector3=game.player.position
	Input.action_press(action)
	await step_frames(frames)
	Input.action_release(action)
	var p: Vector3=game.player.position
	return Vector2(initial.x-p.x,initial.z-p.z).length()

func run() -> void:
	var game: Variant=load("res://main.tscn").instantiate()
	game.load_on_start=false
	game.save_path="user://qa0944_adventure_floor.json"
	root.add_child(game)
	game.journey.data.world=Seed.create(202,"qa0944_village")
	game.journey.data.world.landscape_version=2
	game.journey.data.phase="adventure"
	game.rebuild_region()
	game.flow.sync_village_sites()
	game.flow.apply_character()
	game.prepare_player_spawn(game.village_anchor("camp",Vector3(0,0.03,32)))
	game.set_paused(false)
	await step_frames(15)
	var floor_node=game.find_child("VillageSolidFloor09_4_4",true,false)
	expect(floor_node is StaticBody3D,"Village solid collider not created")
	expect(game.player.is_on_floor(),"Adventure start not on solid floor")
	expect(game.player.position.y>=-0.1,"Adventure start buried below terrain")
	var travel: float=await walk(game,"right",55)
	expect(travel>0.75,"Adventure movement blocked, travel="+str(travel))
	expect(game.player.is_on_floor(),"Player lost contact after walking in village")
	expect(game.player.position.y>=-0.1,"Adventure player fell through ground")
	var entered: bool=game.flow.begin_lab()
	expect(entered,"Cannot enter training from adventure")
	if entered:
		await step_frames(12)
		var lab_travel: float=await walk(game,"up",55)
		expect(lab_travel>0.75,"Training movement broken, travel="+str(lab_travel))
		game.flow.end_lab()
		await step_frames(15)
		expect(game.player.is_on_floor(),"No ground after returning from training")
		var back_travel: float=await walk(game,"left",55)
		expect(back_travel>0.75,"Adventure movement blocked after training, travel="+str(back_travel))
		expect(game.player.position.y>=-0.1,"Returned player buried in village")
	game.set_paused(true)
	if failures.is_empty():
		print("QA0944 PASS: village → training → village grounded movement")
	game.set_paused(false);game.simulation_enabled=false;game.audio_fx.shutdown();OS.delay_msec(120)
	await create_timer(.1,true,false,true).timeout
	game.free();await process_frame;await process_frame
	quit(0 if failures.is_empty() else 1)
