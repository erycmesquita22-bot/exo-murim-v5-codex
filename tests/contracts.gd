extends SceneTree
const P=preload("res://genesis/world_planner.gd")
const R=preload("res://genesis/region_data.gd")
var failures: Array=[]
func _init() -> void:call_deferred("run")
func run() -> void:
	var tested := 0;var gates := 0;var rivers := 0
	var digest_rows: Array=[]
	for seed_value in [101,816204]:
		var world := P.read_atlas("res://genesis/atlas_seed_%d.json"%seed_value)
		var errors := P.validate(world)
		if not errors.is_empty():failures.append({"seed":seed_value,"phase":"legacy_atlas","errors":errors})
		var region_data: Array=[]
		for rid in range(88):
			var r := R.new(world,rid);region_data.append(r);tested+=1
			var re := r.validate()
			if not re.is_empty():failures.append({"seed":seed_value,"rid":rid,"errors":re})
			# Entire width of each lane, not only its centre line.
			for g in r.gates:
				var normal: Vector2=Vector2(-g.p.y,g.p.x).normalized()
				for side in [-1,0,1]:
					var prev := r.height_at(normal*side*3.5)
					for step in range(1,257):
						var point: Vector2=g.p*step/256.0+normal*side*3.5
						var h := r.height_at(point)
						if absf(h-prev)/(g.p.length()/256.0)>.65:failures.append({"seed":seed_value,"rid":rid,"phase":"lane_grade","gate":g.id});break
						prev=h
				gates+=1
			if rid in [32,46,52,61,63,78,86]:digest_rows.append({"seed":str(seed_value),"rid":rid,"digest":r.digest(),"region_seed":str(r.spec.region_seed)})
		for r in region_data:
			for rv in r.rivers:
				var counterpart: Array=region_data[rv.neighbor].rivers.filter(func(v):return v.neighbor==int(r.spec.id))
				if counterpart.size()!=1 or absf(counterpart[0].height-rv.height)>.000001:failures.append({"seed":seed_value,"phase":"river_contract","rid":r.spec.id})
				rivers+=1
	var path := "res://evidence/region_digests.json"
	var prior = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if prior!=null:
		if prior.size()!=digest_rows.size():failures.append("second_process_row_count")
		else:
			for index in range(prior.size()):
				if prior[index].digest!=digest_rows[index].digest or prior[index].seed!=digest_rows[index].seed or int(prior[index].rid)!=int(digest_rows[index].rid):failures.append("second_process_digests_differ")
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(digest_rows))
	var result := {"engine":Engine.get_version_info(),"legacy_worlds":2,"regional_descriptors":tested,"gate_lanes":gates,"river_endpoints":rivers,"second_process":prior!=null,"failures":failures}
	FileAccess.open("res://evidence/contracts.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print(JSON.stringify(result));quit(0 if failures.is_empty() else 1)
