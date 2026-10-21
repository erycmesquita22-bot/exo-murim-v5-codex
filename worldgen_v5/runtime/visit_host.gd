extends Node
## Runtime glue only. Settlement Forge owns scene transition, Core owns all writes.
const PortalController = preload("res://exo_settlement_forge/runtime/portal_controller.gd")
var game: Variant
var portal: Variant
var stage: Node3D
var active_region: Node3D
var service: Variant
var hidden_actors: Dictionary = {}

func _init(host: Node = null) -> void:
    game = host

func _ready() -> void:
    stage = Node3D.new()
    stage.name = "SettlementInteriorStage"
    add_child(stage)
    portal = PortalController.new()
    portal.name = "SettlementPortalController"
    add_child(portal)

func attach_region(region: Node3D) -> void:
    active_region = region
    service = null
    if is_instance_valid(region) and region.has_meta("worldgen_v5_service"):
        var candidate: Variant = region.get_meta("worldgen_v5_service")
        if candidate is Node and is_instance_valid(candidate):
            service = candidate

func inside() -> bool:
    return is_instance_valid(portal) and bool(portal.inside)

func _near_record() -> Dictionary:
    if not is_instance_valid(service) or not is_instance_valid(game) or not is_instance_valid(game.player):
        return {}
    return service.nearest_open_door(game.player.global_position, 3.0)

func interaction_hint() -> String:
    if inside():
        var room: Node3D = portal.get("_interior")
        var out: Marker3D = room.get_node_or_null("InteriorExit") as Marker3D if is_instance_valid(room) else null
        if out != null and game.player.global_position.distance_to(out.global_position) <= 3.0:
            return "E • Sair do edifício"
        return ""
    return "E • Entrar no edifício" if not _near_record().is_empty() else ""

func try_interact() -> bool:
    if not is_instance_valid(portal):
        return false
    if inside():
        if not portal.leave():
            return false
        _restore_actor_visibility()
        return true
    var record: Dictionary = _near_record()
    if record.is_empty() or not is_instance_valid(active_region):
        return false
    # Host/Core access policy. No bypass of character, combat, or institutional state.
    if game._institutional_inside() or game._dungeon_inside() or game.changing_region:
        return false
    if not bool(record.get("accessible", false)) or str(record.get("access_state", "")) != "open":
        return false
    var success: bool = portal.enter(game.player, active_region, stage, game.camera, record, true)
    if success:
        _hide_actors()
    return success

func _hide_actors() -> void:
    hidden_actors.clear()
    for actor in game.residents:
        if is_instance_valid(actor):
            hidden_actors[actor.get_instance_id()] = {"ref": actor, "visible": actor.visible}
            actor.visible = false

func _restore_actor_visibility() -> void:
    for snapshot in hidden_actors.values():
        var actor: Node = snapshot.get("ref")
        if is_instance_valid(actor):
            actor.visible = bool(snapshot.get("visible", true))
    hidden_actors.clear()

func snapshot() -> Dictionary:
    return portal.snapshot_for_core() if is_instance_valid(portal) else {"inside": false}

func restore_saved_visit(snapshot_data: Dictionary) -> bool:
    if not bool(snapshot_data.get("inside", false)):
        return true
    if not is_instance_valid(service) or not is_instance_valid(active_region):
        return false
    if str(snapshot_data.get("region_id", "")) != str(game.current_region):
        return false
    var record: Dictionary = service.get_building(str(snapshot_data.get("building_id", "")))
    if record.is_empty():
        return false
    var ok: bool = portal.restore_from_core(game.player, active_region, stage, game.camera,
        record, snapshot_data, bool(record.get("accessible", false)) and str(record.get("access_state", "")) == "open")
    if ok:
        _hide_actors()
    return ok

func detach() -> bool:
    if inside():
        return false
    active_region = null
    service = null
    hidden_actors.clear()
    return true

func interrupt(reason: String="host_recovery") -> bool:
    if not inside():return true
    if not portal.interrupt(reason):return false
    _restore_actor_visibility()
    return true
