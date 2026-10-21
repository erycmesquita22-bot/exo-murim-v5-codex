extends SceneTree
const Demo=preload("res://genesis/demo.gd")
var world: Node3D
var failures: Array=[]
var walks: Array=[]
var max_floor_error := 0.0
var min_y := INF
var capture := false
func _init() -> void:call_deferred("run")
func run() -> void:
	capture="capture" in OS.get_cmdline_user_args()
	world=Demo.new();root.add_child(world)
	var boot_frames := 0
	while not world.ready_to_play:
		await physics_frame;boot_frames+=1
		if boot_frames>1000:failures.append("boot_timeout");finish();return
	world.automated=true
	world.cache_enabled="preload" in OS.get_cmdline_user_args()
	for i in range(10):await physics_frame
	if capture:
		await capture_regions();finish();return
	var initial_digest: String=world.active.data.digest()
	# Every open edge in the pilot is walked in BOTH directions, DFS returns to the village.
	await visit(86,-1,{})
	if world.current!=86:failures.append("not_returned_to_village")
	if world.visited.size()!=7:failures.append("not_all_regions_visited")
	if world.active.data.digest()!=initial_digest:failures.append("regeneration_changed")
	finish()
func visit(rid: int,parent_id: int,seen: Dictionary) -> void:
	seen[rid]=true
	if not await walk_to(Vector2.ZERO,"arrival_to_hub"):return
	# Real approach, entrance crossing and return; no teleport fixture for buildings.
	if world.active.data.spec.kind in ["settlement","dungeon_approach"] and not world.active.data.lots.is_empty():
		var lot: Dictionary=world.active.data.lots[0]
		var toward_hub: Vector2=-lot.p.normalized()
		var approach: Vector2=lot.p+toward_hub*7
		if not await walk_to(approach,"lot_approach"):return
		var interior: Vector2=lot.p-toward_hub*(7 if world.active.data.spec.kind=="dungeon_approach" else 0)
		if not await walk_to(interior,"dungeon_chamber" if world.active.data.spec.kind=="dungeon_approach" else "house_door_crossing"):return
		if not await walk_to(approach,"lot_exit"):return
		if not await walk_to(Vector2.ZERO,"lot_to_hub"):return
	var targets: Array=[]
	for gate in world.active.gate_nodes:
		if gate.open and gate.contract.neighbor!=parent_id:targets.append({"id":gate.contract.id,"neighbor":gate.contract.neighbor})
	for item in targets:
		if seen.has(item.neighbor):continue
		if not await travel(item.id,item.neighbor):return
		await visit(item.neighbor,rid,seen)
		if not await travel(item.id,rid):return
		if not await walk_to(Vector2.ZERO,"return_to_hub"):return
	# Extra cycles are exercised separately by traversal in the transition suite.
func probe_capsule(point: Vector3) -> bool:
	var q := PhysicsShapeQueryParameters3D.new();q.shape=world.player.get_child(0).shape;q.transform=Transform3D(Basis.IDENTITY,point+Vector3(0,.98,0));q.collision_mask=5
	return world.get_world_3d().direct_space_state.intersect_shape(q).is_empty()
func travel(gate_id: String,destination: int) -> bool:
	var gate: Dictionary={}
	for g in world.active.gate_nodes:
		if g.contract.id==gate_id:gate=g;break
	if gate.is_empty():failures.append("missing_gate");return false
	var target: Vector2=gate.contract.p-gate.contract.p.normalized()*6.5
	if not await walk_to(target,"hub_to_gate"):return false
	var from: int=world.current
	world.cooldown=0
	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	for n in range(200):
		await physics_frame
		if not world.loading and world.current==destination:break
	if world.current!=destination:
		failures.append({"phase":"transition","from":from,"expected":destination,"actual":world.current});return false
	for n in range(10):await physics_frame
	if not world.player.is_on_floor():failures.append({"phase":"arrival_floor","rid":destination});return false
	if not probe_capsule(world.player.position+Vector3(0,.03,0)):failures.append({"phase":"arrival_clearance","rid":destination});return false
	return true
