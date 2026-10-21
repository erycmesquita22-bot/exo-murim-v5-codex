extends RefCounted
# Só previsão; Regional Ecology valida/autorizada spawns físicos.
static func evolve(current: int, capacity: int, pressure: float, days: int) -> int:
    var count:=clampi(current,0,capacity)
    var cycles:=clampi(days,0,90)
    for _i in range(cycles):
        var births:=maxi(0,int(floor(float(count)*0.1))) if count>1 else 0
        var deaths:=maxi(0,int(ceil(float(count)*clampf(pressure,0.0,1.0)*0.17)))
        count=clampi(count+births-deaths,0,capacity)
    return count
