extends Node3D
## One visible resident. Reuses the approved original V4 GLB, rig, UV and clips.
signal life_changed(npc_id: String, hp: int)
const CHARACTER := preload("res://modules/character_core_v3/assets/EXO_Character_Core01.glb")
const APPEARANCE := preload("res://modules/character_customization/appearance.gd")
const NPC_MOTION := preload("res://modules/village_life/npc_motion.gd")
const CULTIVATION_FX := preload("res://modules/village_life/cultivation_fx.gd")
var record: Dictionary
var host: Node3D
var body: CharacterBody3D
var visual: Node3D
var animator: AnimationPlayer
var plate: Label3D
var hurtbox: Area3D
var hp := 1
var maximum := 1
var state := "IDLE"
var state_time := 0.0
var clock_minutes := 540.0
var active_in_village := true
var stuck_time := 0.0
var qi_orbit: Node3D
var counter_cooldown := 0.0
var cultivation_time := 0.0
var cultivation_stage := "off"
var cultivation_progress := 0.0
var work_clip := ""
var badge_background: MeshInstance3D
var health_fill: MeshInstance3D
func configure(spec: Dictionary, world: Node3D) -> void:
	record = spec
	host = world
	maximum = int(spec.hp)
	hp = maximum
func _ready() -> void:
	body = CharacterBody3D.new()
	body.name = str(record.id)+"_Body"
	body.collision_layer = 64
	body.collision_mask = 1|2
	body.floor_snap_length = .45
	body.floor_max_angle = deg_to_rad(46)
	add_child(body)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = .34
	capsule.height = 2.65
	shape.shape = capsule
	shape.position.y = 1.325
	body.add_child(shape)
	visual = CHARACTER.instantiate()
	visual.name = "ApprovedV4ResidentRig"
	var proportions: Vector3 = APPEARANCE.proportions(record)
	visual.position.y = -.125 * proportions.y
	visual.rotation.y = PI
	body.add_child(visual)
	animator = _find_player(visual)
	assert(animator != null and animator.has_animation("Idle") and animator.has_animation("Walk"))
	APPEARANCE.apply_to_visual(visual,record)
	# NPC-only sizing: the player's customization contract keeps its own safer limits.
	proportions = Vector3(clampf(float(record.get("body_style",{}).get("width",1)),.80,1.20),clampf(float(record.get("body_style",{}).get("height",1)),.80,1.20),clampf(float(record.get("body_style",{}).get("depth",1)),.80,1.20))
	visual.scale = proportions
	visual.position.y = -.125 * proportions.y
	if str(record.get("role","")) in ["discípulo","mestre de cultivo"]:
		_install_cultivation()
	work_clip = NPC_MOTION.install(animator,str(record.get("animation_profile","resident")))
	capsule.radius *= maxf(proportions.x,proportions.z)
	capsule.height *= proportions.y
	shape.position.y *= proportions.y
	hurtbox = Area3D.new()
	hurtbox.name = "NPC_Hurtbox"
	hurtbox.collision_layer = 32
	hurtbox.collision_mask = 0
	hurtbox.monitoring = false
	hurtbox.monitorable = true
	hurtbox.set_meta("village_npc",self)
	var hurt_shape := CollisionShape3D.new()
	var hurt_capsule := CapsuleShape3D.new()
	hurt_capsule.radius = .42 * maxf(proportions.x,proportions.z)
	hurt_capsule.height = 2.55 * proportions.y
	hurt_shape.shape = hurt_capsule
	hurt_shape.position.y = 1.30 * proportions.y
	hurtbox.add_child(hurt_shape)
	body.add_child(hurtbox)
	plate = Label3D.new()
	plate.position.y = 2.85 * proportions.y
	plate.pixel_size = .0035
	plate.font_size = 32
	plate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	plate.outline_size = 6
	plate.outline_modulate = Color("141c24")
	plate.render_priority = 3
	plate.outline_render_priority = 2
	body.add_child(plate)
	if str(record.get("importance","ordinary")) != "ordinary": _install_badge(proportions.y)
	var xy: Array = record.home
	body.position = Vector3(float(xy[0]),host._terrain_height(float(xy[0]),float(xy[1]))+.55,float(xy[1]))
	_refresh_plate()
	animator.play("Idle")
