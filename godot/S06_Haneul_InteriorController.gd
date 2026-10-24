extends "res://godot/HWA02_Motion_V3.gd"
## EXO Haneul V1.0 S06 - project entry; parent V3 controller and all previous world sprints remain intact.
## Trigger with F next to a door, never E (already reserved by Character Core V3 for equipment).
const ISOLATED_ORIGIN := Vector3(680.0, 0.0, 680.0)
const ROOMS_MANIFEST := "res://interiors_sprint06/data/rooms_manifest.json"
var entrances: Dictionary = {}
var interior_manifest: Dictionary = {}
var active_room: Node3D
var active_room_id: String = ""
var exit_position: Vector3 = Vector3.ZERO
var s06_prompt: Label
var s06_qa_events: Array[Dictionary] = []
var is_transitioning: bool = false
var environment_nodes: Array[Node3D] = []

func _ready() -> void:
    super._ready()
    var file_data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://infrastructure_sprint05/data/manifest_sprint05.json"))
    if file_data is Dictionary:
        for entry in file_data.get("entrance_anchors", []):
            entrances[str(entry["id"])] = entry
    var room_data: Variant = JSON.parse_string(FileAccess.get_file_as_string(ROOMS_MANIFEST))
    if room_data is Dictionary:
        for record in room_data.get("rooms", []):
            interior_manifest[str(record["id"])] = record
    for node in [haneul_scene, sprint02_architecture, sprint03_props, sprint05_infrastructure, entrance_anchors, wong_signs, wudong_signs]:
        if node is Node3D: environment_nodes.append(node)
    s06_prompt = Label.new()
    s06_prompt.name = "Sprint06DoorPrompt"
    s06_prompt.add_theme_font_size_override("font_size", 18)
    s06_prompt.add_theme_color_override("font_color", Color("f5ead2"))
    s06_prompt.add_theme_color_override("font_shadow_color", Color("202329"))
    s06_prompt.add_theme_constant_override("shadow_offset_x", 2)
    s06_prompt.add_theme_constant_override("shadow_offset_y", 2)
    s06_prompt.position = Vector2(20, 106)
    hud.get_parent().add_child(s06_prompt)
    print("S06_READY doors=", entrances.size(), " interiors=", interior_manifest.size(), " CharacterV3_clips=", player.get_animation_list().size())

func nearest_exterior_door(max_distance: float = 2.55) -> String:
    if actor == null or not is_instance_valid(actor): return ""
    var result: String = ""
    var best: float = max_distance
    for id in entrances:
        var record: Dictionary = entrances[id]
        var xyz: Array = record["door_center"]
        var outward: Array = record["outward_normal"]
        var q: Vector3 = Vector3(float(xyz[0]) + float(outward[0]) * 1.15, float(xyz[1]), float(xyz[2]) + float(outward[2]) * 1.15)
        var horizontal: float = Vector2(actor.position.x - q.x, actor.position.z - q.z).length()
        var vertical: float = absf(actor.position.y - q.y)
        if horizontal < best and vertical < 2.5:
            best = horizontal
            result = str(id)
    return result

func _unhandled_input(event: InputEvent) -> void:
    super._unhandled_input(event)
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F and not is_transitioning:
        if active_room_id != "":
            var exit_local: Vector3 = active_room.local_exit_position()
            var exit_world: Vector3 = ISOLATED_ORIGIN + exit_local
            if actor.global_position.distance_to(exit_world) < 2.65:
                _travel_animated(false, "")
        else:
            var near: String = nearest_exterior_door()
            if near != "" and action_kind.is_empty():
                _travel_animated(true, near)

func _travel_animated(enter_room: bool, id: String) -> void:
    if is_transitioning: return
    is_transitioning = true
    var panel: ColorRect = ColorRect.new()
    panel.name = "S06_Fade"
    panel.color = Color(0.035, 0.046, 0.06, 0.0)
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hud.get_parent().add_child(panel)
    panel.z_index = 100
    var tween: Tween = create_tween()
    tween.tween_property(panel, "color:a", 1.0, 0.14)
    await tween.finished
    if enter_room:
        _commit_enter_room(id)
    else:
        _commit_exit_room()
    var fade: Tween = create_tween()
    fade.tween_property(panel, "color:a", 0.0, 0.19)
    await fade.finished
    panel.queue_free()
    is_transitioning = false

