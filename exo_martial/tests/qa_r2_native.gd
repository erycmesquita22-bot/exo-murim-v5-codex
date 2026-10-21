extends SceneTree
# Candidate lab: use installed EXO Core project; NEVER run this against production save.
const MartialEngine=preload("res://exo_martial/r2/engine_r2.gd")
const State=preload("res://exo_martial/r2/state_r2.gd")
const Catalog=preload("res://exo_martial/styles/martial_catalog.gd")
const Legacy=preload("res://exo_martial/masters/martial_engine.gd")
const Narrative=preload("res://narrative/core/narrative_state.gd")
const Bonds=preload("res://narrative/society/relationship_system.gd")
const Entity=preload("res://exo_core/contracts/entity_contracts.gd")
var passes: int=0
var failures: Array=[]
func check(value: bool,code: String) -> void:
	if value:passes+=1
	else:failures.append(code)
func fixture(seed: int=12) -> Dictionary:
	var d: Dictionary={"version":4,"world":{"id":"r2_lab_world","seed":seed},"living_world":{"npcs":{},"reputation":{}},"narrative":Narrative.fresh(str(seed),"qa"),"journey_dynamic":{"progress":{"level":40}},"known":[],"learned":[],"items":[{"uid":"item_1","kind":"weapon","ref":"sword"}],"equipped":"item_1"}
	d["exo_martial"]=State.fresh(str(seed))
	return d
func add_master(s: Dictionary,id: String,level: int=30) -> void:
	s.living_world.npcs[id]={"id":id,"role":"master","level":level,"active":true,"faction":"neutral","hp":100}
func record(s: Dictionary,learner: String,master: String,action: String,marker: String,marker_type: String,idx: int,phase: String,success: bool=true) -> Dictionary:
	var t: Dictionary=s.exo_martial.training[MartialEngine.key(learner,master)]
	var sc: Dictionary=MartialEngine.school_for(s,master)
	return {"learner_id":learner,"master_id":master,"lesson_id":str(t.lesson_id),"action":action,"marker_type":marker_type,"marker_id":marker,"mode":"lab","event_id":"event/"+str(t.lesson_id)+"/"+str(idx)+"/"+phase,"qi_spent":int(sc.teaching.qi_cost),"stamina_spent":int(sc.teaching.stamina_cost),"success":success}