func _install_badge(height: float) -> void:
	plate.position.y = 3.27 * height
	plate.font_size = 43
	plate.pixel_size = .0038
	badge_background = MeshInstance3D.new()
	badge_background.name = "ImportantNPCBadge"
	var panel := QuadMesh.new()
	panel.size = Vector2(3.35,1.01)
	badge_background.mesh = panel
	badge_background.position = Vector3(0,3.29*height,-.018)
	var ink := StandardMaterial3D.new()
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ink.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	ink.cull_mode = BaseMaterial3D.CULL_DISABLED
	ink.albedo_color = Color(.045,.085,.12,.80)
	ink.render_priority = -2
	badge_background.material_override = ink
	body.add_child(badge_background)
	var rim := MeshInstance3D.new()
	var bar := QuadMesh.new()
	bar.size = Vector2(2.64,.055)
	rim.mesh = bar
	rim.position = Vector3(0,2.93*height,-.005)
	var gold := ink.duplicate()
	gold.albedo_color = Color(.65,.50,.26,.95)
	gold.render_priority = 0
	rim.material_override = gold
	body.add_child(rim)
	health_fill = MeshInstance3D.new()
	var fill := QuadMesh.new()
	fill.size = Vector2(2.54,.042)
	health_fill.mesh = fill
	health_fill.position = Vector3(0,2.93*height,.002)
	var life := ink.duplicate()
	life.albedo_color = Color(.36,.72,.62,.95)
	life.render_priority = 1
	health_fill.material_override = life
	body.add_child(health_fill)
func _install_cultivation() -> void:
	NPC_MOTION.add_cultivation(animator)
	qi_orbit = CULTIVATION_FX.new()
	var tier: int = clampi(int(record.get("cultivation_tier",1)),1,5)
	var tone := Color("e9b663") if str(record.id) == "estate_master_weak" else Color("69d8f0")
	qi_orbit.configure(tier,tone)
	qi_orbit.position.y = 1.25
	body.add_child(qi_orbit)
func _find_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer: return node
	for child in node.get_children():
		var found := _find_player(child)
		if found != null: return found
	return null
func _refresh_plate() -> void:
	if str(record.get("importance","ordinary")) == "ordinary":
		plate.text = "%s%s" % [str(record.get("display_name",record.label)),(" · %d/%d" % [hp,maximum]) if hp < maximum else ""]
		plate.modulate = Color("e4d8c6") if hp > maximum/3 else Color("ee9e82")
	else:
		plate.text = "◆ %s\n%s\nVIDA %d/%d" % [str(record.get("display_name",record.label)),str(record.get("title","")),hp,maximum]
		plate.modulate = Color("e7c48c") if hp > maximum/3 else Color("ee9e82")
		if health_fill != null:
			health_fill.scale.x = maxf(.001,float(hp)/maximum)
			health_fill.position.x = -(1.0-float(hp)/maximum)*1.27
func set_village_active(value: bool) -> void:
	active_in_village = value
	visible = value
	set_physics_process(value)
	if body != null:
		body.collision_layer = 64 if value and hp > 0 else 0
		body.collision_mask = (1|2) if value and hp > 0 else 0
		hurtbox.collision_layer = 32 if value and hp > 0 else 0
