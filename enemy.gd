extends CharacterBody3D

const BossArt=preload("res://boss_art.gd")
const Rig = preload("res://rig.gd")
const SkillCatalog=preload("res://catalog.gd")
var root_timer:=0.0
var forced_velocity:=Vector3.ZERO
var leashing:=false
var regional_mode:=false
var territory_radius:=21.0
var interest_seconds:=0.0
var regional_clock:=0.0
var patrol_point:=Vector3.ZERO
func configure_regional(radius: float,level: int) -> void:
	regional_mode=true
	territory_radius=maxf(10.0,radius)
	patrol_point=home
	set_meta("ecology_level",maxi(1,level))
	max_hp+=maxi(0,level-1)*5
	hp=max_hp

var world: Node3D
var uid := ""
var kind := "blade"
var display_name := "Combatente"
var home := Vector3.ZERO
var rig: Node3D
var hp := 60
var max_hp := 60
var slow := 0.0
var stagger := 0.0
var cooldown := 1.0
var attack_time := -1.0
var attack_direction := Vector3.FORWARD
var attack_kind := "cleave"
var attack_done := false
var pattern := 0
var phase_two := false
var strikes := 0
var enabled := true
var art: Node3D
var hit_flash:=0.0
var encounter_started:=false
var intro_timer:=0.0
var rush_hit:=false
var skill_recovery:float=0.0
var skill_energy:float=100.0
var enemy_skill_data:Dictionary={}
var skills_used:Array[String]=[]

func setup(owner_world: Node3D, id: String, role: String, spawn: Vector3) -> void:
	world=owner_world
	uid=id
	kind=role
	home=spawn
	max_hp=200 if kind=="boss" else 48 if kind=="mage" else 60
	hp=max_hp
	display_name="Vigia dos Ecos" if kind=="boss" else "Cultivador Renegado" if kind=="mage" else "Combatente dos Ecos"
	collision_layer=4
	collision_mask=1|2|4
	add_to_group("enemies")
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius=0.4 if kind=="boss" else 0.3
	shape.height=2.2 if kind=="boss" else 1.95
	collider.shape=shape
	collider.position.y=shape.height*0.5
	add_child(collider)
	rig=Rig.new()
	add_child(rig)
	# Cosmetic components only: preserve boss art, colliders, HP and combat behavior.
	var cosmetics: Dictionary=preload("res://exo_skin3d/appearance_adapter.gd").npc_cosmetics(uid,"boss" if kind=="boss" else "enemy",kind)
	var appearance_seed: int=uid.hash() & 0x7fffffff
	# Same authored skin/UV/wardrobe path as inhabitants and the creator.
	# Combat stats and ownership remain this actor's existing responsibility.
	preload("res://wardrobe.gd").apply(rig,{"race":0,"skin":appearance_seed%6,
		"robe":5 if kind=="mage" else 3 if kind=="blade" else 0,
		"hair":(appearance_seed/7)%6,"haircut":appearance_seed%4,
		"eyes":appearance_seed%4,"eye_color":appearance_seed%6,
		"outfit":1 if kind=="blade" else 3,"style":appearance_seed%3,
		"weapon":"arcane_staff" if kind=="mage" else "sword","skin3d":cosmetics})
	if role!="boss":
		var tactical_profile:String="aggressive_cultivator" if kind=="mage" else ["bandit_swordsman","dagger_raider","bandit_archer"][appearance_seed%3]
		set_meta("bestiary03_profile",tactical_profile)
		if tactical_profile=="bandit_archer":preload("res://wardrobe.gd").apply(rig,{"race":0,"skin":appearance_seed%6,"robe":3,"hair":appearance_seed%6,"weapon":"bow","skin3d":cosmetics})
		if tactical_profile=="dagger_raider":preload("res://wardrobe.gd").apply(rig,{"race":0,"skin":appearance_seed%6,"robe":3,"hair":appearance_seed%6,"weapon":"twin_daggers","skin3d":cosmetics})
	if kind != "boss":
		preload("res://convergence/visual_actor_r10.gd").apply_enemy(rig,uid,"hostile_wanderer",str(world.journey.data.world.seed))
	if str(get_meta("bestiary03_profile",""))=="bandit_archer" and str(rig.get_meta("weapon_id",""))!="bow":preload("res://wardrobe.gd").apply(rig,{"race":0,"skin":appearance_seed%6,"robe":3,"hair":appearance_seed%6,"weapon":"bow","skin3d":cosmetics})
	if kind=="boss":
		rig.scale=Vector3.ONE*1.18
		art=BossArt.new(self)
		add_child(art)
	if kind=="mage":
		rig.sword.visible=false
	var label := Label3D.new()
	label.text=display_name
	label.position.y=3.2 if kind=="boss" else 2.25
	label.font_size=30
	label.pixel_size=0.008
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate=Color("e5c180") if kind=="boss" else Color("dedbd7")
	add_child(label)
	position=home

