extends RefCounted
# Optional local decoration only. No change to WorldGenesis or gameplay RNG.
static func spawn(parent: Node3D, detail_seed: int, anchors: Array, hour: float) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = detail_seed
	var counts := {"butterfly":0,"cicada":0,"firefly":0}
	var caps := {"butterfly":3,"cicada":2,"firefly":8}
	var result: Array = []
	for anchor in anchors:
		var tag: String = anchor.tag
		var night := hour>=18 or hour<6
		var species := "firefly" if night and tag=="wetland" else "cicada" if not night and tag=="trunk" else "butterfly" if not night and tag in ["crop","flowers"] else ""
		if species.is_empty() or counts[species]>=caps[species]:continue
		if rng.randf()>.35:continue
		var id := "butterfly_01" if species=="butterfly" else species
		var node := Node3D.new()
		node.set_script(preload("res://godot/insect_prefab.gd"))
		node.model_id = id
		node.position = anchor.position
		node.set_meta("phase",rng.randf()*TAU)
		parent.add_child(node)
		if species=="cicada":node.rotation.x=PI/2
		counts[species]+=1
		result.append(node)
	return result
