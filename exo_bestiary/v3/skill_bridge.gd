extends RefCounted
# Ponte read-only para Skill Forge R3. Nunca solicita cast nem associa um executor.
const MAX_IDS: int = 16

static func suggest(core: RefCounted, profile: Dictionary, actor: Dictionary, candidate_ids: Array) -> Dictionary:
    if core == null or core.services == null or not core.services.has_service("skill_forge"):
        return {"status": "BLOCKED", "reason": "skill_forge_unavailable", "skills": [], "committed": false}
    if profile.is_empty() or candidate_ids.size() > MAX_IDS:
        return {"status": "BLOCKED", "reason": "invalid_input", "skills": [], "committed": false}
    var options: Array[Dictionary] = []
    var seen: Dictionary = {}
    for raw_id in candidate_ids:
        if not raw_id is String:
            continue
        var id: String = str(raw_id)
        if id.is_empty() or seen.has(id) or id.length() > 128:
            continue
        seen[id] = true
        var data: Variant = core.services.invoke("skill_forge", "skill", [id])
        if not data is Dictionary or data.is_empty():
            continue
        var tags: Dictionary = data.get("tags", {})
        var balance: Dictionary = data.get("balance", {})
        if not _actor_allowed(tags, actor, profile):
            continue
        if int(actor.get("level", 0)) < int(tags.get("min_level", 0)):
            continue
        if int(actor.get("cultivation_rank", 0)) < int(tags.get("min_cultivation_rank", 0)):
            continue
        if float(actor.get("qi", 0.0)) < float(balance.get("qi", 0.0)):
            continue
        if float(actor.get("stamina", 0.0)) < float(balance.get("stamina", 0.0)):
            continue
        options.append({"skill_id": id, "state": str(data.get("state", "unknown")),
            "executor": str(data.get("executor", "")), "execution": "HOST_AUTHORIZATION_REQUIRED",
            "committed": false, "authority": "none"})
    return {"status": "PROPOSED", "skills": options, "committed": false,
        "authority": "none", "never_casts": true, "schema_version": 3}

static func _actor_allowed(tags: Dictionary, actor: Dictionary, profile: Dictionary) -> bool:
    var types: Variant = tags.get("actor_types", [])
    if types is Array and not types.is_empty() and "enemy" not in types:
        return false
    var weapon_ids: Variant = tags.get("weapon_ids", [])
    if weapon_ids is Array and not weapon_ids.is_empty():
        if str(actor.get("weapon_id", "")) not in weapon_ids:
            return false
    var schools: Variant = tags.get("schools", [])
    if schools is Array and not schools.is_empty() and str(actor.get("school_id", "")) not in schools:
        return false
    var styles: Variant = tags.get("styles", [])
    if styles is Array and not styles.is_empty() and str(actor.get("style_id", "")) not in styles:
        return false
    return true
