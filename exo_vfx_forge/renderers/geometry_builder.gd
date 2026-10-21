extends RefCounted
# All meshes are original Godot geometry. No WebGL/Three.js dependency.
static func ribbon(points: PackedVector3Array, width: float) -> ArrayMesh:
    var st: SurfaceTool = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    if points.size() < 2:
        return st.commit()
    for i in range(points.size() - 1):
        var u0: float = float(i) / float(points.size() - 1)
        var u1: float = float(i + 1) / float(points.size() - 1)
        var w0: float = width * (0.14 + 0.86 * sin(PI * u0))
        var w1: float = width * (0.14 + 0.86 * sin(PI * u1))
        var v0: Vector3 = Vector3(-points[i].y, points[i].x, 0.0).normalized() * w0
        var v1: Vector3 = Vector3(-points[i+1].y, points[i+1].x, 0.0).normalized() * w1
        if v0.length_squared() < 0.001:
            v0 = Vector3.UP * w0
        if v1.length_squared() < 0.001:
            v1 = Vector3.UP * w1
        _tri(st, points[i]-v0, points[i]+v0, points[i+1]+v1, Vector2(u0,0.0), Vector2(u0,1.0), Vector2(u1,1.0))
        _tri(st, points[i]-v0, points[i+1]+v1, points[i+1]-v1, Vector2(u0,0.0), Vector2(u1,1.0), Vector2(u1,0.0))
    return st.commit()

static func arc(radius: float, begin_angle: float, end_angle: float, width: float, segments: int = 40) -> ArrayMesh:
    var points: PackedVector3Array = PackedVector3Array()
    for i in range(segments+1):
        var t: float = float(i) / float(segments)
        var a: float = lerpf(begin_angle, end_angle, t)
        points.append(Vector3(cos(a)*radius, 1.1+sin(a)*radius*0.70, 0.0))
    return ribbon(points, width)

static func ring(radius: float, thickness: float, segments: int = 48) -> ArrayMesh:
    var st: SurfaceTool = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(segments):
        var u0: float = float(i)/float(segments)
        var u1: float = float(i+1)/float(segments)
        var a0: float = TAU*u0
        var a1: float = TAU*u1
        var inner: float = maxf(0.02, radius-thickness)
        var o0: Vector3 = Vector3(cos(a0)*radius,0.03,sin(a0)*radius)
        var o1: Vector3 = Vector3(cos(a1)*radius,0.03,sin(a1)*radius)
        var p0: Vector3 = Vector3(cos(a0)*inner,0.03,sin(a0)*inner)
        var p1: Vector3 = Vector3(cos(a1)*inner,0.03,sin(a1)*inner)
        _tri(st,p0,o0,o1,Vector2(u0,0),Vector2(u0,1),Vector2(u1,1))
        _tri(st,p0,o1,p1,Vector2(u0,0),Vector2(u1,1),Vector2(u1,0))
    return st.commit()

static func lightning(length: float, seed_value: int, width: float) -> ArrayMesh:
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = seed_value
    var pts: PackedVector3Array = PackedVector3Array()
    for i in range(15):
        var t: float = float(i)/14.0
        pts.append(Vector3(rng.randf_range(-0.25,0.25)*(1.0-t), 1.3+rng.randf_range(-0.35,0.35), -length*t))
    return ribbon(pts,width)

static func _tri(st: SurfaceTool, a: Vector3,b: Vector3,c: Vector3,ua: Vector2,ub: Vector2,uc: Vector2) -> void:
    st.set_uv(ua)
    st.add_vertex(a)
    st.set_uv(ub)
    st.add_vertex(b)
    st.set_uv(uc)
    st.add_vertex(c)
