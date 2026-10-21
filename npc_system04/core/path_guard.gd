extends RefCounted
## Only WorldGenesis/CityForge prepared corridors may be traversed. No straight-line path fabrication.
static func accepted(points: Variant) -> bool:
    if not points is Array or points.is_empty() or points.size() > 4096: return false
    var last: Vector3 = Vector3.ZERO
    for i in range(points.size()):
        if not points[i] is Vector3: return false
        var p: Vector3 = points[i]
        if not p.is_finite(): return false
        if i > 0 and p.distance_to(last) > 128.0: return false
        last = p
    return true

static func near_segment(point: Vector3, points: Array, max_distance: float = 1.5) -> bool:
    if not accepted(points) or not point.is_finite(): return false
    if points.size() == 1: return point.distance_to(points[0]) <= max_distance
    for i in range(1, points.size()):
        if point.distance_to(Geometry3D.get_closest_point_to_segment(point, points[i - 1], points[i])) <= max_distance:
            return true
    return false

static func route(routes: Dictionary, previous: String, destination: String) -> Array:
    var key: String = previous + ">" + destination
    if not routes.has(key): return []
    var points: Variant = routes[key]
    return points.duplicate() if accepted(points) else []
