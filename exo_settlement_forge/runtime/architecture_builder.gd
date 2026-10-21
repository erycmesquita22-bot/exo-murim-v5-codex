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
    _box(root, "GroundFoundation", Vector3(0,-0.12,0), Vector3(w,0.24,d), "#81684a")
    _box(root, "WallLeft", Vector3(-w*0.5+0.14,h*0.5,0), Vector3(0.28,h,d), walls)
    _box(root, "WallRight", Vector3(w*0.5-0.14,h*0.5,0), Vector3(0.28,h,d), walls)
    _box(root, "WallBack", Vector3(0,h*0.5,-d*0.5+0.14), Vector3(w,h,0.28), walls)
    var jamb: float = maxf(0.2, (w-2.4)*0.5)
    for side in [-1.0,1.0]:
        _box(root,"FrontJamb",Vector3(side*(1.2+jamb*0.5),h*0.5,d*0.5-0.14),Vector3(jamb,h,0.28),walls)
        _box(root,"Window",Vector3(side*w*0.30,h*0.62,d*0.5+0.045),Vector3(0.72,0.62,0.08),"#354b4d",false)
    _box(root,"DoorLintel",Vector3(0,h-0.26,d*0.5),Vector3(2.4,0.52,0.34),walls)
    _box(root,"Roof",Vector3(0,h+0.23,0),Vector3(w+0.6,0.46,d+0.6),roof)
    _box(root,"RoofRidge",Vector3(0,h+0.62,0),Vector3(w*0.62,0.30,d*0.67),roof)
    if f == "smithy":
        _box(root,"ForgeChimney",Vector3(w*0.32,h+1.0,-d*0.25),Vector3(0.9,1.8,0.9),"#67605d")
    if f == "martial_school":
        _box(root,"MartialSign",Vector3(0,h+0.84,d*0.20),Vector3(w*0.35,0.25,0.35),"#b9914c",false)
    if f == "inn":
        _box(root,"InnSign",Vector3(w*0.35,2.2,d*0.51),Vector3(0.65,1.35,0.20),"#b75d39",false)
    # Authored Forja geometry regenerated from its supplied construction source.
    # Wall-mounted accents stay above walking clearance; shell/door collision
    # and the canonical building record remain Settlement Forge's authority.
    for side in [-1.0,1.0]:
        preload("res://godot/modular_kit.gd").place(root,"hanging_wall_torch",
            Vector3(side * w * 0.34,2.2,d * 0.5),0,"",false)
    root.set_meta("forja_visual_assets",["hanging_wall_torch"])
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
