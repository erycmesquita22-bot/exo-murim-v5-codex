extends RefCounted
const Selector = preload("res://exo_bestiary/ai/utility_selector.gd")
const Threat = preload("res://exo_bestiary/ai/threat_evaluator.gd")
const States = preload("res://exo_bestiary/ai/behavior_states.gd")
var profile: Dictionary = {}
var state: String = "IDLE"
var elapsed: float = 0.0
var phase: int = 0
var last_intent: String = ""
func configure(value: Dictionary) -> void:
    profile = value.duplicate(true); state="IDLE"; elapsed=0.0; phase=0; last_intent=""
func step(ctx: Dictionary, dt: float) -> Dictionary:
    elapsed += maxf(dt,0.0)
    if float(ctx.get("hp_ratio",1.0)) <= 0.0:
        state="DEFEATED"
        return _result("none")
    if state=="DEFEATED": return _result("none")
    if not bool(ctx.get("territory_exists",true)):
        state="RETURN_HOME"
        return _result("request_safe_despawn")
    if bool(ctx.get("outside_territory",false)):
        state="RETURN_HOME"
        return _result("go_home")
    if Threat.should_flee(profile,ctx):
        state="FLEE"
        return _result("flee")
    if bool(ctx.get("predator_visible",false)) and str(profile.get("behavior",""))=="prey":
        state="FLEE"
        return _result("flee")
    var see_target := bool(ctx.get("target_visible",false))
    if not see_target:
        if bool(ctx.get("heard_noise",false)):
            state="INVESTIGATE"
            return _result("investigate")
        state="PATROL" if elapsed>2.5 else "OBSERVE"
        return _result("patrol" if state=="PATROL" else "observe")
    if str(profile.get("behavior",""))=="prey":
        state="FLEE"
        return _result("flee")
    if str(profile.get("behavior",""))=="territorial" and not bool(ctx.get("intruding",false)):
        state="OBSERVE"
        return _result("watch")
    if str(profile.get("behavior",""))=="predator" and not bool(ctx.get("hungry",true)) and not bool(ctx.get("intruding",false)):
        state="OBSERVE"
        return _result("watch")
    var effective: Dictionary=profile
    if profile.get("phases",[]) is Array and not profile.get("phases",[]).is_empty():
        var phases: Array=profile.phases
        update_boss_phase(float(ctx.get("hp_ratio",1.0)),phases)
        effective=profile.duplicate(true)
        effective["combat_style"]=str(phases[phase].get("style","pressure"))
    var decision: String = Selector.choose(effective,ctx)
    match decision:
        "attack":state="ATTACK"
        "approach":state="APPROACH"
        "position":state="POSITION"
        "defend":state="DEFEND"
        "evade":state="EVADE"
        "retreat":state="RETREAT"
        _:state="OBSERVE"
    return _result(decision)
func _result(intent: String) -> Dictionary:
    last_intent=intent
    return {"state":state,"intent":intent,"needs_authoritative_attack":intent=="attack","phase":phase,"telegraph":str(profile.get("telegraph","")) if intent=="attack" else "","vulnerability":str(profile.get("vulnerability",""))}
func update_boss_phase(hp_ratio: float, phases: Array) -> int:
    var next_phase := 0
    for i in range(phases.size()):
        if hp_ratio <= float(phases[i].get("threshold",1.0)):
            next_phase=i
    phase=maxi(phase,next_phase)
    return phase
