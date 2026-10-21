extends RefCounted
# Operational acquaintance only. Narrative Society remains authoritative for story bonds.
# Social memory lives in Living World NPC records and is capped to avoid unbounded saves.
const MAX_CONTACTS := 8
const MAX_LINKS := 3
const PAIR_COOLDOWN := 75.0
const MEMORY_TTL := 6480.0 # Three full in-game days at 90 seconds/hour
const Relationships=preload("res://narrative/society/relationship_system.gd")
static func _text(person: Dictionary,key: String) -> String:
	return str(person.get(key,"")).strip_edges()
static func context_points(a: Dictionary,b: Dictionary) -> int:
	if _text(a,"id").is_empty() or _text(a,"id")==_text(b,"id"):return 0
	var points:=0
	var ah:=_text(a,"home_slot");var bh:=_text(b,"home_slot")
	var aw:=_text(a,"work_slot");var bw:=_text(b,"work_slot")
	# Two undefined homes / factions MUST NOT create a social link.
	if not ah.is_empty() and ah==bh:points+=6
	if not aw.is_empty() and aw==bw:points+=7
	if not aw.is_empty() and aw==bh and aw!=ah:points+=2
	if not bw.is_empty() and bw==ah and bw!=bh:points+=2
	var af:=_text(a,"faction");var bf:=_text(b,"faction")
	if not af.is_empty() and af==bf and points>0:points+=2
	if _text(a,"role")==_text(b,"role") and points>0:points+=1
	return points
static func story_bond(narrative: Dictionary,a: String,b: String) -> String:
	if a.is_empty() or b.is_empty() or a==b:return ""
	if not narrative.get("relationships",{}) is Dictionary:return ""
	return str(Relationships.get_bond(narrative,a,b).get("kind",""))
static func operational(person: Dictionary,other_id: String) -> Dictionary:
	var records: Variant=person.get("social_memory",{})
	return records.get(other_id,{}) if records is Dictionary else {}
static func affinity(a: Dictionary,b: Dictionary,narrative: Dictionary={}) -> float:
	if _text(a,"id")==_text(b,"id") or _text(a,"id").is_empty():return -1000.0
	var aid:=_text(a,"id");var bid:=_text(b,"id")
	var score: float=float(context_points(a,b))*2.0
	var rec: Dictionary=operational(a,bid)
	score+=minf(25.0,float(rec.get("count",0))*4.0)+float(rec.get("warmth",0))*2.0
	if bid in a.get("relations",[]):score+=9.0
	var bond: String=story_bond(narrative,aid,bid)
	if bond in ["family","ally","master_disciple"]:score+=35.0
	elif bond=="rival":score-=55.0
	elif bond=="independent":score-=4.0
	return score
static func compact(person: Dictionary,now: float) -> void:
	var records: Variant=person.get("social_memory",{})
	if not records is Dictionary:return
	for other_id in records.keys():
		var record: Dictionary=records[other_id]
		if now-float(record.get("last_clock",now))>MEMORY_TTL:records.erase(other_id)
static func eligible(a: Dictionary,b: Dictionary,now: float,narrative: Dictionary={},physical_encounter: bool=false) -> bool:
	if a.is_empty() or b.is_empty() or a==b:return false
	compact(a,now);compact(b,now)
	var aid:=_text(a,"id");var bid:=_text(b,"id")
	if aid.is_empty() or bid.is_empty() or aid==bid:return false
	if story_bond(narrative,aid,bid)=="rival":return false
	if now<float(operational(a,bid).get("next_clock",-1)) or now<float(operational(b,aid).get("next_clock",-1)):return false
	if context_points(a,b)==0 and not (bid in a.get("relations",[]) or aid in b.get("relations",[])) and operational(a,bid).is_empty() and operational(b,aid).is_empty():
		# Genuine nearby meetings may introduce strangers, but empty fields never do.
		if not physical_encounter:return false
		var outgoing: int=int(a.get("preferences",{}).get("social",40))
		var welcoming: int=int(b.get("preferences",{}).get("social",40))
		if outgoing<70 and welcoming<70:return false
		var key: String=(aid+"|"+bid) if aid<bid else (bid+"|"+aid)
		# Deterministic per day and pair, NOT frame-rate dependent.
		if abs((key+"|"+str(int(now/2160.0))).hash())%4!=0:return false
	return true
