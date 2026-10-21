extends RefCounted
static func can_detect(observer: Dictionary, target: Dictionary) -> bool:
    if not bool(target.get("exists", false)): return false
    var distance := float(target.get("distance", INF))
    if distance < 0.0: return false
    var sight := float(observer.get("perception", 12.0))
    var heard := bool(target.get("noise",false)) and distance < sight * 1.35
    return (distance <= sight and bool(target.get("line_of_sight", false))) or heard
static func physical_los(space: PhysicsDirectSpaceState3D, origin: Vector3, goal: Vector3, exclude: Array[RID] = []) -> bool:
    var query := PhysicsRayQueryParameters3D.create(origin, goal)
    query.exclude = exclude
    var hit: Dictionary = space.intersect_ray(query)
    return hit.is_empty()
