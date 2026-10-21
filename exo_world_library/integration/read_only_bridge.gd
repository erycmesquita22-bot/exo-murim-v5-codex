extends RefCounted
# Optional host bridge: explicit per-owner whitelist; never registers or mutates Core.
const LIBRARY = preload("res://exo_world_library/core/entrypoint.gd")
const ADVANCED = preload("res://exo_world_library/integration/advanced_selection_r4.gd")
const CONTRACT = "res://exo_world_library/contracts/adapter_requirements.json"
var library: Variant = null
var advanced: Variant = null
var adapters: Dictionary = {}
var last_error: String = ""

func initialize() -> bool:
    var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONTRACT)) if FileAccess.file_exists(CONTRACT) else null
    if not (raw is Dictionary):
        last_error = "adapter_contract_missing"
        return false
    adapters = raw.duplicate(true)
    advanced = ADVANCED.new()
    if not advanced.initialize():
        last_error = "catalog_load_failed"
        return false
    library = advanced.library
    last_error = ""
    return true

func catalog_preview(owner_id: String, request: Dictionary, domains: Array) -> Dictionary:
    if library == null:
        return {"status":"BLOCKED", "reason":"bridge_not_initialized", "committed":false}
    if not adapters.has(owner_id):
        return {"status":"BLOCKED", "reason":"unknown_owner", "committed":false}
    var spec: Dictionary = adapters[owner_id]
    if bool(spec.get("owner_can_apply", true)):
        return {"status":"BLOCKED", "reason":"unsafe_owner_contract", "committed":false}
    for required_key in spec.get("expected_host_context", []):
        if not request.has(str(required_key)):
            return {"status":"BLOCKED", "reason":"owner_context_missing:" + str(required_key), "committed":false}
    for domain in domains:
        if str(domain) not in spec.get("data", []):
            return {"status":"BLOCKED", "reason":"domain_not_authorized_for_owner:" + str(domain), "committed":false}
        if str(domain).begins_with("ref_") or str(domain) == "terrain_texture":
            return {"status":"BLOCKED", "reason":"source_ref_non_selectable", "committed":false}
    var result: Dictionary = advanced.compose(request, domains)
    result["requested_owner"] = owner_id
    result["gate"] = str(spec.get("gate", "owner_approval_required"))
    result["committed"] = false
    return result
