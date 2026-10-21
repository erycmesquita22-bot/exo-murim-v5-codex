extends Node
## Single transition authority for Settlement Forge. Save/recovery delegated to EXO Core.
const Catalog = preload("res://exo_settlement_forge/runtime/interior_catalog.gd")
const Builder = preload("res://exo_settlement_forge/runtime/interior_builder.gd")
signal transition_done(inside: bool, building_id: String)
signal transition_failed(reason: String)
var inside: bool = false
var busy: bool = false
var active_id: String = ""
var _player: CharacterBody3D
var _exterior: Node3D
var _staging: Node3D
var _interior: Node3D
var _return_transform: Transform3D
var _old_camera_size: float = 15.0
var _outside_process_mode: int = Node.PROCESS_MODE_INHERIT
var _camera: Camera3D
var _record: Dictionary = {}

func enter(player: CharacterBody3D, exterior: Node3D, staging: Node3D,
        camera: Camera3D, record: Dictionary, authorized: bool) -> bool:
    if busy or inside:
        return _fail("transition_busy")
    if not authorized or not bool(record.get("accessible", false)) or str(record.get("access_state","closed")) != "open":
        return _fail("access_denied")
    if not is_instance_valid(player) or not is_instance_valid(exterior) or not is_instance_valid(staging) or not is_instance_valid(camera):
        return _fail("missing_nodes")
    if not player.is_inside_tree() or not exterior.is_inside_tree() or not staging.is_inside_tree():
        return _fail("nodes_not_mounted")
    if exterior == staging or exterior.is_ancestor_of(player) or staging.is_ancestor_of(player):
        return _fail("player_must_remain_outside_streamed_roots")
    if str(record.get("building_id","")).is_empty() or str(record.get("interior_id","")).is_empty():
        return _fail("invalid_identity")
    var door: Array = record.get("exterior_door", [])
    if door.size() != 3:
        return _fail("missing_door")
    var door_point := Vector3(float(door[0]),float(door[1]),float(door[2]))
    var horizontal := Vector2(player.global_position.x - door_point.x,player.global_position.z - door_point.z)
    if horizontal.length() > 3.0:
        return _fail("too_far_from_door")
    var authored: Dictionary = Catalog.get_prefab(str(record["interior_id"]))
    if authored.is_empty():
        return _fail("prefab_not_found")
    if int(record.get("enabled_floors",0)) < 1:
        return _fail("no_enabled_floor")
    # Two-floor prefabs are not enabled for play until native physics QA.
    if int(authored.get("floors",1)) > int(record.get("enabled_floors",1)):
        return _fail("unvalidated_upper_floor")
    var room: Node3D = Builder.build(authored)
    Builder.set_cutaway(room,true)
    var spawn: Marker3D = room.get_node_or_null("InteriorSpawn") as Marker3D
    if spawn == null:
        room.free()
        return _fail("missing_spawn")
    var returning: Array = record.get("return_anchor",[])
    if returning.size()!=3:
        room.free()
        return _fail("missing_return_anchor")
    var return_point:=Vector3(float(returning[0]),float(returning[1]),float(returning[2]))
    if not return_point.is_finite() or not door_point.is_finite():
        room.free()
        return _fail("invalid_return_anchor")
    busy = true
    staging.add_child(room)
    room.position = Vector3(10000.0, 0.0, 10000.0)
    _return_transform = player.global_transform
    _return_transform.origin = Vector3(float(returning[0]),
        float(returning[1]) + (player.global_position.y - door_point.y),float(returning[2]))
    _outside_process_mode = exterior.process_mode
    _player = player
    _exterior = exterior
    _staging = staging
    _interior = room
    _camera = camera
    _old_camera_size = camera.size
    _record = record.duplicate(true)
    active_id = str(record["building_id"])
    player.velocity = Vector3.ZERO
    exterior.visible = false
    exterior.process_mode = Node.PROCESS_MODE_DISABLED
    player.global_position = spawn.global_position + Vector3(0,0.13,0)
    camera.size = 12.0
    inside = true
    busy = false
    transition_done.emit(true,active_id)
    return true

func leave() -> bool:
    if busy or not inside or not is_instance_valid(_player) or not is_instance_valid(_exterior):
        return _fail("no_valid_active_interior")
    var exit: Marker3D = _interior.get_node_or_null("InteriorExit") as Marker3D if is_instance_valid(_interior) else null
    if exit == null or _player.global_position.distance_to(exit.global_position) > 3.0:
        return _fail("player_not_at_exit")
    return interrupt("voluntary_exit")

