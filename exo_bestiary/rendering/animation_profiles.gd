extends RefCounted
static func pose(legs: Array,tail: Node3D,t: float,speed_ratio: float,mode: String) -> void:
    var energy:=clampf(speed_ratio,0.0,1.0)
    if mode=="DEFEATED":energy=0.0
    for i in range(legs.size()):
        var leg: Node3D=legs[i]
        if is_instance_valid(leg):
            leg.rotation.x=sin(t*10.0+(0.0 if i in [0,3] else PI))*0.45*energy
    if is_instance_valid(tail):tail.rotation.y=sin(t*3.1)*.14
