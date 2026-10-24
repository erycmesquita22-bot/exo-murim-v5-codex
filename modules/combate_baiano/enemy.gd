extends "res://modules/character_core_v3/V3_Controller.gd"
## Reuses original geometry/UVs/rig/clips, animation tree, equipment anchors and poses.
var combat
var vitals
var sword
var ai_enabled := true
var state := "APPROACH"
var state_time := 0.0
var state_limit := .3
var strikes := 0
var attack_index := 2
var dodge_wait := 0.0
var home := Vector3.ZERO
var nameplate: Label3D
var states_seen: Dictionary = {}
var rng := RandomNumberGenerator.new()
var side_sign := 1.0
func _ready() -> void:
	motion_config = JSON.parse_string(FileAccess.get_file_as_string("res://modules/character_core_v3/motion_config.json"))
	initialize_character()
	actor.name = "RivalBody"
	actor.collision_layer = 4
	actor.collision_mask = 1|2
	actor.get_child(0).shape.radius = .55
	armed = true
	stance_blend = 1
	visual.rotation.y = PI
	rng.seed = 7291
	var cloth: StandardMaterial3D
	for node in visual.find_children("*","MeshInstance3D",true,false):
		if node.name.begins_with("BODY") or node.name.begins_with("LEG") or node.name.begins_with("SKIRT") or node.name.begins_with("FRONT") or node.name.begins_with("SASH"):
			if cloth == null:
				cloth = node.mesh.surface_get_material(0).duplicate()
				cloth.albedo_color = Color(.74,.38,.34)
			node.material_override = cloth
	nameplate = Label3D.new()
	nameplate.position.y = 3.05
	nameplate.pixel_size = .0035
	nameplate.font_size = 38
	nameplate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	actor.add_child(nameplate)
	update_animation(1.0/60)
func change_state(next: String, duration := .3) -> void:
	state = next
	state_time = 0
	state_limit = duration
	states_seen[state] = true
	if state == "WINDUP":
		attack_index = (attack_index+1)%5
		start_action(["Sword_Attack_01","Sword_Attack_02","Sword_Attack_03","Sword_Attack_04","Sword_Attack_05"][attack_index])
		action_rate = 1.22
		action_duration = motion_config[action_kind].duration/action_rate
		tree.set("parameters/ActionSpeed/scale",action_rate)
		if sword: sword.begin_swing()
	elif state == "DODGE":
		var away: Vector3 = (actor.position-combat.actor.position)*Vector3(1,0,1)
		var intended := (away.normalized()*.35+away.normalized().cross(Vector3.UP)*side_sign).normalized()
		var camera_relative := Basis(Vector3.UP,yaw).inverse()*intended
		move_input = Vector2(camera_relative.x,camera_relative.z)
		start_action("Dodge")
		move_input = Vector2.ZERO
		dodge_wait = 1.6
	elif state in ["GUARD","APPROACH","RECOVER","RETURN"]:
		action_kind = ""
