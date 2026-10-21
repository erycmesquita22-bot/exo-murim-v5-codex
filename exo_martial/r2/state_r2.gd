extends RefCounted
# Educational domain only. Does not own Narrative relationships or Core skills.
const OldState=preload("res://exo_martial/progression/martial_state.gd")
const REVISION=2

static func fresh(seed: String) -> Dictionary:
	var d: Dictionary=OldState.fresh(seed)
	d["r2_schema"]=REVISION
	d["exams"]={}
	return d

static func upgrade(raw: Dictionary) -> Dictionary:
	if not OldState.valid(raw):return {}
	if raw.has("r2_schema") and int(raw.get("r2_schema",0))!=REVISION:return {}
	var d: Dictionary=raw.duplicate(true)
	d["r2_schema"]=REVISION
	if not d.has("exams"):d.exams={}
	for k in d.training:
		var t: Dictionary=d.training[k]
		# Preserve R1 progress and learned metadata; do not create Core grants during upgrade.
		if not t.has("r2"):
			t["r2"]={"lesson_seq":int(t.get("completed_lessons",0)),"observation_done":false,"practice_done":0,"exam_passed":false,"pending_unlock":"","exam_history":{},"outcome":"active","school_id":"","transfer_from":"","refusals":0}
		# In-progress R1 lessons lacked typed witnesses. Never auto-complete them.
		if str(t.get("phase","")) in ["instructed","practiced","demonstrated"]:
			t.phase="ready";t.practice=0;t.lesson_goal=0;t.lesson_id="";t.pending_technique="";t.method=""
	return d if valid(d) else {}

static func valid(v: Variant) -> bool:
	if not OldState.valid(v):return false
	var d: Dictionary=v
	if int(d.get("r2_schema",0))!=REVISION or not d.get("exams") is Dictionary or d.exams.size()>8192:return false
	for k in d.training:
		var t: Dictionary=d.training[k]
		if not t.has("r2") or not t.r2 is Dictionary:return false
		var e: Dictionary=t.r2
		for field in ["lesson_seq","practice_done","refusals"]:
			if not OldState.integer_in(e.get(field),0,1000000):return false
		for field in ["observation_done","exam_passed"]:
			if not e.get(field) is bool:return false
		for field in ["pending_unlock","outcome","school_id","transfer_from"]:
			if not e.get(field) is String or str(e[field]).length()>220:return false
		if not e.get("exam_history") is Dictionary or e.exam_history.size()>16:return false
		if str(t.get("phase","")) not in ["ready","instructed","practiced","demonstrated","graduated","suspended","observing","practicing","examining","awaiting_unlock"]:return false
		if e.practice_done>t.lesson_goal and t.lesson_goal>0:return false
		if e.pending_unlock!="" and str(t.get("phase",""))!="awaiting_unlock":return false
	for exam_id in d.exams:
		if not str(exam_id).begins_with("exam/") or str(exam_id).length()>155:return false
		if not d.exams[exam_id] is Dictionary:return false
	return true