func interrupt(_reason: String="host_recovery") -> bool:
    if busy or not inside or not is_instance_valid(_player) or not is_instance_valid(_exterior):
        return _fail("no_valid_active_interior")
    busy = true
    _player.velocity = Vector3.ZERO
    _player.global_transform = _return_transform
    _exterior.visible = true
    _exterior.process_mode = _outside_process_mode
    if is_instance_valid(_camera):
        _camera.size = _old_camera_size
    _interior.queue_free()
    _interior = null
    inside = false
    busy = false
    transition_done.emit(false,active_id)
    active_id = ""
    _record.clear()
    return true

func snapshot_for_core() -> Dictionary:
    return {"schema":"exo.settlement.transition.v1", "inside":inside,
        "building_id":active_id,"region_id":str(_record.get("region_id","")),
        "interior_id":str(_record.get("interior_id","")),
        "player_position":_array_position(_player.global_position) if is_instance_valid(_player) else [],
        "return_position":_array_position(_return_transform.origin) if inside else []}

func restore_from_core(player: CharacterBody3D, exterior: Node3D, staging: Node3D,
        camera: Camera3D, record: Dictionary, snapshot: Dictionary, authorized: bool) -> bool:
    # Called ONLY after host has validated its save and loaded correct region.
    if str(snapshot.get("schema","")) != "exo.settlement.transition.v1" or not bool(snapshot.get("inside",false)):
        return _fail("invalid_snapshot")
    if str(snapshot.get("building_id","")) != str(record.get("building_id","")) or str(snapshot.get("interior_id","")) != str(record.get("interior_id","")):
        return _fail("stale_building_snapshot")
    if str(snapshot.get("region_id","")) != str(record.get("region_id","")):
        return _fail("wrong_region")
    var anchor: Array = record.get("exterior_door",[])
    var pos: Array = snapshot.get("player_position",[])
    var ret: Array = snapshot.get("return_position",[])
    if anchor.size()!=3 or pos.size()!=3 or ret.size()!=3:
        return _fail("invalid_positions")
    var previous_transform: Transform3D = player.global_transform
    var exterior_anchor := Vector3(float(anchor[0]),float(anchor[1]),float(anchor[2]))
    if not exterior_anchor.is_finite():
        return _fail("invalid_exterior_anchor")
    player.global_position = exterior_anchor
    if not enter(player,exterior,staging,camera,record,authorized):
        player.global_transform = previous_transform
        return false
    # Reject void/out-of-footprint saves; enter() already selected the authored spawn.
    var saved := Vector3(float(pos[0]),float(pos[1]),float(pos[2]))
    if _position_supported(saved):
        player.global_position = saved
    # Recompute exterior return from the current building, never a stale saved coordinate.
    return true

func _array_position(p: Vector3) -> Array:
    return [p.x,p.y,p.z]

func _fail(code: String) -> bool:
    transition_failed.emit(code)
    return false

func _position_supported(point: Vector3) -> bool:
    if not is_instance_valid(_interior) or not point.is_finite():
        return false
    var local: Vector3 = _interior.to_local(point)
    if local.y < -0.25 or local.y > 8.0:
        return false
    var width: int = int(_interior.get_meta("width_tiles", 0))
    var depth: int = int(_interior.get_meta("depth_tiles", 0))
    var x: float = local.x / Builder.TILE + float(width - 1) * 0.5
    var z: float = local.z / Builder.TILE + float(depth - 1) * 0.5
    for run in _interior.get_meta("floor_runs", []):
        if absf(z - float(run.z)) <= 0.5 and x >= float(run.start) - 0.5 and x <= float(run.end) + 0.5:
            return true
    return false

func recover_to_spawn() -> bool:
    if not inside or busy or not is_instance_valid(_player) or not is_instance_valid(_interior):
        return false
    var spawn: Marker3D = _interior.get_node_or_null("InteriorSpawn") as Marker3D
    if spawn == null:
        return false
    _player.velocity = Vector3.ZERO
    _player.global_position = spawn.global_position + Vector3(0, 0.13, 0)
    return true

func _physics_process(_delta: float) -> void:
    if inside and not busy and is_instance_valid(_player) and not _position_supported(_player.global_position):
        recover_to_spawn()
