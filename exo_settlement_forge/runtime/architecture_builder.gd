extends RefCounted
## One external building is materialized from one canonical record.
## Exterior access is explicit; no collider may seal its central 2.4m door.
static func _material(c: String) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = Color.html(c)
    material.roughness = 0.92
    return material

static func _box(parent: Node3D, name_value: String, point: Vector3, size_value: Vector3,
        color_value: String, solid: bool = true) -> Node3D:
    var node := Node3D.new()
    node.name = name_value
    node.position = point
    parent.add_child(node)
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size_value
    mesh.mesh = box
    mesh.material_override = _material(color_value)
    node.add_child(mesh)
    if solid:
        var body := StaticBody3D.new()
        body.collision_layer = 1
        body.collision_mask = 1
        var collider := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size_value
        collider.shape = shape
        body.add_child(collider)
        node.add_child(body)
    return node

static func build(parent: Node3D, record: Dictionary) -> Node3D:
    if not bool(record.get("accessible", false)):
        return null
    var dims: Array = record.get("dimensions", [])
    var loc: Array = record.get("position", [])
    if dims.size() != 3 or loc.size() != 3:
        return null
    var root := Node3D.new()
    root.name = ("Building_" + str(record.get("building_id", "invalid"))).validate_node_name()
    root.position = Vector3(float(loc[0]),float(loc[1]),float(loc[2]))
    root.rotation.y = float(record.get("yaw", 0.0))
    root.set_meta("building_id", str(record.get("building_id", "")))
    root.set_meta("function", str(record.get("function", "")))
    parent.add_child(root)
    var w: float = float(dims[0]); var h: float = float(dims[1]); var d: float = float(dims[2])
    var f: String = str(record.get("function", "residence"))
    var walls: String = "#d6b48b" if f in ["inn","market"] else "#aab4a8" if f in ["martial_school","administration"] else "#be9b78"
    var roof: String = "#aa5146" if f in ["inn","market"] else "#3a6b68"
    # EXO Urban A+C: retain a single collision body and the original complete
    # Forja visual as one mesh (textures consolidated to a shared atlas).
    var baked: Dictionary = preload("res://exo_settlement_forge/runtime/house_baker_ac.gd").get_house()
    if baked.is_empty():
        push_error("EXO AC: failed to bake canonical Forja house "+str(record.get("building_id", "")))
        return root
    var near := MeshInstance3D.new()
    near.name = "ForjaCompleteVisual"
    near.mesh = baked.mesh
    near.scale = Vector3(w/6.0,1.0,d/4.0)
    near.visibility_range_end = 65.0
    near.visibility_range_end_margin = 5.0
    root.add_child(near)
    var far := MeshInstance3D.new()
    far.name = "ForjaDistantLOD"
    far.mesh = baked.lod
    far.scale = Vector3(w/6.0,1.0,d/4.0)
    far.visibility_range_begin = 65.0
    far.visibility_range_begin_margin = 5.0
    root.add_child(far)
    root.set_meta("forja_house_template","godot/modular_kit.gd:build_house/murim_blue/6/2")
    root.set_meta("exo_ac_mesh_count",1)
    root.set_meta("exo_ac_triangles",baked.triangles)
    var body := StaticBody3D.new()
    body.name = "ExteriorShellCollision"
    body.collision_layer = 1
    root.add_child(body)
    var collision_specs: Array = [
        [Vector3(0,-.12,0), Vector3(w,.24,d)],
        [Vector3(-w*.5+.14,h*.5,0),Vector3(.28,h,d)],
        [Vector3(w*.5-.14,h*.5,0),Vector3(.28,h,d)],
        [Vector3(0,h*.5,-d*.5+.14),Vector3(w,h,.28)],
    ]
    var jamb: float = maxf(.2,(w-2.4)*.5)
    for side in [-1.0,1.0]:
        collision_specs.append([Vector3(side*(1.2+jamb*.5),h*.5,d*.5-.14),Vector3(jamb,h,.28)])
    collision_specs.append([Vector3(0,h-.26,d*.5),Vector3(2.4,.52,.34)])
    for spec in collision_specs:
        var shape := BoxShape3D.new()
        shape.size = spec[1]
        var collider := CollisionShape3D.new()
        collider.position = spec[0]
        collider.shape = shape
        body.add_child(collider)
    var portal := Marker3D.new()
    portal.name = "ExteriorDoor"
    portal.position = Vector3(0,0,d*0.5+0.6)
    root.add_child(portal)
    var approach := Marker3D.new()
    approach.name = "ReturnExterior"
    approach.position = Vector3(0,0,d*0.5+2.7)
    root.add_child(approach)
    root.set_meta("exo_settlement_record",record.duplicate(true))
    return root

static func build_roads(parent: Node3D, plan: Dictionary) -> void:
    var origin: Array = plan.get("origin", [0,0,0])
    for road in plan.get("roads", []):
        var a: Array = road.get("start",[0,0]);var b: Array = road.get("end",[0,0])
        var d := Vector2(float(b[0])-float(a[0]),float(b[1])-float(a[1]))
        var middle := Vector3(float(origin[0])+(float(a[0])+float(b[0]))*0.5,float(origin[1])-0.008,float(origin[2])+(float(a[1])+float(b[1]))*0.5)
        var segment: Node3D = _box(parent,"Road",middle,Vector3(float(road.get("width",4.0)),0.028,d.length()),"#807965",false)
        segment.rotation.y = -atan2(d.x,d.y)
