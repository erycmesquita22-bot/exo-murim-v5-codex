extends RefCounted
const State=preload("res://narrative/core/narrative_state.gd")
# Optional in save version 4. No original field is replaced, and new schema is
# only created on the first narrative event. Unknown future schemas are rejected.
static func migrate(save: Dictionary,seed: String,character_id: String) -> Dictionary:
	if not save.has("narrative"):return State.ensure(save,seed,character_id)
	var section: Variant=save.narrative
	if not State.valid(section):return {}
	if str(section.seed)!=seed:return {}
	return section
static func encode(state: Dictionary) -> String:
	return JSON.stringify(state) if State.valid(state) else ""
static func decode(payload: String) -> Dictionary:
	var parsed: Variant=JSON.parse_string(payload)
	if not parsed is Dictionary:return {}
	parsed=preload("res://living_world/state.gd").restore_numbers(parsed)
	return parsed if State.valid(parsed) else {}
