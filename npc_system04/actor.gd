extends CharacterBody3D
## NPC04 is the only physical actor class for REAL inhabitants in this candidate.
## The canonical EXO Rig/Wardrobe/Humanoids remain the source of appearance and animation.
const Rig = preload("res://rig.gd")
const Wardrobe = preload("res://wardrobe.gd")
const Visual = preload("res://convergence/visual_actor_r10.gd")
const Brain = preload("res://npc_system04/core/brain.gd")
const Paths = preload("res://npc_system04/core/path_guard.gd")
var identity: Dictionary = {}
var rig: Node3D
var caption: Label3D
var routes: Dictionary = {}
var route: Array = []
var route_index: int = 0
var from_slot: String = ""
var to_slot: String = ""
var activity_name: String = ""
var desired_slot: String = ""
var arrived: bool = false
var sheltered: bool = false
var near_player: bool = false
var danger_nearby: bool = false
var presentation_visible: bool = true
var visual_active: bool = true
var nearby_residents: Array = []
var player_interest_position: Vector3 = Vector3.ZERO
var paused_for_talk: float = 0.0
var social_time: float = 0.0
var social_cooldown: float = 0.0
var social_target: Node3D
var talks: int = 0
var entries: int = 0
var exits: int = 0
var visits: Dictionary = {}
var work_cycles: int = 0
var travelled: float = 0.0
var blocked_seconds: float = 0.0
var blocked_count: int = 0
var route_failures: int = 0
var patrol_leg: int = 0
var patrol_observations: int = 0
var next_decision: float = 0.0
var next_action: float = 0.0
var game_clock: float = 0.0
var setup_error: String = ""
var hold_seconds: float = 0.0
var last_priority: int = 0

func setup(person: Dictionary, points: Array, saved: Dictionary = {}, routine_paths: Dictionary = {}, now: float = 0.0, seed_text: String = "") -> void:
    identity = person
    routes = routine_paths
    game_clock = now
    if not str(person.get("id", "")).begins_with("npc/r"):
        setup_error = "invalid_living_world_uid"; push_error("NPC04 "+setup_error); return
    from_slot = str(person.get("home_slot", ""))
    to_slot = from_slot
    route = Paths.route(routes, from_slot, from_slot)
    if route.is_empty() and Paths.accepted(points): route = points.duplicate()
    if route.is_empty():
        setup_error = "no_authorized_spawn_corridor:" + str(person.get("id", ""))
        push_error("NPC04 " + setup_error); return
    position = route[0]
    collision_layer = 8
    collision_mask = 1 | 2 | 4 | 8
    floor_snap_length = 0.4
    floor_max_angle = deg_to_rad(50.0)
    var shape: CapsuleShape3D = CapsuleShape3D.new()
    shape.radius = 0.26; shape.height = 1.9
    var collider: CollisionShape3D = CollisionShape3D.new()
    collider.shape = shape; collider.position.y = 0.96
    add_child(collider)
    var appearance: Dictionary = person.get("appearance", {})
    if not appearance.has("skin3d"):
        appearance["skin3d"] = preload("res://exo_skin3d/appearance_adapter.gd").npc_cosmetics(str(person.get("id", "")), str(person.get("role", "resident")), str(person.get("faction", "")), seed_text)
        identity["appearance"] = appearance
    rig = Rig.new()
    add_child(rig)
    Wardrobe.apply(rig, appearance)
    Visual.apply_resident(rig, identity, saved, seed_text)
    rig.sword.hide()
    for weapon in rig.get_meta("weapon_nodes", []):
        if is_instance_valid(weapon): weapon.hide()
    caption = Label3D.new()
    caption.font_size = 28; caption.pixel_size = 0.007
    caption.outline_size = 6; caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    caption.modulate = Color("f7f1e4"); caption.outline_modulate = Color("161f25")
    caption.position.y = 2.46
    caption.text = str(person.get("display_name", person.get("name", "Morador")))
    add_child(caption)
    visits = saved.get("visits", {}).duplicate(true)
    talks = int(saved.get("talks", 0)); work_cycles = int(saved.get("work_cycles", 0))
    entries = int(saved.get("entries", 0)); exits = int(saved.get("exits", 0))
    patrol_leg = int(saved.get("patrol_leg", 0)) % 2
    patrol_observations = int(saved.get("patrol_observations", 0))
    social_cooldown = maxf(0.0, float(saved.get("social_cooldown", 0.0)) - maxf(0.0, now - float(saved.get("snapshot_clock", now))))
    if int(saved.get("npc04_schema", 0)) == 1:
        var previous: String = str(saved.get("from_slot", from_slot))
        var target: String = str(saved.get("to_slot", to_slot))
        var candidate: Array = Paths.route(routes, previous, target)
        if not candidate.is_empty():
            route = candidate
            from_slot = previous; to_slot = target
            route_index = clampi(int(saved.get("route_index", 0)), 0, route.size() - 1)
            var coords: Variant = saved.get("position", [])
            if coords is Array and coords.size() == 3:
                var saved_position: Vector3 = Vector3(float(coords[0]), float(coords[1]), float(coords[2]))
                if Paths.near_segment(saved_position, route): position = saved_position
    arrived = position.distance_to(route[route.size() - 1]) <= 0.35
    activity_name = str(saved.get("activity", "descanso"))
    desired_slot = str(saved.get("desired_slot", to_slot))

