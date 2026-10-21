extends SceneTree
# Run with Godot 4.6.x: godot --headless --path . --script res://qa0945.gd
# Logical generation and a real scene smoke test, including 3 grounded route colliders.
const Seed=preload("res://procedural/world_state.gd")
const Plan=preload("res://world/biome_plan.gd")
const Landscape=preload("res://world/landscape.gd")
const Design=preload("res://world/level_design.gd")
var failures: Array[String]=[]
func expect(ok: bool,reason: String) -> void:
	if not ok:
		failures.append(reason)
		push_error("QA0945: "+reason)
func _initialize() -> void:
	call_deferred("run")
func frames(count: int) -> void:
	for i in range(count):await physics_frame
func run() -> void:
	var kinds: Dictionary={}
	var patterns: Dictionary={}
	for seed_value in range(160):
		var world_data: Dictionary=Seed.create(seed_value,"qa0945_village")
		world_data.landscape_version=2
		var a: Dictionary=Plan.create(world_data)
		var b: Dictionary=Plan.create(world_data.duplicate(true))
		expect(a==b,"Same seed produced a different village layout")
		expect(Plan.safe_layout(a),"Invalid village layout for seed "+str(seed_value))
		kinds[str(a.kind)]=true
		patterns[str(a.pattern)]=true
		for role in ["npc","bed","mat","board"]:
			var anchor: Vector3=preload("res://world/village_layout_v2.gd").anchor(a,role)
			expect(anchor.z>=17.0 and anchor.z<=65.0,"Service outside walkable village: "+role)
		expect(absf(Design.road_axis(15.0,str(a.pattern)))<.01,"Main entrance no longer at gate")
	var world_data: Dictionary=Seed.create(202,"qa0945_playable")
	world_data.landscape_version=2
	var n: FastNoiseLite=Landscape.noise_for(world_data)
	for x in [-96.0,-40.0,0.0,40.0,96.0]:
		for z in [-100.0,-40.0,12.0,62.0,92.0]:
			var y: float=Landscape.surface_height(x,z,n)
			expect(is_finite(y),"Invalid terrain height")
			if x==0.0 and z==12.0:
				expect(absf(y)<.001,"Village floor is no longer level")
	expect(kinds.size()==4,"One or more birth conditions not generated")
	expect(patterns.size()==4,"One or more street templates missing")
	var game=load("res://main.tscn").instantiate()
	game.load_on_start=false
	game.save_path="user://qa0945_level_design.json"
	root.add_child(game)
	game.journey.data.world=world_data
	game.journey.data.phase="adventure"
	game.flow.phase="adventure"
	game.rebuild_region()
	game.flow.sync_village_sites()
	var info: Dictionary=game.get_meta("village_level_design",{})
	expect(int(info.get("revision",0))==1,"New village presentation not created")
	for i in range(3):
		expect(game.find_child("GroundedTrail_%d"%i,true,false)!=null,"Visual path missing: "+str(i))
		expect(game.find_child("TrailWalkable_%d"%i,true,false)!=null,"Physical path missing: "+str(i))
	game.prepare_player_spawn(game.village_anchor("camp",Vector3(0,.03,32)))
	game.set_paused(false)
	await frames(18)
	expect(game.player.position.y>=-.1,"Spawn fell below village floor")
	var old: Vector3=game.player.position
	Input.action_press("right")
	await frames(40)
	Input.action_release("right")
	var delta: Vector3=game.player.position-old
	expect(Vector2(delta.x,delta.z).length()>.65,"WASD movement blocked in designed village")
	game.set_paused(true)
	if failures.is_empty():print("QA0945 PASS: 160 seeds + grounded routes + service anchors + playable movement")
	game.set_paused(false);game.simulation_enabled=false;game.audio_fx.shutdown();OS.delay_msec(120)
	await create_timer(.1,true,false,true).timeout
	game.free();await process_frame;await process_frame
	quit(0 if failures.is_empty() else 1)
