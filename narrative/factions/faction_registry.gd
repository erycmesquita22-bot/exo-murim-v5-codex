extends RefCounted
const FILE="res://narrative/data/factions.json"
static func data() -> Dictionary:
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(FILE))
	return parsed if parsed is Dictionary else {}
static func ids() -> Array:
	var result: Array=[]
	for record in data().get("factions",[]):
		if record is Dictionary and record.has("id"):result.append(str(record.id))
	return result
static func has(faction: String) -> bool:return faction in ids()
static func name_of(faction: String) -> String:
	for record in data().get("factions",[]):
		if str(record.get("id",""))==faction:return str(record.get("name",faction))
	return ""
static func pair(a: String,b: String) -> String:
	return a+"|"+b if a<b else b+"|"+a
static func relationship(state: Dictionary,a: String,b: String) -> int:
	if not has(a) or not has(b):return 0
	if a==b:return 100
	var key:=pair(a,b)
	var baseline:=int(data().get("diplomacy",{}).get(key,0))
	return clampi(baseline+int(state.get("diplomacy_delta",{}).get(key,0)),-100,100)
static func shift(state: Dictionary,a: String,b: String,amount: int) -> bool:
	if not has(a) or not has(b) or a==b or abs(amount)>20:return false
	var key:=pair(a,b)
	var initial:=int(data().get("diplomacy",{}).get(key,0))
	state.diplomacy_delta[key]=clampi(relationship(state,a,b)+amount,-100,100)-initial
	return true
static func influence(state: Dictionary,region: int,faction: String) -> int:
	return int(state.get("influence",{}).get(str(region),{}).get(faction,0))
static func shift_influence(state: Dictionary,region: int,faction: String,amount: int) -> bool:
	if region<0 or region>=88 or not has(faction) or abs(amount)>20:return false
	var key:=str(region)
	if not state.influence.has(key):state.influence[key]={}
	state.influence[key][faction]=clampi(influence(state,region,faction)+amount,-100,100)
	return true
