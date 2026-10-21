extends RefCounted
const VERSION=1
const MAX_RECEIPTS=12000
const MAX_HISTORY=384
const MAX_NPCS=2048
const MAX_MEMORY_PER_NPC=16
const MAX_RUMORS=256
const MAX_SCHEDULED=128
const MAX_DECISIONS=1024
static func fresh(seed: String,character_id: String) -> Dictionary:
	return {"schema":VERSION,"world_id":("EXO-NARRATIVE-01|"+seed).sha256_text().substr(0,24),"seed":seed,
		"character_id":character_id,"receipts":{},"history":[],"decisions":{},"influence":{},"diplomacy_delta":{},
		"player_factions":{},"npc_memories":{},"relationships":{},"knowledge":{},"rumors":[],"scheduled":[],"remote_cursor":0.0,"destiny":{}}
static func ensure(save: Dictionary,seed: String,character_id: String) -> Dictionary:
	if not save.has("narrative"):
		save.narrative=fresh(seed,character_id)
	if not save.narrative is Dictionary:return {}
	if str(save.narrative.get("seed",""))!=seed:return {}
	return save.narrative
static func valid(raw: Variant) -> bool:
	if not raw is Dictionary:return false
	var s: Dictionary=raw
	if int(s.get("schema",0))!=VERSION:return false
	for key in ["world_id","seed","character_id"]:
		if not s.get(key) is String or str(s.get(key)).length()>128 or str(s.get(key)).is_empty():return false
	if str(s.world_id)!=("EXO-NARRATIVE-01|"+str(s.seed)).sha256_text().substr(0,24):return false
	for key in ["receipts","decisions","influence","diplomacy_delta","player_factions","npc_memories","relationships","knowledge","destiny"]:
		if not s.get(key) is Dictionary:return false
	for key in ["history","rumors","scheduled"]:
		if not s.get(key) is Array:return false
	if s.history.size()>MAX_HISTORY or s.npc_memories.size()>MAX_NPCS:return false
	if s.decisions.size()>MAX_DECISIONS or s.relationships.size()>2048 or s.rumors.size()>MAX_RUMORS or s.scheduled.size()>MAX_SCHEDULED:return false
	if s.influence.size()>88 or s.diplomacy_delta.size()>32 or s.player_factions.size()>16 or s.knowledge.size()>512:return false
	if not (s.get("remote_cursor") is float or s.get("remote_cursor") is int):return false
	if not is_finite(float(s.remote_cursor)) or float(s.remote_cursor)<0:return false
	for rid in s.influence:
		if not str(rid).is_valid_int() or int(rid)<0 or int(rid)>=88:return false
		if not s.influence[rid] is Dictionary or s.influence[rid].size()>16:return false
		for influence in s.influence[rid].values():
			if not number_in(influence,-100,100):return false
	for influence in s.player_factions.values():
		if not number_in(influence,-100,100):return false
	for mem in s.npc_memories.values():
		if not mem is Array or mem.size()>MAX_MEMORY_PER_NPC:return false
		for m in mem:
			if not m is Dictionary or not m.get("id") is String or not m.get("kind") is String:return false
			if not m.get("permanent") is bool or not number_in(m.get("importance"),1,10):return false
			if not (m.get("clock") is float or m.get("clock") is int) or not is_finite(float(m.clock)):return false
	for known in s.knowledge.values():
		if not known is Array or known.size()>32:return false
	for receipt in s.receipts:
		if not receipt is String or receipt.length()>160 or receipt.is_empty():return false
	for value in s.relationships.values():
		if not value is Dictionary or not value.get("a") is String or not value.get("b") is String:return false
		if not value.get("kind") is String or not value.get("event") is String:return false
	for value in s.decisions.values():
		if not value is Dictionary or not value.get("resolution") is String or not value.get("event") is String:return false
	for e in s.scheduled:
		if not e is Dictionary or not str(e.get("id","")).begins_with("scheduled/"):return false
		if not (e.get("due") is int or e.get("due") is float):return false
	return true
static func number_in(value: Variant,minimum: int,maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and int(value)==value and value>=minimum and value<=maximum
static func remember_history(s: Dictionary,e: Dictionary) -> void:
	s.history.append({"id":str(e.id),"type":str(e.type),"region":int(e.region),"clock":float(e.clock),"npc_id":str(e.get("npc_id","")),"story":str(e.get("context",{}).get("story_id",""))})
	if s.history.size()>MAX_HISTORY:s.history.pop_front()