func walk_to(target: Vector2,phase: String) -> bool:
	var begin := Time.get_ticks_usec();var origin: Vector3=world.player.position
	var last := origin;var stalled := 0;var frames := 0;var airborne := 0;var walked := 0.0
	for n in range(16000):
		var p := Vector2(world.player.position.x,world.player.position.z)
		if p.distance_to(target)<.3:break
		world.qa_direction=Vector3(target.x-p.x,0,target.y-p.y).normalized()
		await physics_frame;frames+=1
		var current_pos: Vector3=world.player.position;walked+=Vector2(current_pos.x-last.x,current_pos.z-last.z).length()
		if current_pos.distance_to(last)<.0002:stalled+=1
		else:stalled=0
		last=current_pos
		if not world.player.is_on_floor():airborne+=1
		var h: float=world.active.data.height_at(Vector2(current_pos.x,current_pos.z))
		min_y=minf(min_y,current_pos.y)
		max_floor_error=maxf(max_floor_error,absf(current_pos.y-h))
		if current_pos.y<h-1:failures.append({"phase":"below_surface","rid":world.current,"point":str(current_pos)});world.qa_direction=Vector3.ZERO;return false
		if stalled>120:failures.append({"phase":"stalled","rid":world.current,"at":str(current_pos),"target":str(target)});world.qa_direction=Vector3.ZERO;return false
	world.qa_direction=Vector3.ZERO
	for n in range(5):await physics_frame
	var distance: float=Vector2(world.player.position.x,world.player.position.z).distance_to(target)
	walks.append({"rid":world.current,"phase":phase,"distance_m":walked,"frames":frames,"airborne_frames":airborne,"target_error":distance,"wall_ms":(Time.get_ticks_usec()-begin)/1000.0})
	print("WALK ",world.current," ",phase," ",snappedf(walked,.1),"m target_error ",distance)
	if distance>1:failures.append({"phase":"walk_timeout","rid":world.current,"error":distance});return false
	return true
func capture_regions() -> void:
	for rid in world.pilot.ids:
		if world.current!=rid:await world.change_region(rid,"")
		world.qa_direction=Vector3.ZERO
		for n in range(20):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://evidence/region_%02d.png"%rid)
		world.set_physics_process(false)
		if not world.active.data.lots.is_empty():
			var lot: Dictionary=world.active.data.lots[0]
			var focus := Vector3(lot.p.x,lot.height+1,lot.p.y)
			world.camera.position=focus+Vector3(12,15,15);world.camera.size=19;world.camera.look_at(focus)
			for n in range(4):await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://evidence/landmark_%02d.png"%rid)
		# Overview is an actual second camera view of the same instantiated scene.
		world.set_physics_process(false)
		world.camera.position=Vector3(95,world.active.data.center_h+120,105);world.camera.size=190;world.camera.look_at(Vector3(0,world.active.data.center_h,0))
		world.set_physics_process(false)
		for n in range(4):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://evidence/overview_%02d.png"%rid)
		world.set_physics_process(true)
func finish() -> void:
	var d := {"engine":Engine.get_version_info(),"mode":"rendered_captures" if capture else "automated_real_character_physics","failures":failures,"visited":world.visited,"walks":walks,"transitions":world.transition_log,"prepares":world.prepare_log,"max_floor_error_m":max_floor_error,"min_y":min_y if is_finite(min_y) else null,"fixture":("capture-only: direct region loads and inspection camera; movement evidence is in playable.json" if capture else "isolated original make_player capsule + original rig; automated direction, real move_and_slide, E action; no movement teleports except region transfer")}
	FileAccess.open("res://evidence/captures.json" if capture else ("res://evidence/playable-preloaded.json" if "preload" in OS.get_cmdline_user_args() else "res://evidence/playable.json"),FileAccess.WRITE).store_string(JSON.stringify(d,"\t"))
	print("RESULT ",JSON.stringify(d));quit(0 if failures.is_empty() else 1)