func steer(direction: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state
	var at := actor.position+Vector3(0,1,0)
	var q := PhysicsRayQueryParameters3D.create(at,at+direction*2.0,1)
	if space.intersect_ray(q).is_empty(): return direction
	for angle in [.65,-.65,1.2,-1.2,1.57,-1.57]:
		var candidate := direction.rotated(Vector3.UP,angle*side_sign)
		q.to = at+candidate*1.8
		if space.intersect_ray(q).is_empty(): return candidate
	return Vector3.ZERO
func _physics_process(delta: float) -> void:
	if combat == null or vitals == null: return
	vitals.tick(delta)
	simulation_time += delta
	dodge_wait = maxf(0,dodge_wait-delta)
	nameplate.text = "RIVAL\n%d / %d" % [vitals.hp,vitals.maximum]
	nameplate.modulate = Color("ffb36b") if state == "WINDUP" else Color("f5e4d6")
	if state == "WINDUP": nameplate.text += "\nCORTE!"
	if vitals.dead:
		combat.tick_down(self,delta)
		nameplate.text = "DERROTADO"
		sword.active = false
		sword.update_visual(delta)
		return
	if vitals.freeze > 0:
		sword.active = false
		sword.update_visual(delta)
		return
	if vitals.stun > 0:
		combat.tick_stunned(self,delta)
		sword.active = false
		sword.update_visual(delta)
		return
	if not ai_enabled:
		actor.velocity.y = -.2 if actor.is_on_floor() else actor.velocity.y-GRAVITY*delta
		actor.velocity.x = 0
		actor.velocity.z = 0
		actor.move_and_slide()
		update_animation(delta)
		sword.active = false
		sword.update_visual(delta)
		return
	state_time += delta
	var offset: Vector3 = (combat.actor.position-actor.position)*Vector3(1,0,1)
	var distance := offset.length()
	var toward := offset.normalized()
	var direction := Vector3.ZERO
	var speed := 0.0
	var facing := toward
	vitals.set_guard(state == "GUARD")
	if combat.health.dead or distance > 22 or actor.position.distance_to(home) > 26:
		if state != "RETURN": change_state("RETURN")
	match state:
		"APPROACH":
			if distance > 1.65:
				direction = steer(toward)
				speed = 6.2 if distance > 4 else 4.0
			elif combat.can_see(actor,combat.actor):
				if combat.action_kind.begins_with("Sword_Attack") and combat.action_time > .13 and dodge_wait <= 0 and rng.randf() < .35:
					change_state("DODGE")
				elif vitals.stamina < 30:
					change_state("GUARD",.4)
				else: change_state("WINDUP",.34 if strikes == 0 else .25)
		"WINDUP":
			# Show the initial authored windup, then hold it; no damage during anticipation.
			action_time = minf(action_time+delta,action_duration*.17)
			tree.set("parameters/ActionSpeed/scale",action_rate if action_time < action_duration*.17 else 0)
			if state_time >= state_limit:
				state = "STRIKE"
				states_seen[state] = true
				state_time = 0
				tree.set("parameters/ActionSpeed/scale",action_rate)
			if state_time > state_limit*.65: facing = forward_vector()
		"STRIKE":
			action_time += delta
			facing = forward_vector()
			var phase := action_time/action_duration
			direction = action_direction
			speed = 3.4 if phase > .20 and phase < .51 and distance > 1.4 else 0.0
			if phase >= .94:
				strikes += 1
				change_state("RECOVER",.16 if strikes < 2 else .42)
		"RECOVER":
			direction = (-toward*.65+toward.cross(Vector3.UP)*.35*side_sign).normalized()
			speed = 2.1
			if state_time >= state_limit:
				if strikes >= 2:
					strikes = 0
					side_sign *= -1
				change_state("APPROACH")
		"GUARD":
			direction = -toward*.6+toward.cross(Vector3.UP)*.4*side_sign
			speed = 1.6
			if state_time >= state_limit: change_state("APPROACH")
		"DODGE":
			action_time += delta
			direction = action_direction
			speed = 7.5*(1-clampf(action_time/action_duration,0,1))
			facing = forward_vector()
			if action_time >= action_duration: change_state("APPROACH")
		"RETURN":
			var to_home := (home-actor.position)*Vector3(1,0,1)
			direction = steer(to_home.normalized()) if to_home.length() > .5 else Vector3.ZERO
			facing = direction
			speed = 4.5
			if not combat.health.dead and distance < 10 and actor.position.distance_to(home)<23: change_state("APPROACH")
	dodge_invulnerable = state == "DODGE" and action_time >= .04 and action_time <= .25
	actor.velocity.x = move_toward(actor.velocity.x,direction.x*speed,28*delta)
	actor.velocity.z = move_toward(actor.velocity.z,direction.z*speed,28*delta)
	actor.velocity.y = -.2 if actor.is_on_floor() else actor.velocity.y-GRAVITY*delta
	actor.move_and_slide()
	actual_speed = Vector2(actor.get_real_velocity().x,actor.get_real_velocity().z).length()
	if facing.length() > .1: visual.rotation.y = rotate_toward(visual.rotation.y,atan2(facing.x,facing.z),delta*(7 if state == "WINDUP" else 13))
	update_animation(delta)
	combat.process_sword(self,sword,combat,delta,state == "STRIKE")
func reset_ai(at: Vector3) -> void:
	actor.position = at
	actor.velocity = Vector3.ZERO
	visual.position.y = -.125
	armed = true
	neutral = false
	vitals.reset()
	home = at
	strikes = 0
	dodge_wait = 0
	change_state("APPROACH")

func motion_guarding() -> bool:
	return vitals != null and vitals.blocking
