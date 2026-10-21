extends RefCounted
const Fate=preload("res://living_world/fate.gd")
const Factions=preload("res://living_world/factions.gd")
const Attributes=["forca","agilidade","vitalidade","inteligencia","vontade","sorte"]
const VERSION=1

static func fresh(seed_text: String,identity: String) -> Dictionary:
	return {"schema":VERSION,"fate":Fate.generate(seed_text,identity),"npcs":{},
		"quests":{},"finished":{},"receipts":{},"balances":{"bronze":0,"renown":0},
		"reputation":{},"region_visits":{},"ruleset":"living_world/1"}

static func ensure(journey_data: Dictionary,seed_text: String="",identity: String="") -> Dictionary:
	if not journey_data.has("living_world"):
		if seed_text.is_empty():seed_text=str(journey_data.get("world",{}).get("seed","0"))
		if identity.is_empty():identity=str(journey_data.get("character",{}).get("name","traveler"))
		journey_data.living_world=fresh(seed_text,identity)
	return journey_data.living_world

static func valid(state: Variant) -> bool:
	if not state is Dictionary or state.get("schema")!=VERSION or state.get("ruleset")!="living_world/1":return false
	for field in ["npcs","quests","finished","receipts","balances","reputation","region_visits","fate"]:
		if not state.get(field) is Dictionary:return false
	if state.npcs.size()>12000 or state.quests.size()>256:return false
	for currency in ["bronze","renown"]:
		var value: Variant=state.balances.get(currency)
		if not value is int or value<0 or value>1000000000:return false
	for faction in state.reputation:
		if faction not in Factions.FACTIONS or not state.reputation[faction] is int:return false
		if absi(int(state.reputation[faction]))>100:return false
	if state.fate.get("version")!=1 or not state.fate.get("clues") is Array:return false
	if state.fate.clues.size()>128 or state.fate.get("thread","") not in Fate.OPTIONS:return false
	if state.fate.get("personality","") not in Fate.QUIRKS:return false
	for clue in state.fate.clues:
		if not clue is String or clue.is_empty() or clue.length()>80:return false
	for receipt in state.receipts:
		if not receipt is String or receipt.is_empty() or receipt.length()>128:return false
	for npc in state.npcs.values():
		if not npc is Dictionary or npc.get("generation_version")!=1:return false
		if not npc.get("attributes") is Dictionary or not npc.get("appearance") is Dictionary:return false
		if not npc.get("id") is String or not str(npc.id).begins_with("npc/r"):return false
		if not npc.get("level") is int or npc.level<1 or npc.level>30:return false
		if npc.appearance.has("visual_r2") and not preload("res://exo_humanoids03_r2/scripts/preset_selector.gd").valid(npc.appearance.visual_r2):return false
		for slot in ["race","robe","hair","skin","style","voice"]:
			if not npc.appearance.get(slot) is int:return false
		for attribute in Attributes:
			var value: Variant=npc.attributes.get(attribute)
			if not value is int or value<0 or value>30:return false
	return true

# JSON represents all numeric literals as float. Restore only integral extension
# values before validation; fractional or non-finite values stay invalid.
static func restore_numbers(value: Variant) -> Variant:
	if value is Dictionary:
		for key in value.keys():value[key]=restore_numbers(value[key])
	elif value is Array:
		for index in range(value.size()):value[index]=restore_numbers(value[index])
	elif value is float and is_finite(value) and value==floorf(value) and absf(value)<=1000000000:
		return int(value)
	return value
