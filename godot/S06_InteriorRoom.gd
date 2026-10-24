extends Node3D
## Sprint 06 - one instance per fixed door. The exterior layout remains untouched.
## Roof intentionally open in this separate dimension for Toram-style third-person framing.
@export var room_id: String = ""
@export var room_kind: String = ""
@export var room_width: float = 11.0
@export var room_depth: float = 9.0
var family_name: String = "WONG"
var generated_collisions: int = 0
var data: Dictionary = {}

func _ready() -> void:
    var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://interiors_sprint06/data/rooms_manifest.json"))
    for entry in source.get("rooms", []):
        if entry.get("id", "") == room_id:
            data = entry
            break
    if data.is_empty():
        push_error("S06_ROOM_INVALID_ID: " + room_id)
        return
    _collision_box("FLOOR", Vector3(0, -0.15, 0), Vector3(room_width + 0.7, 0.30, room_depth + 0.7))
    var h: float = 3.35
    var thick: float = 0.25
    _collision_box("WALL_BACK", Vector3(0, h / 2.0, -room_depth / 2.0), Vector3(room_width, h, thick))
    _collision_box("WALL_LEFT", Vector3(-room_width / 2.0, h / 2.0, 0), Vector3(thick, h, room_depth))
    _collision_box("WALL_RIGHT", Vector3(room_width / 2.0, h / 2.0, 0), Vector3(thick, h, room_depth))
    var opening: float = 2.45
    var side_width: float = (room_width - opening) / 2.0
    for sign in [-1.0, 1.0]:
        _collision_box("WALL_FRONT_%s" % str(sign), Vector3(sign * (opening / 2.0 + side_width / 2.0), h / 2.0, room_depth / 2.0), Vector3(side_width, h, thick))
    var i: int = 0
    for box_data in data.get("collision_furniture", []):
        var c: Array = box_data["center"]
        var s: Array = box_data["size"]
        _collision_box("FURNITURE_%02d" % i, Vector3(c[0], c[1], c[2]), Vector3(s[0], s[1], s[2]))
        i += 1
    configure_family(family_name)

func _collision_box(tag: String, center: Vector3, size: Vector3) -> void:
    var body: StaticBody3D = StaticBody3D.new()
    body.name = "S06_STATIC_" + tag
    body.collision_layer = 1
    body.collision_mask = 1
    add_child(body)
    var cs: CollisionShape3D = CollisionShape3D.new()
    var box: BoxShape3D = BoxShape3D.new()
    box.size = size
    cs.shape = box
    cs.position = center
    body.add_child(cs)
    generated_collisions += 1

func configure_family(value: String) -> void:
    family_name = value
    for m in $Visual.find_children("*", "MeshInstance3D", true, false):
        if m.name == "BANNER_WONG":
            m.visible = value == "WONG"
        elif m.name == "BANNER_WUDONG":
            m.visible = value == "WUDONG"

func local_entry_position() -> Vector3:
    return Vector3(0, 0.25, room_depth / 2.0 - 2.4)

func local_exit_position() -> Vector3:
    return Vector3(0, 0.25, room_depth / 2.0 - 0.82)
