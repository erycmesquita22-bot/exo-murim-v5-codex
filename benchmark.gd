extends SceneTree
var w: Node3D
func _initialize() -> void:call_deferred("run")
func run() -> void:
	root.size=Vector2i(960,600)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var start:=Time.get_ticks_usec()
	w=load("res://main.gd").new();w.load_on_start=false;w.save_path="user://benchmark.json";w.settings_path="user://benchmark.cfg";root.add_child(w)
	await process_frame
	w.flow.phase="creator";w.flow.create_character({"name":"Benchmark","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0,"weapon":"sword"});w.ui.resume()
	for a in w.enemies:a.enabled=false
	w.player.position=Vector3(0,.03,28);w.camera.size=15
	var load_ms:=(Time.get_ticks_usec()-start)/1000.0
	var result: Array=[]
	for level in [0,1,2]:
		w.graphics.select(level)
		for i in range(18):await process_frame
		var samples: Array[float]=[]
		var process_times: Array[float]=[];var physics: Array[float]=[]
		for i in range(80):
			var before:=Time.get_ticks_usec();await process_frame;samples.append((Time.get_ticks_usec()-before)/1000.0)
			process_times.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000.0);physics.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0)
		samples.sort()
		result.append({"quality":level,"frame_ms_mean":mean(samples),"frame_ms_median":samples[40],"frame_ms_p95":samples[76],"process_ms_mean":mean(process_times),"physics_ms_mean":mean(physics),"static_memory_mb":Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0,"video_memory_mb":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1048576.0,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"objects":Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"resources":Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT)})
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://evidencias/benchmark-%d.png"%level)
	print("BENCHMARK_JSON ",JSON.stringify({"load_ms":load_ms,"samples":result,"renderer":RenderingServer.get_video_adapter_name(),"resolution":"960x600","frames_per_quality":80,"warmup_frames":18}))
	w.audio_fx.shutdown();w.queue_free();await process_frame;await process_frame;quit()
func mean(a: Array[float]) -> float:
	var s:=0.0
	for v in a:s+=v
	return s/maxi(a.size(),1)
