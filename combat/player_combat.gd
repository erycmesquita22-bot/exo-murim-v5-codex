extends RefCounted
# Combat execution; world remains the scene-facing adapter during this consolidation.
var whooshed:=false
var critical:=false
const Unarmed=preload("res://combat/unarmed.gd")
var world: Node3D
func _init(owner_world: Node3D) -> void:world=owner_world

func start_attack() -> bool:
	if world.activity!=null and world.activity.locked():return false
	if world.get_tree().paused or world.health<=0 or world.roll_time>=0 or world.techniques.busy():
		return false
	var combo_last:=3 if world.current_weapon().pose=="unarmed" else 2
	if world.attack_time>=0:
		if world.attack_time>=.1 and world.combo_index<combo_last:
			world.combo_queued=true
		return false
	world.combo_index=(world.combo_index+1)%(combo_last+1) if world.combo_timeout>0 else 0
	world.attack_spec=world.current_weapon().duplicate(true)
	if world.attack_spec.pose=="unarmed":
		world.attack_spec.duration=Unarmed.STEPS[world.combo_index].duration
		world.attack_spec.hit=Unarmed.STEPS[world.combo_index].hit
		world.attack_spec.damage*=Unarmed.STEPS[world.combo_index].power
	world.attack_duration=float(world.attack_spec.duration)/(1+world.attribute("agilidade")*.02)*(1.15 if world.combo_index==2 and world.attack_spec.pose!="unarmed" else 1.0)
	world.attack_hit=world.attack_duration*float(world.attack_spec.hit)
	world.attack_damage=int(round(world.attack_spec.damage*(1.3 if world.combo_index==2 and world.attack_spec.pose!="unarmed" else 1.0)*world.basic_multiplier()))
	critical=randf()<world.attribute("sorte")*.02
	if critical:
		world.attack_damage=int(round(world.attack_damage*1.5))
	world.combat_timer=maxf(world.combat_timer,4)
	world.attack_time=0
	world.combo_timeout=0
	world.combo_queued=false
	world.attack_direction=world.facing
	world.attack_landed=false
	world.model.rotation.y=atan2(-world.facing.x,-world.facing.z)
	whooshed=false
	return true

func update_attack(delta: float) -> void:
	if world.attack_time<0:
		return
	world.attack_time+=delta
	if not whooshed and world.attack_time>=world.attack_hit-.06:
		whooshed=true
		if world.combo_index==(3 if world.attack_spec.pose=="unarmed" else 2):world.audio_fx.actor_voice(world.model,true)
		if not world.attack_spec.ranged:world.audio_fx.play_event("punch" if world.attack_spec.pose in ["fists","unarmed"] else "blunt_swing" if world.attack_spec.pose in ["staff","pole","crush"] else "swing","combat",.55)
	if world.attack_time>=world.attack_hit and not world.attack_landed:
		world.attack_landed=true
		if world.attack_spec.ranged:
			world.techniques.weapon_shot(world.attack_spec,world.attack_direction,world.attack_damage)
			world.audio_fx.play_event("magia" if world.attack_spec.pose not in ["bow","crossbow"] else "crossbow" if world.attack_spec.pose=="crossbow" else "arrow","magic" if world.attack_spec.pose not in ["bow","crossbow"] else "combat",.5)
			if world.attack_spec.pose=="crossbow":world.audio_fx.play_event("mechanism","combat",.15)
		else:
			if world.attack_spec.pose not in ["fists","unarmed"] and int(world.graphics.values.weapon_trails)>0:world.spawn_arc(world.player.position,world.attack_direction,world.attack_spec.reach,Color("b9cccb"),.09 if int(world.graphics.values.weapon_trails)==1 else .18)
			for actor in world.enemies:
				if actor.hp>0 and world.can_hit(world.player.position,actor.position,world.attack_direction,world.attack_spec.reach,world.attack_spec.cone):
					if actor.hurt(world.attack_damage,world.attack_direction*(4 if world.combo_index==(3 if world.attack_spec.pose=="unarmed" else 2) else 2),0,{"family":"fists" if world.attack_spec.pose=="unarmed" else world.attack_spec.pose,"critical":critical,"heavy":world.combo_index==(3 if world.attack_spec.pose=="unarmed" else 2)}):
						world.combat_timer=4
						world.impact_feedback(.04)
						if int(world.graphics.values.impact_details)>0:
							world.techniques.burst(actor.position+Vector3(0,1,0),Color("e2c58a"),4+int(world.graphics.values.impact_details)*4)
	if world.attack_time>=world.attack_duration:
		var queued: bool=world.combo_queued
		world.attack_time=-1
		world.combo_timeout=.3
		world.combo_queued=false
		if queued and world.combo_index<(3 if world.attack_spec.pose=="unarmed" else 2):
			start_attack()

