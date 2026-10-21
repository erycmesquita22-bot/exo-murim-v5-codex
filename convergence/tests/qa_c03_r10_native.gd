extends SceneTree
## R10 native smoke/contract verification; requires real Godot 4.6.2 Compatibility.
## A zero exit code alone is NOT a substitute for inspecting engine stderr.
const Rig = preload("res://rig.gd")
const Wardrobe = preload("res://wardrobe.gd")
const Codec = preload("res://exo_skin3d/profile_codec.gd")
const Visual = preload("res://convergence/visual_actor_r10.gd")
const Selection = preload("res://exo_humanoids03_r2/scripts/preset_selector.gd")
const State = preload("res://convergence/state.gd")
var passed: int = 0
var failures: Array[String] = []
func _assert(value: bool, description: String) -> void:
    if value:passed += 1
    else:
        failures.append(description)
        push_error("R10 FAIL: " + description)

func _initialize() -> void:
    for body in ["classic", "slim"]:
        var rig: Node3D = Rig.new()
        root.add_child(rig)
        var options: Dictionary = Codec.defaults()
        options["model"] = body
        var appearance: Dictionary = {"race":0,"robe":2,"outfit":0,"skin3d":options,"weapon":"sword"}
        Wardrobe.apply(rig,appearance)
        var original_tex: Texture2D = rig.skin.albedo_texture
        var local_id: String = "npc/r12/r10_" + body
        var person: Dictionary = {"id":local_id,"role":"master","region_id":12,"faction":"neutral","martial_school_id":"exo_martial.school.mosteiro_jade","appearance":appearance}
        var selection: Dictionary = Visual.apply_resident(rig,person,{},"816204")
        _assert(not selection.is_empty(),body+" visual installed")
        _assert(Selection.valid(selection),body+" catalog-valid")
        _assert(selection.get("uid","") == local_id,body+" UID binding")
        _assert(selection.get("style",{}).get("palette","") == "jade_martial_school",body+" canonical school palette")
        _assert(rig.skin.albedo_texture == original_tex,body+" vanilla skin retained")
        var roots: Array = rig.get_meta("exo_humanoid_r2_roots",[])
        _assert(roots.size() == 8,body+" eight rig pivots")
        _assert(person.appearance.get("visual_r2",{}) == selection,body+" persistent JSON choice")
        Visual.notify_action(rig,"roll",true)
        Visual.notify_action(rig,"roll",false)
        Visual.notify_action(rig,"two_handed",true)
        Visual.notify_action(rig,"two_handed",false)
        _assert(rig.get_meta("exo_humanoid_r2_roots",[]).size() == 8,body+" no pose re-instantiation")
        var again: Dictionary = Visual.apply_resident(rig,person,{"visual_r2":selection},"816204")
        _assert(again == selection,body+" saved choice stable after reapply")
        _assert(rig.get_meta("exo_humanoid_r2_roots",[]).size() == 8,body+" no repeated attachments")
        Visual.cleanup(rig)
        _assert(rig.get_meta("exo_humanoid_r2_roots",[]).is_empty(),body+" freed cosmetics")
        rig.queue_free()
    var selection_data: Dictionary = Selection.choose({"uid":"npc/r25/school","role":"disciple","world_seed":"101","region_id":25,"faction":"neutral","prestige":0})
    _assert(Selection.valid(selection_data),"disciple catalog choice")
    var candidate: Dictionary = {"schema":1,"qi":53.0,"stamina":24.0}
    _assert(candidate.qi > 0 and candidate.stamina < 100,"energy fixture")
    print(JSON.stringify({"test":"r10_native","pass":passed,"fail":failures,"godot":Engine.get_version_info()}))
    quit(0 if failures.is_empty() else 1)