func run() -> void:
	check(Catalog.valid_catalogs().get("ok",false),"catalog")
	check(Catalog.schools().size()==9 and Catalog.styles().size()==12 and Catalog.techniques().size()==16,"catalog_counts")
	var unique_fingerprints: Dictionary={}
	for school in Catalog.schools():
		unique_fingerprints[JSON.stringify(school.teaching)]=true
	check(unique_fingerprints.size()==9,"nine_distinct_schools")
	var s: Dictionary=fixture()
	var a: String="npc/r00/m1"
	var b: String="npc/r00/m2"
	add_master(s,a);add_master(s,b)
	var learner: String=Entity.player_id(s)
	check(Legacy.discover(s,a).ok and Legacy.discover(s,b).ok,"discover_both")
	var profile: Dictionary=s.exo_martial.profiles[a]
	var sc: Dictionary=MartialEngine.school_for(s,a)
	var accepted: Dictionary={"trust":100,"reputation":100,"proofs_completed":9,"admission_trial_verified":true}
	check(not MartialEngine.apply(s,learner,a,{"trust":-99,"reputation":99,"proofs_completed":9,"admission_trial_verified":true},"denied").ok,"admission_denied")
	check(MartialEngine.apply(s,learner,a,accepted,"apply/A").ok,"apply_accepted")
	check(not MartialEngine.apply(s,learner,b,accepted,"apply/B").ok,"two_schools_pending")
	check(not MartialEngine.confirm(s,learner,a).ok,"cannot_invent_bond")
	var la: String=Legacy.identity(s,a)
	check(Bonds.establish(s.narrative,learner,la,"master_disciple","test_mock_bond",0.0),"mock_narrative_owner")
	check(MartialEngine.confirm(s,learner,a).ok,"bond_matched")
	check(not MartialEngine.confirm(s,learner,a).get("changed",false),"confirm_idempotent")
	var tech_id: String=str(profile.techniques[0])
	var method: String=""
	for m in sc.teaching.allowed_methods:
		var t: Dictionary=Catalog.technique(tech_id)
		if t.category in Catalog.method(str(m)).categories or "*" in Catalog.method(str(m)).categories:
			method=str(m);break
	check(not method.is_empty(),"allowed_teaching_method")
	# Resolve equipped UID via true inventory row, not equipped string as weapon ID.
	var forms: Dictionary={"blade":"sword","sword":"sword","draw":"katana","katana":"katana","pole":"halberd","spear":"spear","thrust":"spear","fists":"gauntlets","unarmed":"gauntlets","reverse":"dagger","dagger":"dagger","focus":"arcane_staff","wand":"wand","bow":"bow","crossbow":"crossbow"}
	var style: Dictionary=Catalog.style(str(profile.style_id))
	if not style.weapon_families.is_empty():
		var pose: String=str(style.weapon_families[0])
		s.items[0].ref=str(forms.get(pose,"sword"))
	var plan: Dictionary=MartialEngine.begin_lesson(s,learner,a,tech_id,method,"lab/lane")
	check(plan.ok,"individual_lesson_started")
	check(not MartialEngine.begin_lesson(s,learner,a,tech_id,method,"lab/lane").ok,"no_parallel_lesson")
	if not plan.ok:return
	var guide: Dictionary=sc.teaching
	var ob: Dictionary=record(s,learner,a,str(guide.observation_action),"lab/lane",str(guide.class_marker),0,"observe")
	check(not MartialEngine.record_action(s,learner,a,record(s,learner,a,"invalid_action","lab/lane",str(guide.class_marker),0,"invalid")).ok,"wrong_observation")
	check(MartialEngine.record_action(s,learner,a,ob).ok,"observed_real_action")
	check(not MartialEngine.record_action(s,learner,a,ob).ok,"observation_replay")
	for i in range(int(guide.practice_repetitions)):
		var proof: Dictionary=record(s,learner,a,str(guide.practice_action),"lab/lane",str(guide.class_marker),i+1,"practice")
		if i==0:
			var wrong: Dictionary=proof.duplicate();wrong.qi_spent=0;wrong.stamina_spent=0
			if int(guide.qi_cost)+int(guide.stamina_cost)>0:check(not MartialEngine.record_action(s,learner,a,wrong).ok,"resource_verified")
		check(MartialEngine.record_action(s,learner,a,proof).ok,"practice_%d"%i)
		check(not MartialEngine.record_action(s,learner,a,proof).ok,"no_xp_replay_%d"%i)
	var trial: Dictionary=record(s,learner,a,str(guide.examination_action),"lab/trial",str(guide.exam_marker),88,"exam")
	trial.success=false
	check(not MartialEngine.record_action(s,learner,a,trial).ok,"failed_trial_rejected")
	trial.success=true
	check(MartialEngine.record_action(s,learner,a,trial).ok,"trial_success")
	var before: int=int(s.exo_martial.training[MartialEngine.key(learner,a)].mastery)
	var completed: Dictionary=MartialEngine.finish_lesson(s,learner,a)
	check(completed.ok,"lesson_final")
	check(int(s.exo_martial.training[MartialEngine.key(learner,a)].mastery)>before,"mastery_only_on_completion")
	check(not MartialEngine.finish_lesson(s,learner,a).ok,"final_replay_blocked")
	if completed.get("reason")=="aguardando_desbloqueio_core":
		check(not MartialEngine.confirm_core_unlock(s,learner,a,tech_id).ok,"core_not_yet_authorized")
		var core_id: String=str(Catalog.technique(tech_id).core_skill_id)
		s.known.append(core_id);s.learned.append(core_id) # LAB ONLY: mock of core-owned transaction.
		check(MartialEngine.confirm_core_unlock(s,learner,a,tech_id).ok,"core_proof_confirmed")
		check(not MartialEngine.confirm_core_unlock(s,learner,a,tech_id).ok,"core_grant_idempotence")
	# Withdrawal, transfer and dead master's continuity are independent of gameplay node simulation.
	check(MartialEngine.request_separation(s,learner,a,"transfer","leave/a").ok,"transfer_requested")
	check(not MartialEngine.finalize_separation(s,learner,a).ok,"narrative_not_removed")
	s.narrative.relationships.erase(Bonds.pair(learner,la)) # LAB OWNER MOCK ONLY
	check(MartialEngine.finalize_separation(s,learner,a).ok,"transfer_finalized")
	check(MartialEngine.apply(s,learner,b,accepted,"apply/second").ok,"new_school_allowed")
	var lb: String=Legacy.identity(s,b)
	check(Bonds.establish(s.narrative,learner,lb,"master_disciple","test_mock_bond_2",0.0),"mock_second_bond")
	check(MartialEngine.confirm(s,learner,b).ok,"new_master_confirmed")
	s.living_world.npcs[b].active=false
	check(not MartialEngine.begin_lesson(s,learner,b,str(s.exo_martial.profiles[b].techniques[0]),method,"lab/side").ok,"master_removed")
	s.living_world.npcs[b].active=true
	check(State.valid(s.exo_martial),"r2_state_valid")
	var clone: Variant=JSON.parse_string(JSON.stringify(s.exo_martial))
	check(State.valid(clone),"reload_doesnt_complete")
	check(MartialEngine.relation(s,learner,b).status=="ativo","relationship_consistent")
	# Two existing NPC students at one collective marker, two distinct lesson receipts.
	var group: Dictionary=fixture(18)
	var mentor: String="npc/r00/group_teacher"
	add_master(group,mentor)
	check(Legacy.discover(group,mentor).ok,"group_master")
	var main_skill: String=str(group.exo_martial.profiles[mentor].techniques[0])
	var group_school: Dictionary=MartialEngine.school_for(group,mentor)
	var group_method: String=""
	for candidate in group_school.teaching.allowed_methods:
		var rule: Dictionary=Catalog.method(str(candidate))
		if Catalog.technique(main_skill).category in rule.categories or "*" in rule.categories:
			group_method=str(candidate);break
	check(not group_method.is_empty(),"group_method")
	for idx in range(2):
		var sid: String="npc/r00/group_student_%d"%idx
		group.living_world.npcs[sid]={"id":sid,"role":"disciple","level":40,"active":true,"hp":100,"faction":"neutral"}
		check(MartialEngine.apply(group,sid,mentor,accepted,"group/app/%d"%idx).ok,"group_apply_%d"%idx)
		check(Bonds.establish(group.narrative,Legacy.identity(group,sid),Legacy.identity(group,mentor),"master_disciple","mock_group_%d"%idx,1.0),"group_bond_%d"%idx)
		check(MartialEngine.confirm(group,sid,mentor).ok,"group_enroll_%d"%idx)
		check(MartialEngine.begin_lesson(group,sid,mentor,main_skill,group_method,"lab/shared_dojang").ok,"group_begin_%d"%idx)
	var member1: String="npc/r00/group_student_0"
	var member2: String="npc/r00/group_student_1"
	var watch: Dictionary=record(group,member1,mentor,str(group_school.teaching.observation_action),"lab/shared_dojang",str(group_school.teaching.class_marker),11,"collective")
	check(MartialEngine.record_action(group,member1,mentor,watch).ok,"group_first_progress")
	check(str(group.exo_martial.training[MartialEngine.key(member2,mentor)].phase)=="observing","group_second_untouched")
	check(MartialEngine.record_action(group,member2,mentor,record(group,member2,mentor,str(group_school.teaching.observation_action),"lab/shared_dojang",str(group_school.teaching.class_marker),12,"collective")).ok,"group_second_progress")
	# Promotion exam idempotence against school policy, using an isolated lab state.
	var groom: Dictionary=group.exo_martial.training[MartialEngine.key(member1,mentor)]
	groom.phase="ready";groom.mastery=300;groom.completed_lessons=6;groom.practice=0;groom.lesson_goal=0;groom.r2.practice_done=0;groom.r2.observation_done=false
	var exam_id: String="exam/"+MartialEngine.key(member1,mentor).substr(0,32)+"/rank/4"
	var ex: Dictionary={"exam_id":exam_id,"action":str(group_school.teaching.examination_action),"marker_type":str(group_school.teaching.exam_marker),"success":true,"event_id":"group/promotion/r4"}
	check(MartialEngine.promotion_exam(group,member1,mentor,ex).ok,"promotion_exam_pass")
	check(not MartialEngine.promotion_exam(group,member1,mentor,ex).ok,"promotion_not_repeated")
	check(State.valid(group.exo_martial),"group_state_valid")
	var stress: Dictionary=fixture(961)
	for i in range(1800):
		var nid: String="npc/r00/stress%05d"%i
		add_master(stress,nid)
		check(Legacy.discover(stress,nid).ok,"stress_%d"%i)
	check(stress.exo_martial.profiles.size()==1800,"stress_1800_unique")
	check(State.valid(stress.exo_martial),"stress_valid")
func _initialize() -> void:
	run()
	print("EXO_MARTIAL_R2_NATIVE_QA ",JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","passed":passes,"failed":failures}))
	quit(0 if failures.is_empty() else 1)