func start_dash(movement: Vector3=Vector3.ZERO) -> bool:
	if world.activity!=null and world.activity.locked():return false
	if world.techniques.channeling():
		world.techniques.finish()
	if world.get_tree().paused or world.health<=0 or world.roll_time>=0 or (world.attack_time>=0 and world.attack_time<world.attack_hit+0.08) or world.techniques.busy() or world.roll_cooldown>0 or not world.player.is_on_floor():
		return false
	world.attack_time=-1
	world.combo_queued=false
	world.combo_timeout=0
	world.roll_direction=movement.normalized() if movement.length()>0.05 else -world.facing
	var right:=Vector3(-world.facing.z,0,world.facing.x)
	world.roll_lateral=world.roll_direction.dot(right)
	world.roll_forward=world.roll_direction.dot(world.facing)
	world.roll_time=0
	world.roll_cooldown=maxf(.55,world.ROLL_COOLDOWN-(.15 if world.race_body()=="dark" else .1 if world.race_body()=="raven" else 0)-world.attribute("agilidade")*.01)
	world.dodges+=1
	world.audio_fx.play_event("evade","combat",.32)
	# Snapshot the approved articulated rig; pure visual geometry, no collision or gameplay.
	if world.graphics!=null and int(world.graphics.values.afterimages)>0:
		preload("res://exo_visual/afterimage.gd").spawn(world)
	return true

func damage_player(amount: int,context: Dictionary={}) -> bool:
	if world.is_safe(world.player.position):
		return false
	if world.health<=0 or world.get_tree().paused:
		return false
	if world.invulnerability>0 or (world.roll_time>=0.06 and world.roll_time<=0.34):
		world.message("Esquiva!")
		return false
	world.combat_timer=4
	if world.race_body()=="reptile":
		amount=maxi(1,int(round(amount*.9)))
	if amount>0:amount=maxi(1,amount-int(world.equipment_stat("guard")))
	var absorbed: int=mini(amount,int(ceil(world.techniques.shield)))
	world.techniques.shield=maxf(0,world.techniques.shield-absorbed)
	amount-=absorbed
	if absorbed>0:world.cultivation.credit(world.techniques.shield_source)
	if amount>0 and world.has_passive("corpo_1"):world.cultivation.award("corpo_1")
	world.health=maxi(0,world.health-amount)
	world.invulnerability=0.45
	world.impact_feedback(0.06)
	if amount>0:
		var incoming: Dictionary=context.duplicate()
		incoming.fatal=world.health==0
		world.audio_fx.impact(world.model.get_meta("surface","body"),incoming)
		world.audio_fx.actor_voice(world.model)
	world.message("Você recebeu %d de dano." % amount)
	if world.health==0 and world.flow!=null and world.flow.phase=="prologue":
		world.health=world.max_health
		world.invulnerability=2.0
		world.message("A memória da guerra persiste. Continue até a intervenção.")
		return true
	if world.health==0:
		if world.has_method("on_fatal_dungeon_damage"):world.call("on_fatal_dungeon_damage")
		world.save_progress()
		world.message("Você caiu. Retome do último marco sem perder os objetivos concluídos.")
		world.set_paused(true)
	return true

func enemy_orb(origin: Vector3, direction: Vector3, amount: int) -> void:
	var node: MeshInstance3D=world.techniques.sphere(0.2,Color("eea0d8"))
	node.position=origin
	world.hostile_shots.append({"node":node,"direction":direction,"remaining":13.0,"damage":amount})
	world.audio_fx.play_event("magia","magic",.45)

func update_hostile_shots(delta: float) -> void:
	for i in range(world.hostile_shots.size()-1,-1,-1):
		var shot: Dictionary=world.hostile_shots[i]
		var travel:=minf(shot.remaining,6.0*delta)
		var steps:=maxi(1,int(ceil(travel/0.1)))
		var hit:=false
		for j in range(steps):
			shot.node.position+=shot.direction*travel/steps
			if world.is_safe(shot.node.position):
				hit=true
				break
			var query:=PhysicsShapeQueryParameters3D.new()
			var shape:=SphereShape3D.new()
			shape.radius=0.2
			query.shape=shape
			query.transform.origin=shot.node.position
			query.collision_mask=1|2
			var contacts:=world.get_world_3d().direct_space_state.intersect_shape(query,8)
			if not contacts.is_empty():
				var wall:=false
				var player_hit:=false
				for contact in contacts:
					if contact.collider==world.player:
						player_hit=true
					else:
						wall=true
				if player_hit and not wall:
					damage_player(shot.damage,{"magic":true})
				world.techniques.burst(shot.node.position,Color("e3a6df"),6)
				hit=true
				break
		shot.remaining-=travel
		if hit or shot.remaining<=0:
			shot.node.queue_free()
			world.hostile_shots.remove_at(i)

func clear_hostile_shots() -> void:
	for shot in world.hostile_shots:
		shot.node.queue_free()
	world.hostile_shots.clear()

