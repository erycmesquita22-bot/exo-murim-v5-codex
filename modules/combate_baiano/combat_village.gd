extends "res://world_sprint07/S07_Haneul_MapController.gd"
## Combate baiano: additive village module, no replacement arena/environment assets.
const Vitals = preload("res://modules/combate_baiano/vitals.gd")
const Sword = preload("res://modules/combate_baiano/sword.gd")
const Enemy = preload("res://modules/combate_baiano/enemy.gd")
const ImpactFX = preload("res://modules/combate_baiano/impact_fx.gd")
var health
var enemy
var sword
var fx
var player_spawn := Vector3.ZERO
var rival_spawn := Vector3.ZERO
var combat_log: Array[Dictionary] = []
var occlusion_time := 0.0
var camera_kick := 0.0
var combat_orbit := 0.0
var debug_hitboxes := false
var debug_nodes: Array[Node3D] = []
var health_text: Label
var total_queries := 0
var confirmed_contacts := 0
var ai_started := false
func configure_input() -> void:
	super.configure_input()
	for pair in [["guard",KEY_F],["retry",KEY_R],["hitboxes",KEY_F6]]:
		if not InputMap.has_action(pair[0]): InputMap.add_action(pair[0])
		InputMap.action_erase_events(pair[0])
		var key := InputEventKey.new()
		key.physical_keycode = pair[1]
		InputMap.action_add_event(pair[0],key)
func _ready() -> void:
	super._ready()
	validating = false # isolated V3 replay is superseded by the combat QA suite
	name = "CombateBaiano"
	camera_distance = 5.2
	camera.position.x = .85
	pitch = -.24
	actor.collision_layer = 2
	actor.collision_mask = 1|4
	actor.get_child(0).shape.radius = .55
	if is_instance_valid(target):
		remove_child(target)
		target.queue_free()
	health = Vitals.new()
	health.name = "PlayerVitals"
	add_child(health)
	fx = ImpactFX.new()
	add_child(fx)
	var definition: Resource = load("res://modules/combate_baiano/sword.tres")
	sword = Sword.new()
	add_child(sword)
	sword.configure(self,definition,Color("d8eff2"))
	enemy = Enemy.new()
	enemy.name = "RivalSameV4Rig"
	add_child(enemy)
	enemy.combat = self
	enemy.vitals = Vitals.new()
	enemy.vitals.maximum = 160
	enemy.vitals.reset()
	enemy.add_child(enemy.vitals)
	enemy.sword = Sword.new()
	enemy.add_child(enemy.sword)
	enemy.sword.configure(enemy,definition,Color("e9ac83"))
	player_spawn = actor.position
	rival_spawn = player_spawn+Vector3(0,0,8)
	enemy.reset_ai(rival_spawn)
	target = enemy.actor
	register_hurtbox(self,8)
	register_hurtbox(enemy,16)
	health_text = Label.new()
	health_text.position = Vector2(22,145)
	health_text.add_theme_color_override("font_shadow_color",Color("18242a"))
	health_text.add_theme_constant_override("shadow_offset_x",2)
	health_text.add_theme_constant_override("shadow_offset_y",2)
	hud.get_parent().add_child(health_text)
	focus_label.position.y = 240
	print("COMBATE_BAIANO_READY bones=",skeleton.get_bone_count()," enemy_bones=",enemy.skeleton.get_bone_count())
func register_hurtbox(controller, layer_mask: int) -> void:
	var area := Area3D.new()
	area.name = "CombatHurtbox"
	area.collision_layer = layer_mask
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = true
	area.set_meta("controller",controller)
	var capsule := CapsuleShape3D.new()
	capsule.radius = .39
	capsule.height = 2.6
	var shape := CollisionShape3D.new()
	shape.shape = capsule
	shape.position.y = 1.30
	area.add_child(shape)
	controller.actor.add_child(area)
func stats(controller):
	return health if controller == self else controller.vitals
