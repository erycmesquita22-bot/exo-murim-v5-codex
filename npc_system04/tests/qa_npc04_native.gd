extends SceneTree
## Execute in a COPIED full project with: godot --headless --path . --script res://npc_system04/tests/qa_npc04_native.gd
## Parser/scene fixture only, never counted as the complete campaign/bench/visual test.
const Brain = preload("res://npc_system04/core/brain.gd")
const Paths = preload("res://npc_system04/core/path_guard.gd")
const Social = preload("res://npc_system04/core/social.gd")
const Actor = preload("res://npc_system04/actor.gd")
const Director = preload("res://npc_system04/director.gd")
const Module = preload("res://npc_system04/module.gd")
var fails: Array = []
func _initialize() -> void:
    call_deferred("run")
func check(condition: bool, reason: String) -> void:
    if not condition: fails.append(reason)
func run() -> void:
    var p: Dictionary = {"id":"npc/r12/a", "role":"merchant", "home_slot":"home", "work_slot":"shop", "preferences":{"social":80,"duty":90,"risk":20}}
    var q: Dictionary = p.duplicate(true)
    q.id = "npc/r12/b"
    check(str(Brain.choose(p, 900.0).activity) == "atendimento", "merchant_must_work")
    check(str(Brain.choose(p, 900.0, true).activity) == "evitar_risco", "merchant_risk")
    check(Paths.accepted([Vector3.ZERO, Vector3(2, 0, 0)]), "valid_corridor")
    check(not Paths.accepted([Vector3.ZERO, Vector3(500, 0, 0)]), "reject_teleport")
    check(Social.meet(p, q, 900.0), "meeting")
    check(not Social.meet(p, q, 901.0), "bounded_cooldown")
    check(Actor != null and Director != null and Module != null, "native_script_preloads")
    print("NPC04 NATIVE UNIT %s %s" % ["PASS" if fails.is_empty() else "FAIL", JSON.stringify(fails)])
    quit(0 if fails.is_empty() else 1)
