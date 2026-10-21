extends RefCounted
## Builds geometry only from explicit frozen prefab data. Does not reroll items.
const TILE: float = 1.6
const LEVEL_H: float = 4.0

static func palette(key: String) -> Dictionary:
    var palettes: Dictionary = {
        "clay": ["#be976b", "#e4c796", "#64472f", "#9b7255"],
        "teal": ["#698a80", "#c3bb91", "#4c5c50", "#728c7b"],
        "cedar": ["#956b55", "#d4b690", "#51382e", "#b38b61"],
        "crimson": ["#af6e5a", "#d9ba91", "#632f31", "#7e523e"],
        "amber": ["#bd8757", "#eed2a3", "#634b37", "#ab774a"],
        "jade": ["#8fa989", "#dccfa8", "#426155", "#b38562"],
        "stone": ["#92928a", "#d2c4a7", "#595b53", "#8d7964"],
        "iron": ["#736f70", "#b9ad9d", "#45454b", "#b17d51"],
        "green": ["#8b9e77", "#c4bd96", "#4d6452", "#977755"]
    }
    var colors: Array = palettes.get(key, palettes["clay"])
    return {
        "floor": _material(str(colors[0])),
        "wall": _material(str(colors[1])),
        "wood": _material(str(colors[2])),
        "furniture": _material(str(colors[3])),
        "dark": _material("#3e3632")
    }

static func _material(hex_color: String) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color.html(hex_color)
    mat.roughness = 0.9
    return mat

static func _solid(parent: Node3D, name_text: String, position_3d: Vector3, size_3d: Vector3, material: Material, collider: bool = true, pitch: float = 0.0, level_id: int = 0) -> void:
    var body := Node3D.new()
    body.name = name_text
    body.position = position_3d
    body.rotation.x = pitch
    body.set_meta("interior_level", level_id)
    parent.add_child(body)
    var mesh_node := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size_3d
    mesh_node.mesh = mesh
    mesh_node.material_override = material
    body.add_child(mesh_node)
    if collider:
        var static_body := StaticBody3D.new()
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size_3d
        collision.shape = shape
        static_body.add_child(collision)
        body.add_child(static_body)

static func _xyz(tx: float, tz: float, width: int, depth: int, elevation: float) -> Vector3:
    return Vector3((tx - float(width - 1) / 2.0) * TILE, elevation, (tz - float(depth - 1) / 2.0) * TILE)

