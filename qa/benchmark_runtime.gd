extends SceneTree
## Benchmark FORJA02 real, exige Godot e GLBs importados. NAO testa FPS do jogo completo.
const Planner = preload("res://forja/forja_planner.gd")
const Builder = preload("res://forja/forja_builder.gd")
var results: Array = []

func _initialize() -> void:
	call_deferred("_bench")

func _lot(idx: int) -> Dictionary:
	return {"id":"bench_%d" % idx,"center_x":float(idx%8)*22.0,"center_z":float(int(float(idx)/8.0))*24.0,
		"ground_y":0.0,"width_m":13.0,"depth_m":20.0,
		"yaw_quadrants":idx%4,"district":"city","role":"auto","max_stories":2,
		"detail_profile":"high","terrain_samples_y":[0.0,0.0,0.0,0.0],"approach_clear":true}

func _bench() -> void:
	var parent := Node3D.new()
	root.add_child(parent)
	for count in [4,8,16,32]:
		var lots: Array = []
		for i in range(count): lots.append(_lot(i))
		var planned: Dictionary = Planner.plan_settlement(7302026,lots,true)
		if not planned["ok"]:
			results.append({"count":count,"status":"planning_failed","rejections":planned.get("rejections",[])})
			continue
		var started: int = Time.get_ticks_usec()
		var built: Dictionary = Builder.build_batch(parent,planned)
		var milliseconds: float = float(Time.get_ticks_usec()-started)/1000.0
		var meta: Dictionary = {"count":count,"status":"ok" if built["ok"] else str(built.get("code","failed")),
			"assemble_ms":milliseconds,
			"node_count":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
			"static_memory_bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC))}
		results.append(meta)
		if built["ok"]:
			for node in built["nodes"]: node.free()
		await process_frame
	var result := {"benchmarks":results,"engine":Engine.get_version_info().get("string","")}
	var f := FileAccess.open("res://qa/benchmark_last_run.json",FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(result,"  "))
		f.close()
	print("FORJA_BENCH_V2_FINAL ",JSON.stringify(result))
	quit(0)
