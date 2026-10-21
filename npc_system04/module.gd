extends RefCounted
## Registry-facing observability. NPC04 director exclusively controls real actors in convergence/game.gd.
const VERSION := "0.4.1"
var world: Node3D
var core: RefCounted
func initialize(context: RefCounted) -> bool:
    if context == null or context.get("world") == null: return false
    core = context
    world = context.world
    return bool(context.services.register_service("npc04.runtime", "npc_system04", self,
        ["status", "actor_snapshot", "diagnostics"], VERSION))

func status() -> Dictionary:
    return {"schema":1, "version":VERSION, "operational_owner":"npc_system04/director.gd",
        "uid_owner":"living_world", "scene_owner":"convergence/game.gd",
        "save_owner":"convergence/game.gd/Core Persistence", "online":world != null}

func actor_snapshot(uid: String) -> Dictionary:
    if world == null or not world.get("residents") is Array: return {}
    for actor in world.residents:
        if is_instance_valid(actor) and str(actor.identity.get("id", "")) == uid:
            return actor.snapshot()
    return {}

func diagnostics() -> Dictionary:
    if world == null or world.get("npc_director") == null: return {"ok":false, "reason":"host_unavailable"}
    return world.npc_director.report(world.residents)

func shutdown() -> void:
    world = null
    core = null
