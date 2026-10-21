extends RefCounted
## Original V5 voxel props. No imported village pack, source geometry or textures.
static var catalog: Dictionary={}
static var shared_material: Material
static func ensure() -> void:
    catalog={"source":"EXO V5 procedural geometry","version":5}
static func _box(root: Node3D, at: Vector3, size: Vector3, color: Color) -> void:
    var m:=MeshInstance3D.new();var b:=BoxMesh.new();b.size=size;m.mesh=b
    var mat:=StandardMaterial3D.new();mat.albedo_color=color;mat.roughness=.95
    m.material_override=mat;m.position=at;root.add_child(m)
static func place(parent: Node3D,id: String,point: Vector3,width: float,yaw: float=0) -> Node3D:
    var root:=Node3D.new();root.name="V5_"+id;parent.add_child(root)
    root.position=point;root.rotation.y=yaw
    var wood:=Color("86613f");var stone:=Color("8c9589")
    if id.begins_with("building_") or id=="shop":
        _box(root,Vector3(0,.02,0),Vector3(1,.04,.85),stone)
        _box(root,Vector3(-.46,.3,0),Vector3(.08,.6,.85),Color("c8b28a"))
        _box(root,Vector3(.46,.3,0),Vector3(.08,.6,.85),Color("c8b28a"))
        _box(root,Vector3(0,.3,-.38),Vector3(1,.6,.08),Color("c8b28a"))
        _box(root,Vector3(0,.64,0),Vector3(1.12,.1,.98),Color("386f68"))
        _box(root,Vector3(0,.74,0),Vector3(.8,.1,.72),Color("477f73"))
    elif "well" in id:
        for side in [-1.0,1.0]:
            _box(root,Vector3(side*.42,.3,0),Vector3(.16,.6,1),stone)
            _box(root,Vector3(side*.4,.95,0),Vector3(.08,1.3,.08),wood)
        _box(root,Vector3(0,.3,-.42),Vector3(.7,.6,.16),stone)
        _box(root,Vector3(0,.3,.42),Vector3(.7,.6,.16),stone)
        _box(root,Vector3(0,1.6,0),Vector3(1.15,.12,1.15),Color("326860"))
    elif "cart" in id:
        _box(root,Vector3(0,.4,0),Vector3(1,.15,.75),wood)
        for side in [-1.0,1.0]:
            _box(root,Vector3(side*.48,.63,0),Vector3(.08,.4,.75),wood)
            _box(root,Vector3(side*.55,.23,0),Vector3(.1,.45,.45),Color("403d37"))
        _box(root,Vector3(0,.45,.8),Vector3(.12,.1,1.1),wood)
    elif "gong" in id:
        for side in [-1.0,1.0]:_box(root,Vector3(side*.4,.7,0),Vector3(.1,1.4,.12),wood)
        _box(root,Vector3(0,1.4,0),Vector3(1,.1,.2),wood)
        _box(root,Vector3(0,.9,0),Vector3(.65,.65,.08),Color("bd9f55"))
    elif "statue" in id:
        _box(root,Vector3(0,.1,0),Vector3(.8,.2,.8),stone)
        _box(root,Vector3(0,.7,0),Vector3(.45,1,.35),stone)
        _box(root,Vector3(0,1.4,0),Vector3(.35,.35,.35),stone)
    elif "bush" in id:
        _box(root,Vector3(0,.35,0),Vector3(1,.7,.8),Color("467d50"))
        _box(root,Vector3(.2,.7,0),Vector3(.5,.4,.5),Color("57905e"))
    else:
        _box(root,Vector3(0,.35,0),Vector3(.7,.7,.7),wood)
        _box(root,Vector3(0,.12,0),Vector3(.76,.08,.76),stone)
        _box(root,Vector3(0,.6,0),Vector3(.76,.08,.76),stone)
    var bounds:=AABB()
    var first: bool=true
    for child in root.get_children():
        if child is MeshInstance3D:
            child.position*=width
            child.mesh.size*=width
            var box: AABB=child.get_aabb()
            box.position+=child.position
            bounds=box if first else bounds.merge(box)
            first=false
    root.set_meta("bounds",bounds)
    root.set_meta("source","EXO V5 original procedural prop")
    root.set_meta("asset_id",id)
    return root
