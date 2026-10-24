extends "res://modules/murim_footwork/skills.gd"
const FrenzyUI = preload("res://modules/sword_frenzy/catalog_ui.gd")
const FrenzyMotion = preload("res://modules/sword_frenzy/motion.gd")
var combo_index := 0
var combo_wait := 0.0
var frenzy_buffer := 0.0
var frenzy_previous := Vector3.ZERO
func configure(controller):
	super.configure(controller)
	var skill: Resource = load("res://modules/sword_frenzy/frenzy.tres")
	catalog.append(skill);cooldowns[skill.skill_id] = 0.0
	catalog[3] = catalog[3].duplicate();catalog[3].display_name += " (legado)"
	ui.get_parent().remove_child(ui);ui.queue_free();ui = FrenzyUI.new();host.hud.get_parent().add_child(ui);ui.configure(self);ui.refresh()
	if not InputMap.has_action("skill_6"):
		InputMap.add_action("skill_6");var key := InputEventKey.new();key.physical_keycode = KEY_6;InputMap.action_add_event("skill_6",key)
func begin(skill: Resource):
	var chosen := skill.duplicate()
	if chosen.skill_id == &"sword_frenzy":
		if combo_wait <= 0: combo_index = 0
		chosen.animation = StringName("Skill_Sword_Frenzy_%02d"%(combo_index+1));frenzy_previous = Vector3.ZERO
	super.begin(chosen)
func pre_tick(delta: float):
	combo_wait = maxf(0,combo_wait-delta);frenzy_buffer = maxf(0,frenzy_buffer-delta)
	if active != null and active.skill_id == &"sword_frenzy" and Input.is_action_pressed("attack"): frenzy_buffer = .25
	super.pre_tick(delta)
func post_tick(delta: float):
	if active != null and active.skill_id == &"sword_frenzy" and host.action_kind == str(active.animation) and host.health.freeze <= 0 and host.health.stun <= 0:
		var position := FrenzyMotion.sample("cut"+str(combo_index+1),phase())
		host.actor.move_and_collide(FrenzyMotion.world_delta(host.action_direction,position-frenzy_previous));frenzy_previous = position
	super.post_tick(delta)
	if active != null and active.skill_id == &"sword_frenzy" and combo_index < 2 and phase() >= .82 and frenzy_buffer > 0:
		var next := combo_index+1
		host.action_kind = "";super.finish();combo_index = next;combo_wait = .5;frenzy_buffer = 0
		request(5)
func finish():
	var frenzy: bool = active != null and active.skill_id == &"sword_frenzy"
	super.finish()
	if frenzy: combo_index = 0;combo_wait = 0
func cancel(reason := "interrompida"):
	frenzy_buffer = 0;combo_index = 0;combo_wait = 0
	super.cancel(reason)
