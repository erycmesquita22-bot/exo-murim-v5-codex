extends RefCounted
# EXO Skill Forge 01 - strict data validation; read-only and fail-closed.
const SOURCES := ["legacy", "authorial"]
const STATES := ["legacy_connected", "candidate_not_unlocked"]
const EXECUTORS := ["legacy", "generic"]
const PHASES := ["prepare", "release", "impact", "tick", "expire", "cancel"]
const OPS := ["damage", "status", "movement", "field", "channel", "projectile", "shield", "heal", "cleanse"]
const SHAPES := ["self", "line", "cone", "circle", "projectile", "dash"]
const STATUSES := ["none", "bleed", "burn", "slow", "root", "stagger", "knockback", "mark", "pierce"]

static func verify(spec: Dictionary, styles: Dictionary, schools: Dictionary, poses: Dictionary, templates: Dictionary, weapon_ids: Dictionary = {}) -> Array[String]:
	var errors: Array[String] = []
	var identifier: String = str(spec.get("id", ""))
	if identifier.is_empty() or identifier.length() > 96 or identifier.contains("/") or identifier.contains(".."):
		errors.append("bad_id")
	if not spec.get("name") is String or str(spec.get("name", "")).strip_edges().is_empty(): errors.append("bad_name")
	if str(spec.get("source", "")) not in SOURCES: errors.append("bad_source")
	if str(spec.get("state", "")) not in STATES: errors.append("bad_state")
	if str(spec.get("executor", "")) not in EXECUTORS: errors.append("bad_executor")
	if spec.get("source") == "legacy" and (spec.get("executor") != "legacy" or identifier != str(spec.get("legacy_id", ""))): errors.append("legacy_identity")
	if spec.get("source") == "authorial" and (spec.get("executor") != "generic" or not identifier.begins_with("exo.sf.")): errors.append("authorial_identity")
	if not templates.has(str(spec.get("template", ""))) and str(spec.get("source", "")) != "legacy": errors.append("unknown_template")
	if not spec.get("tags") is Dictionary or not spec.get("balance") is Dictionary or not spec.get("presentation") is Dictionary or not spec.get("effects") is Array:
		errors.append("invalid_sections")
		return errors
	var tags: Dictionary = spec["tags"]
	var balance: Dictionary = spec["balance"]
	var presentation: Dictionary = spec["presentation"]
	for name in ["styles", "schools", "weapon_poses", "weapon_ids", "actor_types"]:
		if not tags.get(name) is Array:
			errors.append("bad_tags_" + name)
			return errors
	for sid in tags["styles"]:
		if not styles.has(str(sid)): errors.append("unknown_style:" + str(sid))
	for sid in tags["schools"]:
		if not schools.has(str(sid)): errors.append("unknown_school:" + str(sid))
	for pose in tags["weapon_poses"]:
		if not poses.has(str(pose)): errors.append("unknown_weapon_pose:" + str(pose))
	for weapon_id in tags["weapon_ids"]:
		if not weapon_ids.is_empty():
			if not weapon_ids.has(str(weapon_id)):
				errors.append("unknown_weapon_id:" + str(weapon_id))
			elif not tags["weapon_poses"].has(weapon_ids[str(weapon_id)]):
				errors.append("weapon_pose_mismatch:" + str(weapon_id))
	if identifier.begins_with("exo.sf.r2."):
		if str(tags.get("inspiration_origin", "")) not in ["anime", "manhwa", "lendas", "cinema"]: errors.append("bad_inspiration_origin")
		if str(tags.get("power_family", "")) not in ["corpo", "armas", "qi", "sangue", "demonica", "celestial", "mundana"]: errors.append("bad_power_family")
		if str(tags.get("combat_role", "")) not in ["precision", "cleave", "ranged_pressure", "mobility", "area_control", "disruption", "sustained_pressure", "defense", "support", "zone_denial"]: errors.append("bad_combat_role")
		if str(tags.get("combo_role", "")) not in ["opener", "chaser", "finisher", "counter", "defensive"]: errors.append("bad_combo_role")
		if not integer_value(tags.get("rarity_tier")) or int(tags.get("rarity_tier", 0)) < 1 or int(tags.get("rarity_tier", 0)) > 5: errors.append("bad_rarity_tier")
		if not tags.get("world_tags") is Array or tags.get("world_tags", []).size() > 8: errors.append("bad_world_tags")
		if not spec.get("design") is Dictionary: errors.append("missing_design_metadata")
	for actor in tags["actor_types"]:
		if str(actor) not in ["player", "npc", "enemy"]: errors.append("unknown_actor_type")
	for k in ["min_level", "min_cultivation_rank"]:
		if not integer_value(tags.get(k)) or int(tags.get(k, -1)) < 0: errors.append("bad_requirement_" + k)
	var maxvals: Dictionary = {"damage": 5000.0, "qi": 100.0, "stamina": 100.0, "cooldown": 180.0, "range": 18.0, "radius": 8.0, "cone_degrees": 360.0, "cast_time": 30.0, "release_time": 30.0}
	for k in maxvals:
		var val: Variant = balance.get(k, 0.0)
		if not (val is int or val is float):
			errors.append("bad_number:" + k)
			continue
		if (is_nan(float(val)) or is_inf(float(val))) or float(val) < 0 or float(val) > float(maxvals[k]): errors.append("out_of_bounds:" + k)
	if float(balance.get("release_time", 0)) > float(balance.get("cast_time", 0)) and float(balance.get("cast_time", 0)) != 0.0: errors.append("release_after_cast")
	if spec["effects"].size() > 16: errors.append("too_many_effects")
	for item in spec["effects"]:
		if not item is Dictionary:
			errors.append("bad_effect")
			continue
		if str(item.get("stage", "")) not in PHASES or str(item.get("op", "")) not in OPS: errors.append("bad_effect_operation")
		if item.has("shape") and str(item["shape"]) not in SHAPES: errors.append("bad_shape")
		if item.has("status") and str(item["status"]) not in STATUSES: errors.append("bad_status")
		for k in ["duration", "value", "strength", "distance", "speed", "tick_interval", "coefficient"]:
			if item.has(k) and (not (item[k] is int or item[k] is float) or (is_nan(float(item[k])) or is_inf(float(item[k]))) or float(item[k]) < 0 or float(item[k]) > 1000): errors.append("bad_effect_value:" + k)
		for k in ["max_targets", "max_instances", "max_ticks", "max_projectiles"]:
			if item.has(k) and (not integer_value(item[k]) or int(item[k]) < 1 or int(item[k]) > 20): errors.append("bad_effect_limit:" + k)
		if item.has("tick_interval") and float(item["tick_interval"]) <= 0: errors.append("zero_tick_interval")
	for track in ["audio", "vfx"]:
		if not presentation.get(track) is Array:
			errors.append("bad_presentation_" + track)
			continue
		if presentation[track].size() > 12: errors.append("too_many_cues:" + track)
		for cue in presentation[track]:
			if not cue is Dictionary:
				errors.append("bad_cue")
				continue
			if str(cue.get("phase", "")) not in PHASES: errors.append("bad_cue_phase")
			if str(cue.get("binding", "")) not in ["host_existing", "requires_binding", "asset_verified"]: errors.append("bad_cue_binding")
			if str(cue.get("binding", "")) == "asset_verified":
				if not bool(cue.get("commercial_use_verified", false)): errors.append("media_rights_unverified")
				var path: String = str(cue.get("resource_path", ""))
				if not path.begins_with("res://") or not FileAccess.file_exists(path):
					errors.append("media_file_missing")
				elif str(cue.get("source_sha256", "")) != FileAccess.get_sha256(path):
					errors.append("media_hash_mismatch")
	if not presentation.get("animation") is Dictionary:
		errors.append("bad_animation")
	elif str(presentation["animation"].get("binding", "")) == "asset_verified" and not bool(presentation["animation"].get("commercial_use_verified", false)):
		errors.append("animation_not_approved")
	return errors

static func integer_value(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and absf(float(value)) <= 2147483647.0
