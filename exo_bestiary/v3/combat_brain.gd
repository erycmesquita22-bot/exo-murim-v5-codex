extends RefCounted
# Passo tático consultivo; host ainda precisa confirmar LOS, distância, estado e executor real.
const AttackSelector = preload("res://exo_bestiary/combat/attack_selector.gd")

static func decide(profile: Dictionary, catalog: RefCounted, snapshot: Dictionary, order: Dictionary = {}) -> Dictionary:
    if profile.is_empty() or catalog == null:
        return _blocked("missing_profile")
    var hp: float = float(snapshot.get("hp_ratio", 1.0))
    if not is_finite(hp):
        return _blocked("invalid_hp")
    if hp <= 0.0:
        return _proposal("none", "DEFEATED")
    if not bool(snapshot.get("territory_exists", true)) or bool(snapshot.get("outside_territory", false)):
        return _proposal("go_home", "RETURN_HOME")
    if bool(snapshot.get("safe_zone", false)):
        return _proposal("hold", "OBSERVE")
    if not bool(snapshot.get("target_visible", false)):
        return _proposal("investigate" if bool(snapshot.get("heard_noise", false)) else "patrol", "SEARCH")
    if bool(snapshot.get("target_defeated", false)):
        return _proposal("hold", "OBSERVE")
    if str(profile.get("behavior", "")) == "prey":
        return _proposal("flee", "FLEE")
    var role: String = str(order.get("role", "pressure"))
    var hp_ratio: float = clampf(hp, 0.0, 1.0)
    if (hp_ratio < 0.18 and float(profile.get("morale", 0.5)) < 0.65) or str(order.get("intent", "")) == "retreat":
        return _proposal("retreat", "RETREAT")
    if bool(snapshot.get("enemy_winding_up", false)):
        if str(profile.get("combat_style", "")) in ["counter", "defensive", "duelist"]:
            return _proposal("defend", "DEFEND")
        if bool(snapshot.get("evade_ready", false)) and hp_ratio < 0.5:
            return _proposal("evade", "EVADE")
    var distance: float = float(snapshot.get("distance", INF))
    if not is_finite(distance) or distance < 0.0:
        return _blocked("invalid_distance")
    var desired: Variant = profile.get("preferred_distance", [1.0, 2.5])
    var near: float = float(desired[0]) if desired is Array and desired.size() > 0 else 1.0
    var far: float = float(desired[1]) if desired is Array and desired.size() > 1 else 2.5
    if role == "flanker" and not bool(snapshot.get("flank_reached", false)):
        return _proposal("position", "POSITION")
    if distance < near:
        return _proposal("position", "POSITION")
    if distance > far:
        return _proposal("approach", "APPROACH")
    # Nenhuma ordem pode transformar um ataque proibido em dano. Mesmo ataques aprovados são propostas.
    var slot: bool = bool(order.get("attack_slot", false))
    var ready: bool = bool(snapshot.get("attack_ready", false))
    var sight: bool = bool(snapshot.get("line_of_sight", false))
    if not slot or not ready or not sight:
        return _proposal("defend" if bool(snapshot.get("enemy_winding_up", false)) else "position", "DEFEND" if bool(snapshot.get("enemy_winding_up", false)) else "POSITION")
    var attack: Dictionary = AttackSelector.select(profile, catalog, snapshot)
    if attack.is_empty():
        return _proposal("position", "POSITION")
    var result: Dictionary = _proposal("attack", "ATTACK")
    result["attack_id"] = str(attack.get("id", ""))
    result["requires_authoritative_attack"] = true
    result["telegraph"] = str(profile.get("telegraph", ""))
    return result

static func _proposal(intent: String, state: String) -> Dictionary:
    return {"status": "PROPOSED", "committed": false, "authority": "none",
        "intent": intent, "state": state, "attack_id": "", "requires_authoritative_attack": false,
        "requires_host_combat_check": true, "schema_version": 3}

static func _blocked(reason: String) -> Dictionary:
    return {"status": "BLOCKED", "committed": false, "authority": "none", "reason": reason, "schema_version": 3}
