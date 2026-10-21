extends "res://validation_r3/support.gd"
var rows: Array=[]
var tag:="R3"
func _initialize():
	var args:=OS.get_cmdline_user_args();if not args.is_empty():tag=args[0]
	call_deferred("run")
func measure(label: String,load_ms: float,combat: bool=false):
	for i in range(40):await process_frame
	var raw: Array=[];var physics: Array=[];var process: Array=[]
	var previous:=Time.get_ticks_usec()
	for i in range(180):
		if combat:
			w.set_facing(Vector3.FORWARD)
			if i%40==0:Input.action_press("attack")
			if i%40==2:Input.action_release("attack")
			if i==60:Input.action_press("skill_2")
			if i==62:Input.action_release("skill_2")
		await process_frame
		var now:=Time.get_ticks_usec();raw.append(float(now-previous)/1000.0);previous=now
		physics.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000)
		process.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
	var sorted:=raw.duplicate();sorted.sort();var total:=0.0;var phy:=0.0;var cpu:=0.0
	for i in range(raw.size()):total+=raw[i];phy+=physics[i];cpu+=process[i]
	var avg: float=total/raw.size()
	var row: Dictionary={"scene":label,"region":w.current_region,"load_ms":load_ms,"mean_frame_ms":avg,"fps":1000/avg,"p95_frame_ms":sorted[int(ceil(sorted.size()*.95))-1],"physics_mean_ms":phy/raw.size(),"process_mean_ms":cpu/raw.size(),"static_memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"nodes":get_node_count(),"residents":w.residents.size(),"enemies":w.ecology_director.active.size(),"buildings":w.active_region.props.size() if w.active_region!=null else 0,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"raw_frame_ms":raw}
	rows.append(row);print("BENCH ",JSON.stringify(row))
func shot(label: String):
	w.ui.hide()
	for i in range(5):await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("res://validation_r3/captures/"+tag+"-"+label+".png")==OK,"capture_"+label)
	w.ui.show()
func run():
	await boot("user://functional_r3_bench_"+tag+".json")
	w.graphics.select(1);w.graphics.shake_enabled=false;DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	for rid in [78,52,86]:
		var began:=Time.get_ticks_usec();check(await w.change_region(rid),"region_"+str(rid));var loading:=float(Time.get_ticks_usec()-began)/1000
		w.extension().clock=900.0
		if rid==52:
			await observe(w.ecology_director.sites[0]);w.camera.size=35;w.update_camera()
		else:
			w.camera.size=21;var lot: Dictionary=w.active_region.data.lots[0]
			for parcel in w.active_region.data.lots:
				if parcel.function=="martial_school":lot=parcel;break
			w.player.position=w.active_region.station_points[lot.id]+Vector3(0,0,3);w.update_camera()
		await measure("city" if rid==78 else ("enemies" if rid==52 else "village"),loading)
		await shot(str(rid)+"-player")
		if rid==78:
			w.camera.size=65;w.update_camera();await shot("78-overview")
		if rid==52:
			w.camera.size=55;w.update_camera();await shot("52-landscape")
	var began:=Time.get_ticks_usec();w.return_home();var loading:=float(Time.get_ticks_usec()-began)/1000
	for actor in w.enemies:actor.enabled=false
	w.player.position=Vector3(0,.03,28);w.player.velocity=Vector3.ZERO;w.camera.size=15;w.update_camera()
	var target: Node3D=load("res://training_target.gd").new();target.setup(w,"benchmark_target","blade",Vector3(0,.03,26.65));w.add_child(target);target.max_hp=100000;target.hp=100000;w.enemies.append(target)
	await measure("legacy_combat_training_fixture",loading,true)
	facts["legacy_dummy_damage"]=target.damage_total
	check(target.damage_total>0,"benchmark_combat_inflicts_real_damage")
	await shot("legacy-combat")
	facts["benchmark"]={"tag":tag,"engine":Engine.get_version_info(),"renderer":RenderingServer.get_video_adapter_name(),"resolution":[1152,720],"fixed_fps":false,"profile":"Equilibrado","seed":101,"rows":rows}
	await finish("benchmark_"+tag)
