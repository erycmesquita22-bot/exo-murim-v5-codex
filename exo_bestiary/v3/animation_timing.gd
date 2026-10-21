extends RefCounted
# Perfil consultivo em segundos: AnimationPlayer/Skill Forge host aplica quando clips existirem.
# Não encurta janelas de hitbox, recarga, defesa ou custos por si mesmo.
static func preview(profile: Dictionary) -> Dictionary:
    if profile.is_empty():
        return {"status":"BLOCKED", "reason":"unknown_profile"}
    var weapon: String = str(profile.get("weapon_family", ""))
    var style: String = str(profile.get("combat_style", ""))
    var clip_time: float = 0.34
    var recovery: float = 0.14
    if weapon == "daggers" or style == "flank":
        clip_time = 0.23
        recovery = 0.09
    elif weapon == "spear":
        clip_time = 0.37
        recovery = 0.14
    elif weapon in ["bow", "crossbow"]:
        clip_time = 0.42
        recovery = 0.18
    elif style in ["defensive", "counter"]:
        clip_time = 0.39
        recovery = 0.18
    elif style == "technique":
        clip_time = 0.48
        recovery = 0.2
    return {"status":"PROPOSED","committed":false,"attack_clip_seconds":clip_time,
        "recovery_seconds":recovery,"input_buffer_seconds":0.12,
        "telegraph_seconds":0.15 if clip_time < 0.3 else 0.22,
        "reaction_hit_seconds":0.18,"allow_cancel_to_evade":true,
        "requires_existing_animation":true,"requires_host_combat_validation":true,
        "schema_version":3}
