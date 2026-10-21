extends SceneTree
## Native test; execute: godot --headless --path . --script res://exo_crowd_illusion/tests/qa_native_r4.gd
const Planner = preload("res://exo_crowd_illusion/runtime/planner.gd")
const Director = preload("res://exo_crowd_illusion/runtime/director.gd")
const Adapter = preload("res://exo_crowd_illusion/runtime/region_adapter.gd")
class MockData:
	extends RefCounted
	var spec: Dictionary = {"kind": "settlement", "settlement_scale": "village", "id": 13}
	var settlement_plan: Dictionary = {"status": "ready"}
	var lots: Array = []
	func height_at(_pos: Vector2) -> float:
		return 0.0
class MockRegion:
	extends Node3D
	var data: RefCounted
	var station_points: Dictionary = {}

var assertions := 0
func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> bool:
	assertions += 1
	if not condition:
		printerr("CROWD_R4_NATIVE_FAIL | " + label)
		quit(1)
		return false
	return true

func _run() -> void:
	var zone: Dictionary = {"id": "cf/r13/main", "points": [[0.0,0.0,0.0],[28.0,0.0,0.0]], "capacity": 30, "role": "merchant", "activity": "walk", "lateral": 0.12, "safety_radius": 2.0}
	if not _check(Planner.valid_zone(zone), "valid_zone"): return
	var poison := zone.duplicate(true)
	poison["points"][0][0] = NAN
	if not _check(not Planner.valid_zone(poison), "reject_nan_coordinates"): return
	poison = zone.duplicate(true)
	poison["points"] = [[1.0, 1.0, 1.0], [1.0,1.0,1.0]]
	if not _check(not Planner.valid_zone(poison), "reject_degenerate_road"): return
	poison = zone.duplicate(true)
	poison["lateral"] = INF
	if not _check(not Planner.valid_zone(poison), "reject_inf_lateral"): return
	if not _check(not bool(Planner.plan(zone, "x", NAN).get("ok", true)), "reject_nan_density"): return
	var first: Dictionary = Planner.plan(zone, "seed", 1.0)
	var second: Dictionary = Planner.plan(zone, "seed", 1.0)
	if not _check(first == second, "determinism"): return
	var segment_obstacle: Array = [Vector3(14, 0, 0.12)]
	var avoided: Dictionary = Planner.plan(zone, "seed", 1.0, segment_obstacle)
	if not _check(int(avoided.get("placed", 999)) <= int(first.get("placed", 0)), "reserved_route"): return
	var region := MockRegion.new()
	region.data = MockData.new()
	root.add_child(region)
	preload("res://exo_crowd_illusion/tests/npc_texture_fixture.gd").install(region)
	region.set_meta("cidade_viva", {"rendered": true})
	if not _check(str(Adapter.from_r13_region(region).get("reason", "")) == "village_requires_authored_safe_zones", "village_fail_closed"): return
	region.set_meta("exo_city_forge_crowd_zones", [zone])
	region.set_meta("city_forge_physical", {"owner":"city_forge_r4","buildings":1})
	var physical_fixture:=Node3D.new();region.add_child(physical_fixture)
	if not _check(str(Adapter.from_r13_region(region).get("reason", "")) == "physical_geometry_receipt_required", "no_receipt_fail_closed"): return
	var receipt := {"version": "1.0.0", "owner": "WorldGenesis", "region_id": 13, "geometry_revision": "geometry/test/1", "geometry_materialized": true, "collision_checked": true, "lane_envelopes_checked": true, "safe_zone_ids": [zone.id]}
	region.set_meta("exo_crowd_geometry_receipt", receipt)
	region.set_meta("exo_crowd_geometry_revision", "geometry/test/1")
	if not _check(bool(Adapter.from_r13_region(region).get("ok", false)), "authorized_geometry_allowed"): return
	receipt["region_id"] = 14
	region.set_meta("exo_crowd_geometry_receipt", receipt)
	if not _check(not bool(Adapter.from_r13_region(region).get("ok", false)), "foreign_receipt_rejected"): return
	receipt["region_id"] = 13
	region.set_meta("exo_crowd_geometry_receipt", receipt)
	physical_fixture.free()
	var director := Director.new()
	var zero: Dictionary = director.attach_region(region,13,[zone],"seed",null,false,12)
	if not _check(bool(zero.get("ok", false)), "create_visual_container"): return
	var first_count := int(director.status().get("ghosts", 0))
	if not _check(first_count > 0, "positive_population"): return
	director.set_density(0.0)
	if not _check(int(director.status().get("ghosts", -1)) == 0 and director.source_zones.size() == 1, "density_zero_retains_authored_zones"): return
	director.set_density(1.0)
	if not _check(int(director.status().get("ghosts", 0)) == first_count, "zero_to_high_restores_deterministically"): return
	director.set_density(INF)
	if not _check(int(director.status().get("ghosts", 0)) == first_count, "reject_nonfinite_density_without_erase"): return
	for hour in range(24):
		director.set_hour(hour)
		if not _check(int(director.status().get("ghosts", 0)) <= 180, "24h_hard_cap_%s" % str(hour)): return
	for i in range(100):
		var result: Dictionary = director.attach_region(region,13,[zone],"seed",null,i%2==0,12)
		if not _check(bool(result.get("ok", false)) and region.get_child_count() == 1, "reentry_no_orphan_%s" % str(i)): return
	if not _check(director.notify_event("danger", Vector3(5,0,0)), "visual_reaction"): return
	if not _check(not director.notify_event("quest_reward",Vector3.ZERO), "no_gameplay_event"): return
	director.detach()
	if not _check(director.status().get("ghosts", 1) == 0 and region.get_child_count() == 0, "detach_removes_all"): return
	print("CROWD_R4_NATIVE_PASS | assertions=" + str(assertions) + " | physics_performance_NOT_MEASURED")
	quit(0)
