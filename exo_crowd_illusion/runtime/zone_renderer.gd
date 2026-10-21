extends Node3D
## Hive R1: identical real-NPC geometry, material, cosmetics and animation.
## One logical planner (Director); one visual-only Rig per currently visible ghost.
## No CharacterBody3D, collision, per-agent planner, quest, interaction or save.
const Proxy = preload("res://exo_crowd_illusion/visuals/real_npc_visual.gd")
const Planner = preload("res://exo_crowd_illusion/runtime/planner.gd")
const NPC04Brain = preload("res://npc_system04/core/brain.gd")
var hive_activity: String = "idle"
var agents: Array = []
var profiles: Array = []
var visuals: Dictionary = {}  # agent index -> noninteractive NPC visual
var out_of_view: Dictionary = {}
var generations: Dictionary = {}
var elapsed: float = 0.0
var accumulator: float = 0.0
var clip_interval: float = 0.16
var focus: Node3D
var mobile: bool = false
var max_visible: int = 32
var clip_distance: float = 75.0
var seed_text: String = ""
var danger_point: Vector3 = Vector3.ZERO
var danger_left: float = 0.0
var rendered_count: int = 0
var update_calls: int = 0
var recycled_count: int = 0
var culled_count: int = 0
var born_count: int = 0

func configure(plan_data: Dictionary, camera_target: Node3D = null, target_mobile: bool = false, _crowd_panic_limit: float = 0.0, approved_profiles: Array = [], world_seed: String = "", daytime_hour: int = 12) -> void:
    _clear_visuals()
    agents = plan_data.get("agents", []).duplicate(true)
    profiles = approved_profiles.duplicate(true)
    seed_text = world_seed
    hive_activity = "idle"
    # ONE group-level NPC04 agenda proposal. Figurantes never run their own AI.
    if not profiles.is_empty() and not agents.is_empty():
        var representative: Dictionary = profiles[0].duplicate(true)
        representative["role"] = str(agents[0].get("role", "resident"))
        var proposed: Dictionary = NPC04Brain.choose(representative, float(daytime_hour) * 90.0)
        if not proposed.is_empty():
            var activity: String = str(proposed.get("activity", "idle"))
            if activity in ["treino", "treino_individual", "meditacao", "trabalho", "preparar_banca", "atendimento", "alerta", "observar_risco", "investigar", "organizar_mercadorias"]:
                hive_activity = activity
    focus = camera_target
    mobile = target_mobile
    elapsed = 0.0
    accumulator = 0.0
    out_of_view.clear()
    generations.clear()
    recycled_count = 0
    culled_count = 0
    born_count = 0
    # Actual R10/NPC wardrobe rigs are heavier than the previous six-piece MultiMesh.
    # A performance budget may cap VISIBLE instances, NEVER degrade their appearance.
    max_visible = 18 if mobile else 36
    clip_distance = 46.0 if mobile else 75.0
    clip_interval = 0.22 if mobile else 0.16
    set_process(not agents.is_empty() and not profiles.is_empty())

func set_max_visible(amount: int) -> void:
    max_visible = clampi(amount, 0, 60)

func react(position: Vector3, seconds: float = 4.0) -> void:
    danger_point = position
    danger_left = clampf(seconds, 0.0, 10.0)

func _actor_progress(actor: Dictionary) -> float:
    var length: float = maxf(0.01, float(actor.get("route_length", 0.01)))
    return clampf(float(actor.get("phase", 0.0)) + maxf(0.0, elapsed - float(actor.get("hive_born_at", 0.0))) * float(actor.get("speed", 0.0)) / length, 0.0, 1.0)

func _actor_position(actor: Dictionary) -> Vector3:
    var route: Array = actor.get("route", [actor.get("a", Vector3.ZERO), actor.get("b", Vector3.ZERO)])
    if route.is_empty():
        return Vector3.ZERO
    if route.size() == 1:
        return route[0]
    return Planner._walk_route_vectors(route, _actor_progress(actor))

func _in_view(position_local: Vector3, margin_pixels: float) -> bool:
    var where: Vector3 = to_global(position_local)
    var camera: Camera3D = get_viewport().get_camera_3d()
    if not is_instance_valid(camera):
        return is_instance_valid(focus) and where.distance_to(focus.global_position) <= clip_distance
    var size: Vector2 = get_viewport().get_visible_rect().size
    # Inspect feet, torso and head: never destroy a partly visible NPC.
    for h in [0.1, 1.05, 2.1]:
        var point: Vector3 = where + Vector3.UP * h
        if camera.is_position_behind(point):
            continue
        var pixel: Vector2 = camera.unproject_position(point)
        if pixel.x >= -margin_pixels and pixel.y >= -margin_pixels and pixel.x <= size.x + margin_pixels and pixel.y <= size.y + margin_pixels:
            return true
    return false