func restore(defeated: bool) -> void:
	root_timer=0
	interest_seconds=0.0
	regional_clock=0.0
	forced_velocity=Vector3.ZERO
	leashing=false
	hp=0 if defeated else max_hp
	visible=not defeated
	collision_layer=0 if defeated else 4
	position=home
	velocity=Vector3.ZERO
	slow=0
	stagger=0
	cooldown=1.0
	attack_time=-1
	phase_two=false
	pattern=0
	encounter_started=false
	intro_timer=0
	hit_flash=0
	rush_hit=false
	skill_recovery=0.0
	skill_energy=100.0
	enemy_skill_data.clear()
	skills_used.clear()
	rig.pose(0,false,false,true)

func hurt(amount: int, impulse: Vector3, slow_seconds: float=0.0,context: Dictionary={}) -> bool:
	if hp<=0 or (kind=="boss" and world.journey.data.stage==0):
		return false
	world.combat_timer=4
	hp=maxi(0,hp-amount)
	hit_flash=0.10
	world.impact_feedback(0.025)
	slow=maxf(slow,slow_seconds)
	# Regional enemies investigate and retaliate when struck from behind.
	if regional_mode:interest_seconds=maxf(interest_seconds,6.0)
	stagger=0.12 if kind=="boss" else 0.28
	velocity+=impulse*(0.3 if kind=="boss" else 1.0)
	if kind!="boss":
		attack_time=-1
		cooldown=maxf(cooldown,0.5)
	world.hits+=1
	var sound_context: Dictionary=context.duplicate()
	sound_context.fatal=hp==0
	world.audio_fx.impact(rig.get_meta("surface","body"),sound_context)
	world.audio_fx.actor_voice(rig)
	world.target=self
	world.message("%s: −%d%s" % [display_name,amount," • Lentidão" if slow_seconds>0 else ""])
	if hp==0:
		visible=false
		collision_layer=0
		world.enemy_defeated(self)
	return true

