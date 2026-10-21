extends Node3D
## EXO Crowd Hive: NPC-identical presentation, zero NPC gameplay systems.
const Rig = preload("res://rig.gd")
const Wardrobe = preload("res://wardrobe.gd")
const VisualR10 = preload("res://convergence/visual_actor_r10.gd")
const Actions = preload("res://convergence/npc_visual_actions.gd")
var rig: Node3D
var action_time: float = 0.0

func configure(real_profile: Dictionary, ghost_uid: String, seed_text: String) -> bool:
    if rig != null or ghost_uid.is_empty():
        return false
    var identity: Dictionary = real_profile.duplicate(true)
    identity["id"] = ghost_uid
    var appearance: Variant = identity.get("appearance", {})
    if not appearance is Dictionary or appearance.is_empty():
        return false
    # Same fallback cosmetics and exact constructor used by Resident.setup().
    if not appearance.has("skin3d"):
        appearance["skin3d"] = preload("res://exo_skin3d/appearance_adapter.gd").npc_cosmetics(ghost_uid, str(identity.get("role","resident")), str(identity.get("faction","")), seed_text)
    # Reuse the source actor's resolved wardrobe selection on a deep copy.
    # Only the transient visual token changes; do not reroll its costume.
    var selection: Dictionary = appearance.get("visual_r2", {})
    if not selection.is_empty():selection["uid"] = ghost_uid
    rig = Rig.new()
    add_child(rig)
    Wardrobe.apply(rig, appearance)
    VisualR10.apply_resident(rig, identity, {}, seed_text)
    rig.sword.hide()
    for weapon in rig.get_meta("weapon_nodes", []):
        if is_instance_valid(weapon):
            weapon.hide()
    set_meta("exo_crowd_visual_only", true)
    return true

func display_step(delta: float, location: Vector3, world_motion: Vector3, action: String, variant: int) -> void:
    if not is_instance_valid(rig):
        return
    position = location
    action_time += maxf(delta, 0.0)
    var walking: bool = action == "walk" and world_motion.length_squared() > 0.00001
    if walking:
        rig.rotation.y = lerp_angle(rig.rotation.y, atan2(-world_motion.x, -world_motion.z), minf(1.0, delta * 8.0))
    # Both the real Resident and this ghost use these exact animation functions.
    rig.pose(action_time, false, false, true)
    rig.locomotion(world_motion if walking else Vector3.ZERO, delta, false, true, true)
    if not walking:
        Actions.apply(rig, action, action_time, variant)

func _exit_tree() -> void:
    if is_instance_valid(rig):
        VisualR10.cleanup(rig)
