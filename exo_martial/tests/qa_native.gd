extends SceneTree
# Run inside an existing EXO Core project: godot --headless --path PROJECT --script res://exo_martial/tests/qa_native.gd
const MartialEngine=preload("res://exo_martial/masters/martial_engine.gd")
const State=preload("res://exo_martial/progression/martial_state.gd")
const Catalog=preload("res://exo_martial/styles/martial_catalog.gd")
const Variants=preload("res://exo_martial/techniques/variants.gd")
const Entity=preload("res://exo_core/contracts/entity_contracts.gd")
const Bonds=preload("res://narrative/society/relationship_system.gd")
const Narrative=preload("res://narrative/core/narrative_state.gd")
var passes: int=0
var fails: Array=[]
func check(v: bool,name: String) -> void:
	if v:passes+=1
	else:fails.append(name)
func npc_record(id: String, role: String="master") -> Dictionary:
	return {"id":id,"role":role,"level":26,"active":true,"faction":"neutral","generation_version":1,"attributes":{"forca":15,"agilidade":14,"vitalidade":14,"inteligencia":14,"vontade":14,"sorte":14},"appearance":{}}
func make_save(seed: int=11) -> Dictionary:
	return {"version":4,"world":{"id":"martial_qa_world","seed":seed},"living_world":{"npcs":{},"reputation":{}},"narrative":Narrative.fresh(str(seed),"qa"),"journey_dynamic":{"progress":{"level":30}},"exo_martial":State.fresh(str(seed))}
