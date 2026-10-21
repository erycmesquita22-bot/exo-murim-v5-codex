extends RefCounted
static func learn(s: Dictionary,holder: String,fact: String) -> bool:
	if holder.is_empty() or fact.is_empty() or holder.length()>128 or fact.length()>128:return false
	var known: Array=s.knowledge.get(holder,[])
	if fact in known:return false
	if known.size()>=32 or s.knowledge.size()>=512 and not s.knowledge.has(holder):return false
	known.append(fact)
	s.knowledge[holder]=known
	return true
static func knows(s: Dictionary,holder: String,fact: String) -> bool:
	return fact in s.knowledge.get(holder,[])
static func add_rumor(s: Dictionary,rumor: Dictionary) -> bool:
	if not rumor.has("id") or str(rumor.id).length()>128 or s.rumors.size()>=256:return false
	for item in s.rumors:
		if str(item.id)==str(rumor.id):return false
	s.rumors.append({"id":str(rumor.id),"fact":str(rumor.get("fact","")),"source":str(rumor.get("source","")),"verified":false})
	return true
