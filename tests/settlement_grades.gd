extends SceneTree
## Diagnostic ONLY, not a guarantee of road usability; measures scene-sampled elevation changes.
## godot --headless --path . --script res://tests/settlement_grades.gd -- 101
const Planner = preload("res://genesis/world_planner.gd")
const Data = preload("res://genesis/region_data.gd")

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var seed_value: String = str(args[0]) if not args.is_empty() else "101"
	var world: Dictionary = Planner.plan(seed_value)
	var total_segments := 0
	var sharp_segments := 0
	var examples: Array = []
	var failing_regions: Dictionary = {}
	var start := Time.get_ticks_msec()
	for rid in range(88):
		var spec: Dictionary = world["regions"][rid]
		if spec["kind"] != "settlement":
			continue
		var data := Data.new(world, rid)
		if data.settlement_plan.get("status", "invalid") != "ready":
			if examples.size() < 20:
				examples.append({"region":rid,"kind":"invalid_settlement","reasons":data.settlement_plan.get("errors",[])})
			failing_regions[rid] = true
			continue
		for k in range(data.settlement_roads.size()):
			var segment: Dictionary = data.settlement_roads[k]
			var a: Vector2 = segment["a"]
			var b: Vector2 = segment["b"]
			var steps := maxi(1, ceili(a.distance_to(b) / 2.0))
			var previous := data.height_at(a)
			for m in range(1, steps + 1):
				var current: Vector2 = a.lerp(b, float(m) / float(steps))
				var height_value := data.height_at(current)
				var previous_position: Vector2 = a.lerp(b, float(m - 1) / float(steps))
				var grade := absf(height_value - previous) / maxf(0.001, current.distance_to(previous_position))
				total_segments += 1
				if grade > 0.65 or not is_finite(grade):
					sharp_segments += 1
					failing_regions[rid] = true
					if examples.size() < 20:
						examples.append({"region":rid,"street":k,"sample":m,"slope":grade,"position":[current.x,current.y]})
				previous = height_value
	print("SETTLEMENT_GRADES_RESULT=" + JSON.stringify({"seed":seed_value,"segments":total_segments,"over_65_percent":sharp_segments,"affected_regions":failing_regions.keys(),"examples":examples,"elapsed_ms":Time.get_ticks_msec()-start,"engine":Engine.get_version_info()}))
	# This diagnostic deliberately returns zero. Investigate its slope results separately.
	quit(0)
