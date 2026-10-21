extends RefCounted
# Bestiário 03. Somente propostas; NÃO movimenta atores, faz spawn, valida caminho ou aplica dano.
const MAX_MEMBERS: int = 8
const MAX_ATTACK_SLOTS: int = 2
const MAX_UID_LENGTH: int = 128
const ATTACK_WINDOW: float = 0.45

static func propose(request: Dictionary, catalog: RefCounted) -> Dictionary:
    if catalog == null:
        return _blocked("missing_catalog")
    var region: Variant = request.get("region_id", null)
    var target: Variant = request.get("target_position", null)
    var members: Variant = request.get("members", null)
    var group_id: String = str(request.get("group_id", ""))
    if not region is int or region < 0 or region > 87:
        return _blocked("invalid_region")
    if not target is Vector3 or not _valid_vec(target):
        return _blocked("invalid_target_position")
    if not members is Array or members.is_empty() or members.size() > MAX_MEMBERS:
        return _blocked("invalid_group_size")
    if group_id.is_empty() or group_id.length() > MAX_UID_LENGTH:
        return _blocked("invalid_group_id")

    var prepared: Array[Dictionary] = []
    var seen: Dictionary = {}
    for row in members:
        if not row is Dictionary:
            return _blocked("invalid_member")
        var uid: String = str(row.get("uid", ""))
        var profile_id: String = str(row.get("profile_id", ""))
        var pos: Variant = row.get("position", null)
        if uid.is_empty() or uid.length() > MAX_UID_LENGTH or seen.has(uid):
            return _blocked("invalid_or_duplicate_uid")
        if not pos is Vector3 or not _valid_vec(pos):
            return _blocked("invalid_position")
        # Se o host forneceu região do ator, ela precisa coincidir com a região do grupo.
        if row.has("region_id") and (not row["region_id"] is int or row["region_id"] != region):
            return _blocked("cross_region_member")
        var profile: Dictionary = catalog.get_profile(profile_id)
        if profile.is_empty():
            return _blocked("unknown_profile:" + profile_id)
        var hp_ratio: float = clampf(float(row.get("hp_ratio", 1.0)), 0.0, 1.0)
        if not is_finite(hp_ratio):
            return _blocked("invalid_hp_ratio")
        seen[uid] = true
        if hp_ratio <= 0.0:
            continue
        var p: Dictionary = row.duplicate(true)
        p["uid"] = uid
        p["profile_id"] = profile_id
        p["profile"] = profile
        p["role"] = _role(profile)
        p["hp_ratio"] = hp_ratio
        prepared.append(p)
    if prepared.is_empty():
        return _blocked("no_live_members")
    prepared.sort_custom(func(a: Dictionary, b: Dictionary): return str(a.get("uid", "")) < str(b.get("uid", "")))

    # Ordem estável por UID; rotaciona apenas a prioridade de pressão em janelas temporais.
    var clock: float = float(request.get("combat_seconds", 0.0))
    if not is_finite(clock) or clock < 0.0 or clock > 100000000.0:
        return _blocked("invalid_combat_clock")
    var combat_blocked: bool = bool(request.get("target_in_safe_zone", false)) or bool(request.get("target_defeated", false))
    var attack_candidates: Array[String] = []
    var orders: Dictionary = {}
    var n: int = prepared.size()
    for i in range(n):
        var m: Dictionary = prepared[i]
        var profile: Dictionary = m["profile"]
        var role: String = m["role"]
        var radius: float = _preferred_radius(profile, role)
        var angle: float = -PI * 0.5 + TAU * float(i) / float(n)
        var destination: Vector3 = target + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
        var distance: float = _planar_distance(m["position"], target)
        var ready: bool = bool(m.get("attack_ready", false))
        var los: bool = bool(m.get("line_of_sight", false))
        var min_d: float = _min_range(profile)
        var max_d: float = _max_range(profile)
        var can_engage: bool = not combat_blocked and ready and los and bool(m.get("target_visible", false)) and distance >= min_d and distance <= max_d
        var morale: float = clampf(float(profile.get("morale", 0.5)), 0.0, 1.0)
        var retreat: bool = m["hp_ratio"] < (1.0 - morale) * 0.42 and n <= 2
        var intent: String = "hold" if combat_blocked else ("retreat" if retreat else ("hold_range" if role in ["ranged", "support"] else "pressure"))
        if role == "flanker" and not retreat and not combat_blocked:
            intent = "flank"
        orders[m["uid"]] = {"uid": m["uid"], "role": role, "intent": intent,
            "position_hint": destination, "position_is_navigable": false,
            "distance": distance, "attack_slot": false, "eligible": can_engage,
            "requires_host_navigation": true, "requires_host_attack_check": true}
        if can_engage and not retreat:
            attack_candidates.append(m["uid"])
    var cap: int = mini(MAX_ATTACK_SLOTS, maxi(1, int(request.get("max_attackers", 2))))
    var allowed: Array[String] = []
    if not attack_candidates.is_empty():
        var index: int = int(floor(clock / ATTACK_WINDOW)) % attack_candidates.size()
        for i in range(mini(cap, attack_candidates.size())):
            var uid: String = attack_candidates[(index + i) % attack_candidates.size()]
            allowed.append(uid)
            orders[uid]["attack_slot"] = true
    var leader: String = _leader(prepared)
    return {"status": "PROPOSED", "committed": false, "authority": "none",
        "group_id": group_id, "region_id": region, "leader_uid": leader,
        "member_count": n, "attack_slots": allowed, "orders": orders,
        "window": int(floor(clock / ATTACK_WINDOW)), "schema_version": 3,
        "physical_verified": false, "owner_required": ["regional_ecology", "combat", "navigation"]}