func start_action(clip: String) -> void:
	if health != null and health.dead and clip != "Defeat": return
	super.start_action(clip)
	if sword != null and clip.begins_with("Sword_Attack"):
		health.set_guard(false)
		sword.begin_swing()
func desired_direction() -> Vector3:
	var result := super.desired_direction()
	if health != null and health.blocking: result *= .45
	return result
func attack_request() -> void:
	if health != null and (health.dead or health.stun > 0 or health.blocking): return
	super.attack_request()
func try_hit() -> void:
	# Old single-distance/cone target test deliberately disabled in this scene.
	pass
func update_target(_delta: float) -> void:
	pass
func _physics_process(delta: float) -> void:
	if health == null: return
	if Input.is_action_just_pressed("retry"): reset_duel()
	if Input.is_action_just_pressed("hitboxes"): debug_hitboxes = not debug_hitboxes
	for node in debug_nodes: node.queue_free()
	debug_nodes.clear()
	health.tick(delta)
	health.set_guard(Input.is_action_pressed("guard") and armed and action_kind.is_empty() and not travel_mode and not health.dead and health.stun <= 0)
	if health.dead:
		simulation_time += delta
		tick_down(self,delta)
		update_camera(delta)
		finish_frame(delta)
	elif health.freeze > 0:
		simulation_time += delta
		update_camera(delta)
		finish_frame(delta)
	elif health.stun > 0:
		simulation_time += delta
		tick_stunned(self,delta)
		update_camera(delta)
		finish_frame(delta)
	else:
		super._physics_process(delta)
	process_sword(self,sword,enemy,delta,not health.dead and health.stun <= 0)
	camera_kick = maxf(0,camera_kick-delta*2.5)
func can_see(a: Node3D, b: Node3D) -> bool:
	var q := PhysicsRayQueryParameters3D.create(a.global_position+Vector3(0,1.35,0),b.global_position+Vector3(0,1.35,0),1)
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()
func process_sword(controller, weapon, defender, delta: float, permitted: bool) -> void:
	var phase: float = controller.action_time/controller.action_duration
	weapon.active = permitted and controller.armed and controller.action_kind.begins_with("Sword_Attack") and phase >= weapon.definition.active_start and phase <= weapon.definition.active_end
	if weapon.active and weapon.sounded_serial != weapon.serial:
		weapon.sounded_serial = weapon.serial
		fx.sound("swing",controller.actor.position+Vector3.UP)
	var p: Array[Vector3] = weapon.update_visual(delta)
	if weapon.active and not stats(defender).dead:
		var old_base: Vector3 = weapon.previous_base if weapon.sampled else p[0]
		var old_tip: Vector3 = weapon.previous_tip if weapon.sampled else p[1]
		var steps := mini(32,maxi(1,int(ceil(maxf(p[0].distance_to(old_base),p[1].distance_to(old_tip))/.09))))
		for i in range(1,steps+1):
			var fraction := float(i)/steps
			query_blade(controller,weapon,old_base.lerp(p[0],fraction),old_tip.lerp(p[1],fraction),defender)
	weapon.previous_base = p[0]
	weapon.previous_tip = p[1]
	weapon.sampled = true
func query_blade(controller, weapon, base: Vector3, tip: Vector3, defender) -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius = weapon.definition.query_radius
	capsule.height = base.distance_to(tip)+capsule.radius*2
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = Transform3D(Basis(Quaternion(Vector3.UP,(tip-base).normalized())),(base+tip)*.5)
	query.collision_mask = 16 if controller == self else 8
	query.collide_with_areas = true
	query.collide_with_bodies = false
	total_queries += 1
	if debug_hitboxes and debug_nodes.size() < 12:
		var debug := MeshInstance3D.new()
		var mesh := CapsuleMesh.new()
		mesh.radius = capsule.radius
		mesh.height = capsule.height
		debug.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(1,.3,.1,.25)
		debug.material_override = mat
		add_child(debug)
		debug.global_transform = query.transform
		debug_nodes.append(debug)
	for contact in get_world_3d().direct_space_state.intersect_shape(query,8):
		var area: Area3D = contact.collider
		if not area.has_meta("controller"): continue
		var victim = area.get_meta("controller")
		if victim != defender or weapon.victims.has(victim.get_instance_id()): continue
		if not can_see(controller.actor,victim.actor): continue
		weapon.victims[victim.get_instance_id()] = true
		confirmed_contacts += 1
		var center: Vector3 = victim.actor.global_position+Vector3(0,1.3,0)
		var point := Geometry3D.get_closest_point_to_segment(center,base,tip)
		receive_damage(victim,controller,weapon,point)
