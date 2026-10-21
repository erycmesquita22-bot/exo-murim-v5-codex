extends RefCounted
# Dispatches multiple phase-based cues through verified host media adapters.
# Never plays placeholders or duplicates the legacy Techniques audio pipeline.
static func dispatch(plan: Dictionary, phase: String, actor: Object, adapters: Dictionary) -> Dictionary:
	if not bool(plan.get("ok", false)): return {"ok": false, "reason": "invalid_plan"}
	if str(plan.get("source", "")) == "legacy": return {"ok": true, "dispatched": 0, "reason": "legacy_host_owns_presentation"}
	if phase not in ["prepare", "release", "impact", "tick", "expire", "cancel"]: return {"ok": false, "reason": "invalid_phase"}
	var presentation: Dictionary = plan.get("presentation", {})
	var played: int = 0
	var skipped: Array = []
	if phase == "release":
		var animation: Dictionary = presentation.get("animation", {})
		if str(animation.get("binding", "")) == "asset_verified" and adapters.get("animation") is Callable and adapters["animation"].is_valid():
			adapters["animation"].call(actor, str(animation.get("key", "")), plan["skill_id"])
			played += 1
		elif str(animation.get("binding", "")) == "requires_binding": skipped.append(str(animation.get("key", "")))
	for media in ["audio", "vfx"]:
		for cue in presentation.get(media, []):
			if str(cue.get("phase", "")) != phase: continue
			if str(cue.get("binding", "")) != "asset_verified":
				skipped.append(str(cue.get("key", "")))
				continue
			var adapter: Variant = adapters.get(media, null)
			if not adapter is Callable or not adapter.is_valid():
				skipped.append(str(cue.get("key", "")))
				continue
			adapter.call(actor, str(cue.get("key", "")), float(cue.get("gain", 1.0)), plan["skill_id"])
			played += 1
	return {"ok": true, "dispatched": played, "unbound_or_unavailable": skipped}
