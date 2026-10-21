extends RefCounted
const Slots=preload("res://data/slot_rules.gd")
const Catalog=preload("res://catalog.gd")
const Arsenal=preload("res://arsenal.gd")
const Wardrobe=preload("res://wardrobe.gd")
var DATA: Array=[]
var world: Node3D
var mana:=100.0
var stamina:=100.0
var regen_delay:=0.0
var cast_serial:=0
var cooldowns: Array[float]=[]
var recovery: Dictionary={}
var active:=-1
var casting: Dictionary={}
var time:=0.0
var released:=false
var direction:=Vector3.FORWARD
var airborne:=false
var landed:=false
var landing_time:=0.0
var landings:=0
var movement_cue_played:=false
var impacts:=0
var pulse:=0.0
var projectiles: Array[Dictionary]=[]
var fields: Array[Dictionary]=[]
var summons: Array[Dictionary]=[]
var charge: MeshInstance3D
var shield:=0.0
var shield_source: Dictionary={}
var shield_time:=0.0
var shield_node: MeshInstance3D
var struck: Array[Node3D]=[]

func _init(owner_world: Node3D) -> void:
	world=owner_world
	configure(["corte_inicial","bola_de_gelo","salto_impetuoso"])

func configure(ids: Array) -> void:
	DATA.clear()
	for id in ids:
		DATA.append(Catalog.skill(id).duplicate(true))
	cooldowns.resize(DATA.size())
	for i in range(DATA.size()):
		cooldowns[i]=float(recovery.get(DATA[i].id,0))

func busy() -> bool:
	return active>=0

func channeling() -> bool:
	return busy() and casting.kind=="channel"

func cast(index: int) -> bool:
	if index>=0 and index<DATA.size() and DATA[index].has("forge_id"):
		return bool(world.exo_core.services.invoke("skill_forge","authorized_cast",["player",str(DATA[index].id)]).get("committed",false))
	if world.activity!=null and world.activity.locked():return false
	if index<0 or index>=DATA.size() or world.get_tree().paused or world.health<=0 or busy() or world.attack_time>=0 or world.roll_time>=0:
		return false
	var data: Dictionary=world.cultivation.stats(DATA[index])
	if float(recovery.get(data.id,0))>0:
		world.message("%s recarregando." % data.name)
		return false
	if mana<data.mana or stamina<data.stamina:
		world.message("Energia ou vigor insuficiente.")
		return false
	if data.kind in ["leap","dash"] and not world.player.is_on_floor():
		return false
	mana-=data.mana
	stamina-=data.stamina
	regen_delay=1.2
	recovery[data.id]=float(data.cooldown)*(.35 if world.peak_power() else 1.0)
	cooldowns[index]=recovery[data.id]
	cast_serial+=1
	casting=data.duplicate(true)
	casting["_cast"]=cast_serial
	if world.peak_power():
		world.message("Auge • "+data.name)
		world.techniques.ring(world.player.position,1.8,color_for(data),.3)
	active=index
	time=0
	released=false
	airborne=false
	landed=false
	landing_time=0
	movement_cue_played=false
	pulse=0
	struck.clear()
	direction=world.facing
	world.model.rotation.y=atan2(-direction.x,-direction.z)
	world.message(data.name)
	world.audio_fx.skill(data,true)
	if data.kind in ["projectile","channel","heal","summon"]:
		charge=sphere(.15,color_for(data))
	return true

func color_for(data: Dictionary) -> Color:
	return Color(Catalog.COLORS[int(data.get("element",11))])