func step(delta: float) -> void:
	if hp<=0 or not enabled:
		return
	hit_flash=maxf(0,hit_flash-delta)
	slow=maxf(0,slow-delta)
	stagger=maxf(0,stagger-delta)
	cooldown=maxf(0,cooldown-delta)
	skill_recovery=maxf(0.0,skill_recovery-delta)
	skill_energy=minf(100.0,skill_energy+8.0*delta)
	var offset: Vector3=world.player.position-position
	offset.y=0
	var distance:=offset.length()
	var direction:=offset.normalized()
	if position.distance_to(home)>(territory_radius if regional_mode else 8.0) or (not regional_mode and position.z>9.5):
		leashing=true
	if leashing and position.distance_to(home)<.5:
		leashing=false
	var sees_player:=false
	if regional_mode:
		regional_clock+=delta
		sees_player=distance<12.0 and world.can_hit(position,world.player.position,direction,12.5,-1)
		interest_seconds=4.0 if sees_player else maxf(0.0,interest_seconds-delta)
	var returning: bool=leashing or world.is_safe(world.player.position) or (distance>10 and not regional_mode)
	if returning and position.distance_to(home)<.6:
		hp=mini(max_hp,hp+1)
	var locked: bool=kind=="boss" and world.journey.data.stage==0
	if hp<=max_hp/2 and kind=="boss" and not phase_two:
		phase_two=true
		world.message("Segunda fase • O Vigia rompe o selo!")
		world.techniques.burst(position+Vector3.UP,Color("f0ba78"),18)
		world.impact_feedback(0.08)
		world.play_sound("boss_phase")
	if kind=="boss" and not locked and not returning and distance<8 and not encounter_started:
		encounter_started=true
		intro_timer=1.15
		world.target=self
		world.message("Vigia dos Ecos • Guardião do fragmento")
		world.techniques.ring(position,1.4,Color("b49de0"),1.15)
		world.play_sound("boss_entry")
	if intro_timer>0:
		intro_timer=maxf(0,intro_timer-delta)
		velocity=Vector3.ZERO
		rig.pose(world.elapsed,false,false,true)
		if art!=null:
			art.step(world.elapsed,phase_two,hit_flash)
		return
	var move:=Vector3.ZERO
	if locked or returning:
		attack_time=-1
		var retreat: Vector3=home-position
		retreat.y=0
		move=retreat.normalized()*1.7 if retreat.length()>0.3 else Vector3.ZERO
	elif stagger>0 and kind!="boss":
		velocity.x=move_toward(velocity.x,0,12*delta)
		velocity.z=move_toward(velocity.z,0,12*delta)
	elif attack_time>=0:
		attack_time+=delta
		var windup:=windup_time()
		if attack_time>=windup and not attack_done:
			attack_done=true
			if world.flow.phase=="adventure" and position.distance_to(world.player.position)<9:
				world.cultivation.rumor("dardo_arcano" if kind=="mage" else "golpe_circular")
			execute_attack()
		if attack_time>=windup+0.24:
			attack_time=-1
			cooldown=0.65 if phase_two else 1.05 if kind=="boss" else .68
	else:
		if (not regional_mode or interest_seconds>0.0) and cooldown<=0 and distance<(9.5 if kind in ["mage","boss"] else 11.0 if weapon_profile().ranged else weapon_profile().reach) and world.can_hit(position,world.player.position,direction,10,-1):
			begin_attack(direction,distance)
			if attack_time<0 and world.get("bestiary_v4")!=null:
				var suggested:Vector3=world.bestiary_v4.tactical_velocity(self)
				if suggested.is_finite():move=suggested
		elif distance<12 and (not regional_mode or interest_seconds>0.0):
			if kind=="mage":
				move=-direction*1.4 if distance<3 else direction*1.6 if distance>6.5 else Vector3.ZERO
			else:
				move=direction*(1.9 if kind=="boss" else 1.7) if distance>(1.4 if kind=="boss" else maxf(1.4,weapon_profile().reach-.4)) else Vector3.ZERO
		elif regional_mode and not returning:
			# Small, deterministic patrol circuit; independent of the player position.
			var phase: float=regional_clock*0.34+float(abs(uid.hash())%16)
			patrol_point=home+Vector3(cos(phase),0,sin(phase))*minf(4.0,territory_radius*0.25)
			if is_instance_valid(world.active_region) and world.active_region.data!=null:
				var map_data: RefCounted=world.active_region.data
				var a: Vector2=Vector2(position.x,position.z)
				var b: Vector2=Vector2(patrol_point.x,patrol_point.z)
				if absf(map_data.height_at(a)-map_data.height_at(b))>0.65 or map_data.river_distance(b)<3.0:
					patrol_point=home
			var drift: Vector3=patrol_point-position
			drift.y=0
			if drift.length()>0.65:move=drift.normalized()*0.9
	if not locked and not returning and attack_time<0 and distance<16 and (not regional_mode or interest_seconds>0.0) and world.get("bestiary_v4")!=null:
		var suggested:Vector3=world.bestiary_v4.tactical_velocity(self)
		if suggested.is_finite():move=suggested
	if stagger<=0 or kind=="boss" or locked or returning:
		if move.length()>0.05:
			move=steer(move)
		if attack_kind=="rush" and attack_time>=windup_time() and attack_time<windup_time()+0.30:
			move=attack_direction*7
		velocity.x=move.x*(0.45 if slow>0 else 1.0)
		velocity.z=move.z*(0.45 if slow>0 else 1.0)
	if not is_on_floor():
		velocity.y-=20*delta
	root_timer=maxf(0,root_timer-delta)
	if root_timer>0:
		velocity.x=0
		velocity.z=0
	velocity+=forced_velocity
	forced_velocity=forced_velocity.move_toward(Vector3.ZERO,delta*12)
	move_and_slide()
	if not regional_mode and position.z>9.5:
		position.z=9.5
		leashing=true
	if attack_kind=="rush" and attack_time>=windup_time() and attack_time<windup_time()+0.30 and not rush_hit:
		if world.can_hit(position,world.player.position,attack_direction,1.5,0.3):
			rush_hit=true
			world.damage_player(14,{"heavy":true})
	if attack_time<0 and direction.length()>0.1:
		rig.rotation.y=atan2(-direction.x,-direction.z)
	rig.pose(world.elapsed,false,false,is_on_floor(),clampf(attack_time/(windup_time()+0.36),0,1) if attack_time>=0 else -1)
	rig.locomotion(get_real_velocity(),delta,false,is_on_floor(),attack_time<0)
	if attack_time>=0 and attack_kind=="orb":
		rig.skill_pose(1,minf(0.4,attack_time),false,0)
	if kind=="blade":
		world.Arsenal.animate(rig,weapon_profile(),pattern%3,attack_time/(windup_time()+.36) if attack_time>=0 else -1)
	world.Anatomy.animate(rig,world.elapsed,velocity.length(),is_on_floor())
	if art!=null:
		art.step(world.elapsed,phase_two,hit_flash)
	rig.skin.albedo_color=Color.WHITE if hit_flash>0 else Color("7ed5ed") if slow>0 else Color("efbf76") if phase_two else Color("d5b98c") if kind=="boss" else Color("879ec9") if kind=="mage" else Color("b08c9b")

	if rig.has_meta("garments") and hit_flash<=0 and slow<=0 and not phase_two:
		rig.skin.albedo_color=Color.WHITE