func _exit_tree() -> void:
    if is_instance_valid(rig): Visual.cleanup(rig)

func request_destination(slot: String, priority: int) -> bool:
    if slot.is_empty(): return false
    if slot == to_slot: return true
    if not arrived and priority < 90: return false
    var candidate: Array = Paths.route(routes, to_slot, slot)
    if candidate.is_empty():
        route_failures += 1
        if route_failures <= 3: push_warning("NPC04 corridor unavailable %s %s>%s" % [str(identity.get("id", "")), to_slot, slot])
        return false
    if position.distance_to(candidate[0]) > 1.8:
        # Do not snap to a fabricated beginning; first finish a valid current route.
        route_failures += 1
        return false
    if sheltered: exits += 1
    sheltered = false
    from_slot = to_slot; to_slot = slot
    route = candidate; route_index = 0; arrived = false
    hold_seconds = 0.0
    return true

func decide(now: float) -> void:
    if setup_error != "": return
    if now < next_decision: return
    next_decision = now + (0.4 if near_player else 1.2)
    var social: bool = not nearby_residents.is_empty()
    var plan: Dictionary = Brain.choose(identity, now, danger_nearby, social, patrol_leg)
    last_priority = int(plan.get("priority", 20))
    activity_name = str(plan.get("activity", "descanso"))
    var target: String = str(plan.get("slot", ""))
    desired_slot = target
    if target != to_slot: request_destination(target, last_priority)
    if activity_name == "patrulhar" and arrived and hold_seconds <= 0.0:
        patrol_leg = (patrol_leg + 1) % 2
        patrol_observations += 1
        hold_seconds = 2.0
        var next_plan: Dictionary = Brain.choose(identity, now, danger_nearby, false, patrol_leg)
        request_destination(str(next_plan.get("slot", "")), 60)

func begin_social(other: Node3D) -> void:
    if social_cooldown > 0 or social_time > 0 or not is_instance_valid(other): return
    social_target = other
    social_time = 2.0
    social_cooldown = 65.0 if int(identity.get("preferences", {}).get("social", 40)) < 30 else 30.0

