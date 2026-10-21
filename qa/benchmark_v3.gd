extends SceneTree
## Colete tempos de instanciamento e contagem de nodes (NAO mede FPS).
const Fort = preload("res://forja/fortification_planner.gd")
const Wall = preload("res://forja/fortification_builder.gd")
const Civic = preload("res://forja/civic_planner.gd")
const Builder = preload("res://forja/civic_builder.gd")
const Compound = preload("res://forja/compound_assembler.gd")
var records: Array[Dictionary] = []
func _initialize() -> void:call_deferred("run")
func lot(id: String,role: String) -> Dictionary:
	return {"id":id,"role":role,"style":"stone","center_x":0.0,"center_z":0.0,"ground_y":0.0,
		"width_m":32.0,"depth_m":36.0,"yaw_quadrants":0,"terrain_samples_y":[0.0,0.0,0.0,0.0],
		"approach_clear":true,"detail_profile":"medium"}
func run() -> void:
	var parent := Node3D.new()
	root.add_child(parent)
	for count in [1,2,4,8]:
		for role in ["civic","fort","compound"]:
			var held: Array[Node3D] = []
			var start: int = Time.get_ticks_usec()
			for i in range(count):
				var parcel: Dictionary = lot("site_%d_%s" % [i,role],"sect_hall")
				parcel["center_x"] = float(i)*42.0
				var generated: Dictionary
				var created: Dictionary
				match role:
					"civic":
						generated = Civic.plan_civic(9911,parcel)
						created = Builder.build(parent,generated["plan"]) if generated["ok"] else generated
					"fort":
						generated = Fort.plan_fort(9911,parcel)
						created = Wall.build(parent,generated["plan"]) if generated["ok"] else generated
					"compound":
						generated = Compound.plan_compound(9911,parcel)
						created = Compound.build_compound(parent,generated) if generated["ok"] else generated
				if not bool(created.get("ok",false)):
					push_error("benchmark build failed " + str(created))
					quit(1)
					return
				held.append(created["node"])
			var us: int = Time.get_ticks_usec()-start
			records.append({"kind":role,"count":count,"microseconds":us,
				"nodes_live":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
				"static_mem_bytes":Performance.get_monitor(Performance.MEMORY_STATIC)})
			for obj in held:obj.free()
	var out: Dictionary = {"engine":Engine.get_version_info().get("string",""),"records":records,"measures_fps":false}
	var file := FileAccess.open("res://qa/benchmark_last_run_v3.json",FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(out,"  "))
		file.close()
	print("FORJA03_BENCHMARK ",JSON.stringify(out))
	quit(0)