func receive_damage(victim, attacker, weapon, at: Vector3) -> String:
	var status = stats(victim)
	if status.dead: return "dead"
	var attacking_clip: String = attacker.action_kind
	var attack_phase: float = attacker.action_time/attacker.action_duration
	var outcome := "hit"
	var damage: int = weapon.definition.damage_for_clip(attacker.action_kind)
	var direction: Vector3 = ((victim.actor.position-attacker.actor.position)*Vector3(1,0,1)).normalized()
	if victim.dodge_invulnerable:
		status.evade_count += 1
		outcome = "evade"
	else:
		var front: float = victim.forward_vector().dot(-direction)
		if status.blocking and front > .2 and status.stamina >= 20:
			status.stamina -= 20
			status.block_count += 1
			if status.block_time <= .13:
				status.parry_count += 1
				victim.start_action("Parry")
				outcome = "parry"
				damage = 0
				stats(attacker).stun = .30
				attacker.hit_variant = "Hit_Reaction"
				attacker.start_action("Hit_Reaction")
				if attacker == enemy:
					enemy.state = "RECOVER"
					enemy.state_time = 0
					enemy.state_limit = .35
			else:
				outcome = "block"
				damage = maxi(1,int(damage*.2))
				victim.start_action("Block_Recoil")
			fx.impact(at,direction,true)
		else:
			status.hurt_count += 1
			status.stun = .38
			status.freeze = .035
			status.set_guard(false)
			var local_hit: Vector3 = victim.visual.global_basis.inverse()*direction
			victim.hit_variant = "Hit_Left" if local_hit.x < -.25 else ("Hit_Right" if local_hit.x > .25 else "Hit_Reaction")
			victim.start_action("Hit_Reaction")
			if victim == enemy:
				enemy.state = "GUARD" if status.hurt_count%2 == 0 else "RECOVER"
				enemy.state_time = 0
				enemy.state_limit = .35 if enemy.state == "GUARD" else .22
				enemy.states_seen[enemy.state] = true
				enemy.strikes = 0
			victim.actor.move_and_collide(direction*.18)
			fx.impact(at,direction,false)
		status.hp = maxi(0,status.hp-damage)
		stats(attacker).freeze = .025
		camera_kick = .13
		if status.hp == 0:
			status.dead = true
			status.stun = 0
			victim.start_action("Defeat")
			victim.tree.active = false
			victim.player.play("Defeat")
			victim.player.seek(0,true)
			victim.player.pause()
			locked = false
	combat_log.append({"time":simulation_time,"attacker":"player" if attacker == self else "rival","outcome":outcome,"damage":0 if outcome == "evade" else damage,"hp_after":status.hp,"swing":weapon.serial,"clip":attacking_clip,"phase":attack_phase,"point":vec(at)})
	return outcome
func tick_stunned(controller, delta: float) -> void:
	controller.action_time += delta
	if controller.action_time >= controller.action_duration: controller.action_kind = ""
	controller.actor.velocity.x = move_toward(controller.actor.velocity.x,0,30*delta)
	controller.actor.velocity.z = move_toward(controller.actor.velocity.z,0,30*delta)
	controller.actor.velocity.y = -.2 if controller.actor.is_on_floor() else controller.actor.velocity.y-GRAVITY*delta
	controller.actor.move_and_slide()
	controller.actual_speed = Vector2(controller.actor.get_real_velocity().x,controller.actor.get_real_velocity().z).length()
	controller.update_animation(delta)