func tick(delta: float) -> void:
	for id in recovery.keys():
		recovery[id]=maxf(0,float(recovery[id])-delta)
	for i in range(DATA.size()):
		cooldowns[i]=float(recovery.get(DATA[i].id,0))
	regen_delay=maxf(0,regen_delay-delta)
	if regen_delay<=0:
		mana=minf(100,mana+(8+world.equipment_stat("mana_regen")+world.attribute("inteligencia")*.4+(2 if world.has_passive("concentracao_1") else 0))*delta)
		stamina=minf(100,stamina+(18+world.equipment_stat("stamina_regen")+(3 if world.has_passive("folego_1") else 0))*delta)
	update_projectiles(delta)
	update_fields(delta)
	update_summons(delta)
	shield_time=maxf(0,shield_time-delta)
	if shield_time<=0:
		shield=0
	if is_instance_valid(shield_node):
		shield_node.position=world.player.position+Vector3.UP
		shield_node.visible=shield>0
	if not busy():
		return
	time+=delta
	if is_instance_valid(charge):
		charge.position=world.player.position+Vector3(0,1.2,0)+direction*.6
	if not released and time>=casting.release:
		released=true
		release()
	if casting.kind=="channel" and released:
		pulse-=delta
		if pulse<=0:
			pulse=.35
			hit_area(world.player.position,6,.92,casting.damage,0,0)
			world.aim_line(world.player.position,direction,6,.15,color_for(casting))
			world.audio_fx.skill(casting)
	if casting.kind=="dash" and released:
		for actor in world.enemies:
			if actor not in struck and actor.hp>0 and world.can_hit(world.player.position,actor.position,direction,2,.4):
				struck.append(actor)
				if actor.hurt(scaled_damage(casting.damage,casting),direction*4,0,world.audio_fx.technique_context(casting)):world.cultivation.credit(casting)
	if casting.kind=="leap":
		if landed:
			landing_time+=delta
			if landing_time>=.28:
				finish()
		elif time>2.4:
			finish()
	elif time>=casting.cast:
		finish()

func release() -> void:
	if casting.has("forge_id"):
		world.activation_v4.release_skill(casting)
		return
	world.audio_fx.skill(casting)
	var color:=color_for(casting)
	var bound_visual: bool=false
	if world.get("vfx_host_v5")!=null:bound_visual=world.vfx_host_v5.release(casting)
	if not bound_visual:
		var effect:=preload("res://qi_effect.gd").new()
		world.add_child(effect)
		effect.position=world.player.position+Vector3(0,.15,0)
		effect.setup(color,str(casting.kind))
	match str(casting.kind):
		"cut":
			launch(casting,direction,7 if world.peak_power() else 4,12,false)
		"projectile":
			launch(casting,direction,14 if world.peak_power() else 10,11,false)
		"leap":
			world.player.velocity.y=7.7
			if not world.audio_fx.SkillRegistry.integrated(str(casting.id)):world.play_sound("leap")
		"area","root","repel":
			var radius:=3.4*(1.4 if world.peak_power() else 1.0)
			ring(world.player.position,radius,color,.45)
			hit_area(world.player.position,radius,-1,casting.damage,1.0 if casting.kind=="root" else 0,6 if casting.kind=="repel" else 2)
		"pull":
			var center:=target_point(3.4)
			ring(center,3.4,color,.6)
			for actor in world.enemies:
				if actor.hp>0 and world.can_hit(center,actor.position,Vector3.FORWARD,3.5,-1):
					if actor.hurt(scaled_damage(casting.damage,casting),Vector3.ZERO,0,world.audio_fx.technique_context(casting)):world.cultivation.credit(casting)
					actor.apply_control((center-actor.position).normalized()*6,.35)
		"shield":
			shield=35*(3 if world.peak_power() else 1)*(1+world.attribute("vontade")*.05)*(1.1 if world.race_body()=="mechanical" else 1.0)
			shield_time=6
			shield_source=casting.duplicate(true)
			if not is_instance_valid(shield_node):
				shield_node=sphere(.85,Color("5e97ac"))
				var material:=glowing(Color(.3,.65,.75,.2))
				material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
				shield_node.material_override=material
		"heal":
			if world.health<world.max_health:world.cultivation.credit(casting)
			world.health=mini(world.max_health,world.health+(70 if world.peak_power() else 28)+world.attribute("vontade")*2)
			ring(world.player.position,1.2,color,.65)
		"trap":
			create_field(target_point(3.5),color)
		"summon":
			create_summon()

func scaled_damage(value: float,source: Dictionary={}) -> int:
	var cue: Dictionary=casting if source.is_empty() else source
	var affinity_bonus: float=world.equipment_element_bonus(int(cue.get("element",-1)))
	return int(round(value*(1+affinity_bonus)*(3.0 if world.peak_power() else 1.0)*(1+world.attribute("inteligencia")*.02)*(1.1 if int(world.current_profile().get("path",0))==1 else 1.0)))