func take_hit(damage: int, from_position: Vector3) -> int:
	if hp <= 0 or not active_in_village: return 0
	var master := str(record.get("role","")) == "mestre de cultivo"
	if master: damage = maxi(1,int(ceil(damage*.38)))
	var dealt := mini(hp,maxi(0,damage))
	hp -= dealt
	state = "HURT" if hp > 0 else "DOWN"
	state_time = 0.0
	var away := (body.position-from_position)*Vector3(1,0,1)
	if away.length() > .01:
		away = away.normalized()*1.8
		body.velocity.x = away.x
		body.velocity.z = away.z
	if hp == 0:
		body.collision_layer = 0
		body.collision_mask = 0
		hurtbox.collision_layer = 0
		if animator.has_animation("Defeat"): animator.play("Defeat")
	elif animator.has_animation("Hit_Reaction"): animator.play("Hit_Reaction")
	_refresh_plate()
	if master and hp > 0 and counter_cooldown <= 0 and body.global_position.distance_to(host.actor.global_position) < 4.5:
		counter_cooldown = 5.0
		if animator.has_animation("Skill_Qi_Pulse"): animator.play("Skill_Qi_Pulse",.12)
		if not host.dodge_invulnerable and not host.health.dead:
			host.health.hp = maxi(0,host.health.hp-18)
			host.health.stun = .22
			if host.health.hp == 0: host.health.dead = true
			host.fx.impact(host.actor.global_position+Vector3.UP,(host.actor.global_position-body.global_position).normalized())
	life_changed.emit(str(record.id),hp)
	return dealt
func reset_life() -> void:
	hp = maximum
	state = "IDLE"
	state_time = 0
	clock_minutes = 540.0
	body.position = Vector3(float(record.home[0]),host._terrain_height(float(record.home[0]),float(record.home[1]))+.55,float(record.home[1]))
	body.collision_layer = 64
	body.collision_mask = 1|2
	hurtbox.collision_layer = 32
	animator.play("Idle")
	_refresh_plate()
func _physics_process(delta: float) -> void:
	if not active_in_village: return
	var show_distance: float = 22.0 if str(record.get("importance","ordinary")) != "ordinary" else 9.0
	var view_camera := get_viewport().get_camera_3d()
	var camera_clear: bool = view_camera == null or body.global_position.distance_to(view_camera.global_position) > (3.2 if badge_background != null else 1.5)
	var show_badge: bool = body.global_position.distance_to(host.actor.global_position) < show_distance and camera_clear and hp > 0
	plate.visible = show_badge
	if badge_background != null: badge_background.visible = show_badge
	if health_fill != null: health_fill.visible = show_badge
	clock_minutes = fmod(clock_minutes+delta*4.0,1440.0)
	state_time += delta
	counter_cooldown = maxf(0,counter_cooldown-delta)
	if hp <= 0:
		body.velocity = Vector3.ZERO
		return
	if state == "HURT":
		body.velocity.x = move_toward(body.velocity.x,0,delta*8)
		body.velocity.z = move_toward(body.velocity.z,0,delta*8)
		if state_time > .55: state = "FLEE";state_time = 0
	elif state == "FLEE" and state_time > 9.0:
		state = "IDLE";state_time = 0
	var target := _destination()
	var cultivating := str(record.get("role","")) in ["discípulo","mestre de cultivo"] and state not in ["HURT","FLEE"] and body.position.distance_to(target) < 1.5 and int(clock_minutes) % 480 < 310
	if cultivating:
		if state != "CULTIVATE": cultivation_time = 0.0
		state = "CULTIVATE"
	elif state == "CULTIVATE": state = "IDLE"
	var offset := (target-body.position)*Vector3(1,0,1)
	var direction := Vector3.ZERO
	if state not in ["HURT","CULTIVATE"] and offset.length() > .65:
		direction = offset.normalized()
		direction = _steer(direction)
	body.velocity.x = move_toward(body.velocity.x,direction.x*1.18,delta*5)
	body.velocity.z = move_toward(body.velocity.z,direction.z*1.18,delta*5)
	body.velocity.y = -.2 if body.is_on_floor() else body.velocity.y-23*delta
	body.move_and_slide()
	if direction.length() > .1:
		visual.rotation.y = lerp_angle(visual.rotation.y,atan2(-direction.x,-direction.z),minf(1,delta*5))
		if (animator.current_animation != "Walk" or not animator.is_playing()) and state != "HURT": animator.play("Walk",.15)
	elif state == "CULTIVATE":
		cultivation_time += delta
		var cycle := fmod(cultivation_time,11.0)
		var clip := ""
		if cycle < 2.0:
			cultivation_stage = "gather";cultivation_progress = cycle/2.0;clip = "village_life/Gather_Qi"
		elif cycle < 7.0:
			cultivation_stage = "circulate";cultivation_progress = (cycle-2.0)/5.0;clip = "village_life/Circulate_Qi"
		elif cycle < 8.8:
			cultivation_stage = "release";cultivation_progress = (cycle-7.0)/1.8;clip = "village_life/Release_Qi"
		else:
			cultivation_stage = "settle";cultivation_progress = (cycle-8.8)/2.2;clip = "village_life/Cultivate"
		if animator.current_animation != clip: animator.play(clip,.24)
	elif state != "HURT":
		var idle_clip := _idle_variation()
		if animator.current_animation != idle_clip: animator.play(idle_clip,.26)
	if qi_orbit != null:
		var active_qi := state == "CULTIVATE" or (str(record.get("importance","")) == "master" and animator.current_animation == work_clip)
		var stage := cultivation_stage if state == "CULTIVATE" else "form"
		qi_orbit.update_fx(active_qi,stage,cultivation_progress,host.climate.night_lighting_enabled,delta)