func step(delta: float, _hour: int, now: float = -1.0) -> void:
    if setup_error != "": return
    var clock: float = game_clock + delta if now < 0.0 else now
    game_clock = clock
    paused_for_talk = maxf(0.0, paused_for_talk - delta)
    social_time = maxf(0.0, social_time - delta)
    social_cooldown = maxf(0.0, social_cooldown - delta)
    hold_seconds = maxf(0.0, hold_seconds - delta)
    decide(clock)
    sheltered = arrived and activity_name == "descanso" and paused_for_talk <= 0.0
    if sheltered and rig.visible: entries += 1
    collision_layer = 0 if sheltered else 8
    rig.visible = presentation_visible and not sheltered
    caption.visible = rig.visible
    var moving: bool = not arrived and paused_for_talk <= 0.0 and social_time <= 0.0 and hold_seconds <= 0.0
    if moving:
        var destination: Vector3 = route[route_index]
        var offset: Vector3 = destination - position; offset.y = 0.0
        if offset.length() <= 0.24:
            if route_index < route.size() - 1:
                route_index += 1
                destination = route[route_index]
                offset = destination - position; offset.y = 0.0
            else:
                arrived = true
                visits[to_slot] = int(visits.get(to_slot, 0)) + 1
                hold_seconds = 0.3
                moving = false
        if moving:
            var direction: Vector3 = offset.normalized()
            var avoidance: Vector3 = Vector3.ZERO
            for other in nearby_residents:
                if not is_instance_valid(other) or other == self or other.sheltered: continue
                var away: Vector3 = position - other.position; away.y = 0.0
                if away.length_squared() > 0.03 and away.length_squared() < 1.8:
                    avoidance += away.normalized() * 0.4
            var drive: Vector3 = (direction + avoidance).normalized() * 1.7
            velocity.x = drive.x; velocity.z = drive.z
            rig.rotation.y = lerp_angle(rig.rotation.y, atan2(-direction.x, -direction.z), minf(1.0, delta * 7.0))
    if not moving:
        velocity.x = 0.0; velocity.z = 0.0
        if is_instance_valid(social_target) and social_time > 0:
            var glance: Vector3 = social_target.position - position
            rig.rotation.y = lerp_angle(rig.rotation.y, atan2(-glance.x, -glance.z), minf(1.0, delta * 4.0))
    if not is_on_floor(): velocity.y -= 20.0 * delta
    else: velocity.y = -0.05
    var before: Vector3 = position
    if moving or not is_on_floor(): move_and_slide()
    var distance: float = Vector2(position.x - before.x, position.z - before.z).length()
    travelled += distance
    blocked_seconds = blocked_seconds + delta if moving and distance < delta * 0.18 else 0.0
    if blocked_seconds > 3.0:
        blocked_count += 1
        blocked_seconds = 0.0
        hold_seconds = 1.5
        route_index = maxi(0, route_index - 1)
        if blocked_count % 4 == 0:
            route_failures += 1
            push_warning("NPC04 blocked corridor " + str(identity.get("id", "")))
    _work_tick(delta, clock)
    if visual_active and rig.visible:
        rig.pose(clock, false, false, is_on_floor())
        rig.locomotion(get_real_velocity() if moving else Vector3.ZERO, delta, false, is_on_floor(), true)
        preload("res://convergence/npc_visual_actions.gd").apply(rig, activity_name if arrived else "idle", clock, 0, social_time > 0.0)

func _work_tick(delta: float, now: float) -> void:
    if not arrived or to_slot != desired_slot or sheltered or paused_for_talk > 0 or activity_name not in Brain.WORK: return
    next_action += delta
    if next_action >= 6.0:
        next_action -= 6.0
        work_cycles += 1
        set_meta("npc04_last_work", {"activity": activity_name, "clock": now, "slot": to_slot})

func step_far(delta: float, now: float) -> void:
    if setup_error != "": return
    game_clock = now
    near_player = false; visual_active = false
    rig.visible = false; caption.visible = false
    collision_layer = 0
    paused_for_talk = maxf(0.0, paused_for_talk - delta)
    social_cooldown = maxf(0.0, social_cooldown - delta)
    hold_seconds = maxf(0.0, hold_seconds - delta)
    decide(now)
    if arrived or hold_seconds > 0.0 or paused_for_talk > 0.0: return
    # Logic-only advancement on PRE-APPROVED road segments. Never shown as physical movement.
    var target: Vector3 = route[route_index]
    var d: float = position.distance_to(target)
    if d <= 0.25:
        if route_index < route.size() - 1: route_index += 1
        else:
            arrived = true
            visits[to_slot] = int(visits.get(to_slot, 0)) + 1
    else:
        var motion: float = minf(d, delta * 1.7)
        position = position.move_toward(target, motion)
        travelled += motion

func snapshot(at_clock: float = -1.0) -> Dictionary:
    var selected: Dictionary = rig.get_meta("exo_humanoid_r2_selection", {}) if is_instance_valid(rig) else {}
    return {"npc04_schema": 1, "snapshot_clock": at_clock if at_clock >= 0 else game_clock,
        "position": [position.x, position.y, position.z],
        "from_slot": from_slot, "to_slot": to_slot, "route_index": route_index,
        "activity": activity_name, "desired_slot": desired_slot, "visual_r2": selected.duplicate(true),
        "patrol_leg": patrol_leg, "patrol_observations": patrol_observations,
        "entries": entries, "exits": exits, "talks": talks,
        "visits": visits.duplicate(true), "work_cycles": work_cycles,
        "social_cooldown": social_cooldown, "route_failures": route_failures,
        "blocked_count": blocked_count, "travelled": travelled}

func can_interact(from: Vector3, maximum_distance: float=3.0) -> bool:
    # Presentation culling is not an authority for gameplay availability.
    if not setup_error.is_empty() or sheltered or not is_inside_tree() or not is_on_floor():return false
    if not from.is_finite() or from.distance_to(global_position)>=maximum_distance:return false
    var ray:=PhysicsRayQueryParameters3D.create(from+Vector3.UP,global_position+Vector3.UP,1|4)
    return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
