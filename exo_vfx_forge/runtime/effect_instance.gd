extends Node3D
const G = preload("res://exo_vfx_forge/renderers/geometry_builder.gd")
const SHADER = preload("res://exo_vfx_forge/shaders/energy.gdshader")
signal finished(instance: Node3D)
var recipe: Dictionary = {}
var event: Dictionary = {}
var elapsed: float = 0.0
var duration: float = 0.5
var visual_nodes: Array[Node3D] = []
var glow_mats: Array[ShaderMaterial] = []
var quality: String = "medium"
var active: bool = false
var cancelled: bool = false
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var family: String = ""

func configure(r: Dictionary, av: Dictionary) -> void:
    clear_visuals()
    recipe = r.duplicate(true)
    event = av.duplicate(true)
    family = str(recipe.get("family", ""))
    elapsed = 0.0
    duration = float(recipe.get("timing", {}).get("duration", 0.5))
    quality = str(av.get("quality_profile", "medium"))
    rng.seed = int(av.get("visual_seed", 0))
    cancelled = false
    active = true
    var pos_data: Array = av.get("origin_xyz", [0.0,0.0,0.0])
    position = Vector3(float(pos_data[0]),float(pos_data[1]),float(pos_data[2]))
    var dir: Array = av.get("direction_xyz", [0.0,0.0,-1.0])
    var facing: Vector3 = Vector3(float(dir[0]),0.0,float(dir[2])).normalized()
    rotation.y = atan2(-facing.x,-facing.z) if facing.length_squared() > 0.01 else 0.0
    _create_geometry()
    set_process(true)

func _create_geometry() -> void:
    var col: Color = Color.html(str(recipe.get("shader_params", {}).get("color", "#58aaff")))
    var q: Dictionary = recipe.get("quality_profiles", {}).get(quality, {})
    var count: int = int(q.get("detail", 8))
    match family:
        "slash":
            _add_mesh(G.arc(1.38,-2.3,1.15,0.26),col,0.80)
            if quality != "low":
                _add_mesh(G.arc(1.36,-2.3,1.15,0.40),col,0.20)
        "impact":
            _add_mesh(G.ring(1.0,0.19),col,0.95)
            _fragments(count,col,true)
        "dash":
            for i in range(mini(count,9)):
                var m: Node3D = _add_mesh(G.arc(0.24,-1.6,1.7,0.07),col,0.8)
                m.position = Vector3(0,0.28+0.12*float(i%3),0.25*float(i))
                m.rotation.y = PI/2.0
        "teleport":
            _add_mesh(G.ring(0.72,0.11),col,0.85)
            _add_beam(col,0.16,2.1,0.44)
        "ice":
            _add_mesh(G.ring(0.77,0.11),col,0.55)
            _fragments(count,col,false)
        "thunder":
            _add_mesh(G.lightning(3.6,int(event.get("visual_seed",0)),0.075),col,0.92)
            if quality != "low":
                _add_mesh(G.lightning(3.6,int(event.get("visual_seed",0))+1,0.15),col,0.22)
        "meteor":
            _add_beam(col,0.34,2.2,0.8)
            _fragments(count,col,true)
        "beam":
            _add_beam(col,0.10,3.4,0.95)
            if quality != "low":
                _add_beam(col,0.20,3.4,0.18)
        "snare":
            _add_mesh(G.ring(1.5,0.11),col,0.85)
            if quality != "low":
                _add_mesh(G.ring(1.07,0.06),col,0.32)
        "crown":
            _add_mesh(G.ring(1.25,0.1),col,0.46)
            _fragments(count,col,false)

func _add_mesh(mesh: Mesh, col: Color, opacity_factor: float) -> MeshInstance3D:
    var node: MeshInstance3D = MeshInstance3D.new()
    node.mesh = mesh
    var mat: ShaderMaterial = ShaderMaterial.new()
    mat.shader = SHADER
    mat.set_shader_parameter("tint",Color(col.r,col.g,col.b,opacity_factor))
    mat.set_shader_parameter("opacity",1.0)
    mat.set_shader_parameter("progress",1.0)
    mat.set_shader_parameter("glow_strength",0.8 if quality == "low" else 1.25)
    node.material_override = mat
    add_child(node)
    visual_nodes.append(node)
    glow_mats.append(mat)
    return node

func _add_beam(col: Color, width: float, length: float, alpha: float) -> void:
    var pts: PackedVector3Array = PackedVector3Array([Vector3(0,1.3,0),Vector3(0,1.3,-length)])
    _add_mesh(G.ribbon(pts,width),col,alpha)

func _fragments(count: int, col: Color, ground: bool) -> void:
    for i in range(mini(count,28)):
        var shard: MeshInstance3D = MeshInstance3D.new()
        var box: BoxMesh = BoxMesh.new()
        box.size = Vector3(0.08+rng.randf()*0.16,0.18+rng.randf()*0.35,0.08+rng.randf()*0.16)
        shard.mesh = box
        var mat: StandardMaterial3D = StandardMaterial3D.new()
        mat.albedo_color = col
        mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        shard.material_override = mat
        var a: float = rng.randf_range(0.0,TAU)
        var rad: float = rng.randf_range(0.15,1.1)
        shard.position = Vector3(cos(a)*rad, 0.2+rng.randf_range(0,0.8) if ground else 0.9+rng.randf_range(0,1.1), sin(a)*rad)
        shard.rotation = Vector3(rng.randf(),rng.randf(),rng.randf())
        add_child(shard)
        visual_nodes.append(shard)

func _process(delta: float) -> void:
    if not active:
        return
    elapsed += delta
    var t: float = clampf(elapsed / maxf(0.05,duration),0.0,1.0)
    var fade: float = 1.0-smoothstep(0.53,1.0,t)
    for mat in glow_mats:
        mat.set_shader_parameter("opacity", fade)
        mat.set_shader_parameter("progress", clampf(t*3.0,0.02,1.0))
    match family:
        "impact", "snare", "crown":
            scale = Vector3.ONE * lerpf(0.22,1.35,t)
        "teleport":
            scale = Vector3.ONE * lerpf(0.45,1.1,t)
        "dash":
            scale = Vector3.ONE * lerpf(0.5,1.6,t)
        "meteor":
            scale = Vector3.ONE * lerpf(1.0,0.35,t)
    if t >= 1.0:
        active = false
        set_process(false)
        finished.emit(self)

func cancel() -> void:
    if not active:
        return
    cancelled = true
    active = false
    set_process(false)
    finished.emit(self)

func clear_visuals() -> void:
    for child in visual_nodes:
        if is_instance_valid(child):
            remove_child(child)
            child.queue_free()
    visual_nodes.clear()
    glow_mats.clear()
    scale = Vector3.ONE
