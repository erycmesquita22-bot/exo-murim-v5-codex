extends RefCounted
# Coordenação determinística por ID; não cria nova autoridade de spawn.
static func assign(members: Array, target: Vector3, radius: float=2.8) -> Dictionary:
    var result: Dictionary = {}
    var keys: Array = members.duplicate(); keys.sort()
    for i in range(keys.size()):
        var angle: float = float(i)*TAU/float(maxi(1,keys.size()))
        result[str(keys[i])] = target + Vector3(cos(angle)*radius,0.0,sin(angle)*radius)
    return result
static func leader_lost(members: Array, leader: String) -> String:
    var remain: Array=[]
    for member in members:
        if str(member)!=leader:remain.append(str(member))
    remain.sort()
    return str(remain[0]) if not remain.is_empty() else ""