func trial() -> void:
	var cat: Dictionary=Catalog.valid_catalogs()
	check(cat.ok,"catalogs_valid")
	check(Catalog.styles().size()==12,"style_count")
	check(Catalog.schools().size()==9,"school_count")
	check(Catalog.techniques().size()==16,"technique_count")
	var real: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/skills.json"))
	check(real is Array,"real_core_catalog_present")
	var skill_ids: Dictionary={}
	if real is Array:
		for t in real:skill_ids[str(t.get("id",""))]=t
	for t in Catalog.techniques():
		check(skill_ids.has(str(t.core_skill_id)),"mapped_core_skill:"+str(t.id))
		if skill_ids.has(str(t.core_skill_id)):
			var item: Dictionary=skill_ids[t.core_skill_id]
			check(int(t.resources.qi)==int(item.mana) and int(t.resources.stamina)==int(item.stamina),"energy_mapping:"+str(t.id))
	var save: Dictionary=make_save()
	var master: String="npc/r00/mestre_a"
	save.living_world.npcs[master]=npc_record(master)
	var player: String=Entity.player_id(save)
	var first: Dictionary=MartialEngine.discover(save,master)
	check(first.ok and first.changed,"discover")
	var profile: Dictionary=first.get("profile",{})
	check(not MartialEngine.discover(save,master).get("changed",true),"no_duplicates")
	check(MartialEngine.discover(save,"npc/r00/ghost").get("reason")=="npc_inexistente","unknown_npc_rejected")
	var same: Dictionary=make_save()
	same.living_world.npcs[master]=npc_record(master)
	check(MartialEngine.discover(same,master).get("profile",{})==profile,"deterministic_same_seed")
	var different: Dictionary=make_save(331)
	different.living_world.npcs[master]=npc_record(master)
	check(MartialEngine.discover(different,master).get("profile",{})!=profile,"seed_variation")
	var variation: Dictionary=Variants.descriptor("11",str(profile.school_id),str(profile.techniques[0]))
	check(variation==Variants.descriptor("11",str(profile.school_id),str(profile.techniques[0])),"variant_deterministic")
	check(variation.activation=="catalog_only" and variation.damage_multiplier==1.0,"no_core_damage_mutation")
	check(not MartialEngine.apply(save,player,master,{"trust":-100,"reputation":0},"app_denied").ok,"refuse_untrusted")
	check(MartialEngine.apply(save,player,master,{"trust":100,"reputation":10},"app1").ok,"admission_requested")
	check(not MartialEngine.apply(save,player,master,{"trust":100,"reputation":10},"app2").ok,"no_repeat_application")
	check(not MartialEngine.confirm_enrollment(save,player,master).ok,"narrative_bond_required")
	var a: String=Entity.npc_id(save,master)
	check(Bonds.establish(save.narrative,a,player,"master_disciple","qa/social-001",1.0),"narrative_owner_bond")
	check(MartialEngine.confirm_enrollment(save,player,master).ok,"confirm_after_bond")
	check(not MartialEngine.confirm_enrollment(save,player,master).get("changed",false),"idempotent_confirm")
	check(MartialEngine.relationship_status(save,player,master).status=="externo","discipleship_rank")
	save.living_world.npcs[master].active=false
	check(MartialEngine.relationship_status(save,player,master).status=="mestre_indisponivel","dead_or_missing_master")
	save.living_world.npcs[master].active=true
	var tech_id: String=str(profile.techniques[0])
	var allowed: Array=Catalog.style(str(profile.style_id)).weapon_families
	if not allowed.is_empty():
		check(not MartialEngine.start_lesson(save,player,master,tech_id,"tarefas").ok,"incompatible_gear")
		var weapon: String="sword"
		for family in allowed:
			var matches: Dictionary={"blade":"sword","katana":"katana","pole":"halberd","spear":"spear","unarmed":"gauntlets","fists":"gauntlets","dagger":"dagger","crossbow":"crossbow"}
			if matches.has(str(family)):weapon=str(matches[str(family)]);break
		save.equipped=weapon
	var lesson: Dictionary=MartialEngine.start_lesson(save,player,master,tech_id,"tarefas")
	check(lesson.ok,"lesson_created")
	check(not MartialEngine.start_lesson(save,player,master,tech_id,"tarefas").ok,"cannot_open_two_lessons")
	check(not MartialEngine.record_verified_practice(save,player,master,"wrong", "e0").ok,"wrong_lesson_rejected")
	var i: int=0
	var mastered: bool=false
	while i<8 and not mastered:
		for j in range(2):
			var proof: String="proof/%d/%d"%[i,j]
			check(MartialEngine.record_verified_practice(save,player,master,str(lesson.lesson_id),proof).ok,"practice_"+proof)
			check(not MartialEngine.record_verified_practice(save,player,master,str(lesson.lesson_id),proof).ok,"duplicate_"+proof)
		check(MartialEngine.demonstrate(save,player,master,"trial/%d"%i).ok,"demonstration")
		var finished: Dictionary=MartialEngine.finish_lesson(save,player,master)
		check(finished.ok,"lesson_completion")
		if finished.reason=="tecnica_aprendida":mastered=true
		i+=1
	check(mastered,"learning_after_training")
	var status: Dictionary=MartialEngine.relationship_status(save,player,master)
	check(status.techniques.has(tech_id),"technique_award")
	check(not MartialEngine.finish_lesson(save,player,master).ok,"no_repeat_reward")
	check(not MartialEngine.start_lesson(save,player,master,"exo_martial.technique.nao_existe","tarefas").ok,"invalid_technique")
	var alien: String=""
	for candidate in Catalog.techniques():
		if str(candidate.id) not in profile.techniques:alien=str(candidate.id);break
	check(not MartialEngine.start_lesson(save,player,master,alien,"tarefas").ok,"incompatible_master")
	check(MartialEngine.request_separation(save,player,master,"quit1").ok,"withdrawal_requested")
	check(not MartialEngine.finalize_separation(save,player,master).ok,"no_narrative_bypass")
	save.narrative.relationships.erase(Bonds.pair(a,player))
	check(MartialEngine.finalize_separation(save,player,master).ok,"finalize_after_bond_removed")
	check(MartialEngine.relationship_status(save,player,master).status=="suspenso","withdrawal_consequence")
	check(State.valid(save.exo_martial),"martial_domain_validation")
	var corrupt: Dictionary=save.exo_martial.duplicate(true)
	corrupt.training[MartialEngine.pair_key(player,master)].mastery=-300
	check(not State.valid(corrupt),"corrupt_mastery_rejected")
	var serialized: String=JSON.stringify(save.exo_martial)
	var loaded: Variant=JSON.parse_string(serialized)
	check(State.valid(loaded),"isolated_json_roundtrip")
	# 4,000 persistent NPCs, 1,800 narrative relationships and active NPC lessons.
	var stress: Dictionary=make_save(940)
	for n in range(2200):
		var mid: String="npc/r00/master%05d"%n
		var sid: String="npc/r00/student%05d"%n
		stress.living_world.npcs[mid]=npc_record(mid,"master")
		stress.living_world.npcs[sid]=npc_record(sid,"disciple")
		check(MartialEngine.discover(stress,mid).ok,"stress_master_%d"%n)
	for n in range(2000):
		var mid: String="npc/r00/master%05d"%n
		var sid: String="npc/r00/student%05d"%n
		var learner: String=Entity.npc_id(stress,sid)
		var mentor: String=Entity.npc_id(stress,mid)
		check(Bonds.establish(stress.narrative,learner,mentor,"master_disciple","social/stress/%d"%n,float(n)),"stress_social_%d"%n)
		check(MartialEngine.apply(stress,sid,mid,{"trust":100,"reputation":100},"app/stress/%d"%n).ok,"stress_apply_%d"%n)
		check(MartialEngine.confirm_enrollment(stress,sid,mid).ok,"stress_confirm_%d"%n)
	check(stress.narrative.relationships.size()==2000,"social_2000")
	check(stress.exo_martial.profiles.size()==2200,"profiles_2200")
	check(stress.exo_martial.training.size()==2000,"training_2000")
	check(Narrative.valid(stress.narrative),"narrative_domain_valid")
	check(State.valid(stress.exo_martial),"stress_domain_valid")
	check(MartialEngine.simulate_npc_day(stress,1,512).npc_progressed==512,"npc_day_1")
	check(not MartialEngine.simulate_npc_day(stress,1,512).ok,"npc_day_idempotence")
	check(MartialEngine.simulate_npc_day(stress,2,512).npc_progressed==512,"npc_day_2")
	check(MartialEngine.simulate_npc_day(stress,3,512).npc_progressed==512,"npc_day_3")
	check(MartialEngine.simulate_npc_day(stress,4,512).npc_progressed==512,"npc_day_4")
	var progressed: int=0
	for record in stress.exo_martial.training.values():
		if int(record.mastery)>0:progressed+=1
	check(progressed==2000,"fairness_all_2000_mentored")
	check(State.valid(stress.exo_martial),"after_sim_state_valid")
	# Export JSON and reload in a test-only file: NOT equivalent to v4 save transaction.
	var test_file: String="user://exo_martial_isolated_roundtrip.json"
	var file: FileAccess=FileAccess.open(test_file,FileAccess.WRITE)
	if file!=null:
		file.store_string(JSON.stringify(stress.exo_martial));file.close()
		check(State.valid(JSON.parse_string(FileAccess.get_file_as_string(test_file))),"isolated_storage_read")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_file))
	else:check(false,"isolated_storage_open")

func _initialize() -> void:
	trial()
	print("EXO_MARTIAL_NATIVE_QA ",JSON.stringify({"passed":passes,"failed":fails,"status":"PASS" if fails.is_empty() else "FAIL"}))
	quit(0 if fails.is_empty() else 1)
