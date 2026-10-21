extends SceneTree
## Runtime follow-up for Work: instantiate settlement scenes and check physics separately.
## Run with: godot --headless --path . --script res://tests/settlement_geometry.gd
const Planner=preload("res://genesis/world_planner.gd")
const Data=preload("res://genesis/region_data.gd")
const Scene=preload("res://genesis/region_scene.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var world := Planner.plan("101")
	var checked := 0
	var failures: Array=[]
	for rid in range(88):
		var spec: Dictionary=world.regions[rid]
		if spec.kind!="settlement":continue
		if checked>=3:break
		var data := Data.new(world,rid)
		if not data.validate().is_empty():
			failures.append({"rid":rid,"error":"region_data","details":data.validate()})
			continue
		var scene := Scene.new()
		root.add_child(scene)
		scene.build(data,[])
		var placed := 0
		for node in scene.props:
			if node.has_meta("building_id"):
				placed+=1
		if placed!=data.lots.size():failures.append({"rid":rid,"error":"instance_count","expected":data.lots.size(),"placed":placed})
		checked+=1
		scene.queue_free()
		await process_frame
	print("SETTLEMENT_GEOMETRY_RESULT="+JSON.stringify({"engine":Engine.get_version_info(),"regions_built":checked,"failures":failures}))
	quit(0 if failures.is_empty() and checked==3 else 1)
