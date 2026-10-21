extends RefCounted
const MAX_SIZE=16
static func add(state: Dictionary,npc_id: String,receipt: String,kind: String,clock: float,weight: int=2,permanent: bool=false) -> bool:
	if npc_id.is_empty() or receipt.is_empty():return false
	var memories: Array=state.npc_memories.get(npc_id,[])
	for m in memories:
		if str(m.id)==receipt:return false
	memories.append({"id":receipt,"kind":kind,"clock":clock,"importance":clampi(weight,1,10),"permanent":permanent})
	# Stable priority order avoids nondeterministic memory after different event orders.
	memories.sort_custom(func(a,b):
		if bool(a.permanent)!=bool(b.permanent):return bool(a.permanent)
		if int(a.importance)!=int(b.importance):return int(a.importance)>int(b.importance)
		if float(a.clock)!=float(b.clock):return float(a.clock)>float(b.clock)
		return str(a.id)<str(b.id))
	if memories.size()>MAX_SIZE:
		var last: Dictionary=memories[MAX_SIZE]
		if bool(last.permanent) or str(last.id)==receipt:return false
		memories.resize(MAX_SIZE)
	state.npc_memories[npc_id]=memories
	return true
static func trust(state: Dictionary,npc_id: String,now: float) -> int:
	var result:=0
	for m in state.npc_memories.get(npc_id,[]):
		if not bool(m.permanent) and now-float(m.clock)>12960.0:continue
		if m.kind=="help":result+=int(m.importance)*2
		elif m.kind=="attack":result-=int(m.importance)*3
		elif m.kind=="rival_settled":result+=5
	return clampi(result,-100,100)
static func knows(state: Dictionary,npc_id: String,receipt: String) -> bool:
	for m in state.npc_memories.get(npc_id,[]):
		if str(m.id)==receipt:return true
	return false
static func compact(state: Dictionary,now: float) -> void:
	for npc_id in state.npc_memories.keys():
		var kept: Array=[]
		for m in state.npc_memories[npc_id]:
			if bool(m.permanent) or now-float(m.clock)<=12960.0:kept.append(m)
		if kept.is_empty():state.npc_memories.erase(npc_id)
		else:state.npc_memories[npc_id]=kept
