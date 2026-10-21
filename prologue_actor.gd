extends "res://enemy.gd"
const Arsenal=preload("res://arsenal.gd")
const Catalog=preload("res://catalog.gd")

var faction:=0
var victim: Node3D
var color:=Color.WHITE
var clashes:=0
var technique_clock:=3.0
var technique_windup:=-1.0
var technique_target:=Vector3.ZERO

func step(delta: float) -> void:
	if hp<=0 or not enabled:
		return
	technique_clock-=delta
	if technique_windup>=0:
		technique_windup+=delta
		if technique_windup>=.8:
			world.techniques.ring(technique_target,2.2,color,.4)
			for candidate in world.enemies:
				if candidate!=self and candidate.hp>0 and candidate.faction!=faction and candidate.position.distance_to(technique_target)<2.2:
					candidate.hurt(24,Vector3.ZERO)
			if world.player.position.distance_to(technique_target)<2.2:
				world.damage_player(14)
			technique_windup=-1
			technique_clock=5+faction*.13
	cooldown=maxf(0,cooldown-delta)
	slow=maxf(0,slow-delta)
	stagger=maxf(0,stagger-delta)
	if not is_instance_valid(victim) or (victim!=world.player and victim.hp<=0):
		victim=null
		var distance:=1000.0
		for candidate in world.enemies:
			if candidate!=self and candidate.hp>0 and candidate.faction!=faction:
				var d:=position.distance_to(candidate.position)
				if d<distance:
					distance=d
					victim=candidate
		if position.distance_to(world.player.position)<distance+2:
			victim=world.player
	if not is_instance_valid(victim):
		return
	if technique_clock<=0 and technique_windup<0:
		technique_target=victim.position
		technique_windup=0
		world.techniques.ring(technique_target,2.2,color.darkened(.35),.8)
	var offset: Vector3=victim.position-position
	offset.y=0
	var spec:=Catalog.weapon(str(rig.get_meta("weapon_id","sword")))
	var range_value: float=7 if spec.ranged else spec.reach
	var distance:=offset.length()
	var direction:=offset.normalized()
	var movement:=Vector3.ZERO
	if attack_time>=0:
		attack_time+=delta
		if attack_time>=0.65 and not attack_done:
			attack_done=true
			clashes+=1
			world.aim_line(position,attack_direction,range_value,.18,color) if spec.ranged else world.spawn_arc(position,attack_direction,range_value,color,.18)
			if world.can_hit(position,victim.position,attack_direction,range_value,.3):
				if victim==world.player:
					world.damage_player(6)
				else:
					victim.hurt(7,attack_direction*0.7)
		if attack_time>=1.0:
			attack_time=-1
			cooldown=1.1
	elif cooldown<=0 and distance<range_value-.1:
		attack_time=0
		attack_done=false
		attack_direction=direction
		world.aim_line(position,direction,range_value,.65,color.darkened(.4)) if spec.ranged else world.spawn_arc(position,direction,range_value,color.darkened(.4),.65)
	elif distance>range_value-.3 and stagger<=0:
		movement=steer(direction*1.55)*(0.45 if slow>0 else 1)
	velocity.x=movement.x
	velocity.z=movement.z
	if not is_on_floor():
		velocity.y-=20*delta
	if root_timer>0:
		velocity.x=0
		velocity.z=0
	root_timer=maxf(0,root_timer-delta)
	velocity+=forced_velocity
	forced_velocity=forced_velocity.move_toward(Vector3.ZERO,delta*12)
	move_and_slide()
	rig.rotation.y=atan2(-direction.x,-direction.z)
	rig.pose(world.elapsed,false,false,is_on_floor(),attack_time if attack_time>=0 else -1)
	rig.locomotion(get_real_velocity(),delta,false,is_on_floor(),attack_time<0)
	var pose_time:=attack_time
	if spec.pose in ["bow","crossbow"] and attack_time>=0:
		pose_time=attack_time/.65*float(spec.hit) if attack_time<=.65 else float(spec.hit)+(1.0-float(spec.hit))*(attack_time-.65)/.35
	Arsenal.animate(rig,spec,pattern%3,pose_time)
	world.Anatomy.animate(rig,world.elapsed,velocity.length(),is_on_floor())

func hurt(amount: int,impulse: Vector3,slow_seconds: float=0.0,context: Dictionary={}) -> bool:
	if hp<=0:
		return false
	hp=maxi(0,hp-amount)
	slow=maxf(slow,slow_seconds)
	stagger=0.18
	forced_velocity+=impulse
	world.hits+=1
	world.target=self
	world.audio_fx.impact(rig.get_meta("surface","body"),context)
	world.message("%s • −%d" % [display_name,amount])
	if hp==0:
		visible=false
		collision_layer=0
	return true
