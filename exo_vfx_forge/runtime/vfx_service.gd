extends Node3D
# Passive visual service. NEVER executes skills, creates damage, or plays audio.
const Contract = preload("res://exo_vfx_forge/api/av_contract.gd")
const Library = preload("res://exo_vfx_forge/api/recipe_library.gd")
const Instance = preload("res://exo_vfx_forge/runtime/effect_instance.gd")
const CAPS := {"low": 4, "medium": 8, "high": 14}
var library: Variant
var active_by_cast: Dictionary = {}
var recent_keys: Dictionary = {}
var recent_order: Array[String] = []
var pool: Array[Node3D] = []
var started_casts: Dictionary = {}
var cancelled_casts: Dictionary = {}
var max_pool: int = 16
var blocked_count: int = 0
var approved_bindings: Dictionary = {}

func _ready() -> void:
    library = Library.new()
    library.load_directory()

func approve_binding(skill_id: String, allowed_vfx_ids: Array) -> void:
    # Host-side explicit approval; sandbox can opt into fake events.
    approved_bindings[skill_id] = allowed_vfx_ids.duplicate()

func consume_av_event(e: Dictionary) -> Dictionary:
    var validation: Dictionary = Contract.validate(e)
    if not validation.ok:
        return _blocked(str(validation.reason))
    var cast: String = str(e.cast_instance_id)
    var phase: String = str(e.phase)
    var visual: String = str(e.vfx_id)
    if not approved_bindings.has(str(e.skill_id)) or visual not in approved_bindings[str(e.skill_id)]:
        return _blocked("HOST_EVENT_MISSING:binding_not_authorized")
    var key: String = cast + "|" + phase + "|" + str(e.cue_id) + "|" + str(e.get("event_sequence",-1))
    if recent_keys.has(key):
        return {"ok": true, "duplicate": true, "status": "DEDUPLICATED"}
    if phase == "interrupt":
        _remember(key)
        cancelled_casts[cast] = true
        cancel_cast(cast)
        return {"ok": true, "status": "CANCELLED"}
    if cancelled_casts.has(cast):
        return _blocked("CAST_INTERRUPTED")
    if phase == "impact" and not started_casts.has(cast):
        return _blocked("HOST_EVENT_MISSING:impact_without_authorized_prior_phase")
    var recipe: Dictionary = library.get_recipe(visual)
    if recipe.is_empty():
        return _blocked("NEEDS_VFX:missing_recipe")
    var required: String = str(recipe.get("timing", {}).get("phase", "launch"))
    if required != phase:
        return _blocked("PHASE_MISMATCH:expected_"+required)
    _remember(key)
    if phase in ["prepare", "draw", "launch"]:
        started_casts[cast] = true
    var quality: String = str(e.get("quality_profile", "medium"))
    var cap: int = int(CAPS.get(quality,4))
    if _active_count() >= cap:
        return {"ok": false, "status": "DROPPED_BUDGET", "reason": "visual_cap"}
    var node: Node3D = _acquire()
    var on_done: Callable = Callable(self,"_on_finished")
    if not node.is_connected("finished", on_done):
        node.connect("finished",on_done)
    node.call("configure",recipe,e)
    if not active_by_cast.has(cast):
        active_by_cast[cast]=[]
    active_by_cast[cast].append(node)
    return {"ok": true, "status": "VISUAL_ONLY", "vfx_id":visual}

func _remember(key: String) -> void:
    recent_keys[key] = true
    recent_order.append(key)
    if recent_order.size() > 1024:
        recent_keys.erase(recent_order.pop_front())
    # No long-term campaign state is written; release old cast guards.
    if started_casts.size() > 1024:
        started_casts.clear()
        cancelled_casts.clear()

func _blocked(reason: String) -> Dictionary:
    blocked_count += 1
    return {"ok": false, "status": "BLOCKED", "reason":reason}

func _active_count() -> int:
    var total: int = 0
    for cast in active_by_cast.keys():
        total += active_by_cast[cast].size()
    return total

func _acquire() -> Node3D:
    var node: Node3D
    if pool.is_empty():
        node = Instance.new()
        add_child(node)
    else:
        node = pool.pop_back()
    node.visible = true
    return node

func _on_finished(node: Node3D) -> void:
    for cast in active_by_cast.keys():
        active_by_cast[cast].erase(node)
        if active_by_cast[cast].is_empty():
            active_by_cast.erase(cast)
    node.visible = false
    node.call("clear_visuals")
    if pool.size() < max_pool:
        pool.append(node)
    else:
        node.queue_free()

func cancel_cast(cast: String) -> void:
    var list: Array = active_by_cast.get(cast, []).duplicate()
    for node in list:
        node.call("cancel")

func clear_all() -> void:
    for cast in active_by_cast.keys().duplicate():
        cancel_cast(str(cast))
    recent_keys.clear()
    recent_order.clear()
    started_casts.clear()
    cancelled_casts.clear()

func stats() -> Dictionary:
    return {"active":_active_count(),"pool":pool.size(),"blocked":blocked_count,"recipes":library.recipes.size()}
