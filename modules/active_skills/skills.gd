extends Node
signal skill_started(skill_id: StringName)
signal skill_finished(skill_id: StringName, interrupted: bool)
signal skill_hit(skill_id: StringName, outcome: String)
const FX = preload("res://modules/active_skills/effects.gd")
const UI = preload("res://modules/active_skills/catalog_ui.gd")
class Contact extends RefCounted:
	var definition: Resource
	var serial := 0
	var victims: Dictionary = {}
var host
var catalog: Array[Resource] = []
var cooldowns: Dictionary = {}
var active: Resource
var pending: Resource
var pending_restore := false
var restore_requested := false
var maximum_qi := 100.0
var qi := 100.0
var regeneration := 9.0
var feedback := ""
var feedback_time := 0.0
var payload: Contact
var serial := 0
var previous_points: Array[Vector3] = []
var lunge_previous := 0.0
var fired := false
var effects
var charge: Node3D
var ui
var projectiles: Array[Dictionary] = []
var log: Array[Dictionary] = []
func configure(controller):
	host = controller
	catalog.assign(load("res://modules/active_skills/catalog.tres").entries)
	for skill in catalog:
		assert(skill.is_valid_definition());assert(not cooldowns.has(skill.skill_id))
		cooldowns[skill.skill_id] = 0.0
	for i in mini(catalog.size(),9):
		var action := "skill_"+str(i+1)
		if not InputMap.has_action(action): InputMap.add_action(action)
		if InputMap.action_get_events(action).is_empty():
			var key := InputEventKey.new();key.physical_keycode = KEY_1+i;InputMap.action_add_event(action,key)
	if not InputMap.has_action("skill_catalog"):
		InputMap.add_action("skill_catalog");var key := InputEventKey.new();key.physical_keycode = KEY_K;InputMap.action_add_event("skill_catalog",key)
	effects = FX.new();host.add_child(effects)
	charge = effects.orb(Color(.67,.88,1));effects.add_child(charge);charge.visible = false
	ui = UI.new();host.hud.get_parent().add_child(ui);ui.configure(self);ui.refresh()
func notify(message: String): feedback = message;feedback_time = 1.6
func request(index: int) -> bool:
	if index < 0 or index >= catalog.size(): return false
	var skill = catalog[index]
	if active != null or pending != null or not host.action_kind.is_empty(): notify("Conclua a ação atual.");return false
	if host.health.dead or host.health.stun > 0 or host.health.freeze > 0 or host.neutral or not host.actor.is_on_floor(): notify("Sem apoio para executar a arte.");return false
	if cooldowns[skill.skill_id] > 0: notify("Arte em recuperação.");return false
	if qi < skill.qi_cost: notify("Qi insuficiente.");return false
	host.travel_mode = false;host.travel_pending = false;host.health.set_guard(false)
	var sword_needed: bool = skill.delivery == "blade"
	pending_restore = host.armed and not sword_needed
	if host.armed != sword_needed:
		pending = skill
		host.queued_after_draw = false;host.attack_buffer = 0
		host.start_action("Sword_Draw" if sword_needed else "Sword_Sheath")
		notify("Preparando "+skill.display_name)
		return true
	begin(skill)
	return true
func begin(skill: Resource):
	active = skill;pending = null;qi -= skill.qi_cost;cooldowns[skill.skill_id] = skill.cooldown
	serial += 1;payload = Contact.new();payload.definition = skill;payload.serial = serial
	previous_points.clear();lunge_previous = 0;fired = false
	host.attack_buffer = 0;host.dodge_buffer = 0;host.jump_buffer = 0
	host.start_action(str(skill.animation))
	log.append({"event":"start","id":skill.skill_id,"qi":qi,"time":host.simulation_time})
	skill_started.emit(skill.skill_id);notify(skill.display_name)
