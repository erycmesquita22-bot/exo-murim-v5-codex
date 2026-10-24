extends "res://modules/murim_footwork/village.gd"
const FrenzyMotion = preload("res://modules/sword_frenzy/motion.gd")
const FrenzySkills = preload("res://modules/sword_frenzy/skills.gd")
const FrenzyEnemy = preload("res://modules/sword_frenzy/enemy.gd")
func install_motion_library() -> void:
	super.install_motion_library();FrenzyMotion.install(self)
func _ready():
	super._ready()
	for node in [skills.ui,skills.effects,skills]: node.get_parent().remove_child(node);node.queue_free()
	skills = FrenzySkills.new();add_child(skills);skills.configure(self)
	enemy.get_parent().remove_child(enemy);enemy.queue_free()
	enemy = FrenzyEnemy.new();add_child(enemy);enemy.combat = self
	enemy.vitals = Vitals.new();enemy.vitals.maximum = 160;enemy.vitals.reset();enemy.add_child(enemy.vitals)
	enemy.sword = Sword.new();enemy.add_child(enemy.sword);enemy.sword.configure(enemy,load("res://modules/combate_baiano/sword.tres"),Color("e9ac83"))
	enemy.reset_ai(rival_spawn);target = enemy.actor;register_hurtbox(enemy,16)
func attack_request() -> void:
	if footwork_mode and skills != null:
		if skills.active != null and skills.active.skill_id == &"sword_frenzy": skills.frenzy_buffer = .35
		else: skills.request(5)
		return
	super.attack_request()
func desired_direction() -> Vector3:
	if skills != null and skills.active != null and skills.active.skill_id == &"sword_frenzy": return Vector3.ZERO
	return super.desired_direction()
func process_sword(controller, weapon, defender, delta: float, permitted: bool) -> void:
	if controller == enemy and controller.action_kind.begins_with("Skill_Sword_Frenzy"):
		var u: float = controller.action_time/controller.action_duration
		weapon.active = permitted and u >= .30 and u <= .65
		if weapon.active and weapon.sounded_serial != weapon.serial:
			weapon.sounded_serial = weapon.serial;fx.sound("swing",controller.actor.position+Vector3.UP)
		var points: Array[Vector3] = weapon.update_visual(delta)
		if weapon.active:
			var a: Vector3 = weapon.previous_base if weapon.sampled else points[0]
			var b: Vector3 = weapon.previous_tip if weapon.sampled else points[1]
			var steps := mini(32,maxi(1,int(ceil(maxf(a.distance_to(points[0]),b.distance_to(points[1]))/.08))))
			for i in range(1,steps+1): query_blade(controller,weapon,a.lerp(points[0],float(i)/steps),b.lerp(points[1],float(i)/steps),defender)
		weapon.previous_base = points[0];weapon.previous_tip = points[1];weapon.sampled = true
		return
	super.process_sword(controller,weapon,defender,delta,permitted)