func hit_area(origin: Vector3,radius: float,cone: float,damage: float,root_seconds: float,push: float) -> void:
	for actor in world.enemies:
		if actor.hp>0 and world.can_hit(origin,actor.position,direction,radius,cone):
			var away: Vector3=(actor.position-origin).normalized()
			if actor.hurt(scaled_damage(damage,casting),away*push,2.0 if root_seconds>0 else 0,world.audio_fx.technique_context(casting)):world.cultivation.credit(casting)
			if root_seconds>0 or push>0:
				actor.apply_control(away*push,root_seconds)

func target_point(distance: float) -> Vector3:
	var start: Vector3=world.player.position+Vector3.UP
	var query:=PhysicsRayQueryParameters3D.create(start,start+direction*distance,1)
	var contact: Dictionary=world.get_world_3d().direct_space_state.intersect_ray(query)
	var point: Vector3=(contact.position-direction*.5) if not contact.is_empty() else start+direction*distance
	point.y=.04
	return point

func move(input_direction: Vector3) -> void:
	var speed:=.8
	var move_direction:=input_direction
	if casting.kind=="leap" and released and not landed:
		speed=6.2
		move_direction=direction
	elif casting.kind=="dash" and released:
		speed=8
		move_direction=direction
	elif casting.kind=="channel":
		speed=0
	world.player.velocity.x=move_direction.x*speed
	world.player.velocity.z=move_direction.z*speed

func after_motion() -> void:
	if not busy() or casting.kind!="leap" or not released or landed:
		return
	if not world.player.is_on_floor():
		airborne=true
		if not movement_cue_played:
			movement_cue_played=true
			world.audio_fx.SkillRegistry.play(world.audio_fx,str(casting.id),"movement")
	elif airborne:
		landed=true
		landing_time=0
		landings+=1
		ring(world.player.position,3,Color("cdb685"),.35)
		hit_area(world.player.position,3,-1,casting.damage,0,4)
		if not world.audio_fx.SkillRegistry.play(world.audio_fx,str(casting.id),"impact"):world.play_sound("landing")

func animate() -> void:
	if busy():
		world.model.skill_pose(2 if casting.kind=="leap" else 0 if casting.kind in ["cut","area","dash"] else 1,time,landed,landing_time)

func launch(data: Dictionary,travel: Vector3,reach: float,speed: float,arrow: bool) -> void:
	var node: Node3D=Arsenal.missile(world,travel,arrow,color_for(data)) if arrow else crescent(travel) if data.kind=="cut" else sphere(.2,color_for(data))
	node.position=world.player.position+Vector3.UP+travel*.5
	if world.peak_power() and not arrow:
		node.scale*=1.65
	if world.aim_has_target:
		world.refresh_aim_target()
		travel=(world.aim_point-node.global_position).normalized()
		node.look_at(node.global_position+travel,Vector3.UP)
	projectiles.append({"node":node,"direction":travel,"speed":speed,"remaining":reach,"data":data.duplicate(true),"arrow":arrow})

func weapon_shot(spec: Dictionary,travel: Vector3,damage: int) -> void:
	var data: Dictionary={"kind":"projectile","id":"weapon","magic":spec.pose not in ["bow","crossbow"],"family":spec.pose,"damage":damage,"element":int(world.current_profile().get("element",11)),"name":spec.name}
	# Pose the hands at the release point before reading the weapon muzzle.
	if spec.pose in ["bow","crossbow"]:
		Arsenal.ranged_pose(world.model,spec.pose,float(spec.hit))
	launch(data,travel,spec.reach,18 if spec.pose in ["bow","crossbow"] else 11,spec.pose in ["bow","crossbow"])
	if spec.pose in ["bow","crossbow"]:
		var frame: Node3D=world.model.get_meta("weapon_root")
		var muzzle: Node3D=frame.get_meta("muzzle")
		projectiles.back().node.global_position=muzzle.global_position
		if world.aim_has_target:
			world.refresh_aim_target()
			var aim: Vector3=(world.aim_point-muzzle.global_position).normalized()
			projectiles.back().direction=aim
			projectiles.back().node.look_at(muzzle.global_position+aim,Vector3.UP)

