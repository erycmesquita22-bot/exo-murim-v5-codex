extends "res://modules/active_skills/skills.gd"
const Motion = preload("res://modules/murim_footwork/motion.gd")
const NewUI = preload("res://modules/murim_footwork/catalog_ui.gd")
var root_previous := Vector3.ZERO
var queued_strike := false
func configure(controller):
	super.configure(controller)
	for id in ["sword_footwork","qi_palm"]:
		var skill: Resource = load("res://modules/murim_footwork/definitions/"+id+".tres")
		catalog.append(skill);cooldowns[skill.skill_id] = 0.0
		var action := "skill_"+str(catalog.size())
		if not InputMap.has_action(action): InputMap.add_action(action)
		if InputMap.action_get_events(action).is_empty():
			var key := InputEventKey.new();key.physical_keycode = KEY_1+catalog.size()-1;InputMap.action_add_event(action,key)
	var old_qi: Resource = catalog[1]
	catalog[1] = catalog[4];catalog[4] = old_qi
	ui.get_parent().remove_child(ui);ui.queue_free()
	ui = NewUI.new();host.hud.get_parent().add_child(ui);ui.configure(self);ui.refresh()
func begin(skill: Resource):
	var selected := skill.duplicate()
	if selected.skill_id == &"sword_footwork": selected.animation = &"Skill_Sword_Footwork_Novice" if host.sword_mastery < .5 else &"Skill_Sword_Footwork_Trained"
	root_previous = Vector3.ZERO
	super.begin(selected)
func pre_tick(delta: float):
	var catalog_visible: bool = ui.panel.visible
	super.pre_tick(delta)
	if ui.panel.visible != catalog_visible and not host.headless: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if ui.panel.visible else Input.MOUSE_MODE_CAPTURED
	if queued_strike and active == null and pending == null and host.action_kind.is_empty() and host.health.stun <= 0 and not host.health.dead:
		queued_strike = false;request(3)
func post_tick(delta: float):
	if active != null and active.skill_id == &"sword_footwork" and host.action_kind == str(active.animation) and host.health.freeze <= 0 and host.health.stun <= 0:
		var p := Motion.sample("novice" if str(active.animation).ends_with("Novice") else "trained",phase())
		host.actor.move_and_collide(Motion.world_delta(host.action_direction,p-root_previous));root_previous = p
	super.post_tick(delta)
	if active != null and active.skill_id == &"qi_palm": charge.visible = false
func launch():
	var palm: bool = active != null and active.skill_id == &"qi_palm"
	super.launch()
	if palm:
		var projectile := projectiles[-1]
		projectile.node.global_position = hand_position("R")+host.forward_vector()*.20
		# Replace the bright orb with compact black/white ink strokes and thin pressure rings.
		for child in projectile.node.get_children(): child.queue_free()
		for i in 5:
			var stroke := MeshInstance3D.new();var mesh := BoxMesh.new();mesh.size = Vector3(.018,.025,.30+i*.035)
			stroke.mesh = mesh;stroke.material_override = effects.material(Color(.03,.04,.06,.9) if i%2==0 else Color(.9,.97,1,.85))
			stroke.position = Vector3(cos(i*1.26)*.12,sin(i*1.26)*.12,0);stroke.rotation.z = i*.7
			projectile.node.add_child(stroke)
func cancel(reason := "interrompida"):
	queued_strike = false
	super.cancel(reason)