func _idle_variation() -> String:
	var phase := (int(clock_minutes/30.0)+absi(hash(str(record.id)))%7)%5
	if phase == 0: return "village_life/Elder_Idle" if str(record.get("age_band","")) == "elder" else "village_life/LookAround"
	if phase == 1 or phase == 3: return work_clip
	if phase == 4: return "village_life/Stretch"
	return "Idle"
func _destination() -> Vector3:
	var xy: Array = record.home
	if state != "FLEE" and host.climate.weather_name != "night" and clock_minutes >= 420 and clock_minutes < 1140:
		var route: Array = record.route
		xy = route[int(clock_minutes/120.0)%route.size()]
	return Vector3(float(xy[0]),0,float(xy[1]))
func _steer(direction: Vector3) -> Vector3:
	var a := body.global_position+Vector3(0,1.1,0)
	var space := get_world_3d().direct_space_state
	for angle in [0.0,.55,-.55,1.1,-1.1]:
		var candidate := direction.rotated(Vector3.UP,angle)
		var ray := PhysicsRayQueryParameters3D.create(a,a+candidate*1.15,1)
		if space.intersect_ray(ray).is_empty(): return candidate
	return Vector3.ZERO
func save_state() -> Dictionary:
	return {"hp":hp,"clock":clock_minutes,"position":[body.position.x,body.position.y,body.position.z],"state":state}
func load_state(saved: Dictionary) -> void:
	hp = clampi(int(saved.get("hp",maximum)),0,maximum)
	clock_minutes = clampf(float(saved.get("clock",540)),0,1439)
	var pos: Array = saved.get("position",[])
	if pos.size() == 3:
		var restored := Vector3(float(pos[0]),float(pos[1]),float(pos[2]))
		var anchor := Vector3(float(record.home[0]),0,float(record.home[1]))
		if restored.is_finite() and (restored-anchor).length() < 40: body.position = restored+Vector3(0,.2,0)
	state = "DOWN" if hp == 0 else "IDLE"
	if hp == 0:
		body.collision_layer = 0;body.collision_mask = 0;hurtbox.collision_layer = 0
		if animator.has_animation("Defeat"): animator.play("Defeat")
	_refresh_plate()