func tick_down(controller, delta: float) -> void:
	controller.travel_mode = false
	controller.travel_pending = false
	controller.dodge_invulnerable = false
	controller.actual_speed = 0
	controller.actor.velocity = Vector3(0,-.2 if controller.actor.is_on_floor() else controller.actor.velocity.y-GRAVITY*delta,0)
	controller.actor.move_and_slide()
	controller.action_time = minf(controller.action_time+delta,controller.motion_config.Defeat.duration)
	controller.tree.active = false
	controller.player.play("Defeat")
	controller.player.seek(controller.action_time,true)
	controller.player.pause()
	controller.skeleton.force_update_all_bone_transforms()
	controller.apply_weapon_anchor()

func update_camera(delta: float) -> void:
	if enemy != null:
		var distance: float = actor.position.distance_to(enemy.actor.position)
		if locked:
			occlusion_time = 0 if can_see(actor,enemy.actor) else occlusion_time+delta
			if distance > 18 or enemy.vitals.dead or health.dead or occlusion_time > .8: locked = false
		elif Input.is_action_just_pressed("lock") and (distance > 14 or enemy.vitals.dead or not can_see(actor,enemy.actor)):
			locked = false
	super.update_camera(delta)
	combat_orbit = lerpf(combat_orbit,.34 if locked else 0.0,1-exp(-delta*5))
	pivot.rotation.y += combat_orbit
	boom.position.x = lerpf(boom.position.x,.8 if locked else .35,1-exp(-delta*6))
	if locked and enemy != null:
		var midpoint: Vector3 = actor.position.lerp(enemy.actor.position,.27)+Vector3(0,1.65,0)
		pivot.position = pivot.position.lerp(midpoint,1-exp(-delta*5))
	camera.h_offset = sin(simulation_time*103)*camera_kick*.25
	camera.v_offset = sin(simulation_time*87)*camera_kick*.18
func finish_frame(delta: float) -> void:
	super.finish_frame(delta)
	if health == null or health_text == null: return
	hud.text = "EXO-MURIM / COMBATE BAIANO\nWASD mover · Shift correr · Espaço pular · Clique golpe · E espada\nQ esquiva · F defender (toque preciso: aparar) · Tab foco · V viagem · R reiniciar"
	health_text.text = "VIDA  %d/%d   DEFESA  %d/100\nRIVAL  %d/%d" % [health.hp,health.maximum,int(health.stamina),enemy.vitals.hp,enemy.vitals.maximum]
	if health.dead: health_text.text += "\nVOCÊ CAIU — R para tentar novamente"
	elif enemy.vitals.dead: health_text.text += "\nRIVAL DERROTADO — R para novo duelo"
	elif travel_mode: health_text.text += "\nVIAGEM"
	focus_label.text = "FOCO NO RIVAL" if locked else ""
func reset_duel() -> void:
	health.reset()
	actor.position = player_spawn
	actor.velocity = Vector3.ZERO
	visual.position.y = -.125
	neutral = false
	tree.active = true
	armed = false
	locked = false
	travel_mode = false
	travel_pending = false
	action_kind = ""
	action_weight = 0
	attack_buffer = 0
	dodge_buffer = 0
	jump_buffer = 0
	dodge_invulnerable = false
	enemy.tree.active = true
	enemy.reset_ai(rival_spawn)
	sword.victims.clear()
	enemy.sword.victims.clear()
	sword.sampled = false
	enemy.sword.sampled = false
	combat_log.append({"time":simulation_time,"event":"retry"})

func can_lock_target() -> bool:
	return locked or (enemy != null and not enemy.vitals.dead and not health.dead and actor.position.distance_to(enemy.actor.position) <= 14 and can_see(actor,enemy.actor))

func motion_guarding() -> bool:
	return health != null and health.blocking
