extends SceneTree
## Execute with Godot 4.6.2 --headless --path HOST --script res://worldgen_v5/qa/native_probe.gd
## Real engine test (NOT EXECUTED unless raw Godot logs accompany artifact).
const AtlasPlanner = preload("res://genesis/world_planner.gd")
const WG4 = preload("res://genesis/v4/world_plan.gd")
const RegionData = preload("res://genesis/region_data.gd")
const Region = preload("res://convergence/region.gd")
const Gate = preload("res://worldgen_v5/runtime/atlas_gate.gd")
const Handoff = preload("res://worldgen_v5/runtime/settlement_handoff.gd")

func _initialize() -> void:
    call_deferred("execute")

func execute() -> void:
    var failures: Array[String] = []
    var checked: int = 0
    var materialized: int = 0
    for seed_text in ["101", "816204", "707"]:
        var base: Dictionary = AtlasPlanner.read_atlas("res://genesis/atlas_seed_" + seed_text + ".json") if seed_text in ["101", "816204"] else AtlasPlanner.plan(seed_text)
        var atlas: Dictionary = WG4.decorate(base, "wg5-native-probe", null)
        var result: Dictionary = Gate.validate(atlas)
        if not bool(result.get("ok", false)):
            failures.append("seed_" + seed_text + ":" + str(result.get("errors", [])))
            continue
        var first: int = -1
        for item in atlas["regions"]:
            if str(item.get("kind", "")) == "settlement":
                first = int(item["id"])
                break
        if first < 0:
            failures.append("no_settlement_" + seed_text)
            continue
        var data = RegionData.new(atlas, first)
        if data.settlement_plan.get("status", "") != "ready":
            failures.append("city_not_approved_" + seed_text)
            continue
        var parent: Node3D = Region.new()
        get_root().add_child(parent)
        parent.data = data
        var plan: Dictionary = Handoff.from_region(parent)
        if not bool(plan.get("ok", false)):
            failures.append("handoff:" + str(plan.get("error", "")))
        else:
            checked += 1
            var installed: Dictionary = Handoff.install(parent)
            if not bool(installed.get("ok", false)):
                failures.append("scene:" + str(installed.get("error", "")))
            else:
                materialized += int(installed["building_count"])
        parent.free()
    print("WG5_NATIVE_PROBE " + JSON.stringify({"checked": checked, "materialized": materialized, "failures": failures}))
    quit(0 if failures.is_empty() and checked == 3 and materialized > 0 else 1)
