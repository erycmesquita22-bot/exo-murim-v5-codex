extends RefCounted
# Communication contract with Journey Dynamic. Mutates only save.narrative;
# callers join it to their existing atomic journey.write transaction.
const State=preload("res://narrative/core/narrative_state.gd")
const Events=preload("res://narrative/core/narrative_events.gd")
const Hooks=preload("res://narrative/stories/narrative_hooks.gd")
const Scheduler=preload("res://narrative/core/narrative_scheduler.gd")
const Memory=preload("res://narrative/society/npc_memory.gd")
const Destiny=preload("res://narrative/destiny/destiny_generator.gd")
static func ensure(save: Dictionary,atlas: Dictionary) -> Dictionary:
	if atlas.is_empty() or not atlas.has("seed") or not atlas.has("regions") or atlas.regions.size()!=88:return {}
	var seed: String=str(atlas.seed)
	var character_id: String=str(save.get("character",{}).get("name","viajante"))
	var s: Dictionary=State.ensure(save,seed,character_id)
	if not s.is_empty() and s.destiny.is_empty():s.destiny=Destiny.build(seed,character_id)
	return s
static func npc_index(save: Dictionary) -> Dictionary:
	return save.get("living_world",{}).get("npcs",{})
static func ingest(save: Dictionary,atlas: Dictionary,event: Dictionary) -> Dictionary:
	var s: Dictionary=ensure(save,atlas)
	if s.is_empty() or not State.valid(s):return {"ok":false,"reason":"invalid_state_or_atlas"}
	return Events.apply(s,atlas,npc_index(save),event)
static func emit(world: Node3D,id: String,kind: String,region: int,npc_id: String="",context: Dictionary={}) -> Dictionary:
	if world.atlas.is_empty():return {"ok":false,"reason":"atlas_unavailable"}
	return ingest(world.journey.data,world.atlas,{"id":id,"type":kind,"source":"journey_dynamic","region":region,"clock":float(world.extension().get("clock",0.0)),"npc_id":npc_id,"context":context})
static func opportunities(save: Dictionary,atlas: Dictionary,region: int) -> Array:
	var s: Dictionary=ensure(save,atlas)
	return Hooks.opportunities(s,atlas,npc_index(save),region) if not s.is_empty() else []
static func context_for(save: Dictionary,atlas: Dictionary,npc_id: String,clock: float) -> Dictionary:
	var s: Dictionary=ensure(save,atlas)
	if s.is_empty():return {}
	var trust: int=Memory.trust(s,npc_id,clock)
	return {"recognizes_player":s.npc_memories.has(npc_id),"trust":trust,"attacked":trust<=-10,"helped":trust>=5,"rumors":s.knowledge.get("npc:"+npc_id,[])}
static func advance(world: Node3D) -> Dictionary:
	if world.atlas.is_empty():return {"applied":0}
	var s: Dictionary=ensure(world.journey.data,world.atlas)
	if s.is_empty():return {"applied":0}
	return Scheduler.advance(s,float(world.extension().get("clock",0.0)),int(world.current_region))
