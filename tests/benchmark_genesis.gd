extends SceneTree
const Demo=preload("res://genesis/demo.gd")
var world: Node3D
var frames: Array=[]
func _init() -> void:call_deferred("run")
func run() -> void:
	world=Demo.new();root.add_child(world)
	while not world.ready_to_play:await process_frame
	world.automated=true
	# Same camera and scene path, one live region, one optional prepared region.
	var result: Dictionary={"engine":Engine.get_version_info(),"renderer":RenderingServer.get_video_adapter_name(),"display":DisplayServer.get_name(),"resolution":root.size,"modes":[],"note":"No fixed FPS or movie capture. Shared host, software rendering. Steady-state frame times EXCLUDE preparation and transitions; their blocking costs are recorded in separate phase fields."}
	for prepared in [false,true]:
		world.cache_enabled=prepared
		var rows: Array=[]
		for rid in [52,46,61,32,86,78,63]:
			var row: Dictionary={"rid":rid,"prepared":prepared}
			if prepared:
				var t := Time.get_ticks_usec();world.prepare_neighbor(rid);row.prepare_ms=(Time.get_ticks_usec()-t)/1000.0
				row.prepared_static_bytes=Performance.get_monitor(Performance.MEMORY_STATIC);row.prepared_rss_kib=rss()
			var t := Time.get_ticks_usec();var ok: bool=await world.change_region(rid,"");row.transition_ms=(Time.get_ticks_usec()-t)/1000.0;row.ok=ok
			for n in range(20):await process_frame
			frames=[]
			var began := Time.get_ticks_usec();var previous := began
			# Timed render loop, ordinary process frames, no artificial FPS target.
			while Time.get_ticks_usec()-began<1500000:
				await process_frame
				var now := Time.get_ticks_usec();frames.append((now-previous)/1000.0);previous=now
			row.frame_ms=stats(frames);row.fps=1000.0/row.frame_ms.mean;row.static_bytes=Performance.get_monitor(Performance.MEMORY_STATIC);row.rss_kib=rss()
			row.triangles=world.active.triangles;row.asset_instances=world.active.asset_count;row.draw_calls=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
			rows.append(row);print("BENCH ",JSON.stringify(row))
		result.modes.append({"prepared":prepared,"rows":rows})
	FileAccess.open("res://evidence/benchmark.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"));print("BENCHMARK_DONE");quit()
func rss() -> int:
	if not FileAccess.file_exists("/proc/self/status"):return -1
	var text := FileAccess.get_file_as_string("/proc/self/status")
	for line in text.split("\n"):
		if line.begins_with("VmRSS:"):return line.trim_prefix("VmRSS:").strip_edges().split(" ",false)[0].to_int()
	return -1
func stats(values: Array) -> Dictionary:
	if values.is_empty():return {"mean":0,"p50":0,"p95":0,"max":0}
	values.sort();var sum := 0.0
	for v in values:sum+=v
	return {"mean":sum/values.size(),"p50":values[int(values.size()*.5)],"p95":values[int(values.size()*.95)],"max":values[-1],"frames":values.size()}