static func remember(person: Dictionary,other_id: String,now: float,valence: int) -> bool:
	if other_id.is_empty() or other_id==_text(person,"id") or other_id.length()>128:return false
	var records: Dictionary=person.get("social_memory",{})
	if not records is Dictionary:records={}
	# Deterministic discard: oldest contact, tie-break by ID.
	if not records.has(other_id) and records.size()>=MAX_CONTACTS:
		var keys: Array=records.keys();keys.sort()
		var eldest: String=str(keys[0]);var stamp: float=float(records[eldest].get("last_clock",-1))
		for key in keys:
			var candidate: float=float(records[key].get("last_clock",-1))
			if candidate<stamp:stamp=candidate;eldest=str(key)
		records.erase(eldest)
	var record: Dictionary=records.get(other_id,{})
	if now<float(record.get("next_clock",-1)):return false
	records[other_id]={"last_clock":now,"count":mini(100,int(record.get("count",0))+1),
		"warmth":clampi(int(record.get("warmth",0))+valence,-10,10),
		"next_clock":now+PAIR_COOLDOWN,"last_valence":clampi(valence,-1,1)}
	person["social_memory"]=records
	return true
static func meet(a: Dictionary,b: Dictionary,now: float,narrative: Dictionary={},physical_encounter: bool=false) -> bool:
	if not eligible(a,b,now,narrative,physical_encounter):return false
	var aid:=_text(a,"id");var bid:=_text(b,"id")
	# Directional impressions are operational, not permanent narrative bonds.
	# Two characters may remember the same meeting differently.
	var response_a: int=-1 if int(a.get("preferences",{}).get("social",40))<20 else 0 if int(a.get("preferences",{}).get("social",40))<40 else 1
	var response_b: int=-1 if int(b.get("preferences",{}).get("social",40))<20 else 0 if int(b.get("preferences",{}).get("social",40))<40 else 1
	return remember(a,bid,now,response_a) and remember(b,aid,now,response_b)
static func link_roster(people: Array) -> bool:
	# Migration of R1 artificial contacts. Only genuine shared context creates
	# initial operational colleagues; real encounters subsequently expand memory.
	var ordered: Array=[]
	for p in people:
		if p is Dictionary and not _text(p,"id").is_empty():ordered.append(p)
	ordered.sort_custom(func(a,b):return _text(a,"id")<_text(b,"id"))
	var changed:=false
	var proposals: Array=[]
	for i in range(ordered.size()):
		for j in range(i+1,ordered.size()):
			var score:=context_points(ordered[i],ordered[j])
			if score<6:continue # faction-only is NEVER sufficient
			var key: String=_text(ordered[i],"id")+"|"+_text(ordered[j],"id")
			# Ranked by context then stable non-ID-order hash of the pair.
			proposals.append({"a":i,"b":j,"score":score,"tie":key.sha256_text()})
	proposals.sort_custom(func(a,b):
		if a.score!=b.score:return a.score>b.score
		return a.tie<b.tie)
	var result: Dictionary={}
	for p in ordered:result[_text(p,"id")]=[]
	for choice in proposals:
		var aid:=_text(ordered[int(choice.a)],"id");var bid:=_text(ordered[int(choice.b)],"id")
		if result[aid].size()>=MAX_LINKS or result[bid].size()>=MAX_LINKS:continue
		result[aid].append(bid);result[bid].append(aid)
	for p in ordered:
		if int(p.get("social_links_version",0))>=2:continue
		var contacts: Array=result[_text(p,"id")];contacts.sort()
		if p.get("relations",[])!=contacts:p["relations"]=contacts;changed=true
		p["social_links_version"]=2;changed=true
	return changed
