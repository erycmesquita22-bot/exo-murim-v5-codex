extends RefCounted
## EXO Humanoides R2: original, low-poly voxel geometry. No skin UV mutation.
## Mesh and material resources are cached per size/tint to avoid duplicate buffers.
static var _boxes: Dictionary = {}
static var _frustums: Dictionary = {}
static var _materials: Dictionary = {}

static func _mat(tint: Color) -> StandardMaterial3D:
    var key: String = tint.to_html(true)
    if not _materials.has(key):
        var material := StandardMaterial3D.new()
        material.albedo_color = tint
        material.roughness = 0.91
        material.metallic = 0.0
        material.cull_mode = BaseMaterial3D.CULL_DISABLED
        _materials[key] = material
    return _materials[key]

static func _box(size: Vector3) -> BoxMesh:
    var key: String = str(size.snapped(Vector3.ONE * 0.0001))
    if not _boxes.has(key):
        var m := BoxMesh.new()
        m.size = size
        _boxes[key] = m
    return _boxes[key]

static func part(parent: Node3D, label: String, point: Vector3, size: Vector3, tint: Color) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = label
    node.mesh = _box(size)
    node.material_override = _mat(tint)
    node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(node)
    node.position = point
    return node

## A 4-sided, closed tapered voxel panel; flat normals, 12 triangles.
static func _frustum(top: Vector2, bottom: Vector2, height: float) -> ArrayMesh:
    var key: String = str([top,bottom,height])
    if _frustums.has(key): return _frustums[key]
    var vertices: Array[Vector3] = []
    for level in range(2):
        var sz: Vector2 = top if level == 0 else bottom
        var yy: float = height * 0.5 if level == 0 else -height * 0.5
        for corner in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
            vertices.append(Vector3(corner.x * sz.x * 0.5, yy, corner.y * sz.y * 0.5))
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for face in [[0,3,2,1], [4,5,6,7], [0,1,5,4], [1,2,6,5], [2,3,7,6], [3,0,4,7]]:
        var va: Vector3 = vertices[face[0]]
        var vb: Vector3 = vertices[face[1]]
        var vc: Vector3 = vertices[face[2]]
        var normal: Vector3 = (vb - va).cross(vc - va).normalized()
        for i in [0,1,2,0,2,3]:
            st.set_normal(normal)
            st.add_vertex(vertices[face[i]])
    var mesh: ArrayMesh = st.commit()
    _frustums[key] = mesh
    return mesh

static func panel(parent: Node3D, label: String, point: Vector3, top: Vector2, bottom: Vector2, height: float, tint: Color) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = label
    node.mesh = _frustum(top,bottom,height)
    node.material_override = _mat(tint)
    node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(node)
    node.position = point
    return node

static func cache_counts() -> Dictionary:
    return {"box_meshes":_boxes.size(),"taper_meshes":_frustums.size(),"shared_materials":_materials.size()}
