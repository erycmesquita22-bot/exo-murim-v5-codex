extends "res://modules/active_skills/skills_village.gd"
const Motion = preload("res://modules/murim_footwork/motion.gd")
const NewSkills = preload("res://modules/murim_footwork/skills.gd")
const NewEnemy = preload("res://modules/murim_footwork/enemy.gd")
@export_range(0,1) var sword_mastery := 0.0
@export var footwork_mode := true
func install_motion_library() -> void:
	super.install_motion_library();Motion.install(self)
func _ready():
	super._ready()
	# Dispose siblings owned by the previous manager before attaching the additive upgrade.
	for node in [skills.ui,skills.effects,skills]: node.get_parent().remove_child(node);node.queue_free()
	skills = NewSkills.new();add_child(skills);skills.configure(self)
	enemy.get_parent().remove_child(enemy);enemy.queue_free()
	enemy = NewEnemy.new();add_child(enemy);enemy.combat = self
	enemy.vitals = Vitals.new();enemy.vitals.maximum = 160;enemy.vitals.reset();enemy.add_child(enemy.vitals)
	enemy.sword = Sword.new();enemy.add_child(enemy.sword);enemy.sword.configure(enemy,load("res://modules/combate_baiano/sword.tres"),Color("e9ac83"))
	enemy.reset_ai(rival_spawn);target = enemy.actor;register_hurtbox(enemy,16)
	for pair in [["mastery_preview",KEY_M],["footwork_mode",KEY_B]]:
		if not InputMap.has_action(pair[0]): InputMap.add_action(pair[0])
		if InputMap.action_get_events(pair[0]).is_empty():
			var key := InputEventKey.new();key.physical_keycode = pair[1];InputMap.action_add_event(pair[0],key)
func _physics_process(delta: float):
	if action_kind.is_empty():
		if Input.is_action_just_pressed("mastery_preview"): sword_mastery = 1.0 if sword_mastery < .5 else 0.0
		if Input.is_action_just_pressed("footwork_mode"): footwork_mode = not footwork_mode
	super._physics_process(delta)
func attack_request() -> void:
	if footwork_mode and skills != null:
		if skills.active != null and skills.active.skill_id == &"sword_footwork":
			if skills.phase() > .45: skills.queued_strike = true
		else: skills.request(3)
		return
	super.attack_request()
func desired_direction() -> Vector3:
	if skills != null and skills.active != null and skills.active.skill_id == &"sword_footwork": return Vector3.ZERO
	return super.desired_direction()
func process_sword(controller, weapon, defender, delta: float, permitted: bool) -> void:
	if controller == enemy and controller.action_kind == "Skill_Sword_Footwork_Trained":
		var u: float = controller.action_time/controller.action_duration
		weapon.active = permitted and u >= .30 and u <= .60
		var points: Array[Vector3] = weapon.update_visual(delta)
		if weapon.active:
			var a: Vector3 = weapon.previous_base if weapon.sampled else points[0]
			var b: Vector3 = weapon.previous_tip if weapon.sampled else points[1]
			var steps := maxi(1,int(ceil(maxf(a.distance_to(points[0]),b.distance_to(points[1]))/.08)))
			for i in range(1,mini(32,steps)+1): query_blade(controller,weapon,a.lerp(points[0],float(i)/mini(32,steps)),b.lerp(points[1],float(i)/mini(32,steps)),defender)
		weapon.previous_base = points[0];weapon.previous_tip = points[1];weapon.sampled = true
		return
	super.process_sword(controller,weapon,defender,delta,permitted)
