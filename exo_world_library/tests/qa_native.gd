extends SceneTree
const Library = preload("res://exo_world_library/core/entrypoint.gd")
const Bridge = preload("res://exo_world_library/integration/read_only_bridge.gd")
const StoryBridge = preload("res://exo_world_library/integration/narrative_story_bridge.gd")

func _initialize() -> void:
    var library: Variant = Library.new()
    if not library.load_catalogs():
        push_error("EXO_LIBRARY_LOAD_FAIL: " + str(library.errors))
        quit(2)
        return
    var status: Dictionary = library.catalog_status()
    if int(status.get("records", 0)) != 1228 or int(status.get("domains", 0)) != 76:
        push_error("EXO_LIBRARY_COUNT_INVALID: " + str(status))
        quit(3)
        return
    var context: Dictionary = {"world_id":"QA-101", "seed":101, "region_id":78,
        "biome":"grassland", "settlement_type":"town", "player_tier":1,
        "tags":["river_access"], "flags":[]}
    var stages: Array = ["region_theme", "settlement_theme", "npc_archetype", "personality",
        "npc_motivation", "region_legacy", "narrative_motif", "world_event", "rumor", "loot_theme"]
    var first: Dictionary = library.compose(context, stages)
    var second: Dictionary = library.compose(context, stages)
    if first != second or str(first.get("status", "")) != "PROPOSAL_ONLY" or bool(first.get("committed", true)):
        push_error("EXO_LIBRARY_DETERMINISM_FAIL")
        quit(4)
        return
    if bool(library.select("ref_city_profiles", context).get("ok", false)):
        push_error("EXO_LIBRARY_REFERENCES_MUST_BE_READONLY")
        quit(5)
        return
    if library.compose({"seed":101}, stages).get("status", "") != "BLOCKED":
        push_error("EXO_LIBRARY_INVALID_CONTEXT_ACCEPTED")
        quit(6)
        return
    var wet: Dictionary = context.duplicate(true)
    wet["biome"] = "wetland"
    var conflict: Dictionary = library.validate_bundle(wet, ["world_event/flood", "climate_phenomenon/estiagem_prolongada"])
    if bool(conflict.get("valid", true)):
        push_error("EXO_LIBRARY_CONFLICT_NOT_BLOCKED")
        quit(7)
        return
    var bridge: Variant = Bridge.new()
    if not bridge.initialize():
        push_error("EXO_LIBRARY_BRIDGE_LOAD_FAIL")
        quit(8)
        return
    var suggestion: Dictionary = bridge.catalog_preview("narrative", context, ["world_event", "rumor"])
    if suggestion.get("status", "") != "PROPOSAL_ONLY" or bool(suggestion.get("committed", true)):
        push_error("EXO_LIBRARY_BRIDGE_PROPOSAL_FAIL")
        quit(9)
        return
    var bad: Dictionary = bridge.catalog_preview("narrative", context, ["ref_city_profiles"])
    if bad.get("status", "") != "BLOCKED":
        push_error("EXO_LIBRARY_BRIDGE_AUTHORITY_FAIL")
        quit(10)
        return
    var story_bridge: Variant = StoryBridge.new()
    if not story_bridge.initialize():
        push_error("EXO_STORY_BRIDGE_LOAD_FAIL")
        quit(11)
        return
    var arc: Dictionary = story_bridge.inspect_arc("story_arc/ponte_das_tres_chaves")
    if arc.get("status", "") != "PROPOSAL_ONLY":
        push_error("EXO_STORY_ARC_MISSING")
        quit(12)
        return
    var step: Dictionary = story_bridge.propose_choice("story_arc/ponte_das_tres_chaves", "opening", "listen", {"world_id":"QA-101","region_id":78,"instance_id":"qa-instance","state_revision":0})
    if step.get("status", "") != "PROPOSAL_ONLY" or step.get("to_node", "") != "investigation" or bool(step.get("committed", true)):
        push_error("EXO_STORY_PREVIEW_NOT_FAIL_CLOSED")
        quit(13)
        return
    print("EXO_WORLD_LIBRARY_NATIVE_QA_PASS: " + str(status))
    quit(0)
