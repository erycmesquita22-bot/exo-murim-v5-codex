extends SceneTree
# Godot runtime QA; execute in the original 09.4.6 project with this patch overlaid.
const World=preload("res://procedural/world_state.gd")
const Save=preload("res://journey_save.gd")
const State=preload("res://living_world/state.gd")
const People=preload("res://living_world/people.gd")
const Names=preload("res://living_world/names.gd")
const Fate=preload("res://living_world/fate.gd")
const Factions=preload("res://living_world/factions.gd")
const Quests=preload("res://living_world/quests.gd")
const Bridge=preload("res://living_world/bridge.gd")

var passed: int=0
var failures: Array=[]

class DeniedSave:
	extends RefCounted
	var data: Dictionary
	func _init(original: Dictionary):data=original.duplicate(true)
	func write() -> bool:return false

func check(condition: bool,label: String) -> void:
	if condition:passed+=1
	else:failures.append(label)

func _initialize() -> void:
	var slots: Array=[
		{"id":"house_01","role":"farmer","work_slot":"farm_01","home_slot":"house_01"},
		{"id":"market_01","role":"merchant","work_slot":"market_01","home_slot":"house_02"},
		{"id":"guild_01","role":"guild_agent","work_slot":"guild_01","home_slot":"house_03"},
		{"id":"watch_01","role":"guard","work_slot":"gate_01","home_slot":"house_04"},
		{"id":"dojo_01","role":"master","work_slot":"dojo_01","home_slot":"house_05"}
	]
	var used: Dictionary={}
	for seed in range(250):
		var a: Array=People.roster(str(seed),86,slots,3)
		var reverse_slots: Array=slots.duplicate(true)
		reverse_slots.reverse()
		var b: Array=People.roster(str(seed),86,reverse_slots,3)
		check(JSON.stringify(a)==JSON.stringify(b),"stable_order_%d"%seed)
		check(a.size()==5,"five_slots_%d"%seed)
		for npc in a:
			check(npc.id.begins_with("npc/r86/"),"stable_id_%d"%seed)
			check(npc.attributes.size()==6,"six_attributes_%d"%seed)
			check(People.activity(npc,2)=="descanso","schedule_rest_%d"%seed)
			used[npc.name]=true
	check(used.size()>40,"name_variety_250_seeds")
	check(Names.generate("123",86,"slot", "master")==Names.generate("123",86,"slot","master"),"name_replay")
	check(Fate.generate("123","hero")==Fate.generate("123","hero"),"fate_replay")
	for file in ["user://living_world_qa_save.json", "user://living_world_qa_save.json.tmp", "user://living_world_qa_save.json.bak"]:
		if FileAccess.file_exists(file):DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	var legacy: RefCounted=Save.new("user://living_world_qa_save.json",12345)
	check(legacy.valid(legacy.data),"existing_v4_save_valid")
	var old: Dictionary=legacy.data.duplicate(true)
	var denied: DeniedSave=DeniedSave.new(old)
	check(not Bridge.setup(denied).ok,"write_failure_detected")
	check(JSON.stringify(denied.data)==JSON.stringify(old),"save_failure_rollback")
	check(Bridge.setup(legacy).ok,"state_created_and_saved")
	check(State.valid(legacy.data.living_world),"state_valid")
	check(legacy.valid(legacy.data),"legacy_save_schema_unmodified")
	var state: Dictionary=legacy.data.living_world
	var c: Dictionary={"id":86,"kind":"settlement","settlement_scale":"village","difficulty":3,"services":["guild","healer","martial_school"]}
	var offers: Array=Quests.offers(c,5)
	check(offers.size()>=2,"settlement_contracts")
	check(Quests.offers(c,0).is_empty(),"intro_stage_gate")
	check(Quests.offers({"id":32,"kind":"ruins","difficulty":2},5).size()==1,"ruins_contract")
	var k: String=Quests.key(86,"vigia_dos_caminhos")
	check(Quests.accept(state,k),"accept")
	check(not Quests.accept(state,k),"no_duplicate_accept")
	check(Quests.emit(state,"road/86/marker/a","visit_site","road_marker",86,1)==1,"first_marker")
	check(Quests.emit(state,"road/86/marker/a","visit_site","road_marker",86,1)==0,"event_receipt_once")
	check(Quests.emit(state,"road/86/marker/b","visit_site","road_marker",86,1)==1,"second_marker")
	check(not Quests.claim(state,k),"cannot_claim_incomplete")
	check(Quests.emit(state,"road/86/bandit/1","defeat_enemy","bandit",86,1)==1,"bandit_progress")
	check(Quests.claim(state,k),"claim_once")
	var balance: Dictionary=state.balances.duplicate(true)
	check(not Quests.claim(state,k),"double_claim_rejected")
	check(state.balances==balance,"no_repeated_currency")
	check(Factions.standing(state,"guilda")=="neutro","faction_ranking")
	check(State.valid(state),"state_after_quest_valid")
	# Validate that the current game's own save accepts the extension and reloads it.
	check(legacy.write(),"write_existing_save")
	var reload: RefCounted=Save.new("user://living_world_qa_save.json",12345)
	check(reload.load_progress(),"reload_existing_save")
	check(reload.data.living_world.finished.has(k),"quest_completion_survives_reload")
	check(reload.data.living_world.balances==balance,"reward_survives_reload")
	var roster: Dictionary=Bridge.record_roster(reload,c,slots,"12345")
	check(roster.ok and roster.npcs.size()==5,"roster_materialized")
	check(reload.valid(reload.data),"save_after_npc_valid")
	check(not Bridge.claim_contract(reload,k),"bridge_no_double_claim")
	for file in ["user://living_world_qa_save.json", "user://living_world_qa_save.json.tmp", "user://living_world_qa_save.json.bak"]:
		if FileAccess.file_exists(file):DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	var report: Dictionary={"passed":passed,"failures":failures,"engine":Engine.get_version_info().get("string", "unknown")}
	var f: FileAccess=FileAccess.open("user://living_world_qa_result.json",FileAccess.WRITE)
	if f!=null:f.store_string(JSON.stringify(report));f.close()
	print("EXO_LIVING_WORLD_QA ",JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
