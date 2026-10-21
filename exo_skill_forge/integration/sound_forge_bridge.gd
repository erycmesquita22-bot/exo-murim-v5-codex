extends RefCounted
# Optional adapter for Sound Forge 01, only after installation AND review.
# The presentation router ignores all cues until binding == asset_verified.
var sound_bank: Node

func _init(bank: Node = null) -> void:
	sound_bank = bank

func play(actor: Object, event_id: String, _gain: float, skill_id: String) -> void:
	if not is_instance_valid(sound_bank) or not sound_bank.has_method("has_event"):
		return
	if not bool(sound_bank.call("has_event", event_id)):
		return
	var token: String = skill_id + ":" + event_id + ":" + str(actor.get_instance_id() if is_instance_valid(actor) else 0)
	if actor is Node3D and is_instance_valid(actor):
		if sound_bank.has_method("play_event_3d"):
			sound_bank.call("play_event_3d", event_id, actor, actor.global_position, token)
	elif sound_bank.has_method("play_event_2d"):
		sound_bank.call("play_event_2d", event_id, token)
