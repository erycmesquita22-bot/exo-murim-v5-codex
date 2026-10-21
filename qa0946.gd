extends SceneTree
# Run in Godot 4.6.x: godot --headless --path . --script res://qa0946.gd
const Ground=preload("res://world/terrain_assets.gd")
const Seed=preload("res://procedural/world_state.gd")
const Plan=preload("res://world/biome_plan.gd")
const Landscape=preload("res://world/landscape.gd")
var failures: Array[String]=[]
func require(condition: bool,description: String) -> void:
	if not condition:
		failures.append(description)
		push_error("QA0946: "+description)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	for id in Ground.TYPES:
		var tex: Texture2D=Ground.texture_for(str(id))
		require(tex!=null,"Missing surface artwork "+str(id))
		if tex!=null:require(tex.get_size()==Vector2(128,128),"Wrong tile size "+str(id))
		require(Ground.material(str(id)).albedo_texture!=null,"Unbound material "+str(id))
	var w: Dictionary=Seed.create(101,"world_qa0946")
	w.landscape_version=2
	var plan: Dictionary=Plan.create(w)
	var noise: FastNoiseLite=Landscape.noise_for(w)
	var sample_points: Array[Vector2]=[
		Vector2(0,35),Vector2(48,70),Vector2(-72,37),Vector2(0,-90)]
	var covers: Dictionary={}
	for p in sample_points:
		var cover: String=Landscape.ground_kind(p.x,p.y,noise,plan)
		covers[cover]=true
		require(cover in Ground.TYPES,"Terrain cover not registered: "+cover)
	var game=load("res://main.tscn").instantiate()
	game.load_on_start=false
	game.save_path="user://qa0946_terrain.json"
	root.add_child(game)
	game.journey.data.world=w
	game.journey.data.phase="adventure"
	game.flow.phase="adventure"
	game.rebuild_region()
	game.flow.sync_village_sites()
	var terrain: MeshInstance3D=game.find_child("PersistentTerrain09_4",true,false)
	require(terrain!=null,"Terrain was not instantiated")
	if terrain!=null:
		require(terrain.mesh.get_surface_count()>=3,"Terrain surfaces still monochrome")
		for j in range(terrain.mesh.get_surface_count()):
			var mat: Material=terrain.mesh.surface_get_material(j)
			require(mat is StandardMaterial3D and (mat as StandardMaterial3D).albedo_texture!=null,"Material missing from terrain surface "+str(j))
	require(game.find_child("VillageSolidFloor09_4_4",true,false)!=null,"Approved floor collider missing")
	require(game.find_child("TerrainGrassTufts_LowCost",true,false)!=null,"Instanced ground foliage missing")
	game.prepare_player_spawn(game.village_anchor("camp",Vector3(0,.03,32)))
	game.set_paused(false)
	for i in range(20):await physics_frame
	require(game.player.position.y>-.3,"Player sank into new terrain")
	var old: Vector3=game.player.position
	Input.action_press("right")
	for i in range(38):await physics_frame
	Input.action_release("right")
	require(Vector2(game.player.position.x-old.x,game.player.position.z-old.z).length()>.5,"Movement blocked after applying ground materials")
	game.set_paused(true)
	if failures.is_empty():print("QA0946 PASS: 8 textures, multiple biome surfaces, physics and movement")
	game.set_paused(false);game.simulation_enabled=false;game.audio_fx.shutdown();OS.delay_msec(120)
	await create_timer(.1,true,false,true).timeout
	game.free();await process_frame;await process_frame
	quit(0 if failures.is_empty() else 1)
