extends RefCounted
# XP is regional, not a second character level. Existing cultivation/weapon
# mastery systems remain authoritative; this bank is available to progression.
const BASE_XP := 12
const Loot=preload("res://procedural/loot_generator.gd")
const Stream=preload("res://procedural/seed_stream.gd")
static func required_total(level: int) -> int:
	var n: int=maxi(0,level-1)
	return int(80*n+20*n*level*(2*level-1)/3)
static func rank(xp: int) -> int:
	var level:=1
	while level<50 and xp>=required_total(level+1):level+=1
	return level
static func compact_claimed(save: Dictionary,goal: int=1500) -> int:
	# Kept for existing callers: schema v2 owns an exact archival receipt for
	# every collected item. A compaction always has a durable uniqueness marker.
	if not save.has("world") or not save.world is Dictionary:return 0
	var before: int=save.world.events.size()
	if not preload("res://procedural/world_state.gd").upgrade(save.world):return 0
	return maxi(0,before-save.world.events.size())
static func queue_loot(world: Node3D,actor: Node3D) -> bool:
	if world.flow.lab_mode or world.trial_mode:return false
	var d: Dictionary=world.journey.data
	if d.pending_loot.size()>=210:return false
	if not preload("res://procedural/world_state.gd").upgrade(d.world):return false
	if d.world.events.size()>=4096:return false
	var key: String="loot/"+str(actor.uid)
	if preload("res://procedural/world_state.gd").has_event(d.world,key):return false
	for drop in d.pending_loot:
		if drop.source==actor.uid:return false
	var roll: int=posmod(Stream.hash_value(str(actor.uid)+"/loot"),100)
	var fauna: bool=str(actor.kind)=="fauna" and actor.has_meta("ecology_species")
	var rewards: Array=[{"kind":"material","ref":"hide" if fauna else "iron","qty":2 if roll%4==0 else 1}]
	if fauna and roll<28:rewards.append({"kind":"material","ref":"fang","qty":1})
	var item_uid: String=""
	if not fauna and roll<20:
		item_uid="item_%d"%int(d.next_item)
		var tier: int=2 if int(actor.get_meta("ecology_level",1))>=4 else 1
		var generated: Dictionary=Loot.generate(d.world,key,"mage" if str(actor.kind)=="mage" else "blade",tier,item_uid)
		if generated.is_empty() or not preload("res://inventory.gd").valid_item(generated):return false
		rewards.append(generated)
	if not preload("res://procedural/world_state.gd").mark_pending(d.world,key,{"item_uid":item_uid}):return false
	if not item_uid.is_empty():d.next_item+=1
	d.pending_loot.append({"source":actor.uid,"x":actor.position.x,"y":actor.position.y+.15,"z":actor.position.z,"region":int(world.current_region),"items":rewards})
	world.inventory.rebuild_drops()
	return true
static func factor(kills: int) -> float:
	return 1.0 if kills<8 else 0.80 if kills<16 else 0.55 if kills<30 else 0.35
static func award(ecology: Dictionary,region: int,kind: String,level: int,day: int) -> int:
	var counters: Dictionary=ecology.get("farm_counts",{})
	var key: String="%02d/%s"%[region,kind]
	var record: Dictionary=counters.get(key,{})
	var count: int=int(record.get("count",0)) if int(record.get("day",-1))==day else 0
	var value: int=maxi(1,int(round(float(BASE_XP+4*maxi(1,level))*factor(count))))
	counters[key]={"day":day,"count":mini(count+1,100000)}
	ecology["farm_counts"]=counters
	ecology["xp_total"]=mini(2000000000,int(ecology.get("xp_total",0))+value)
	ecology["level"]=rank(int(ecology.xp_total))
	return value
static func ensure(state: Dictionary) -> Dictionary:
	if not state.has("ecology") or not state.ecology is Dictionary:
		state.ecology={"version":1,"regions":{},"farm_counts":{},"xp_total":0,"level":1}
	return state.ecology
static func territory_state(ecology: Dictionary,region: int,territory_id: String) -> Dictionary:
	var key: String=str(region)
	var regions: Dictionary=ecology.regions
	if not regions.has(key):regions[key]={}
	var record: Dictionary=regions[key]
	if not record.has(territory_id):record[territory_id]={"generation":0,"defeated_at":-1.0,"kills":0}
	return record[territory_id]
static func permitted(record: Dictionary,clock: float) -> bool:
	var t: float=float(record.get("defeated_at",-1.0))
	return t<0 or clock>=t+540.0 # six game hours; no zero-delay respawn
