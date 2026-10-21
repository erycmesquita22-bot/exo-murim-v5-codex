extends RefCounted
# This bridge is opt-in. It never rewrites main.gd, murim_flow.gd or saves until
# the gameplay owner explicitly invokes the adapter from a supported event.
const State=preload("res://living_world/state.gd")
const People=preload("res://living_world/people.gd")
const Profile=preload("res://npc_system02/profile.gd")
const Quests=preload("res://living_world/quests.gd")

static func setup(journey: RefCounted,atlas_seed: String="") -> Dictionary:
	var previous: Dictionary=journey.data.duplicate(true)
	State.ensure(journey.data,atlas_seed)
	if not State.valid(journey.data.living_world):journey.data=previous;return {"ok":false,"error":"invalid_living_world"}
	if not journey.write():journey.data=previous;return {"ok":false,"error":"save_failed"}
	return {"ok":true}

static func record_roster(journey: RefCounted,region: Dictionary,slots: Array,atlas_seed: String="",persist:bool=true) -> Dictionary:
	var previous: Dictionary=journey.data.duplicate(true)
	var state: Dictionary=State.ensure(journey.data,atlas_seed)
	var seed_text: String=atlas_seed if not atlas_seed.is_empty() else str(journey.data.world.seed)
	var region_id: int=int(region.get("id",0))
	var results: Array=[]
	var changed: bool=false
	for npc in People.roster(seed_text,region_id,slots,int(region.get("difficulty",1))):
		# Materialized identities win over changed definitions and generation order.
		var id: String=str(npc.id)
		if not state.npcs.has(id):state.npcs[id]=npc;changed=true
		if slots.size()>0 and str(region.get("kind",""))=="settlement":
			var stored: Dictionary=state.npcs[id]
			if int(stored.get("occupancy_version",0))<3:
				stored.home_slot=npc.home_slot;stored.work_slot=npc.work_slot;stored["occupancy_version"]=3;changed=true
		if Profile.enrich(state.npcs[id],seed_text):changed=true
		results.append(state.npcs[id])
	if Profile.link_roster(results):changed=true
	if not State.valid(state):journey.data=previous;return {"ok":false,"error":"invalid_roster"}
	if changed and persist and not journey.write():journey.data=previous;return {"ok":false,"error":"save_failed"}
	return {"ok":true,"npcs":results}

static func accept_contract(journey: RefCounted,contract_key: String,context: Dictionary) -> bool:
	var offered: bool=false
	for option in Quests.offers(context,int(journey.data.get("stage",0))):
		if str(option.id)==contract_key:offered=true;break
	if not offered:return false
	var previous: Dictionary=journey.data.duplicate(true)
	var state: Dictionary=State.ensure(journey.data)
	if not Quests.accept(state,contract_key):return false
	if not State.valid(state) or not journey.write():journey.data=previous;return false
	return true

static func event(journey: RefCounted,event_id: String,event_type: String,target: String,region_id: int,amount: int=1) -> int:
	if event_id.is_empty() or event_id.length()>128:return 0
	var previous: Dictionary=journey.data.duplicate(true)
	var state: Dictionary=State.ensure(journey.data)
	if state.receipts.has(event_id):return 0
	var advanced: int=Quests.emit(state,event_id,event_type,target,region_id,amount)
	if advanced==0:return 0
	if not State.valid(state) or not journey.write():journey.data=previous;return -1
	return advanced

static func claim_contract(journey: RefCounted,contract_key: String) -> bool:
	var previous: Dictionary=journey.data.duplicate(true)
	var state: Dictionary=State.ensure(journey.data)
	if not Quests.claim(state,contract_key):return false
	if not State.valid(state) or not journey.write():journey.data=previous;return false
	return true
