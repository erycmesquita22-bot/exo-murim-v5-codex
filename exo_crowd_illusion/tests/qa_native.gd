extends SceneTree
const Planner = preload("res://exo_crowd_illusion/runtime/planner.gd")
const Director = preload("res://exo_crowd_illusion/runtime/director.gd")

func _initialize() -> void:
	call_deferred("_run")

func fail_case(reason: String) -> void:
	printerr("CROWD_NATIVE_QA_FAIL: ", reason)
	quit(1)

func _run() -> void:
	var zone: Dictionary = {"id":"qa/market","points":[[0.0,0.0,0.0],[26.0,0.0,0.0]],"capacity":30,"role":"merchant","activity":"walk","lateral":1.0}
	if not Planner.valid_zone(zone):
		fail_case("valid_zone");return
	var malformed := zone.duplicate(true)
	malformed["points"] = [[1.0,2.0]]
	if Planner.valid_zone(malformed):
		fail_case("invalid_coordinates_accepted");return
	var first: Dictionary = Planner.plan(zone,"TESTSEED",1.0)
	var second: Dictionary = Planner.plan(zone,"TESTSEED",1.0)
	if first.get("placed",-1) != second.get("placed",-2):
		fail_case("seed_count");return
	for i in range(first["agents"].size()):
		if first["agents"][i]["position"] != second["agents"][i]["position"]:
			fail_case("seed_position");return
	var reserved := [Vector3(0.5,0.0,0.5)]
	var avoided: Dictionary = Planner.plan(zone,"TESTSEED",1.0,reserved)
	if int(avoided.get("placed",0)) > int(first.get("placed",0)):
		fail_case("reserve_did_not_reduce_or_equal");return
	var host := Node3D.new()
	root.add_child(host)
	preload("res://exo_crowd_illusion/tests/npc_texture_fixture.gd").install(host)
	var focus := Node3D.new()
	host.add_child(focus)
	focus.position = Vector3(5,0,0)
	var director := Director.new()
	var result: Dictionary = director.attach_region(host,10,[zone],"TESTSEED",focus,false,12)
	if not bool(result.get("ok",false)):
		fail_case("attach_failed");return
	var report: Dictionary = director.status()
	if int(report.get("zones",0)) != 1 or int(report.get("ghosts",0)) <= 0:
		fail_case("status_count");return
	var root_crowd: Node3D = director.container
	var visual_zone: Node3D = root_crowd.get_child(0)
	if visual_zone.get_child_count() != 6:
		fail_case("six_multimesh_parts_expected");return
	for part in visual_zone.get_children():
		if not part is MultiMeshInstance3D:
			fail_case("not_batched_mesh");return
		if part.multimesh.instance_count != int(report["ghosts"]):
			fail_case("batch_population_mismatch");return
	if DisplayServer.get_name()=="headless":
		print("CROWD_FEET_GPU_TRANSFORM NOT_RUN headless_dummy; run rendered QA")
	else:
		visual_zone.focus=null;visual_zone.elapsed=100.0;visual_zone._update_visuals()
		for i in range(visual_zone.agents.size()):
			var foot:Vector3=visual_zone.instances["leg_r"].get_instance_transform(i)*Vector3(0,-0.375,0)
			if absf(foot.y-visual_zone._actor_pos(visual_zone.agents[i]).y)>0.001:
				fail_case("feet_not_grounded_at_destination");return
	if not director.notify_event("combat",Vector3(3,0,0)):
		fail_case("panic_event");return
	if director.notify_event("quest_reward",Vector3.ZERO):
		fail_case("unauthorized_event");return
	director.set_hour(1)
	var night: Dictionary = director.status()
	if int(night.get("ghosts",1000)) >= int(report["ghosts"]):
		fail_case("night_density");return
	director.set_mobile(true)
	if not bool(director.status().get("mobile",false)):
		fail_case("mobile_profile");return
	director.detach()
	if int(director.status().get("ghosts",-1)) != 0:
		fail_case("detach");return
	print("CROWD_NATIVE_QA_PASS: deterministic, validate, region, batched, reaction, night, mobile, detach")
	quit(0)
