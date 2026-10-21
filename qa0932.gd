extends SceneTree
# Godot structural smoke test; run: godot --headless --path . --script res://qa0932.gd
const Rig = preload("res://rig.gd")
const Wardrobe = preload("res://wardrobe.gd")
const Arsenal = preload("res://arsenal.gd")
const Identity = preload("res://exo_identity.gd")
const SkillRegistry = preload("res://audio/skill_registry.gd")

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var rig: Node3D = Rig.new()
    root.add_child(rig)
    for weapon_id in ["sword", "dagger", "greatsword", "katana", "spear", "gauntlets"]:
        Wardrobe.apply(rig, {"race":0,"robe":1,"hair":4,"skin":3,"style":0,"weapon":weapon_id,"outfit":0,"haircut":0,"body":0,"eyes":2,"eye_color":5,"muscles":2,"mark":1})
        var roots: Array = rig.get_meta("carry_roots", [])
        assert(roots.size()>0, "Missing weapon root: "+weapon_id)
        assert(roots[0].get_parent() == rig.forearms[0] or weapon_id=="bow", "Weapon parent is not a forearm")
        var sheath = rig.get_meta("carry_sheath") if rig.has_meta("carry_sheath") else null
        if weapon_id in ["sword","katana"]:
            assert(sheath is Node3D and sheath.get_parent()==rig.torso, "Scabbard not attached to torso")
            assert(sheath.position.z > 0.26, "Scabbard has intersected body front")
            assert(not sheath.visible, "Scabbard must not duplicate a drawn weapon")
        else:
            assert(sheath == null, "Unexpected generic scabbard "+weapon_id)
    assert(Identity.paint({"robe":5,"skin":5,"hair":5}).get_width()==256)
    var registry: Dictionary = SkillRegistry.catalog
    assert(registry.skills.salto_impetuoso.phases.movement.event=="exo_salto_movement")
    assert(ResourceLoader.exists("res://assets/exo_legacy/energy_impact.ogg"))
    rig.queue_free()
    await process_frame
    await process_frame
    print("QA 09.3.2 PASS: weapon mounts, identity palette, EXO audio resources")
    quit()
