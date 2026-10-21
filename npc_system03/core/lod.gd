extends RefCounted
# Render/physics LOD advisory only; the host controls the scene tree and event delivery.
const NEAR_SQ := 225.0
const ACTIVE_SQ := 3600.0
const FAR_SQ := 6400.0
static func advise(distance_squared: float, visible: bool, in_conversation: bool, in_combat: bool) -> Dictionary:
	if distance_squared < 0.0 or not is_finite(distance_squared):
		return {"status":"BLOCKED","reason":"invalid_distance"}
	if in_conversation or in_combat:
		return {"status":"PROPOSED","tier":"full","tick_seconds":0.1,"allow_visual":true,
			"allow_physics":true,"apply_only_if_actor_exists":true,"committed":false}
	if distance_squared > FAR_SQ:
		return {"status":"PROPOSED","tier":"abstract","tick_seconds":5.0,"allow_visual":false,
			"allow_physics":false,"apply_only_if_actor_exists":true,"committed":false}
	if distance_squared > ACTIVE_SQ:
		return {"status":"PROPOSED","tier":"logical","tick_seconds":1.0,"allow_visual":false,
			"allow_physics":true,"apply_only_if_actor_exists":true,"committed":false}
	return {"status":"PROPOSED","tier":"full" if visible or distance_squared <= NEAR_SQ else "reduced",
		"tick_seconds":0.1 if visible or distance_squared <= NEAR_SQ else 0.4,
		"allow_visual":visible,"allow_physics":true,"apply_only_if_actor_exists":true,"committed":false}
