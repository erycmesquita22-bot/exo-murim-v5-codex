extends SceneTree
var w: Node3D
var shots: Array=[]
var checks: Array=[]
var failures: Array=[]
const OUT="/workspace/scratch/7eb713849e80/r2-captures/"
func _initialize():call_deferred("run")
func frames(n: int):
	for i in range(n):await physics_frame
func verify(value: bool,label: String):
	checks.append({"test":label,"pass":value});print("CHECK ",label," ",value)
	if not value:failures.append(label)
func settle(n: int):
	RenderingServer.render_loop_enabled=false
	await frames(n)
	RenderingServer.render_loop_enabled=true
func ground(p: Vector2) -> Vector3:return Vector3(p.x,w.active_region.data.height_at(p)+.08,p.y)
func view(p: Vector3,size: float=20.0,panorama: bool=false):
	w.player.position=p;w.player.velocity=Vector3.ZERO;w.camera.size=size;w.update_camera()
	if panorama:w.camera.position=p+Vector3(65,85,70);w.camera.look_at(p+Vector3.UP)
func shot(label: String):
	w.ui.hide()
	for actor in w.residents:
		actor.presentation_visible=w.resident_is_visible(actor);actor.rig.visible=not actor.sheltered and actor.presentation_visible
	w.update_resident_labels()
	for i in range(5):await process_frame
	await RenderingServer.frame_post_draw
	var error: int=root.get_texture().get_image().save_png(OUT+label+".png")
	verify(error==OK,"png_"+label)
	shots.append({"file":label+".png","seed":101,"region":w.current_region,"biome":w.active_region.data.spec.biome,"residents":w.residents.size(),"ecological_enemies":w.ecology_director.active.size()})
	print("CAPTURE ",shots.size()," ",label)
func enter(rid: int) -> bool:
	w.set_physics_process(true);w.simulation_enabled=true
	var ok: bool=await w.change_region(rid);verify(ok,"enter_%d:%s"%[rid,w.generation_failure])
	if not ok:return false
	await frames(40)
	return true
func run():
	DirAccess.make_dir_recursive_absolute(OUT);root.size=Vector2i(1440,900)
	w=load("res://convergence/game.gd").new();w.load_on_start=false;w.world_seed_override=101
	w.save_path="user://r2_visit.json";w.settings_path="user://r2_visit.cfg";root.add_child(w);await process_frame
	w.graphics.select(1);w.graphics.shake_enabled=false
	w.flow.phase="creator";verify(w.flow.create_character({"name":"Eryc","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0,"weapon":"sword"}),"create_character");w.ui.resume()
	if not await enter(86):finish();return
	w.extension().clock=900.0
	await settle(2400)
	w.set_physics_process(false)
	var chosen: Dictionary=w.active_region.data.lots[0];var best:=-1
	for lot in w.active_region.data.lots:
		var count:=0
		for actor in w.residents:
			if actor.to_slot==lot.id:count+=1
		if count>best:best=count;chosen=lot
	view(w.active_region.station_points[chosen.id]+Vector3(0,0,3),23)
	await shot("01-Aldeia-e-Moradores-R2")
	if not await enter(15):finish();return
	w.extension().clock=900.0;await settle(2000);w.set_physics_process(false)
	view(ground(Vector2.ZERO),88,true);await shot("02-Vila-R2")
	if not await enter(78):finish();return
	w.extension().clock=900.0;await settle(2500);w.set_physics_process(false)
	for lot in w.active_region.data.lots:
		if lot.function=="martial_school":chosen=lot;break
	view(w.active_region.station_points[chosen.id]+Vector3(0,0,2),21)
	await shot("03-Escola-Marcial-R2")
	if not await enter(52):finish();return
	verify(not w.ecology_director.sites.is_empty(),"ecology_territories_planned")
	if w.ecology_director.sites.is_empty():finish();return
	var site: Dictionary=w.ecology_director.sites[0]
	# Fixture: place the observer 35m from an actual planned territory. The native
	# director still owns all enemy materialization and its visibility restrictions.
	var observer: Vector3=ground(site.p+Vector2(0,35))
	var safe: Vector3=w.regional_spawn(w.active_region,observer)
	if safe.is_finite():observer=safe
	view(observer,15)
	verify(not w.ecology_director.visible_spawn(Vector3(site.p.x,site.y,site.p.y)),"territory_offscreen_before_spawn")
	await frames(130)
	verify(not w.ecology_director.active.is_empty(),"native_enemy_spawn")
	verify(w.ecology_director.active.size()<=8,"active_enemy_budget")
	if w.ecology_director.active.is_empty():finish();return
	var foe: Node3D=w.ecology_director.active.values()[0]
	var origin: Vector3=foe.position
	await frames(180)
	verify(foe.position.distance_to(origin)>.15,"physical_enemy_patrol")
	w.set_physics_process(false)
	view(observer,55,true);await shot("04-Territorio-e-Patrulha-R2")
	w.set_physics_process(true);w.invulnerability=60
	# Actual character-body travel towards the native opponent; no enemy is
	# spawned or repositioned for the combat photograph.
	for i in range(800):
		var offset: Vector3=foe.position-w.player.position;offset.y=0
		if offset.length()<6.0:break
		w.simulation_enabled=false
		w.player.velocity=offset.normalized()*4.8+Vector3(0,-2,0)
		w.player.move_and_slide()
		w.update_camera()
		for enemy in w.enemies:enemy.step(1.0/60.0)
		await physics_frame
	w.simulation_enabled=true
	view(w.player.position,19)
	var engaged:=false
	for i in range(240):
		await physics_frame
		if foe.attack_time>.15:engaged=true;break
	verify(engaged,"regional_enemy_attack")
	w.set_physics_process(false);await shot("05-Encontro-Regional-R2")
	if not await enter(46):finish();return
	w.set_physics_process(false);view(ground(Vector2(130,15)),83,true)
	await shot("06-Montanhas-e-Trilhas-R2")
	verify(w.save_progress(),"save_native_session")
	var saved=load("res://journey_save.gd").new(w.save_path)
	verify(saved.load_progress(),"reload_session_json")
	finish()
func finish():
	FileAccess.open(OUT+"session.json",FileAccess.WRITE).store_string(JSON.stringify({"engine":Engine.get_version_info().string,"package":"Mundo Vivo 02 R2","checks":checks,"failures":failures,"captures":shots,"scope":"Native QA plus automated rendered inspection; not a complete regression or human playtest."},"  "))
	print("R2_VISIT_COMPLETE captures=",shots.size()," failures=",failures)
	w.process_mode=Node.PROCESS_MODE_DISABLED;w.audio_fx.shutdown();OS.delay_msec(120);w.free();quit(int(shots.size()<5 or not failures.is_empty()))