func _commit_enter_room(id: String) -> bool:
    if active_room_id != "" or not entrances.has(id) or not interior_manifest.has(id):
        return false
    var pack: PackedScene = load(str(interior_manifest[id]["scene"]))
    if pack == null:
        push_error("S06_MISSING_INTERIOR_SCENE " + id)
        return false
    var room: Node3D = pack.instantiate() as Node3D
    room.position = ISOLATED_ORIGIN
    room.family_name = active_family
    room.name = "S06_Active_" + id
    add_child(room)
    active_room = room
    active_room_id = id
    # Store original position; never modify the saved fixed map/door ID.
    exit_position = actor.position
    for node in environment_nodes: node.visible = false
    for node in get_children():
        if node is Node3D and (node.name == "EXO_Haneul_Terrain_Sprint05_Approaches" or node.name == "EXO_Rio_Hwa_Sprint05_SeamlessWater"):
            node.visible = false
    target.visible = false
    locked = false
    actor.velocity = Vector3.ZERO
    actor.position = ISOLATED_ORIGIN + room.local_entry_position()
    visual.rotation.y = 0.0
    yaw = 0.0
    camera_distance = 3.8
    pivot.position = actor.position + Vector3(0, 1.65, 0)
    s06_qa_events.append({"event":"ENTER", "id": id, "family": active_family})
    print("S06_ENTER id=", id, " kind=", str(interior_manifest[id]["kind"]), " room_colliders=", room.generated_collisions)
    return true

func _commit_exit_room() -> bool:
    if active_room_id == "" or not is_instance_valid(active_room): return false
    var id: String = active_room_id
    var xyz: Array = entrances[id]["door_center"]
    var outward: Array = entrances[id]["outward_normal"]
    var restore: Vector3 = Vector3(float(xyz[0]) + float(outward[0]) * 2.65, float(xyz[1]) + 0.48, float(xyz[2]) + float(outward[2]) * 2.65)
    # Physics world at the remote dimension cannot overlap the exterior region.
    actor.velocity = Vector3.ZERO
    actor.position = restore
    pivot.position = restore + Vector3(0,1.65,0)
    for node in environment_nodes: node.visible = true
    for node in get_children():
        if node is Node3D and (node.name == "EXO_Haneul_Terrain_Sprint05_Approaches" or node.name == "EXO_Rio_Hwa_Sprint05_SeamlessWater"):
            node.visible = true
    # Fixed family selection remains identical after room visit.
    wong_signs.visible = active_family == "WONG"
    wudong_signs.visible = active_family == "WUDONG"
    target.visible = show_training_dummy
    active_room.queue_free()
    active_room = null
    active_room_id = ""
    s06_qa_events.append({"event":"EXIT", "id": id, "family": active_family})
    print("S06_EXIT id=", id)
    return true

func finish_frame(delta: float) -> void:
    super.finish_frame(delta)
    if s06_prompt == null: return
    if active_room_id != "":
        var d: float = actor.position.distance_to(ISOLATED_ORIGIN + active_room.local_exit_position())
        s06_prompt.text = "[F] Sair para Haneul" if d < 2.65 else "Interior: %s  |  dirija-se a porta para sair" % str(interior_manifest[active_room_id]["kind"])
        hud.text = "EXO-MURIM  /  INTERIOR S06  /  %s\nWASD movimento | Shift correr | F porta | E arma | Q esquiva" % active_family
    else:
        var id: String = nearest_exterior_door()
        s06_prompt.text = "[F] Entrar - %s" % id.replace("_", " ") if id != "" else ""
        hud.text = "EXO-MURIM / HANEUL S06 / %s\nWASD movimento | Shift correr | F entrar | E arma | Q esquiva" % active_family
