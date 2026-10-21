extends RefCounted
# Visual composition only; physics, hit detection and combat timing remain in main.gd.
const Wardrobe = preload("res://wardrobe.gd")

var world: Node3D
var stow_weight: float = 0.0
var ready_weight: float = 0.0
var yaw: float = 0.0
var initialized: bool = false
var aim_hold: float = 0.0

func _init(w: Node3D) -> void:
	world = w

func bare() -> bool:
	return world.flow != null and world.flow.phase == "adventure" and bool(world.current_profile().get("hands_free", false))

func toggle() -> bool:
	if world.flow == null or world.flow.phase != "adventure" or world.health <= 0 or world.attack_time >= 0 or world.roll_time >= 0 or world.techniques.busy() or world.activity.locked():
		world.message("Termine a ação antes de guardar ou retomar a arma.")
		return false
	var profile: Dictionary = world.journey.data.character
	var previous: bool = bool(profile.get("hands_free", false))
	profile["hands_free"] = not previous
	if not world.save_progress():
		profile["hands_free"] = previous
		return false
	world.combo_timeout = 0
	world.combo_queued = false
	world.audio_fx.play_event("equip", "combat", 0.2)
	if profile["hands_free"]:
		world.message("Mãos livres • combo marcial • R retoma o equipamento")
	else:
		world.message("Equipamento retomado • saque ao atacar • R guarda")
	return true

func stowed() -> bool:
	if bare():
		return true
	if world.flow == null or world.flow.phase != "adventure":
		return false
	if world.combat_timer > 0 or world.attack_time >= 0 or world.techniques.busy():
		return false
	var weapon_id: String = str(world.current_profile().get("weapon", "sword"))
	var spec: Dictionary = world.Catalog.weapon(weapon_id)
	return (int(spec.get("hands", 1)) == 1 and str(spec.get("pose", "")) in ["blade", "draw", "reverse", "thrust"]) or weapon_id == "greatsword"

func before_pose(delta: float, movement: Vector3) -> void:
	aim_hold = maxf(0.0, aim_hold - delta)
	if not initialized:
		yaw = world.model.rotation.y
		initialized = true
	if movement.length() > 0.1 and aim_hold <= 0.0 and world.combat_timer <= 0.0 and world.attack_time < 0.0 and world.roll_time < 0.0 and not world.techniques.busy() and not world.activity.locked():
		world.facing = movement.normalized()
	var target: float = atan2(-world.facing.x, -world.facing.z)
	if world.roll_time < 0.0:
		yaw = lerp_angle(yaw, target, 1.0 - exp(-delta * 18.0))
	world.model.rotation.y = yaw
	var transfer_time: float = 0.20
	if world.attack_time >= 0.0 and not bare() and world.attack_hit < 0.20:
		transfer_time = maxf(0.035, world.attack_hit * 0.75)
	stow_weight = move_toward(stow_weight, 1.0 if stowed() else 0.0, delta / transfer_time)
	var equipped: Dictionary = world.Catalog.weapon(str(world.current_profile().get("weapon", "sword")))
	var gloves_relaxed: bool = str(equipped.get("pose", "")) == "fists" and world.combat_timer <= 0.0 and world.attack_time < 0.0
	ready_weight = move_toward(ready_weight, 0.0 if stowed() or bare() or gloves_relaxed else 1.0, delta / 0.18)
	world.model.set_meta("ready_weight", ready_weight)

func finish(_delta: float) -> void:
	var rig: Node3D = world.model
	var state: String = "locomotion"
	if world.activity.locked():
		state = "meditation"
	elif world.roll_time >= 0.0:
		state = "evade"
	elif world.techniques.busy():
		state = "skill"
	elif world.attack_time >= 0.0:
		state = "attack"
	elif not world.player.is_on_floor():
		state = "air"
	rig.set_meta("motion_state", state)
	rig.set_meta("motion_bare", bare())
	rig.set_meta("motion_combo", world.combo_index)
	rig.set_meta("motion_skill", str(world.techniques.casting.get("kind", "")))
	rig.set_meta("motion_skill_time", world.techniques.time)
	Wardrobe.animate_cloth(rig, world.elapsed, world.player.get_real_velocity().length() > 0.1)
	present_equipment(rig)

func present_equipment(rig: Node3D) -> void:
	var spec: Dictionary = world.Catalog.weapon(str(world.current_profile().get("weapon", "sword")))
	var pose: String = str(spec.get("pose", ""))
	var unarmed: bool = bare()
	var concealed: bool = stowed() or world.activity.locked() or unarmed
	var roots: Array = rig.get_meta("carry_roots", [])
	# A weapon is parented to its forearm: never replace its local orientation
	# with a global offset during turns, rolling or running.
	for root_value in roots:
		if not (root_value is Node3D):
			continue
		var node: Node3D = root_value as Node3D
		if not is_instance_valid(node):
			continue
		if pose not in ["bow", "crossbow"]:
			var grip_value: Variant = node.get_meta("grip_transform") if node.has_meta("grip_transform") else null
			if grip_value is Transform3D:
				node.transform = grip_value
		node.visible = not concealed and pose != "fists"
	if pose == "fists":
		for shell_value in rig.get_meta("weapon_nodes", []):
			if shell_value is Node3D:
				var shell: Node3D = shell_value as Node3D
				if is_instance_valid(shell):
					shell.visible = not unarmed and not world.activity.locked()
	var sheath_value: Variant = rig.get_meta("carry_sheath") if rig.has_meta("carry_sheath") else null
	if sheath_value is Node3D:
		var sheath: Node3D = sheath_value as Node3D
		if is_instance_valid(sheath):
			# The torso parent owns position/rotation. Never overwrite a fixed
			# world or pivot transform here (the old cause of floating scabbards).
			# Concealed is not the same as stowed: hide while meditating/unarmed.
			sheath.visible = stowed() and not unarmed and not world.activity.locked()
	rig.set_meta("weapon_stowed", stowed())
	rig.set_meta("stow_weight", stow_weight)
