extends RefCounted
# Pure quest logic. Reward transactions must be committed via bridge.gd.
static var RULES: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://living_world/data/contracts.json"))
const Factions=preload("res://living_world/factions.gd")
const Fate=preload("res://living_world/fate.gd")

static func definition(template_id: String) -> Dictionary:
	for template in RULES.contracts:
		if str(template.id)==template_id:return template
	return {}

static func key(region_id: int,template_id: String) -> String:
	return "r%d/%s"%[region_id,template_id]

static func offers(context: Dictionary,stage: int=5) -> Array:
	var result: Array=[]
	var scale: String=str(context.get("settlement_scale",""))
	var kind: String=str(context.get("kind","wild"))
	var difficulty: int=int(context.get("difficulty",1))
	var services: Array=context.get("services",[])
	for template in RULES.contracts:
		if result.size()>=6:break
		if stage<int(template.get("requires_stage",5)):continue
		if difficulty<int(template.min_difficulty) or difficulty>int(template.max_difficulty):continue
		if scale not in template.scopes and kind not in template.scopes:continue
		if template.has("required_service") and str(template.required_service) not in services:continue
		result.append({"id":key(int(context.get("id",0)),str(template.id)),"title":str(template.title),"description":str(template.description)})
	return result

static func accept(state: Dictionary,contract_key: String) -> bool:
	if state.quests.size()>=3 or state.quests.has(contract_key) or state.finished.has(contract_key):return false
	var parts: PackedStringArray=contract_key.split("/")
	if parts.size()!=2 or not parts[0].begins_with("r") or not parts[0].substr(1).is_valid_int():return false
	var template: Dictionary=definition(parts[1])
	if template.is_empty():return false
	var counts: Array=[]
	for objective in template.objectives:counts.append(0)
	state.quests[contract_key]={"template":parts[1],"region":int(parts[0].substr(1)),"counts":counts,"ready":false}
	return true

static func emit(state: Dictionary,event_id: String,event_type: String,target: String,region_id: int,amount: int=1) -> int:
	if event_id.is_empty() or event_id.length()>128 or state.receipts.has(event_id) or amount<1 or amount>50:return 0
	# Only qualifying contract progress is archived. Unrelated world activity
	# must not fill the save with thousands of meaningless receipts.
	var advanced: int=0
	for contract_id in state.quests.keys():
		var progress: Dictionary=state.quests[contract_id]
		if int(progress.region)!=region_id or bool(progress.ready):continue
		var definition_data: Dictionary=definition(str(progress.template))
		for i in range(definition_data.objectives.size()):
			var objective: Dictionary=definition_data.objectives[i]
			if objective.event!=event_type or objective.target!=target:continue
			var previous: int=int(progress.counts[i])
			var updated: int=mini(int(objective.count),previous+amount)
			progress.counts[i]=updated
			advanced+=updated-previous
		var complete:=true
		for i in range(definition_data.objectives.size()):
			if int(progress.counts[i])<int(definition_data.objectives[i].count):complete=false
		progress.ready=complete
	if advanced>0:state.receipts[event_id]="event"
	return advanced

static func claim(state: Dictionary,contract_key: String) -> bool:
	if not state.quests.has(contract_key) or state.finished.has(contract_key):return false
	var progress: Dictionary=state.quests[contract_key]
	if not bool(progress.ready):return false
	var template: Dictionary=definition(str(progress.template))
	if template.is_empty():return false
	var reward: Dictionary=template.reward
	# All rewards live in this extension's own accounts. The legacy 'coins'
	# invariant in JourneySave must not be modified here.
	var bronze_next: int=int(state.balances.bronze)+int(reward.get("bronze",0))
	var renown_next: int=int(state.balances.renown)+int(reward.get("renown",0))
	if bronze_next>1000000000 or renown_next>1000000000:return false
	state.balances.bronze=bronze_next
	state.balances.renown=renown_next
	for faction in reward.get("reputation",{}):
		Factions.adjust(state,str(faction),int(reward.reputation[faction]))
	if reward.has("fate_clue"):
		Fate.add_clue(state.fate,str(reward.fate_clue))
	state.finished[contract_key]={"template":str(progress.template),"claimed":true}
	state.quests.erase(contract_key)
	return true

static func cancel(state: Dictionary,contract_key: String) -> bool:
	if not state.quests.has(contract_key):return false
	state.quests.erase(contract_key)
	return true
