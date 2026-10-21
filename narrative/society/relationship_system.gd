extends RefCounted
const BONDS=["rival","master_disciple","ally","family","independent"]
static func pair(a: String,b: String) -> String:
	return a+"|"+b if a<b else b+"|"+a
static func establish(state: Dictionary,a: String,b: String,kind: String,receipt: String,clock: float) -> bool:
	if a.is_empty() or b.is_empty() or a==b or kind not in BONDS:return false
	var key:=pair(a,b)
	if not state.relationships.has(key) and state.relationships.size()>=2048:return false
	state.relationships[key]={"a":a,"b":b,"kind":kind,"event":receipt,"clock":clock}
	return true
static func get_bond(state: Dictionary,a: String,b: String) -> Dictionary:
	return state.get("relationships",{}).get(pair(a,b),{})
