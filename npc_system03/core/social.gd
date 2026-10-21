extends RefCounted
const Social02 = preload("res://npc_system02/social.gd")
const Identity = preload("res://npc_system03/core/identity.gd")
# No writing to Narrative relationships, affection, social memories or the player state.
static func encounter(a: Dictionary, b: Dictionary, clock: float, narrative: Dictionary = {}, physical: bool = false) -> Dictionary:
	var aid: String = str(a.get("id", ""))
	var bid: String = str(b.get("id", ""))
	if aid.is_empty() or bid.is_empty() or aid == bid:
		return {"status":"BLOCKED","reason":"invalid_pair"}
	# NPC02 eligible() performs TTL compaction; use copies so the preview is read-only.
	var left: Dictionary = a.duplicate(true)
	var right: Dictionary = b.duplicate(true)
	if not Social02.eligible(left, right, clock, narrative, physical):
		return {"status":"BLOCKED","reason":"ineligible_contact"}
	return {"status":"PROPOSED","actor_id":aid,"partner_id":bid,
		"affinity_a":Social02.affinity(a, b, narrative),
		"affinity_b":Social02.affinity(b, a, narrative),
		"owner":"living_world","physical_required":true,"committed":false}

static func romance(a: Dictionary, b: Dictionary, clock: float, narrative: Dictionary = {}, physical: bool = false) -> Dictionary:
	if not Identity.confirmed_adult(a) or not Identity.confirmed_adult(b):
		return {"status":"BLOCKED","reason":"adult_consent_not_confirmed"}
	if not physical:
		return {"status":"BLOCKED","reason":"actual_encounter_required"}
	var contact: Dictionary = encounter(a, b, clock, narrative, true)
	if str(contact.get("status", "")) != "PROPOSED":
		return {"status":"BLOCKED","reason":"encounter_not_eligible"}
	var bond: String = Social02.story_bond(narrative, str(a.get("id", "")), str(b.get("id", "")))
	if bond in ["rival", "family", "master_disciple"]:
		return {"status":"BLOCKED","reason":"narrative_bond_exclusion"}
	if int(a.get("preferences", {}).get("social", 0)) < 35 or int(b.get("preferences", {}).get("social", 0)) < 35:
		return {"status":"BLOCKED","reason":"interest_not_mutual"}
	return {"status":"PROPOSAL_ONLY","actor_id":str(a.get("id", "")),
		"partner_id":str(b.get("id", "")), "loc_key":"npc03.romance.possible_interest",
		"authority":"narrative","requires_mutual_consent":true,
		"requires_narrative_contract":true,"committed":false}
