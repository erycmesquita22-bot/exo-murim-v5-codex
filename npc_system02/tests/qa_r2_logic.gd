extends SceneTree
# Godot 4.6.2: --headless --path PROJECT --script res://npc_system02/tests/qa_r2_logic.gd
const Profile=preload("res://npc_system02/profile.gd")
const Social=preload("res://npc_system02/social.gd")
const Planner=preload("res://npc_system02/planner.gd")
const Stations=preload("res://npc_system02/stations.gd")
var checks:=0
var failed: Array=[]
func check(result: bool,name: String) -> void:
	checks+=1
	if not result:failed.append(name);push_error(name)
func _initialize() -> void:call_deferred("run")
func person(id: String,home: String,work: String,role: String="resident") -> Dictionary:
	var p: Dictionary={"id":id,"home_slot":home,"work_slot":work,"role":role,"faction":""}
	Profile.enrich(p,"101")
	return p
func run() -> void:
	var roster: Array=[]
	for i in range(66):
		roster.append(person("npc/r78/test_%02d"%i,"" if i<4 else "house_%02d"%int(i/3),"" if i<4 else "office_%02d"%int(i/6)))
	Profile.link_roster(roster)
	var by_id: Dictionary={}
	for p in roster:by_id[p.id]=p
	for p in roster:
		check(p.relations.size()<=3,"degree_"+p.id)
		for other_id in p.relations:
			check(p.id in by_id[other_id].relations,"reciprocal_"+p.id)
	for i in range(4):check(roster[i].relations.is_empty(),"empty_fields_%d"%i)
	var reordered: Array=[]
	for p in roster:reordered.append(person(p.id,p.home_slot,p.work_slot))
	reordered.reverse()
	Profile.link_roster(reordered)
	for p in reordered:check(p.relations==by_id[p.id].relations,"order_invariance_"+p.id)
	var a: Dictionary=person("npc/r78/A","house","smithy")
	var b: Dictionary=person("npc/r78/B","house","market")
	a.preferences.social=10;b.preferences.social=90
	check(Social.eligible(a,b,500),"shared_house_eligible")
	check(Social.meet(a,b,500),"meet_two")
	check(a.social_memory.has(b.id) and b.social_memory.has(a.id),"reciprocal_memory")
	check(a.social_memory[b.id].warmth==-1 and b.social_memory[a.id].warmth==1,"asymmetric_impression")
	check(not Social.meet(a,b,550),"pair_cooldown")
	check(Social.meet(a,b,600),"pair_cooldown_expires")
	check(a.social_memory[b.id].count==2 and b.social_memory[a.id].count==2,"encounter_count")
	for i in range(22):
		check(Social.remember(a,"npc/r78/extra_%02d"%i,900+i*100,1),"memory_write_%d"%i)
	check(a.social_memory.size()==Social.MAX_CONTACTS,"memory_bound")
	Social.compact(a,3000.0+Social.MEMORY_TTL+1.0)
	check(a.social_memory.is_empty(),"three_day_memory_expiry")
	var rival: Dictionary={"relationships":{Social.Relationships.pair(a.id,b.id):{"kind":"rival"}}}
	check(Social.story_bond(rival,a.id,b.id)=="rival","narrative_projection")
	check(not Social.eligible(a,b,8000,rival),"narrative_rival_blocks")
	var cautious: Dictionary=person("npc/r78/P","house","market","merchant")
	var daring: Dictionary=person("npc/r78/D","house","market","merchant")
	cautious.preferences.risk=10;daring.preferences.risk=91
	check(Planner.choose(cautious,900.0,{"danger_level":2}).activity=="evitar_risco","cautious_flees")
	check(Planner.choose(daring,900.0,{"danger_level":2}).activity=="observar_risco","daring_observes")
	var guard: Dictionary=person("npc/r78/G","house","post","guard")
	check(Planner.choose(guard,6*90.0,{"patrol_leg":0}).slot=="@square","patrol_leg0")
	check(Planner.choose(guard,6*90.0,{"patrol_leg":1}).slot=="@activity","patrol_leg1")
	check(Stations.resolve("master_station",guard)=="@activity","station_fallback")
	for hour in range(24):
		for p in [cautious,daring,guard]:
			var result: Dictionary=Planner.choose(p,90.0*hour)
			check(result.has("activity") and result.has("slot") and result.has("priority"),"day_%d_%s"%[hour,p.id])
	var output: Dictionary={"suite":"npc_system02_r2_logic","checks":checks,"failures":failed,"godot_version":Engine.get_version_info().get("string","")}
	print("EXO_NPC02_R2_LOGIC ",JSON.stringify(output))
	var file:=FileAccess.open("user://npc02_r2_logic.json",FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify(output,"\t"))
	quit(0 if failed.is_empty() else 1)
