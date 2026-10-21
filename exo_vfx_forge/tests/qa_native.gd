extends SceneTree
# Run from standalone sandbox with: godot --headless --path . --script res://exo_vfx_forge/tests/qa_native.gd
const Lib=preload("res://exo_vfx_forge/api/recipe_library.gd")
const Contract=preload("res://exo_vfx_forge/api/av_contract.gd")
func _initialize() -> void:
    var library: Variant = Lib.new()
    var n: int = library.load_directory()
    print("QA_NATIVE_RECIPES",n)
    if n != 10:
        push_error("recipe_count_invalid: " + str(library.errors))
        quit(1)
        return
    var event: Dictionary={"contract_version":"exo.vfx.events/1","cast_instance_id":"QA-1","skill_id":"corte_inicial","caster_entity_id":"SAMPLE","cue_id":"launch","vfx_id":"vfx.slash.qi.blue.v1","phase":"launch","visual_seed":12,"origin_xyz":[0,0,0],"direction_xyz":[0,0,-1],"quality_profile":"low"}
    if not Contract.validate(event).ok:
        push_error("valid_event_rejected")
        quit(2)
        return
    event.phase="not_a_phase"
    if Contract.validate(event).ok:
        push_error("invalid_event_accepted")
        quit(3)
        return
    print("QA_NATIVE_CONTRACT_PASS")
    quit(0)
