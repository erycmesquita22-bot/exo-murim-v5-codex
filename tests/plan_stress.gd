extends SceneTree
const P=preload("res://genesis/world_planner.gd")
const R=preload("res://genesis/region_data.gd")
func _init() -> void:call_deferred("run")
func run() -> void:
	var count := 2048
	for arg in OS.get_cmdline_user_args():
		if arg.is_valid_int():count=int(arg)
	var started := Time.get_ticks_usec();var failures: Array=[];var timings: Array=[];var regional: Array=[];var repeats := 0
	for seed_value in range(count):
		var t := Time.get_ticks_usec();var w := P.plan(seed_value);timings.append((Time.get_ticks_usec()-t)/1000.0)
		var errors := P.validate(w)
		if not errors.is_empty():failures.append({"seed":seed_value,"phase":"planner","errors":errors})
		# Every seed builds and checks an actual native regional descriptor, rotating all IDs.
		t=Time.get_ticks_usec();var r := R.new(w,seed_value%88);var re := r.validate();regional.append((Time.get_ticks_usec()-t)/1000.0)
		if not re.is_empty():failures.append({"seed":seed_value,"rid":seed_value%88,"phase":"regional","errors":re})
		if seed_value%64==0:
			var other := P.plan(seed_value)
			if JSON.stringify(w)!=JSON.stringify(other):failures.append({"seed":seed_value,"phase":"repeat_planner"})
			var rr := R.new(other,seed_value%88)
			if r.digest()!=rr.digest():failures.append({"seed":seed_value,"phase":"repeat_region"})
			var loaded := P.roundtrip(w)
			if str(w.regions[0].region_seed)!=str(loaded.regions[0].region_seed):failures.append({"seed":seed_value,"phase":"seed_roundtrip"})
			repeats+=1
		if seed_value%256==0:print("PROGRESS ",seed_value," failures ",failures.size())
	var result := {"engine":Engine.get_version_info(),"count":count,"regions_planned":count*88,"regional_descriptors":count,"repeated_worlds":repeats,"failures":failures,"planner_ms":stats(timings),"regional_descriptor_ms":stats(regional),"elapsed_s":(Time.get_ticks_usec()-started)/1000000.0,"scope":"Native Godot logical/regional descriptors; not 180224 instantiated 3D scenes"}
	FileAccess.open("res://evidence/stress.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print(JSON.stringify(result));quit(0 if failures.is_empty() else 1)
func stats(values: Array) -> Dictionary:
	values.sort();var sum := 0.0
	for v in values:sum+=v
	return {"mean":sum/values.size(),"p50":values[int(values.size()*.5)],"p95":values[int(values.size()*.95)],"max":values[-1]}
