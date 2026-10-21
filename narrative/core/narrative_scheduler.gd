extends RefCounted
const Rumors=preload("res://narrative/knowledge/rumor_system.gd")
const NPCMemory=preload("res://narrative/society/npc_memory.gd")
static func schedule(s: Dictionary,id: String,due: float,action: String,payload: Dictionary,physical: bool=false) -> bool:
	if s.scheduled.size()>=128 or id.is_empty() or not is_finite(due) or due<0:return false
	var uid: String="scheduled/"+id
	if s.receipts.has(uid):return false
	for item in s.scheduled:
		if str(item.id)==uid:return false
	s.scheduled.append({"id":uid,"due":due,"action":action,"payload":payload.duplicate(true),"physical":physical})
	return true
static func advance(s: Dictionary,now: float,loaded_region: int=-1) -> Dictionary:
	if not is_finite(now) or now<float(s.remote_cursor):return {"applied":0,"deferred":0}
	var applied:=0
	var kept: Array=[]
	# Bounded queue of due events: no loading regions or instancing NPCs.
	s.scheduled.sort_custom(func(a,b):return float(a.due)<float(b.due) if float(a.due)!=float(b.due) else str(a.id)<str(b.id))
	for item in s.scheduled:
		if float(item.due)>now or bool(item.physical) and int(item.payload.get("region",-1))!=loaded_region:
			kept.append(item);continue
		if s.receipts.has(str(item.id)):continue
		var action: String=str(item.action)
		if action=="spread_rumor":
			Rumors.learn(s,str(item.payload.get("holder","")),str(item.payload.get("fact","")))
		elif action=="historical_echo":
			Rumors.add_rumor(s,{"id":str(item.id),"fact":str(item.payload.get("fact","")),"source":"remote"})
		else:kept.append(item);continue
		s.receipts[str(item.id)]=true
		applied+=1
	s.scheduled=kept
	s.remote_cursor=now
	NPCMemory.compact(s,now)
	return {"applied":applied,"deferred":kept.size()}