func _hive_action(agent: Dictionary, idx: int, is_walking: bool) -> String:
    if is_walking:
        return "walk"
    var role: String = str(agent.get("role", "resident"))
    var turn: int = (int(elapsed / 9.0) + idx) % 4
    if turn != 0 and hive_activity != "idle":
        return hive_activity
    match role:
        "merchant": return "preparar_banca" if turn != 0 else "talk"
        "disciple": return "treino" if turn < 2 else "meditacao"
        "guard": return "alerta" if turn < 2 else "observar_risco"
        "resident": return "talk" if turn == 0 else "trabalho" if turn == 1 else "idle"
        _: return "idle" if turn % 2 == 0 else "observar_risco"

func _visual_profile(idx: int) -> Dictionary:
    if profiles.is_empty():
        return {}
    var generation: int = int(generations.get(idx, 0))
    return profiles[posmod(idx + generation * 7, profiles.size())]

func _create_visual(idx: int) -> void:
    if visuals.size() >= max_visible or visuals.has(idx):
        return
    var actor: Dictionary = agents[idx]
    var visual := Proxy.new()
    visual.name = "HiveVisual_%d" % idx
    var ghost_id: String = "npc/r00/crowd/%s/g%d" % [str(actor.get("id", idx)).replace("/", "_"), int(generations.get(idx, 0))]
    add_child(visual)
    if not visual.configure(_visual_profile(idx), ghost_id, seed_text):
        remove_child(visual)
        visual.queue_free()
        return
    visual.scale = Vector3.ONE * float(actor.get("scale", 1.0))
    visuals[idx] = visual
    born_count += 1

func _destroy_visual(idx: int) -> void:
    if not visuals.has(idx):
        return
    var visual: Node3D = visuals[idx]
    visuals.erase(idx)
    if is_instance_valid(visual):
        remove_child(visual)
        visual.queue_free()
    culled_count += 1

func _clear_visuals() -> void:
    for idx in visuals.keys():
        _destroy_visual(idx)
    visuals.clear()

func _process(delta: float) -> void:
    elapsed += maxf(delta, 0.0)
    danger_left = maxf(0.0, danger_left - delta)
    accumulator += delta
    var check_visibility: bool = accumulator >= clip_interval
    if check_visibility:
        accumulator = fmod(accumulator, clip_interval)
    for idx in range(agents.size()):
        var actor: Dictionary = agents[idx]
        var location: Vector3 = _actor_position(actor)
        if check_visibility:
            _sync_visibility(idx, actor, location, delta)
        if not visuals.has(idx):
            continue
        var p: float = _actor_progress(actor)
        var moving: bool = p < 1.0 and float(actor.get("speed", 0.0)) > 0.0 and str(actor.get("activity", "walk")) == "walk"
        var future: Vector3 = location
        if moving:
            var route: Array = actor.get("route", [actor["a"], actor["b"]])
            future = Planner._walk_route_vectors(route, minf(1.0, p + 0.006))
        var direction: Vector3 = future - location
        direction.y = 0.0
        var velocity: Vector3 = direction.normalized() * float(actor.get("speed", 0.0)) if moving and direction.length_squared() > 0.000001 else Vector3.ZERO
        var gesture: String = _hive_action(actor, idx, not velocity.is_zero_approx())
        (visuals[idx] as Node).call("display_step", delta, location, velocity, gesture, idx % 3)
    rendered_count = visuals.size()
    update_calls += 1

func _sync_visibility(idx: int, actor: Dictionary, location: Vector3, delta: float) -> void:
    var near_screen: bool = _in_view(location, 96.0)
    if near_screen:
        out_of_view.erase(idx)
        _create_visual(idx)
        return
    var first_out: float = float(out_of_view.get(idx, elapsed))
    if not out_of_view.has(idx):
        out_of_view[idx] = elapsed
    if elapsed - first_out >= 0.5:
        _destroy_visual(idx)
    # Recycle ONLY when both departure and new entry are outside the frame.
    if elapsed - first_out < 1.0 or _actor_progress(actor) < 1.0:
        return
    var route: Array = actor.get("route", [])
    if route.size() < 2 or _in_view(route[0], 140.0):
        return
    var current: Dictionary = actor.duplicate(true)
    current["hive_born_at"] = elapsed
    current["phase"] = 0.0
    agents[idx] = current
    generations[idx] = int(generations.get(idx, 0)) + 1
    out_of_view[idx] = elapsed
    recycled_count += 1

func stats() -> Dictionary:
    return {"total": agents.size(), "visible": rendered_count, "visual_instances": visuals.size(), "batches": 0, "updates": update_calls, "recycled_offscreen": recycled_count, "culled_offscreen": culled_count, "visuals_created": born_count, "uses_real_npc_rig": true, "panic_active": danger_left > 0.0}