func cancel(reason := "interrompida"):
	pending = null
	if active == null: return
	var skill = active
	if host.action_kind == str(skill.animation): host.action_kind = ""
	active = null;charge.visible = false;host.sword.active = false;previous_points.clear()
	restore_requested = pending_restore;pending_restore = false
	log.append({"event":"cancel","id":skill.skill_id,"reason":reason,"time":host.simulation_time})
	skill_finished.emit(skill.skill_id,true)
func finish():
	var skill = active;active = null;charge.visible = false;host.sword.active = false
	restore_requested = pending_restore;pending_restore = false
	log.append({"event":"finish","id":skill.skill_id,"time":host.simulation_time})
	skill_finished.emit(skill.skill_id,false)
func pre_tick(delta: float):
	for id in cooldowns: cooldowns[id] = maxf(0,cooldowns[id]-delta)
	if not host.health.dead: qi = minf(maximum_qi,qi+regeneration*delta)
	feedback_time = maxf(0,feedback_time-delta)
	if feedback_time == 0: feedback = ""
	if Input.is_action_just_pressed("skill_catalog"): ui.panel.visible = not ui.panel.visible
	if host.health.dead:
		cancel("derrota");restore_requested = false;pending = null
	if pending != null:
		if host.health.stun > 0 or host.health.dead: pending = null
		elif host.action_kind.is_empty():
			if host.armed == (pending.delivery == "blade") and qi >= pending.qi_cost: begin(pending)
			else: pending = null
	if active != null:
		if host.health.stun > 0 or host.health.dead: cancel("impacto")
		elif Input.is_action_just_pressed("jump") or (Input.is_action_just_pressed("dodge") and phase() >= .25): cancel("movimento")
	if restore_requested and active == null and host.action_kind.is_empty() and not host.health.dead and host.health.stun <= 0:
		restore_requested = false
		if not host.armed:
			host.queued_after_draw = false;host.start_action("Sword_Draw")
	for i in catalog.size():
		if Input.is_action_just_pressed("skill_"+str(i+1)): request(i)
func phase() -> float: return clampf(host.action_time/host.action_duration,0,1)
func post_tick(delta: float):
	if active != null:
		if host.action_kind != str(active.animation): finish()
		elif host.health.freeze <= 0 and host.health.stun <= 0:
			var u := phase()
			var lunge: float = smoothstep(.27,.47,u)*active.lunge_distance
			host.actor.move_and_collide(host.action_direction*(lunge-lunge_previous));lunge_previous = lunge
			var window: bool = u >= active.active_start and u <= active.active_end
			if active.delivery == "projectile":
				charge.visible = not fired
				charge.global_position = hand_position("R").lerp(hand_position("L"),.5)
				charge.scale = Vector3.ONE*(.3+minf(1,u/active.active_start))
				charge.rotate_y(delta*8)
				if u >= active.active_start and not fired: launch()
			elif active.delivery == "blade":
				host.sword.active = window
				var points: Array[Vector3] = host.sword.update_visual(delta)
				if window:
					if not fired: fired = true;effects.burst(points[0],host.forward_vector(),active.effect_color,true);host.fx.sound("swing",points[0])
					sweep(points[0],points[1])
				previous_points = points
			else:
				var wrist := hand_position("R")
				var points: Array[Vector3] = [wrist,wrist+host.forward_vector()*.24]
				if window:
					if not fired: fired = true;effects.burst(points[1],host.forward_vector(),active.effect_color);host.fx.sound("swing",points[1])
					sweep(points[0],points[1])
				previous_points = points
	update_projectiles(delta)
	ui.refresh()
func hand_position(side: String) -> Vector3:
	return host.skeleton.global_transform*host.skeleton.get_bone_global_pose(host.skeleton.find_bone("hand_"+side)).origin
func sweep(base: Vector3, tip: Vector3):
	var a: Vector3 = previous_points[0] if not previous_points.is_empty() else base
	var b: Vector3 = previous_points[1] if not previous_points.is_empty() else tip
	var steps := mini(32,maxi(1,int(ceil(maxf(a.distance_to(base),b.distance_to(tip))/.08))))
	for i in range(1,steps+1): host.query_blade(host,payload,a.lerp(base,float(i)/steps),b.lerp(tip,float(i)/steps),host.enemy)
