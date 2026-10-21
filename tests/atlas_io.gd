extends SceneTree
const P=preload("res://genesis/world_planner.gd")
const R=preload("res://genesis/region_data.gd")
func _init() -> void:
	var failures: Array=[];var seeds := ["101","9007199254740993","9223372036854775807"]
	for seed_value in seeds:
		var world := P.plan(seed_value)
		var path: String= "user://atlas_io_"+seed_value+".json"
		if P.save_atlas(world,path)!=OK:failures.append({"seed":seed_value,"phase":"save"});continue
		var loaded := P.read_atlas(path)
		if not P.validate(loaded).is_empty():failures.append({"seed":seed_value,"phase":"reload_validation"})
		if loaded.seed!=seed_value:failures.append({"seed":seed_value,"phase":"world_seed"})
		for rid in range(88):
			if loaded.regions[rid].region_seed!=world.regions[rid].region_seed:failures.append({"seed":seed_value,"rid":rid,"phase":"region_seed"})
		var before := R.new(world,0);var after := R.new(loaded,0)
		if before.digest()!=after.digest():failures.append({"seed":seed_value,"phase":"regional_reload"})
		if seed_value=="101":P.save_atlas(world,"res://evidence/native_atlas_seed101.json")
	var result := {"engine":Engine.get_version_info(),"seeds":seeds,"region_seed_roundtrips":seeds.size()*88,"failures":failures}
	FileAccess.open("res://evidence/atlas_io.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"));print(JSON.stringify(result));quit(0 if failures.is_empty() else 1)
