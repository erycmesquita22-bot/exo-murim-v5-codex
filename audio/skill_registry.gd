extends RefCounted
# Entries also audit preserved skills. Only explicitly integrated IDs override playback.
static var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://audio/skill_registry.json"))
static func integrated(id: String) -> bool:
	return catalog.skills.get(id,{}).get("status","")=="integrated_original_cc0"
static func play(audio: Node,id: String,phase: String) -> bool:
	if not integrated(id):return false
	var cue: Dictionary=catalog.skills[id].phases.get(phase,{})
	var event_value: Variant = cue.get("event", null)
	if event_value is String and not str(event_value).is_empty():
		audio.play_event(str(event_value), "magic", float(cue.get("gain", 0.85)))
		return true
	return false
