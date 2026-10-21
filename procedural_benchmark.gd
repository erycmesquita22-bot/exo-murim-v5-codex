extends SceneTree
const Seed=preload("res://procedural/world_state.gd")
const Loot=preload("res://procedural/loot_generator.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var world:=Seed.create(123456,"world_benchmark092")
	for i in range(100):Loot.generate(world,"warm/%d"%i,"blade",1,"item_1")
	var nodes_before: int=Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var resources_before: int=Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)
	var memory_before: float=Performance.get_monitor(Performance.MEMORY_STATIC)
	var samples: Array=[]
	for batch in range(5):
		var start:=Time.get_ticks_usec()
		for i in range(10000):Loot.generate(world,"batch/%d/%d"%[batch,i],["blade","mage","boss"][i%3],1+i%3,"item_%d"%(i+1))
		samples.append((Time.get_ticks_usec()-start)/1000.0)
	var result: Dictionary={"count_per_batch":10000,"batches_ms":samples,"warmup_count":100,"seed":123456,"node_delta":Performance.get_monitor(Performance.OBJECT_NODE_COUNT)-nodes_before,"resource_delta":Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)-resources_before,"retained_memory_delta_bytes":Performance.get_monitor(Performance.MEMORY_STATIC)-memory_before,"engine":Engine.get_version_info().string,"rules_sha256":FileAccess.get_sha256("res://data/loot_rules.json"),"method":"headless, generation only, each item released; no validation/JSON in timed region"}
	print("LOOT_BENCHMARK ",JSON.stringify(result));quit()