static func build(prefab: Dictionary) -> Node3D:
    var root := Node3D.new()
    root.name = "Interior_" + str(prefab.get("id", "unknown"))
    root.set_meta("prefab_id", str(prefab.get("id", "unknown")))
    if prefab.is_empty():
        return root
    var width: int = int(prefab.get("width_tiles", 6))
    var depth: int = int(prefab.get("depth_tiles", 6))
    var mats: Dictionary = palette(str(prefab.get("palette", "clay")))
    # Adjacent floor tiles and wall segments are authored as long merged runs.
    # This avoids one StaticBody3D per floor TILE while maintaining fixed geometry.
    for run in prefab.get("floor_runs", []):
        var x_start: int = int(run.get("start", 0))
        var x_end: int = int(run.get("end", 0))
        var z: int = int(run.get("z", 0))
        var xx: float = float(x_start + x_end) * 0.5
        var ww: float = float(x_end - x_start + 1) * TILE
        _solid(root, "Floor_Run", _xyz(xx, float(z), width, depth, -0.16), Vector3(ww, 0.3, TILE), mats["floor"])
    for run in prefab.get("upper_floor_runs", []):
        var x_start: int = int(run.get("start", 0))
        var x_end: int = int(run.get("end", 0))
        var z: int = int(run.get("z", 0))
        var xx: float = float(x_start + x_end) * 0.5
        var ww: float = float(x_end - x_start + 1) * TILE
        _solid(root, "UpperFloor_Run", _xyz(xx, float(z), width, depth, LEVEL_H - 0.16), Vector3(ww, 0.3, TILE), mats["floor"], true, 0.0, 1)
    for run in prefab.get("wall_runs", []):
        var axis: String = str(run.get("axis", "x"))
        var level: int = int(run.get("level", 0))
        var first: float = float(run.get("start", 0))
        var last: float = float(run.get("end", 0))
        var fixed: float = float(run.get("fixed", 0))
        var span: float = (last - first + 1.0) * TILE
        var wx: float = (first + last) * 0.5 if axis == "x" else fixed
        var wz: float = fixed if axis == "x" else (first + last) * 0.5
        var sz: Vector3 = Vector3(span, 2.9, 0.16) if axis == "x" else Vector3(0.16, 2.9, span)
        _solid(root, "WallRun", _xyz(wx, wz, width, depth, float(level) * LEVEL_H + 1.45), sz, mats["wall"], true, 0.0, level)
        var wall: Node3D = root.get_child(root.get_child_count() - 1) as Node3D
        if wall != null and str(run.get("kind", "")) == "outer":
            # Camera looks from positive X/Z, so cut only the camera-facing facade.
            wall.set_meta("cutaway", (axis == "x" and fixed >= float(depth) - 0.5) or (axis == "z" and fixed >= float(width) - 0.5))
    for item in prefab.get("furniture", []):
        var size_arr: Array = item.get("size", [1.0, 0.7, 1.0])
        var size_3d := Vector3(float(size_arr[0]), float(size_arr[1]), float(size_arr[2]))
        var level: int = int(item.get("level", 0))
        var pos: Vector3 = _xyz(float(item.get("x", 0)), float(item.get("z", 0)), width, depth, level * LEVEL_H + size_3d.y * 0.5)
        # Rotating a BoxMesh and its collider together via a wrapper is reserved for art pass.
        _solid(root, str(item.get("kind", "Furniture")), pos, size_3d, mats["furniture"], true, 0.0, level)
    var stairs: Variant = prefab.get("stairs", null)
    if typeof(stairs) == TYPE_DICTIONARY:
        # R1 steps were 0.5 m high: not reliably traversable by CharacterBody3D.
        # A single rotated collider creates a continuous slope, preserving the
        # fixed 3-tile staircase shaft and the authored aperture upstairs.
        var sx: float = float(stairs.get("x", width - 2))
        var za: float = float(stairs.get("z_start", 4))
        var zb: float = float(stairs.get("z_end", 1))
        var horizontal: float = abs(za - zb) * TILE
        if horizontal > 0.01:
            var incline: float = atan2(LEVEL_H, horizontal)
            var sign_dir: float = 1.0 if za > zb else -1.0
            var length: float = sqrt(horizontal * horizontal + LEVEL_H * LEVEL_H)
            _solid(root, "StairRamp", _xyz(sx, (za + zb) * 0.5, width, depth, LEVEL_H * 0.5), Vector3(TILE, 0.22, length), mats["wood"], true, incline * sign_dir, 0)
            var bottom := Marker3D.new()
            bottom.name = "StairBottom"
            bottom.position = _xyz(sx, za, width, depth, 0.35)
            root.add_child(bottom)
            var top := Marker3D.new()
            top.name = "StairTop"
            top.position = _xyz(sx, zb, width, depth, LEVEL_H + 0.35)
            root.add_child(top)
    var entrance: Dictionary = prefab.get("entrance", {})
    var spawn: Dictionary = prefab.get("spawn", entrance)
    var spawn_point := Marker3D.new()
    spawn_point.name = "InteriorSpawn"
    spawn_point.position = _xyz(float(spawn.get("x", 0)), float(spawn.get("z", 0)), width, depth, 0.95)
    root.add_child(spawn_point)
    var exit_point := Marker3D.new()
    exit_point.name = "InteriorExit"
    exit_point.position = spawn_point.position
    root.add_child(exit_point)
    # Entry lintel shows the authorial door location without obstructing the threshold.
    _solid(root, "EntranceLintel", _xyz(float(entrance.get("x", 0)), float(entrance.get("z", 0)) + 0.5, width, depth, 2.85), Vector3(TILE, 0.3, 0.23), mats["wood"])
    # Dark plane masks unloaded exterior/void under an orthographic view.
    _solid(root, "IsolatedDarkBackdrop", Vector3(0.0, -0.48, 0.0), Vector3(110.0, 0.20, 110.0), mats["dark"], false)
    return root

static func set_cutaway(root: Node3D, enabled: bool) -> void:
    if not is_instance_valid(root):
        return
    for part in root.get_children():
        if part is Node3D and part.get_meta("cutaway", false):
            (part as Node3D).visible = not enabled

static func set_upper_floor_visible(root: Node3D, visible_now: bool) -> void:
    # Optional orthographic floor cutaway; does not disable collisions or NPCs.
    if not is_instance_valid(root):
        return
    for child in root.get_children():
        if child is Node3D and int(child.get_meta("interior_level", 0)) > 0:
            (child as Node3D).visible = visible_now
