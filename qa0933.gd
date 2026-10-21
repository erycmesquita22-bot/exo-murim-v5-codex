extends SceneTree
# Validate attachment invariants with the actual Godot scene tree.
# Run: godot --headless --path . --script res://qa0933.gd
const Rig = preload("res://rig.gd")
const Wardrobe = preload("res://wardrobe.gd")
const Arsenal = preload("res://arsenal.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var rig: Node3D = Rig.new()
	root.add_child(rig)
	var profile: Dictionary = {"race":0,"robe":1,"hair":4,"skin":3,"style":0,"weapon":"sword","outfit":0,"haircut":0,"body":0,"eyes":2}
	for weapon_id in ["sword", "katana", "dagger", "twin_daggers", "greatsword", "quarterstaff", "spear", "bow", "crossbow", "gauntlets"]:
		profile["weapon"] = weapon_id
		Wardrobe.apply(rig, profile)
		var weapon_root_value: Variant = rig.get_meta("weapon_root") if rig.has_meta("weapon_root") else null
		assert(weapon_root_value is Node3D, "Missing weapon root: " + weapon_id)
		var weapon_root: Node3D = weapon_root_value as Node3D
		var pose: String = str(preload("res://catalog.gd").weapon(weapon_id).get("pose", ""))
		if pose in ["bow", "crossbow"]:
			assert(weapon_root.get_parent() == rig.torso, "Ranged weapon must have a torso grip target")
			Arsenal.ranged_pose(rig, pose, 0.3)
			for i in range(2):
				assert(rig.arms[i].scale.distance_to(Vector3.ONE) < 0.001, "Arm stretched for " + weapon_id)
				assert(rig.forearms[i].scale.distance_to(Vector3.ONE) < 0.001, "Forearm stretched for " + weapon_id)
		else:
			assert(weapon_root.get_parent() == rig.forearms[0], "Melee weapon not mounted to forearm: " + weapon_id)
		var sheath_value: Variant = rig.get_meta("carry_sheath") if rig.has_meta("carry_sheath") else null
		if weapon_id in ["sword", "katana"]:
			assert(sheath_value is Node3D, "Missing scabbard")
			var sheath: Node3D = sheath_value as Node3D
			assert(sheath.get_parent() == rig.torso, "Scabbard disconnected from torso")
			assert(sheath.position.z >= 0.38, "Scabbard too close to chest")
			assert(not sheath.visible, "Scabbard must begin hidden while weapon is drawn")
		else:
			assert(sheath_value == null, "Incompatible generic scabbard: " + weapon_id)
		assert(rig.get_meta("weapon_nodes", []).size() > 0, "Empty weapon resources")
	print("QA 09.3.3 PASS: no arm scaling, weapon lifecycle and back mounts")
	rig.queue_free()
	quit()
