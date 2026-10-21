extends RefCounted
# Only pedagogical state. Social master_disciple bonds belong exclusively to narrative.relationships.
const SCHEMA: int = 1
const MAX_PROFILES: int = 8192
const MAX_APPLICATIONS: int = 4096
const MAX_TRAINING: int = 8192
const MAX_RECEIPTS: int = 60000

static func fresh(seed: String) -> Dictionary:
	return {"schema":SCHEMA,"seed":seed,"profiles":{},"applications":{},"training":{},"receipts":{},"npc_sim_day":-1,"npc_sim_cursor":0}

static func integer_in(v: Variant, a: int, b: int) -> bool:
	return (v is int or v is float) and is_finite(float(v)) and int(v)==v and int(v)>=a and int(v)<=b

static func valid(v: Variant) -> bool:
	if not v is Dictionary: return false
	if not integer_in(v.get("schema"),1,1):return false
	if not v.get("seed") is String or str(v.seed).length()>256 or str(v.seed).is_empty():return false
	for key in ["profiles","applications","training","receipts"]:
		if not v.get(key) is Dictionary:return false
	if v.profiles.size()>MAX_PROFILES or v.applications.size()>MAX_APPLICATIONS or v.training.size()>MAX_TRAINING or v.receipts.size()>MAX_RECEIPTS:return false
	if not integer_in(v.get("npc_sim_day"),-1,2000000000) or not integer_in(v.get("npc_sim_cursor"),0,8192):return false
	for k in v.profiles:
		var p: Variant=v.profiles[k]
		if not p is Dictionary or str(k)!=str(p.get("npc_id","")):return false
		if not str(k).begins_with("npc/r") or str(k).length()>128:return false
		if not str(p.get("style_id","")).begins_with("exo_martial.style."):return false
		if not str(p.get("school_id","")).begins_with("exo_martial.school."):return false
		if str(p.get("temperament","")) not in ["rigoroso","benevolente","mercenario","solitario","orgulhoso"]:return false
		if not integer_in(p.get("power"),1,1000) or not integer_in(p.get("max_disciples"),1,24):return false
		if not p.get("techniques") is Array or p.techniques.size()>16:return false
		if not p.get("secondary_styles",[]) is Array or p.get("secondary_styles",[]).size()>2:return false
		if not p.get("secret_technique_id","") is String:return false
		for id in p.techniques:
			if not str(id).begins_with("exo_martial.technique."):return false
	for k in v.applications:
		var a: Variant=v.applications[k]
		if not a is Dictionary or str(k).length()!=64:return false
		if str(a.get("status","")) not in ["pending","refused","withdrawal_requested"]:return false
		for key in ["master_id","learner_id","receipt"]:
			if not a.get(key) is String or str(a[key]).is_empty() or str(a[key]).length()>180:return false
	for k in v.training:
		var t: Variant=v.training[k]
		if not t is Dictionary or str(k).length()!=64:return false
		if not t.get("learner_id") is String or not t.get("master_id") is String:return false
		if not integer_in(t.get("rank"),3,6) or not integer_in(t.get("mastery"),0,1000):return false
		if not integer_in(t.get("practice"),0,1000000) or not integer_in(t.get("lesson_goal"),0,1000000):return false
		if not integer_in(t.get("completed_lessons"),0,1000000):return false
		if str(t.get("phase","")) not in ["ready","instructed","practiced","demonstrated","graduated","suspended","observing","practicing","examining","awaiting_unlock"]:return false
		if not t.get("learned") is Dictionary or t.learned.size()>64:return false
		if not t.get("active") is bool:return false
		if not t.get("lesson_id") is String or str(t.lesson_id).length()>200:return false
		for technique_id in t.learned:
			if not str(technique_id).begins_with("exo_martial.technique."):return false
			if not integer_in(t.learned[technique_id],1,5):return false
	for r in v.receipts:
		if not r is String or str(r).is_empty() or str(r).length()>180 or not v.receipts[r] is String or str(v.receipts[r]).length()>128:return false
	return true