func apply_control(force: Vector3,root_seconds: float) -> void:
	forced_velocity=force*(.3 if kind=="boss" else 1.0)
	forced_velocity.y=0
	root_timer=maxf(root_timer,root_seconds*(.3 if kind=="boss" else 1.0))

func steer(movement: Vector3) -> Vector3:
	var query:=PhysicsRayQueryParameters3D.create(position+Vector3.UP,position+Vector3.UP+movement.normalized()*1.0,1|4)
	query.exclude=[get_rid()]
	if world.get_world_3d().direct_space_state.intersect_ray(query).is_empty():
		return movement
	var side:=Vector3(-movement.z,0,movement.x)
	for trial in [side,-side]:
		query.to=position+Vector3.UP+trial.normalized()*1.1
		if world.get_world_3d().direct_space_state.intersect_ray(query).is_empty():
			return trial
	return Vector3.ZERO

func begin_attack(direction: Vector3, distance: float) -> void:
	if world.get("bestiary_v4")!=null and not world.bestiary_v4.can_begin(self):return
	if kind=="boss":world.play_sound("boss_prepare")
	attack_time=0
	attack_done=false
	rush_hit=false
	attack_direction=direction
	attack_kind="orb" if kind=="mage" else "arrow" if weapon_profile().ranged else "cleave"
	enemy_skill_data.clear()
	if kind!="boss" and strikes%3==2 and skill_recovery<=0.0:
		var options:Array=["dardo_arcano"] if kind=="mage" or weapon_profile().ranged else ["golpe_circular","corte_inicial"]
		var candidate:Dictionary=SkillCatalog.skill(str(options[floori(float(strikes)/3.0)%options.size()]))
		if skill_energy>=float(candidate.mana)+float(candidate.stamina) and (str(candidate.kind) in ["projectile","cut"] or distance<=3.4):
			enemy_skill_data=candidate.duplicate(true)
			attack_kind="skill"
	if kind=="boss":
		attack_kind="orb" if distance>3.0 else "shock" if pattern%3==1 else "cleave"
		if phase_two and pattern%4==3 and distance>2.5:
			attack_kind="rush"
		pattern+=1
	rig.rotation.y=atan2(-direction.x,-direction.z)
	if attack_kind=="shock":
		world.techniques.ring(position,3.2,Color("ba785e"),windup_time())
	elif attack_kind in ["orb","arrow","rush"]:
		world.aim_line(position,direction,3.6 if attack_kind=="rush" else 9,windup_time(),Color("dfa575") if attack_kind=="rush" else Color("ba7caa"))
	else:
		if kind=="blade" and weapon_profile().pose=="thrust":
			world.aim_line(position,direction,weapon_profile().reach,windup_time(),Color("ba785e"))
		else:
			world.spawn_arc(position,direction,2.7 if kind=="boss" else weapon_profile().reach,Color("ba785e"),windup_time())

