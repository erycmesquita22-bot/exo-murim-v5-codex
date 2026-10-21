extends RefCounted
# Never calls Interior Forge or City Forge runtime; descriptions ONLY.
const Selector = preload("res://exo_world_library/integration/advanced_selection_r4.gd")
const ALLOWED_FUNCTIONS: Array[String] = ["administration","farmstead","herbalist","inn","market","martial_school","residence","shrine","smithy","warehouse"]
var selector: Variant = null
func initialize() -> bool:
    selector = Selector.new()
    return selector.initialize()
func room_hints(request: Dictionary) -> Dictionary:
    var blocked: Dictionary = {"status":"BLOCKED","committed":false,"authority":"none","proposals":[]}
    for k in ["world_id","seed","region_id","settlement_id","building_instance_id","building_function","biome","settlement_type"]:
        if not request.has(k):
            blocked["reason"] = "missing_"+k
            return blocked
    if str(request["building_function"]) not in ALLOWED_FUNCTIONS:
        blocked["reason"] = "unknown_building_function"
        return blocked
    var norm: Dictionary = Selector.normalize_region_id(request["region_id"])
    if not bool(norm.get("ok",false)):
        blocked["reason"] = "invalid_region_id"
        return blocked
    for k in ["settlement_id","building_instance_id"]:
        if not request[k] is String or str(request[k]).strip_edges().is_empty():
            blocked["reason"] = "missing_stable_"+k
            return blocked
    if request.has("template_id") and request.get("template_id","") == request["building_instance_id"]:
        blocked["reason"] = "template_is_not_global_building_instance_id"
        return blocked
    if selector == null:
        blocked["reason"] = "not_initialized"
        return blocked
    var ctx: Dictionary = request.duplicate(true)
    ctx["region_id"] = int(norm["region_id"])
    ctx["building_function"] = str(request["building_function"])
    ctx["instance_key"] = str(request["settlement_id"]) + "/" + str(request["building_instance_id"])
    var output: Dictionary = selector.propose("interior_scene_hint",ctx,str(request["building_function"]))
    output["building_instance_id"] = str(request["building_instance_id"])
    output["descriptor_only"] = true
    output["requires_owner_for_entrance"] = true
    output["requires_interior_prefab_receipt"] = true
    output["is_existing_building"] = false
    return output
