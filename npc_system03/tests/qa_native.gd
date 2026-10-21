extends SceneTree
# Godot 4.6.2: godot --headless --path <COPY_OF_C3_WITH_NPC03> --script res://npc_system03/tests/qa_native.gd
const Mod = preload("res://npc_system03/module.gd")
const Queue = preload("res://npc_system03/core/queue.gd")
const Stable = preload("res://npc_system03/core/stable.gd")
const Identity = preload("res://npc_system03/core/identity.gd")
const Stations = preload("res://npc_system03/core/stations.gd")
const Patrol = preload("res://npc_system03/core/patrol.gd")
const Visual = preload("res://npc_system03/visuals/feminine_voxel.gd")
var successes: int = 0
var failures: Array = []
func check(ok: bool, name: String) -> void:
	if ok:
		successes += 1
	else:
		failures.append(name)
		printerr("FAIL:", name)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var person: Dictionary = {"id":"npc/r78/demo_1","generation_version":1, "role":"merchant", "life_stage":"adulto",
		"home_slot":"h1", "work_slot":"w1", "habit":"pontual", "personality":"sociavel",
		"routine_offset":0,"preferences":{"risk":45,"social":86,"duty":62,"curiosity":60,"ambition":50},
		"appearance":{"race":0,"robe":1,"hair":2,"skin":3,"style":0,"voice":1}}
	var other: Dictionary = person.duplicate(true)
	other.id = "npc/r78/demo_2"
	var module = Mod.new()
	check(Stable.choose("101",person.id,"g",10) == Stable.choose("101",person.id,"g",10), "seed_repeat")
	check(Stable.choose("101",person.id,"g",0) == -1,"zero_candidates")
	var appearance: Dictionary = module.appearance_preview(person, "101")
	check(str(appearance.get("status","")) == "PROPOSED", "appearance_proposal")
	check(person.appearance.voice == 1 and person.generation_version == 1, "legacy_unchanged")
	check(module.day_preview(person,0.0).size()==24, "full_day")
	check(str(module.encounter_preview(person, other, 1080.0, {}, false).get("status", "")) == "PROPOSED", "coworker_meeting")
	var young: Dictionary = person.duplicate(true)
	young.life_stage = "jovem"
	check(str(module.romance_preview(young, other, 1080.0, {}, true).get("status", "")) == "BLOCKED", "nonadult_romance")
	check(str(module.romance_preview(person, other, 1080.0, {}, false).get("status", "")) == "BLOCKED", "distance_romance")
	var q = Queue.new()
	var station: Dictionary = {"id":"m1", "host_approved":true,"navigable":true,"door_clear":true,
		"capacity":2,"queue_route_slots":["q1","q2"]}
	check(str(q.register_station(station).get("status",""))=="READY","queue_register")
	check(int(q.request("m1",person.id).get("index",-1))==0,"queue_order_0")
	check(int(q.request("m1",other.id).get("index",-1))==1,"queue_order_1")
	check(str(q.request("m1","npc/r78/third").get("reason",""))=="queue_full","queue_capacity")
	check(q.release("m1",person.id),"queue_release")
	check(int(q.request("m1","npc/r78/third").get("index",-1))==1,"queue_reuse")
	var routes: Dictionary = {"w1>p1":[Vector3.ZERO,Vector3(1,0,0)]}
	var listed: Array = [{"id":"station", "semantic":"market_stall","route_slot":"p1", "host_approved":true,
		"navigable":true,"host_owner":"WorldGenesis"}]
	check(str(Stations.propose(person,"market_stall",{"accepted_stations":listed,"routes":routes,"current_slot":"w1"}).get("status",""))=="PROPOSED","real_route")
	check(str(Stations.propose(person,"market_stall",{"accepted_stations":listed,"routes":{},"current_slot":"w1"}).get("status",""))=="BLOCKED","missing_route")
	check(str(module.crowd_view([person.id], {"owner":"exo_crowd_illusion","approved":true,"capacity":4}).get("status",""))=="PROPOSED","crowd_separation")
	check(str(module.lod_view(10000.0,false,false,false).get("tier",""))=="abstract","offscreen_lod")
	var guard: Dictionary = person.duplicate(true)
	guard.role = "guard"
	var stations: Array = [{"id":"a", "semantic":"guard_post", "route_slot":"a", "host_approved":true,
		"navigable":true, "host_owner":"WorldGenesis"}, {"id":"b", "semantic":"patrol_waypoint",
		"route_slot":"b", "host_approved":true,"navigable":true,"host_owner":"WorldGenesis"},
		{"id":"c", "semantic":"gate_station","route_slot":"c", "host_approved":true,
		"navigable":true,"host_owner":"WorldGenesis"}]
	check(str(Patrol.next_stop(guard, {}, {"accepted_stations":stations,"current_slot":"a",
		"seed":"101","routes":{"a>a":[Vector3.ZERO],"a>b":[Vector3.ZERO,Vector3(1,0,0)],"a>c":[Vector3.ZERO,Vector3(0,0,1)]}}).get("status",""))=="PROPOSED", "patrol_three_stops")
	check(str(Patrol.next_stop(guard, {}, {"accepted_stations":stations,"current_slot":"z",
		"routes":{}}).get("status",""))=="BLOCKED", "patrol_no_teleport")
	var robe: Node3D = Visual.build_preview(2)
	check(robe.get_child_count() == 14, "original_voxel_preview")
	robe.free()
	print("NPC03_NATIVE_RESULT ", JSON.stringify({"successes":successes,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