func update_projectiles(delta: float) -> void:
	for i in range(projectiles.size()-1,-1,-1):
		var shot: Dictionary=projectiles[i]
		var distance: float=minf(shot.remaining,shot.speed*delta)
		var steps:=maxi(1,int(ceil(distance/.1)))
		var collided:=false
		for step in range(steps):
			shot.node.position+=shot.direction*distance/steps
			var query:=PhysicsShapeQueryParameters3D.new()
			var shape:=SphereShape3D.new()
			shape.radius=.2
			query.shape=shape
			query.transform.origin=shot.node.position
			query.collision_mask=1|4
			var contacts:=world.get_world_3d().direct_space_state.intersect_shape(query,8)
			if not contacts.is_empty():
				var victim: Node3D=null
				var wall:=false
				for contact in contacts:
					if contact.collider in world.enemies and contact.collider.hp>0:
						victim=contact.collider
					elif contact.collider not in world.enemies:
						wall=true
				if victim!=null and not wall:
					var slow_seconds: float=world.frost_duration() if shot.data.id=="bola_de_gelo" else 0
					var amount: int=int(shot.data.damage) if shot.data.id=="weapon" else scaled_damage(shot.data.damage,shot.data)
					if victim.hurt(amount,shot.direction*(5 if shot.data.id=="rajada_de_vento" else 2),slow_seconds,world.audio_fx.technique_context(shot.data)):world.cultivation.credit(shot.data)
					impacts+=1
					burst(shot.node.position,color_for(shot.data),6)
				collided=true
				break
		shot.remaining-=distance
		if collided or shot.remaining<=0:
			shot.node.queue_free()
			projectiles.remove_at(i)

func create_field(point: Vector3,color: Color) -> void:
	var node:=Node3D.new()
	world.add_child(node)
	node.position=point
	for i in range(8):
		var angle:=TAU*i/8.0
		var spike:=Arsenal.piece(node,Vector3(cos(angle)*1.7,.3,sin(angle)*1.7),Vector3(.18,.6,.18),color)
		spike.rotation.z=.2
	fields.append({"node":node,"point":point,"life":5.0,"pulse":0.0,"damage":15,"source":casting.duplicate(true)})
	ring(point,2.6,color,5)

func update_fields(delta: float) -> void:
	for i in range(fields.size()-1,-1,-1):
		var field: Dictionary=fields[i]
		field.life-=delta
		field.pulse-=delta
		if field.pulse<=0:
			field.pulse=1
			for actor in world.enemies:
				if actor.hp>0 and world.can_hit(field.point,actor.position,Vector3.FORWARD,2.6,-1):
					if actor.hurt(scaled_damage(field.damage,field.source),Vector3.ZERO,1.2,world.audio_fx.technique_context(field.source)):world.cultivation.credit(field.source)
		if field.life<=0:
			field.node.queue_free()
			fields.remove_at(i)

func create_summon() -> void:
	if summons.size()>=1:
		summons[0].node.queue_free()
		summons.clear()
	var node:=CharacterBody3D.new()
	node.collision_layer=8
	node.collision_mask=1|4
	var collision:=CollisionShape3D.new()
	var shape:=CapsuleShape3D.new()
	shape.radius=.3
	shape.height=1.9
	collision.shape=shape
	collision.position.y=.95
	node.add_child(collision)
	world.add_child(node)
	node.position=target_point(1.2)
	var rig: Node3D=world.Rig.new()
	node.add_child(rig)
	Wardrobe.apply(rig,{"race":1,"robe":3,"hair":2,"skin":3,"style":2,"weapon":"spear"})
	var label:=Label3D.new()
	node.add_child(label)
	label.position.y=2.3
	label.text="GUARDIÃO ANCESTRAL"
	label.font_size=26
	label.pixel_size=.008
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate=Color("d7c38b")
	summons.append({"node":node,"rig":rig,"life":12.0,"cooldown":0.0,"source":casting.duplicate(true)})

