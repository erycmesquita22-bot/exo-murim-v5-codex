extends SceneTree
# Runtime regression: godot --headless --path . --script res://qa0943.gd
# Uses a distinct QA save path, never the player's active save.
const Seed=preload("res://procedural/world_state.gd")
const Wardrobe=preload("res://wardrobe.gd")
const Catalog=preload("res://catalog.gd")
var failures: Array[String]=[]

func check(value: bool,reason: String) -> void:
	if not value:
		failures.append(reason)
		push_error("QA0943: "+reason)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene: PackedScene=load("res://main.tscn")
	var game=scene.instantiate()
	game.load_on_start=false
	game.save_path="user://qa0943_movement_test.json"
	root.add_child(game)
	game.journey.data.world=Seed.create(202,"world_test_0943")
	game.journey.data.world.landscape_version=2
	game.journey.data.phase="adventure"
	game.rebuild_region()
	game.flow.sync_village_sites()
	game.flow.apply_character()
	game.prepare_player_spawn(game.village_anchor("camp",Vector3(0,0.03,32)))
	game.set_paused(false)
	for n in range(8):await physics_frame
	check(game.player.position.y>=0.0,"Character spawned below village floor")
	check(game.player.is_on_floor(),"Character not grounded at generated village spawn")
	var initial: Vector3=game.player.position
	Input.action_press("right")
	for n in range(50):await physics_frame
	Input.action_release("right")
	var moved: float=Vector2(game.player.position.x-initial.x,game.player.position.z-initial.z).length()
	check(moved>0.8,"WASD movement blocked at generated village spawn; displacement="+str(moved))
	check(game.player.position.y>=-0.1,"Character sank after movement")
	for weapon_id in ["greatsword","spear","quarterstaff","arcane_staff"]:
		var profile: Dictionary=game.current_profile().duplicate(true)
		profile["weapon"]=weapon_id
		Wardrobe.apply(game.model,profile)
		var blade_value: Variant=game.model.get_meta("weapon_root",null)
		check(blade_value is Node3D,"Weapon has no attachment: "+weapon_id)
		if blade_value is Node3D:
			var attachment: Node3D=blade_value as Node3D
			check(attachment.get_parent()==game.model.forearms[0],"Weapon detached from forearm: "+weapon_id)
			check(attachment.rotation.x>0.0,"Long weapon still points toward the floor: "+weapon_id)
	game.set_paused(true)
	if failures.is_empty():print("QA0943 PASS: grounded spawn, WASD and long-weapon grip")
	game.set_paused(false);game.simulation_enabled=false;game.audio_fx.shutdown();OS.delay_msec(120)
	await create_timer(.1,true,false,true).timeout
	game.free();await process_frame;await process_frame
	quit(0 if failures.is_empty() else 1)
