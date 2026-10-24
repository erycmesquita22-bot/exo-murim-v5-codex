extends "res://modules/combate_baiano/enemy.gd"
const Motion = preload("res://modules/sword_frenzy/motion.gd")
var frenzy_index := -1
var root_previous := Vector3.ZERO
func install_motion_library() -> void:
	super.install_motion_library();preload("res://modules/murim_footwork/motion.gd").install(self);Motion.install(self)
func change_state(next: String, duration := .3) -> void:
	if next == "WINDUP":
		state = "FOOTWORK";state_time = 0;states_seen[state] = true;root_previous = Vector3.ZERO
		frenzy_index = (frenzy_index+1)%3
		start_action("Skill_Sword_Frenzy_%02d"%(frenzy_index+1))
		if sword: sword.begin_swing()
		return
	super.change_state(next,duration)
func _physics_process(delta: float) -> void:
	if (combat != null and combat.health.dead) or not ai_enabled or state not in ["FOOTWORK","CIRCLE"] or vitals == null or vitals.dead or vitals.stun > 0 or vitals.freeze > 0:
		super._physics_process(delta);return
	vitals.tick(delta);vitals.set_guard(false);simulation_time += delta;state_time += delta
	nameplate.text = "RIVAL\n%d / %d" % [vitals.hp,vitals.maximum]
	actor.velocity = Vector3(0,-.2 if actor.is_on_floor() else actor.velocity.y-GRAVITY*delta,0)
	actor.move_and_slide()
	if state == "FOOTWORK":
		action_time += delta
		var u := clampf(action_time/action_duration,0,1)
		var p := Motion.sample("cut"+str(frenzy_index+1),u)
		actor.move_and_collide(Motion.world_delta(action_direction,p-root_previous));root_previous = p
		nameplate.modulate = Color("ffb36b") if u < .30 else Color.WHITE
		update_animation(delta)
		combat.process_sword(self,sword,combat,delta,true)
		if u >= .82 and frenzy_index < 2:
			frenzy_index += 1;root_previous = Vector3.ZERO
			start_action("Skill_Sword_Frenzy_%02d"%(frenzy_index+1));sword.begin_swing()
		elif u >= 1:
			action_kind = "";state = "CIRCLE";state_time = 0;states_seen[state] = true;side_sign *= -1
	else:
		var toward: Vector3 = ((combat.actor.position-actor.position)*Vector3(1,0,1)).normalized()
		actor.velocity = toward.cross(Vector3.UP)*side_sign*2.2+actor.velocity
		actor.move_and_slide();actual_speed = 2.2
		visual.rotation.y = rotate_toward(visual.rotation.y,atan2(toward.x,toward.z),delta*12)
		update_animation(delta);sword.active = false;sword.update_visual(delta)
		if state_time > .16: change_state("APPROACH")