func update_summons(delta: float) -> void:
	for i in range(summons.size()-1,-1,-1):
		var unit: Dictionary=summons[i]
		unit.life-=delta
		unit.cooldown-=delta
		var goal: Vector3=world.player.position+Vector3(1.5,0,0)
		var victim: Node3D=null
		var nearest:=8.0
		for actor in world.enemies:
			if actor.hp>0 and actor.position.distance_to(world.player.position)<12 and not world.is_safe(actor.position):
				var distance: float=unit.node.position.distance_to(actor.position)
				if distance<nearest:
					nearest=distance
					victim=actor
		if victim!=null:
			goal=victim.position
			if nearest<2.5 and unit.cooldown<=0 and world.can_hit(unit.node.position,victim.position,(goal-unit.node.position).normalized(),2.5,-1):
				if victim.hurt(scaled_damage(8,unit.source),Vector3.ZERO,0,world.audio_fx.technique_context(unit.source)):world.cultivation.credit(unit.source)
				unit.cooldown=1
				world.spawn_arc(unit.node.position,(goal-unit.node.position).normalized(),2,Color("d3be87"),.2)
		var direction: Vector3=goal-unit.node.position
		direction.y=0
		unit.node.velocity=direction.normalized()*2.8 if direction.length()>1.6 else Vector3.ZERO
		if not unit.node.is_on_floor():
			unit.node.velocity.y=-5
		unit.node.move_and_slide()
		if direction.length()>.1:
			unit.rig.rotation.y=atan2(-direction.x,-direction.z)
		unit.rig.pose(world.elapsed,false,false,true)
		unit.rig.locomotion(unit.node.velocity,delta,false,true,true)
		if unit.life<=0:
			unit.node.queue_free()
			summons.remove_at(i)

func finish() -> void:
	active=-1
	time=0
	casting={}
	clear_charge()

func clear_charge() -> void:
	if is_instance_valid(charge):
		charge.queue_free()
	charge=null

func reset() -> void:
	finish()
	for shot in projectiles:
		if is_instance_valid(shot.node):
			shot.node.queue_free()
	projectiles.clear()
	for field in fields:
		field.node.queue_free()
	fields.clear()
	for unit in summons:
		unit.node.queue_free()
	summons.clear()
	shield=0
	shield_time=0
	if is_instance_valid(shield_node):
		shield_node.queue_free()
	shield_node=null
	mana=100
	stamina=100
	regen_delay=0
	recovery.clear()
	cooldowns.resize(DATA.size())
	cooldowns.fill(0.0)
	landings=0
	impacts=0

func sphere(radius: float, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius*2
	mesh.radial_segments = [8,12,20][mini(world.graphics.level,2)] if world.graphics!=null else 12
	mesh.rings = 6
	node.mesh = mesh
	node.material_override = glowing(color)
	world.add_child(node)
	return node

func glowing(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

func crescent(travel: Vector3) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(16):
		var a := -1.15+2.3*float(i)/16
		var b := -1.15+2.3*float(i+1)/16
		var points := [Vector3(sin(a),0,-cos(a))*0.9,Vector3(sin(b),0,-cos(b))*0.9,Vector3(sin(b),0,-cos(b))*0.68,Vector3(sin(a),0,-cos(a))*0.68]
		for index in [0,1,2,0,2,3]:
			surface.add_vertex(points[index])
	mesh.mesh = surface.commit()
	mesh.material_override = glowing(Color("f1d5a2"))
	world.add_child(mesh)
	mesh.rotation.y = atan2(-travel.x,-travel.z)
	return mesh

func ring(position: Vector3, radius: float, color: Color, duration: float) -> void:
	var mesh := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius-0.12
	torus.outer_radius = radius
	torus.rings = [16,24,40][mini(world.graphics.level,2)] if world.graphics!=null else 24
	torus.ring_segments = 6
	mesh.mesh = torus
	mesh.material_override = glowing(color)
	world.add_child(mesh)
	mesh.position = position+Vector3(0,0.07,0)
	world.effects.append({"node":mesh,"time":duration})

func burst(position: Vector3, color: Color, count: int) -> void:
	var actual: int=world.graphics.effect_count(count) if world.graphics!=null else count
	var budget: int=world.graphics.effect_budget() if world.graphics!=null else 72
	for i in range(actual):
		if world.effects.size()>=budget:
			break
		var piece := sphere(0.06,color)
		var a := TAU*float(i)/actual
		piece.position = position+Vector3(cos(a),sin(a*2)*0.3,sin(a))*0.4
		world.effects.append({"node":piece,"time":0.3})

