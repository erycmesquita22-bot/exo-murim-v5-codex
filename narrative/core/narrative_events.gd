extends RefCounted
# A single normalized intake. No XP, inventory, combat or quest advancement here.
const State=preload("res://narrative/core/narrative_state.gd")
const Registry=preload("res://narrative/factions/faction_registry.gd")
const Memory=preload("res://narrative/society/npc_memory.gd")
const Rumors=preload("res://narrative/knowledge/rumor_system.gd")
const Hooks=preload("res://narrative/stories/narrative_hooks.gd")
const Scheduler=preload("res://narrative/core/narrative_scheduler.gd")
const Relationships=preload("res://narrative/society/relationship_system.gd")
const TYPES=["enemy_defeated","quest_completed","item_discovered","npc_helped","npc_attacked","npc_met","region_entered","story_choice_made","knowledge_acquired","social_bond_formed"]
static func apply(s: Dictionary,atlas: Dictionary,npcs: Dictionary,event: Dictionary) -> Dictionary:
	for field in ["id","type","source","region","clock","context"]:
		if not event.has(field):return {"ok":false,"reason":"missing_"+field}
	var event_id: String=str(event.id)
	var event_type: String=str(event.type)
	if event_id.is_empty() or event_id.length()>160 or event_type not in TYPES:return {"ok":false,"reason":"invalid_event"}
	if not event.context is Dictionary or event.context.size()>12 or JSON.stringify(event.context).length()>2048 or not event.source is String or str(event.source).is_empty() or str(event.source).length()>80:return {"ok":false,"reason":"invalid_origin"}
	if not event.region is int and not event.region is float:return {"ok":false,"reason":"invalid_region"}
	var region: int=int(event.region)
	if region<0 or region>=88 or region!=event.region or not atlas.has("regions") or atlas.regions.size()!=88:return {"ok":false,"reason":"region_not_found"}
	if not event.clock is float and not event.clock is int:return {"ok":false,"reason":"invalid_clock"}
	var clock: float=float(event.clock)
	if not is_finite(clock) or clock<0:return {"ok":false,"reason":"invalid_clock"}
	if s.receipts.has(event_id):return {"ok":true,"duplicate":true,"changed":false}
	var npc_id: String=str(event.get("npc_id",""))
	if event_type in ["npc_helped","npc_attacked","npc_met","social_bond_formed"] and npc_id.is_empty():return {"ok":false,"reason":"missing_npc"}
	if not npc_id.is_empty() and not npcs.has(npc_id):return {"ok":false,"reason":"unknown_npc"}
	var faction: String=str(event.get("faction",""))
	if not faction.is_empty() and not Registry.has(faction):return {"ok":false,"reason":"unknown_faction"}
	var context: Dictionary=event.context
	if event_type=="social_bond_formed":
		if npc_id.is_empty() or not npcs.has(str(context.get("other_npc_id",""))) or str(context.get("other_npc_id",""))==npc_id or str(context.get("bond","")) not in Relationships.BONDS:
			return {"ok":false,"reason":"invalid_social_bond"}
	var story: Dictionary={}
	if event_type=="story_choice_made":
		story=Hooks.validate_choice(s,atlas,npcs,str(context.get("story_id","")),str(context.get("resolution","")))
		if story.is_empty():return {"ok":false,"reason":"invalid_story_choice"}
		if s.decisions.size()>=State.MAX_DECISIONS:return {"ok":false,"reason":"decision_capacity"}
	# Apply only after all dependencies and choices have been validated.
	var snapshot: Dictionary=s.duplicate(true)
	if event_type in ["npc_helped","npc_attacked","npc_met"] and not npc_id.is_empty():
		var kind: String="help" if event_type=="npc_helped" else "attack" if event_type=="npc_attacked" else "met"
		var first_aggression: bool=event_type=="npc_attacked"
		if first_aggression:
			for past in s.npc_memories.get(npc_id,[]):
				if str(past.kind)=="attack" and bool(past.permanent):first_aggression=false;break
		if not Memory.add(s,npc_id,event_id,kind,clock,5 if kind=="attack" else 4 if kind=="help" else 1,first_aggression):
			s.clear();s.merge(snapshot,true)
			return {"ok":false,"reason":"npc_memory_capacity"}
	if event_type=="quest_completed" and not npc_id.is_empty():
		if not Memory.add(s,npc_id,event_id,"help",clock,2):
			s.clear();s.merge(snapshot,true)
			return {"ok":false,"reason":"npc_memory_capacity"}
	if event_type=="enemy_defeated" and not faction.is_empty():Registry.shift_influence(s,region,faction,-1)
	if event_type=="npc_helped" and not faction.is_empty():
		s.player_factions[faction]=clampi(int(s.player_factions.get(faction,0))+2,-100,100)
	if event_type=="npc_attacked" and not faction.is_empty():
		s.player_factions[faction]=clampi(int(s.player_factions.get(faction,0))-4,-100,100)
	if event_type=="social_bond_formed":
		if not Relationships.establish(s,npc_id,str(context.other_npc_id),str(context.bond),event_id,clock):
			s.clear();s.merge(snapshot,true)
			return {"ok":false,"reason":"relationship_capacity"}
	if event_type=="knowledge_acquired" or event_type=="item_discovered":
		var fact: String=str(context.get("knowledge_id",""))
		if not fact.is_empty():Rumors.learn(s,"npc:"+npc_id if not npc_id.is_empty() else "player",fact)
	if event_type=="story_choice_made":
		var choice: String=str(context.resolution)
		s.decisions[str(story.id)]={"resolution":choice,"event":event_id,"clock":clock}
		var f0: String="caminho_celestial"
		var f1: String="culto_abismo"
		if choice=="manual_shared":
			Rumors.learn(s,"player","manual_perdido")
			Scheduler.schedule(s,"manual/"+str(story.id),clock+2160.0,"spread_rumor",{"holder":"faction:cronicas_silenciosas","fact":"manual_perdido"})
			Registry.shift_influence(s,int(story.region),"cronicas_silenciosas",8)
		elif choice=="manual_hidden":Registry.shift_influence(s,int(story.region),"familias_ancestrais",5)
		elif choice=="rival_resolved":Memory.add(s,str(story.npc_ids[0]),event_id,"rival_settled",clock,6,true)
		elif choice=="rival_worsened":Memory.add(s,str(story.npc_ids[0]),event_id,"attack",clock,5,true)
		elif choice=="support_celestial":
			Registry.shift_influence(s,int(story.region),f0,10)
			Registry.shift_influence(s,int(story.region),f1,-5)
		elif choice=="support_abismo":
			Registry.shift_influence(s,int(story.region),f1,10)
			Registry.shift_influence(s,int(story.region),f0,-5)
	if event_type=="region_entered":Rumors.learn(s,"player","region/%02d"%region)
	s.receipts[event_id]=true
	State.remember_history(s,event)
	if not State.valid(s):
		s.clear();s.merge(snapshot,true)
		return {"ok":false,"reason":"state_invalid_rollback"}
	return {"ok":true,"changed":true,"duplicate":false}
