extends RefCounted
const STATES: Array[String] = ["IDLE","PATROL","OBSERVE","INVESTIGATE","ALERT","APPROACH","POSITION","ATTACK","DEFEND","EVADE","RETREAT","FLEE","RETURN_HOME","DEFEATED"]
static func valid(value: String) -> bool:
    return value in STATES
static func can_transition(start: String, dest: String) -> bool:
    if not valid(start) or not valid(dest): return false
    if start == "DEFEATED": return dest == "DEFEATED"
    return true
