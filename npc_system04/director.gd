extends RefCounted
## Single live decision/tick owner for NPC04. No second roster, wallet, save writer or camera.
const Social = preload("res://npc_system04/core/social.gd")
var host: Node3D
var social_clock: float = 0.0
var neighbors_clock: float = 0.0
var social_cursor: int = 0
var stats: Dictionary = {"ticks":0, "near_ticks":0, "mid_ticks":0, "far_ticks":0,
    "social_meetings":0, "invalid_actors":0, "route_failures":0, "frame_cost_usec":0}

func _init(world: Node3D) -> void:
    host = world

func tick(delta: float, actors: Array, now: float) -> void:
    if actors.is_empty(): return
    var started: int = Time.get_ticks_usec()
    var player_position: Vector3 = host.player.position
    neighbors_clock -= delta
    if neighbors_clock <= 0.0:
        neighbors_clock = 0.3
        _collect_nearby(actors)
    var hour: int = posmod(int(floor(now / 90.0)), 24)
    for actor in actors:
        if not is_instance_valid(actor) or str(actor.setup_error) != "":
            stats.invalid_actors = int(stats.invalid_actors) + 1
            continue
        var d2: float = actor.position.distance_squared_to(player_position)
        actor.near_player = d2 < 225.0
        actor.player_interest_position = player_position
        actor.danger_nearby = float(host.get("combat_timer")) > 0.0 and d2 < 144.0
        actor.visual_active = actor.presentation_visible and d2 < 3600.0
        if d2 > 6400.0:
            actor.step_far(delta, now)
            stats.far_ticks = int(stats.far_ticks) + 1
        else:
            # Intermediate actors retain physical collision/navigation. Do not assume
            # abstract interpolation makes them walk through actual doors.
            actor.step(delta, hour, now)
            if d2 > 900.0: stats.mid_ticks = int(stats.mid_ticks) + 1
            else: stats.near_ticks = int(stats.near_ticks) + 1
    stats.ticks = int(stats.ticks) + 1
    social_clock -= delta
    if social_clock <= 0.0:
        social_clock = 1.2
        _social_tick(actors, now)
    stats.frame_cost_usec = Time.get_ticks_usec() - started

func _collect_nearby(actors: Array) -> void:
    var cells: Dictionary = {}
    for actor in actors:
        if not is_instance_valid(actor) or str(actor.setup_error) != "": continue
        var x: int = int(floor(actor.position.x / 4.0))
        var z: int = int(floor(actor.position.z / 4.0))
        var key: String = str(x) + ":" + str(z)
        if not cells.has(key): cells[key] = []
        cells[key].append(actor)
    for actor in actors:
        if not is_instance_valid(actor) or str(actor.setup_error) != "": continue
        actor.nearby_residents = []
        var cx: int = int(floor(actor.position.x / 4.0))
        var cz: int = int(floor(actor.position.z / 4.0))
        for x in range(cx - 1, cx + 2):
            for z in range(cz - 1, cz + 2):
                var key: String = str(x) + ":" + str(z)
                for other in cells.get(key, []):
                    if actor != other and actor.position.distance_squared_to(other.position) < 16.0:
                        actor.nearby_residents.append(other)

func _social_tick(actors: Array, now: float) -> void:
    if actors.is_empty(): return
    var actor: Variant = actors[social_cursor % actors.size()]
    social_cursor += 1
    if not is_instance_valid(actor) or str(actor.setup_error) != "" or actor.social_cooldown > 0.0 or actor.social_time > 0.0: return
    if actor.sheltered or not actor.arrived or actor.activity_name not in ["convivio", "procurar_conhecidos", "pausa_curta"]: return
    for other in actor.nearby_residents:
        if not is_instance_valid(other) or str(other.setup_error) != "": continue
        if other.social_time > 0.0 or other.social_cooldown > 0.0 or not other.arrived or other.sheltered: continue
        if other.activity_name not in ["convivio", "procurar_conhecidos", "pausa_curta"]: continue
        var distance: float = actor.position.distance_squared_to(other.position)
        if distance < 0.5 or distance > 6.25: continue
        var friendliness: int = int(actor.identity.get("preferences", {}).get("social", 40))
        if friendliness < 35: continue
        # Narrative rules veto permanent bonds here; this is short lived contact only.
        var narrative: Dictionary = host.journey.data.get("narrative", {})
        var bond: String = str(preload("res://narrative/society/relationship_system.gd").get_bond(narrative, str(actor.identity.id), str(other.identity.id)).get("kind", ""))
        if bond not in ["", "ally", "friend", "family", "master_disciple"]: continue
        if Social.meet(actor.identity, other.identity, now):
            actor.begin_social(other)
            other.begin_social(actor)
            stats.social_meetings = int(stats.social_meetings) + 1
        return

func report(actors: Array) -> Dictionary:
    var result: Dictionary = stats.duplicate(true)
    result["active_actors"] = actors.size()
    result["failed_routes"] = 0
    for actor in actors:
        if is_instance_valid(actor) and str(actor.setup_error) == "":
            result.failed_routes = int(result.failed_routes) + int(actor.route_failures)
    return result
