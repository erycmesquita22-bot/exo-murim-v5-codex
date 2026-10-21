extends SceneTree
const Atlas=preload("res://genesis/world_planner.gd")
const Bridge=preload("res://narrative/adapters/journey_bridge.gd")
const Scheduler=preload("res://narrative/core/narrative_scheduler.gd")
const Destiny=preload("res://narrative/destiny/destiny_generator.gd")
const Registry=preload("res://narrative/factions/faction_registry.gd")
const State=preload("res://narrative/core/narrative_state.gd")
var checks:=0
var failures: Array=[]
func check(condition: bool,label: String) -> void:
	checks+=1
	if not condition:failures.append(label)
func event(id: String,kind: String,region: int,clock: float,npc_id: String="",context: Dictionary={}) -> Dictionary:
	return {"id":id,"type":kind,"source":"qa_fixture","region":region,"clock":clock,"npc_id":npc_id,"context":context}
func _initialize() -> void:
	var started:=Time.get_ticks_usec()
	var atlas: Dictionary=Atlas.read_atlas("res://genesis/atlas_seed_101.json")
	check(Atlas.validate(atlas).is_empty(),"atlas_101_valid")
	var npc_id: String="npc/r86/narrative_fixture"
	var npc: Dictionary={"id":npc_id,"region_id":86,"faction":"comunidade","role":"disciple"}
	var save: Dictionary={"character":{"name":"Viajante"},"living_world":{"npcs":{}}}
	save.living_world.npcs[npc_id]=npc
	save.living_world.npcs[npc_id+"2"]={"id":npc_id+"2","region_id":86,"role":"master"}
	var s: Dictionary=Bridge.ensure(save,atlas)
	check(State.valid(s),"state_valid")
	check(not s.destiny.is_empty(),"destiny_exists")
	var hooks: Array=Bridge.opportunities(save,atlas,86)
	check(hooks.size()==3,"three_scenarios")
	var second: Array=Bridge.opportunities(save,atlas,86)
	check(hooks==second,"hook_determinism")
	for hook in hooks:
		check(int(hook.region)>=0 and int(hook.region)<88,"reachable_region")
		check(npc_id in hook.npc_ids,"real_npc_reference")
	var encounter: Dictionary=event("npc/help/001","npc_helped",86,910,npc_id)
	check(bool(Bridge.ingest(save,atlas,encounter).get("ok",false)),"help_valid")
	check(not bool(Bridge.ingest(save,atlas,encounter).get("changed",true)),"duplicate_no_change")
	var ctx: Dictionary=Bridge.context_for(save,atlas,npc_id,911)
	check(int(ctx.trust)==8,"trust_help")
	check(bool(Bridge.ingest(save,atlas,event("npc/attack/001","npc_attacked",86,920,npc_id)).get("ok",false)),"attack_valid")
	check(int(Bridge.context_for(save,atlas,npc_id,921).trust)==-7,"trust_conflict_separate_from_karma")
	check(bool(Bridge.ingest(save,atlas,event("social/mentor/01","social_bond_formed",86,923,npc_id,{"other_npc_id":npc_id+"2","bond":"master_disciple"})).get("ok",false)),"master_disciple_bond")
	check(s.relationships.size()==1,"social_link_persisted")
	check(not bool(Bridge.ingest(save,atlas,event("unknown","npc_helped",86,922,"npc/invalid")).get("ok",true)),"invalid_npc_rejected")
	for hook in hooks:
		var outcome: String=str(hook.outcomes[0])
		var r: Dictionary=Bridge.ingest(save,atlas,event("choice/"+str(hook.kind),"story_choice_made",int(hook.origin),950,npc_id,{"story_id":str(hook.id),"resolution":outcome}))
		check(bool(r.get("ok",false)),"story_choice_"+str(hook.kind))
		check(not bool(Bridge.ingest(save,atlas,event("choice/"+str(hook.kind),"story_choice_made",int(hook.origin),950,npc_id,{"story_id":str(hook.id),"resolution":outcome})).get("changed",true)),"story_idempotence")
		check(s.decisions.has(hook.id),"story_recorded")
	check(Registry.influence(s,int(hooks[2].region),"caminho_celestial")==10,"regional_dispute")
	check(s.scheduled.size()==1,"rumor_scheduled")
	check(int(Scheduler.advance(s,3200,-1).applied)==1,"remote_rumor_once")
	check(int(Scheduler.advance(s,3200,-1).applied)==0,"clock_reentry_not_double")
	check("manual_perdido" in s.knowledge.get("faction:cronicas_silenciosas",[]),"rumor_spread")
	check(Scheduler.schedule(s,"physical/86",3300.0,"spread_rumor",{"holder":"npc:"+npc_id,"fact":"visitante_visto","region":86},true),"deferred_physical_created")
	check(int(Scheduler.advance(s,3300,-1).applied)==0,"physical_event_still_pending")
	check(int(Scheduler.advance(s,3300,86).applied)==1,"physical_event_applied_on_region_load")
	check(int(Scheduler.advance(s,3300,86).applied)==0,"physical_event_idempotent")
	check(State.valid(s),"valid_after_scenarios")
	for k in range(2500):
		var seed: String="seed/"+str(k)
		check(Destiny.build(seed,"Viajante")==Destiny.build(seed,"Viajante"),"seed_repeat_"+str(k))
	# Preserve exact JSON result for a second Godot process, not only same-process roundtrip.
	var path: String="user://narrative_qa_reopen.json"
	var output:=FileAccess.open(path,FileAccess.WRITE)
	check(output!=null,"qa_file_open")
	if output!=null:
		output.store_string(JSON.stringify(save));output.flush();output.close()
	var stat: Dictionary={"checks":checks,"failures":failures,"elapsed_ms":(Time.get_ticks_usec()-started)/1000.0,"saved_bytes":JSON.stringify(save.narrative).length(),"source":"godot_native"}
	print("NARRATIVE_QA "+JSON.stringify(stat))
	quit(0 if failures.is_empty() else 1)