static func _role(profile: Dictionary) -> String:
    var style: String = str(profile.get("combat_style", profile.get("behavior", "pressure")))
    var family: String = str(profile.get("weapon_family", ""))
    if style in ["ranged"] or family in ["bow", "crossbow"]:
        return "ranged"
    if style in ["technique"]:
        return "support"
    if style in ["flank", "predator"] or family in ["daggers"]:
        return "flanker"
    if style in ["defensive", "spacing", "territorial"] or family == "shield":
        return "vanguard"
    if style in ["duelist", "counter"]:
        return "duelist"
    return "pressure"

static func _leader(members: Array[Dictionary]) -> String:
    var best_uid: String = ""
    var best_value: float = -1.0
    for m in members:
        var p: Dictionary = m["profile"]
        var score: float = clampf(float(p.get("morale", 0.5)), 0.0, 1.0)
        if str(p.get("category", "")) in ["boss", "elite"]:
            score += 2.0
        if score > best_value:
            best_uid = str(m["uid"])
            best_value = score
    return best_uid

static func _min_range(profile: Dictionary) -> float:
    var ranges: Variant = profile.get("preferred_distance", [1.0, 2.5])
    if ranges is Array and ranges.size() > 0:
        return maxf(0.0, float(ranges[0]))
    return 1.0

static func _max_range(profile: Dictionary) -> float:
    var ranges: Variant = profile.get("preferred_distance", [1.0, 2.5])
    if ranges is Array and ranges.size() > 1:
        return maxf(_min_range(profile), float(ranges[1]))
    return 2.5

static func _preferred_radius(profile: Dictionary, role: String) -> float:
    var desired: float = (_min_range(profile) + _max_range(profile)) * 0.5
    if role == "flanker":
        desired *= 1.15
    return clampf(desired, 1.1, 12.0)

static func _planar_distance(a: Vector3, b: Vector3) -> float:
    return Vector2(a.x - b.x, a.z - b.z).length()

static func _valid_vec(v: Vector3) -> bool:
    return is_finite(v.x) and is_finite(v.y) and is_finite(v.z) and absf(v.x) < 100000.0 and absf(v.z) < 100000.0

static func _blocked(reason: String) -> Dictionary:
    return {"status": "BLOCKED", "committed": false, "authority": "none", "reason": reason, "schema_version": 3}