func windup_time() -> float:
	if attack_kind=="skill":
		return maxf(.35,float(enemy_skill_data.cast))
	if kind=="blade":
		return maxf(.4,weapon_profile().duration*weapon_profile().hit+.2)
	if attack_kind=="rush":
		return 0.9
	return 0.8 if kind=="mage" else 1.0 if attack_kind in ["shock","orb"] and kind=="boss" else 0.78 if kind=="boss" else 0.65

func execute_attack() -> void:
	if world.get("bestiary_v4")!=null and not world.bestiary_v4.can_release(self):return
	if kind=="boss":world.play_sound("boss_release")
	strikes+=1
	world.audio_fx.actor_voice(rig,true)
	if attack_kind=="skill":
		_release_catalog_skill()
		return
	if attack_kind=="arrow":
		world.combat.enemy_orb(position+Vector3.UP,attack_direction,8,{"family":"arrow","speed":13.0})
		world.audio_fx.play_event("arrow","combat",.45)
		return
	if attack_kind=="rush":
		world.play_sound("leap")
		return
	if attack_kind=="orb":
		world.enemy_orb(position+Vector3.UP,attack_direction,10 if kind=="boss" else 9)
		if phase_two:
			world.enemy_orb(position+Vector3.UP,attack_direction.rotated(Vector3.UP,0.24),10)
			world.enemy_orb(position+Vector3.UP,attack_direction.rotated(Vector3.UP,-0.24),10)
	elif attack_kind=="shock":
		world.play_sound("boss_impact")
		world.techniques.ring(position,3.2,Color("ffbd85"),0.3)
		if world.can_hit(position,world.player.position,attack_direction,3.2,-1):
			world.damage_player(18,{"magic":true})
	else:
		world.audio_fx.play_event("punch" if weapon_profile().pose=="fists" else "swing","combat",.4)
		world.spawn_arc(position,attack_direction,2.7 if kind=="boss" else weapon_profile().reach,Color("ffbd85"),0.2)
		if world.can_hit(position,world.player.position,attack_direction,2.7 if kind=="boss" else weapon_profile().reach,.5 if kind=="boss" else weapon_profile().cone):
			world.damage_player(16 if kind=="boss" else int(round(weapon_profile().damage*.7)),{"family":weapon_profile().pose,"heavy":kind=="boss"})

func _release_catalog_skill() -> void:
	if enemy_skill_data.is_empty():return
	var cost:float=float(enemy_skill_data.mana)+float(enemy_skill_data.stamina)
	if skill_energy<cost:return
	skill_energy-=cost
	skill_recovery=float(enemy_skill_data.cooldown)
	skills_used.append(str(enemy_skill_data.id))
	world.audio_fx.skill(enemy_skill_data)
	var effect_color:Color=Color(SkillCatalog.COLORS[int(enemy_skill_data.element)])
	world.techniques.ring(position,3.4 if str(enemy_skill_data.kind) in ["area","root"] else 1.0,effect_color,.38)
	if str(enemy_skill_data.kind) in ["projectile","cut"]:
		# Existing hostile projectile owns movement, wall collision and damage.
		world.combat.enemy_orb(position+Vector3.UP,attack_direction,int(enemy_skill_data.damage),{"family":"qi","speed":11.0,"reach":4.0 if str(enemy_skill_data.kind)=="cut" else 13.0,"skill_id":str(enemy_skill_data.id)})
	else:
		if world.can_hit(position,world.player.position,attack_direction,3.4,-1):
			world.damage_player(int(enemy_skill_data.damage),{"magic":true,"element":int(enemy_skill_data.element)})

func weapon_profile() -> Dictionary:
	return world.Catalog.weapon(str(rig.get_meta("weapon_id","sword")))
