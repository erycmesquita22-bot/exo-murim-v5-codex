extends SceneTree
## Work/CI regression: executable Godot runner. The presence of this file is not a passed test.
const Planner = preload("res://genesis/world_planner.gd")
const Data = preload("res://genesis/region_data.gd")
const Settlement = preload("res://genesis/settlements/settlement_planner.gd")

func _initialize() -> void:
	var failures: Array = []
	var checked := 0
	var lots_checked := 0
	var scales := {"village":0,"town":0,"city":0}
	var seeds := ["101", "707", "816204", "9007199254740993", "9223372036854775807"]
	# Optional stress: -- 1000. Uses a deterministic set, independent of the world seed.
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		var extra := clampi(int(args[0]), 0, 10000)
		for k in range(extra):seeds.append(str(1000003 + k * 7919))
	for seed_value in seeds:
		var world: Dictionary = Planner.plan(seed_value)
		var world_errors: Array = Planner.validate(world)
		if not world_errors.is_empty():
			failures.append({"seed":seed_value,"error":"atlas","details":world_errors})
			continue
		for rid in range(88):
			var spec: Dictionary = world.regions[rid]
			if spec.kind!="settlement":continue
			var region := Data.new(world,rid)
			var errors: Array = Settlement.validate(region.settlement_plan,region.gates,region.rivers,region.half,region.river_hub)
			if not errors.is_empty():failures.append({"seed":seed_value,"rid":rid,"error":"plan","details":errors})
			if region.lots.size()!=int(region.settlement_plan.get("target",0)):
				failures.append({"seed":seed_value,"rid":rid,"error":"lot_count"})
			if region.settlement_plan.get("status", "invalid")=="ready":
				var contract: Dictionary = Settlement.export_contract(region.settlement_plan)
				var text_contract := JSON.stringify(contract)
				var loaded = JSON.parse_string(text_contract)
				if not (loaded is Dictionary) or loaded["lots"].size()!=contract["lots"].size():
					failures.append({"seed":seed_value,"rid":rid,"error":"json_contract"})
			var again := Data.new(world,rid)
			if JSON.stringify(Settlement.export_contract(region.settlement_plan))!=JSON.stringify(Settlement.export_contract(again.settlement_plan)):
				failures.append({"seed":seed_value,"rid":rid,"error":"nondeterministic"})
			checked+=1
			lots_checked+=region.lots.size()
			scales[spec.settlement_scale]+=1
	var output := {"suite":"settlement_core_v1", "engine":Engine.get_version_info(), "seeds":seeds,"settlements_checked":checked,"lots_checked":lots_checked,"scales":scales,"failures":failures}
	print("SETTLEMENT_QA_RESULT="+JSON.stringify(output))
	quit(0 if failures.is_empty() else 1)