func launch():
	fired = true;charge.visible = false
	var direction: Vector3 = host.forward_vector()
	var at := hand_position("R").lerp(hand_position("L"),.5)+direction*.25
	var node: Node3D = effects.orb(active.effect_color);effects.add_child(node);node.global_position = at
	projectiles.append({"node":node,"direction":direction,"distance":0.0,"contact":payload,"skill":active,"origin":at})
	effects.burst(at,direction,active.effect_color,true);host.fx.sound("swing",at)
	log.append({"event":"projectile_launch","id":active.skill_id,"time":host.simulation_time})
func update_projectiles(delta: float):
	for i in range(projectiles.size()-1,-1,-1):
		var projectile := projectiles[i];var skill = projectile.skill
		var a: Vector3 = projectile.node.global_position
		var travel := minf(skill.projectile_speed*delta,skill.projectile_range-projectile.distance)
		var b: Vector3 = a+projectile.direction*travel
		var world_query := PhysicsShapeQueryParameters3D.new()
		var sphere := SphereShape3D.new();sphere.radius = skill.query_radius
		world_query.shape = sphere;world_query.collision_mask = 1
		world_query.transform = Transform3D(Basis.IDENTITY,a)
		var space: PhysicsDirectSpaceState3D = host.get_world_3d().direct_space_state
		var wall := {}
		if not space.intersect_shape(world_query,1).is_empty():
			b = a;wall = {"position":a}
		else:
			world_query.motion = b-a
			var fractions := space.cast_motion(world_query)
			if fractions[0] < 1:
				b = a+(b-a)*fractions[0];wall = {"position":b}
		var shape := CapsuleShape3D.new();shape.radius = skill.query_radius;shape.height = a.distance_to(b)+shape.radius*2
		var query := PhysicsShapeQueryParameters3D.new();query.shape = shape;query.collision_mask = 16;query.collide_with_areas = true;query.collide_with_bodies = false
		var direction: Vector3 = (b-a).normalized() if a.distance_to(b) > .0001 else Vector3.UP
		query.transform = Transform3D(Basis(Quaternion(Vector3.UP,direction)),(a+b)*.5)
		var touched := false
		for hit in host.get_world_3d().direct_space_state.intersect_shape(query,8):
			if hit.collider.has_meta("controller") and hit.collider.get_meta("controller") == host.enemy and not host.enemy.vitals.dead:
				var old_kind: String = host.action_kind
				var old_time: float = host.action_time;var old_duration: float = host.action_duration
				host.action_kind = str(skill.animation);host.action_time = .5;host.action_duration = 1
				var outcome: String = host.receive_damage(host.enemy,host,projectile.contact,b)
				if host.action_kind == str(skill.animation): host.action_kind = old_kind;host.action_time = old_time;host.action_duration = old_duration
				log.append({"event":"projectile_contact","id":skill.skill_id,"outcome":outcome,"time":host.simulation_time})
				skill_hit.emit(skill.skill_id,outcome);touched = true;break
		projectile.node.global_position = b;projectile.node.rotate_y(delta*10);projectile.distance += travel
		if touched or not wall.is_empty() or projectile.distance >= skill.projectile_range or host.health.dead:
			effects.burst(b,projectile.direction,skill.effect_color,true)
			log.append({"event":"projectile_end","reason":"hit" if touched else ("wall" if not wall.is_empty() else "range"),"time":host.simulation_time})
			projectile.node.queue_free();projectiles.remove_at(i)
func reset():
	cancel("reinício");pending = null;restore_requested = false;pending_restore = false
	for projectile in projectiles: projectile.node.queue_free()
	projectiles.clear();qi = maximum_qi;charge.visible = false
	for id in cooldowns: cooldowns[id] = 0.0
