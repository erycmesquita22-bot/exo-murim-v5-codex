extends SceneTree
const Catalog = preload("res://exo_bestiary/catalog/species_catalog.gd")
const Tactics = preload("res://exo_bestiary/v3/group_tactics.gd")
const Brain = preload("res://exo_bestiary/v3/combat_brain.gd")
const Timing = preload("res://exo_bestiary/v3/animation_timing.gd")

var checks: int = 0
func verify(condition: bool, message: String) -> void:
    if not condition:
        push_error("BESTIARY_V3_FAIL: " + message)
        quit(1)
    checks += 1

func _initialize() -> void:
    var catalog = Catalog.new()
    verify(catalog.load_data(), "catalog_load")
    var ids: Array[String] = ["bandit_swordsman", "bandit_archer", "bandit_spearman", "dagger_raider"]
    var members: Array[Dictionary] = []
    for i in range(ids.size()):
        members.append({"uid": "enemy_" + str(i), "profile_id": ids[i],
            "region_id": 7, "position": Vector3(2.0 + float(i), 0.0, 0.0),
            "hp_ratio": 1.0, "attack_ready": true,
            "line_of_sight": true, "target_visible": true})
    var req: Dictionary = {"group_id": "test/7/1", "region_id": 7,
        "target_position": Vector3(0, 0, 0), "members": members, "combat_seconds": 0.0}
    var a: Dictionary = Tactics.propose(req, catalog)
    verify(a.get("status") == "PROPOSED", "group_ok")
    verify(not bool(a.get("committed", true)), "no_commit")
    verify(a["member_count"] == 4, "all_members")
    verify(a["attack_slots"].size() <= 2, "max_two_attackers")
    var b: Dictionary = Tactics.propose(req, catalog)
    verify(a == b, "deterministic")
    var ctx: Dictionary = {"hp_ratio": 1.0, "territory_exists": true,
        "target_visible": true, "distance": 2.0, "attack_ready": true,
        "line_of_sight": true}
    var actor: Dictionary = Brain.decide(catalog.get_profile("bandit_swordsman"), catalog, ctx,
        {"role":"pressure", "attack_slot":true})
    verify(actor["status"] == "PROPOSED", "actor_proposal")
    verify(actor["intent"] == "attack", "attack_candidate")
    ctx["line_of_sight"] = false
    actor = Brain.decide(catalog.get_profile("bandit_swordsman"), catalog, ctx,
        {"role":"pressure", "attack_slot":true})
    verify(actor["intent"] != "attack", "no_attack_without_los")
    ctx["line_of_sight"] = true
    actor = Brain.decide(catalog.get_profile("bandit_swordsman"), catalog, ctx,
        {"role":"pressure", "attack_slot":false})
    verify(actor["intent"] != "attack", "no_attack_without_slot")
    var duplicate: Dictionary = req.duplicate(true)
    duplicate["members"].append(members[0])
    verify(Tactics.propose(duplicate, catalog)["status"] == "BLOCKED", "duplicate_uid")
    var cross: Dictionary = req.duplicate(true)
    cross["members"][0]["region_id"] = 8
    verify(Tactics.propose(cross, catalog)["status"] == "BLOCKED", "cross_region")
    var timing: Dictionary = Timing.preview(catalog.get_profile("dagger_raider"))
    verify(timing["status"] == "PROPOSED", "timing_profile")
    print("BESTIARY_V3_PASS ", checks, " checks")
    quit(0)
