extends "res://modules/combate_baiano/combat_village.gd"
const Skills = preload("res://modules/active_skills/skills.gd")
var skills
func install_motion_library() -> void:
	super.install_motion_library()
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://modules/active_skills/motion_config.json"))
	motion_config.merge(config,true)
	var library: AnimationLibrary = load("res://modules/active_skills/motion_library.tres")
	var current := player.get_animation_library("")
	for clip in library.get_animation_list(): current.add_animation(clip,library.get_animation(clip))
func _ready():
	super._ready()
	skills = Skills.new();add_child(skills);skills.configure(self)
	print("ACTIVE_SKILLS_READY ids=",skills.cooldowns.keys())
func _physics_process(delta: float):
	if skills != null: skills.pre_tick(delta)
	super._physics_process(delta)
	if skills != null: skills.post_tick(delta)
func start_action(clip: String) -> void:
	if skills != null:
		if skills.active != null and clip != str(skills.active.animation):
			if clip not in ["Hit_Reaction","Defeat","Dodge","Parry","Block_Recoil"]: return
			skills.cancel("ação: "+clip)
		if skills.pending != null and clip not in ["Sword_Draw","Sword_Sheath"]: skills.pending = null
	super.start_action(clip)
func attack_request() -> void:
	if skills != null and (skills.active != null or skills.pending != null): return
	super.attack_request()
func toggle_travel() -> void:
	if skills != null and (skills.active != null or skills.pending != null): return
	super.toggle_travel()
func process_sword(controller, weapon, defender, delta: float, permitted: bool) -> void:
	if skills != null and controller == self and skills.active != null:
		weapon.active = false
		return
	super.process_sword(controller,weapon,defender,delta,permitted)
func receive_damage(victim, attacker, weapon, at: Vector3) -> String:
	var result := super.receive_damage(victim,attacker,weapon,at)
	if skills != null and attacker == self and weapon is Skills.Contact:
		skills.log.append({"event":"hit","id":weapon.definition.skill_id,"outcome":result,"time":simulation_time})
		skills.skill_hit.emit(weapon.definition.skill_id,result)
	return result
func reset_duel() -> void:
	if skills != null: skills.reset()
	super.reset_duel()
