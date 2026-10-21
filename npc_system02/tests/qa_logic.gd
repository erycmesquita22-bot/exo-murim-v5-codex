extends SceneTree
# Execute in Godot 4.6.2: --headless --path <project> --script res://npc_system02/tests/qa_logic.gd
const Profile=preload("res://npc_system02/profile.gd")
const Planner=preload("res://npc_system02/planner.gd")
const Crowd=preload("res://npc_system02/crowd.gd")
const People=preload("res://living_world/people.gd")
const WorldClock=preload("res://ai_core/world_clock.gd")
var failures: Array=[]
var passed:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,code: String) -> void:
	if ok:passed+=1
	else:failures.append(code);push_error(code)
func run() -> void:
	var roles: Array=People.PEOPLE.roles.keys()
	for seed in ["101","816204","72502","349812","15"]:
		var people: Array=[]
		for i in range(200):
			var role: String=str(roles[i%roles.size()])
			var slot: Dictionary={"id":"test_%03d"%i,"role":role,"home_slot":"home_%02d"%int(i/2),"work_slot":"work_%02d"%int(i/5)}
			var a: Dictionary=People.create(seed,i%88,slot,3)
			var b: Dictionary=a.duplicate(true)
			Profile.enrich(a,seed);Profile.enrich(b,seed)
			check(a==b,"stable_identity_%s_%d"%[seed,i])
			check(str(a.personality) in Profile.TEMPERAMENTS,"coherent_personality_%s_%d"%[seed,i])
			for h in range(24):
				var plan: Dictionary=Planner.choose(a,float(h)*WorldClock.SECONDS_PER_HOUR)
				check(plan.slot in [a.home_slot,a.work_slot,"@square","@activity"],"legal_slot_%s_%d_%d"%[seed,i,h])
			people.append(a)
		Profile.link_roster(people)
		var ids: Dictionary={}
		for person in people:
			check(not ids.has(person.id),"unique_id_%s_%s"%[seed,person.id])
			ids[person.id]=true
		for person in people:
			for friend in person.relations:check(friend!=person.id and ids.has(friend),"relation_valid_%s_%s"%[seed,person.id])
		var shuffled: Array=people.duplicate(true)
		shuffled.reverse()
		Profile.link_roster(shuffled)
		check(shuffled.size()==people.size(),"roster_size_%s"%seed)
	var farmer: Dictionary=People.create("101",9,{"id":"farm_a","role":"farmer","home_slot":"home","work_slot":"field"},2)
	Profile.enrich(farmer,"101")
	check(Planner.choose(farmer,12.0*90.0,{"danger":true}).slot=="home","flee_home")
	check(Planner.choose(farmer,12.0*90.0,{"danger":false}).slot=="@activity","resume_work")
	var guard: Dictionary=People.create("101",9,{"id":"guard_a","role":"guard","home_slot":"home","work_slot":"post"},2)
	Profile.enrich(guard,"101")
	check(Planner.choose(guard,8.0*90.0,{"danger":true}).activity!="evitar_risco","guard_does_not_flee")
	var report: Dictionary={"suite":"native_godot_logic","passed":passed,"failures":failures,"engine":Engine.get_version_info().get("string","unknown")}
	print("EXO_NPC02_LOGIC ",JSON.stringify(report))
	var file:=FileAccess.open("user://npc02_qa_logic.json",FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify(report,"\t"))
	quit(0 if failures.is_empty() else 1)
