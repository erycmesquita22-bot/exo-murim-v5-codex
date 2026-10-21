extends Node3D

const Slots=preload("res://data/slot_rules.gd")
const Catalog=preload("res://catalog.gd")
const Arsenal=preload("res://arsenal.gd")
const Anatomy=preload("res://anatomy.gd")
var attack_spec: Dictionary={}
var attack_duration:=0.52
var attack_hit:=0.23
var attack_damage:=12
var combat_timer:=0.0
var martial: RefCounted
var combat: RefCounted
var audio_fx: Node

const MurimFlow=preload("res://murim_flow.gd")
var activity: RefCounted
var flow: RefCounted
var world_seed_override:=-1
var inventory: RefCounted
var cultivation: RefCounted
var encounters: Node3D
var aim_point:=Vector3.ZERO
var aim_has_target:=false

const Graphics=preload("res://graphics.gd")
const BossArt=preload("res://boss_art.gd")
const Rig=preload("res://rig.gd")
const Techniques=preload("res://techniques.gd")
const PauseUI=preload("res://pause_ui.gd")
const Enemy=preload("res://enemy.gd")
const JourneySave=preload("res://journey_save.gd")
const WorldSeed=preload("res://procedural/world_state.gd")
const Region=preload("res://region.gd")
const ATTACK_DURATION:=0.52
const ATTACK_HIT:=0.23
const ROLL_DURATION:=0.46
const ROLL_COOLDOWN:=0.85
const MOUSE_SENSITIVITY:=1.0
const CAMP:=Vector3(0,0.03,26)
const RUINS:=Vector3(-3,0.03,-7)
const ALTAR:=Vector3(0,0.03,-35)
const NPC_POS:=Vector3(-2.5,0.03,25)
const ROSTER:=[
	["road_blade","blade",Vector3(1,0.03,-4)],
	["road_mage","mage",Vector3(-3,0.03,-10)],
	["ruin_blade_a","blade",Vector3(8,0.03,-24)],
	["ruin_mage","mage",Vector3(-3,0.03,-21)],
	["ruin_blade_b","blade",Vector3(3,0.03,-25)],
	["ascendant","boss",Vector3(0,0.03,-31)]]

var player: CharacterBody3D
var model: Node3D
var camera: Camera3D
var ui: CanvasLayer
var techniques: RefCounted
var journey: RefCounted
var save_path:=JourneySave.DEFAULT_PATH
var load_on_start:=true
var enemies: Array[Node3D]=[]
var target: Node3D
var npc: Node3D
var beacon: MeshInstance3D
var fragment: MeshInstance3D
var badge: MeshInstance3D
var elapsed:=0.0
var health:=100
var max_health:=100
var graphics: RefCounted
var settings_path:="user://graphics.cfg"
var sun: DirectionalLight3D
var environment: Environment
var shake:=0.0
var trial_mode:=false
var combo_index:=0
var combo_queued:=false
var combo_timeout:=0.0
const COMBO_DURATION:=[0.48,0.50,0.66]
const COMBO_HIT:=[0.20,0.22,0.31]
const COMBO_DAMAGE:=[12,14,20]
var facing:=Vector3.FORWARD
var aim_source:="mouse"
var aim_offset:=Vector2(0,-140)
var attack_time:=-1.0
var attack_direction:=Vector3.FORWARD
var attack_landed:=false
var roll_time:=-1.0
var roll_cooldown:=0.0
var roll_direction:=Vector3.RIGHT
var roll_side:=1.0
var roll_forward:=0.0
var roll_lateral:=1.0
var invulnerability:=0.0
var feedback:=""
var feedback_time:=0.0
var hits:=0
var dodges:=0
var effects: Array[Dictionary]=[]
var hostile_shots: Array[Dictionary]=[]
var headless:=false
var batch_static:=true
var autosave_time:=0.0
var interaction_cooldown:=0.0
var simulation_enabled:=true
var region_nodes: Array[Node]=[]
var exploration_sites: Array[Dictionary]=[]
# Movement safety: newly spawned actors must have a valid floor and free capsule.
# This does not change the save schema or the generated village.
var pending_ground_check: bool=false
var movement_stall_time: float=0.0
var spawn_recovery_done: bool=false
var spawn_recovery_elapsed: float=0.0
var spawn_recovery_center: Vector3=Vector3.ZERO
var last_physics_position: Vector3=Vector3.ZERO
var terrain_safety_cooldown: float=0.0

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_PAUSABLE
	headless=DisplayServer.get_name()=="headless"
	get_tree().auto_accept_quit=false
	combat=preload("res://combat/player_combat.gd").new(self)
	setup_inputs()
	var sky:=WorldEnvironment.new()
	sky.environment=Environment.new()
	sky.environment.background_mode=Environment.BG_COLOR
	sky.environment.background_color=Color("142832")
	sky.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	sky.environment.ambient_light_color=Color("b6cce0")
	sky.environment.ambient_light_energy=0.33
	add_child(sky)
	environment=sky.environment
	sun=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-55,-25,0)
	sun.light_color=Color("fff1d1")
	sun.light_energy=0.85
	sun.shadow_enabled=true
	add_child(sun)
	player=make_player()
	model=Rig.new()
	player.add_child(model)
	badge=MeshInstance3D.new()
	var badge_mesh:=BoxMesh.new()
	badge_mesh.size=Vector3(0.13,0.13,0.025)
	badge.mesh=badge_mesh
	var gold:=StandardMaterial3D.new()
	gold.albedo_color=Color("f4cf79")
	badge.material_override=gold
	model.torso.add_child(badge)
	badge.position=Vector3(-0.12,0.48,-0.145)
	camera=Camera3D.new()
	add_child(camera)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=15
	camera.current=true
	audio_fx=preload("res://exo_audio.gd").new()
	add_child(audio_fx)
	techniques=Techniques.new(self)
	journey=JourneySave.new(save_path,world_seed_override)
	if load_on_start:
		journey.load_progress()
	inventory=preload("res://inventory.gd").new(self)
	cultivation=preload("res://cultivation.gd").new(self)
	martial=preload("res://combat/martial_motion.gd").new(self)
	graphics=Graphics.new(self,settings_path)
	rebuild_region()
	for spec in ROSTER:
		var actor:=Enemy.new()
		actor.setup(self,spec[0],spec[1],spec[2])
		add_child(actor)
		enemies.append(actor)
	npc=Rig.new(Color("a2c6bd"))
	add_child(npc)
	npc.position=village_anchor("npc",NPC_POS)
	npc.sword.visible=false
	if get_meta("village_services",{}).is_empty():
		add_sign(NPC_POS+Vector3(0,2.5,0),"GUILDA • E",Color("e9d8a9"))
	beacon=techniques.sphere(0.16,Color("f1d597"))
	fragment=techniques.sphere(0.28,Color("8ee3e6"))
	fragment.position=ALTAR+Vector3(0,1.55,0)
	graphics.apply()
	ui=PauseUI.new()
	ui.world=self
	add_child(ui)
	resume_checkpoint()
	message(journey.status if not journey.status.is_empty() else "Procure o Cronista no acampamento.")
	set_paused(true)
	flow=MurimFlow.new(self)
	activity=preload("res://activities/meditation.gd").new(self)
	encounters=preload("res://encounters.gd").new()
	encounters.world=self
	add_child(encounters)
	inventory.rebuild_drops()
	ui.boot()


func rebuild_region() -> void:
	# Reuse the single scene, discard only region-owned nodes (not player/NPC/UI).
	for node in region_nodes:
		if is_instance_valid(node):node.free()
	region_nodes.clear()
	exploration_sites.clear()
	var existing: Dictionary={}
	for node in get_children():existing[node.get_instance_id()]=true
	Region.build(self)
	if batch_static:preload("res://world/static_batch.gd").apply(self)
	for node in get_children():
		if not existing.has(node.get_instance_id()):region_nodes.append(node)
	if is_instance_valid(npc):npc.position=village_anchor("npc",NPC_POS)
	if flow!=null:flow.sync_village_sites()
	if graphics!=null and sun!=null:graphics.apply()

func village_anchor(key: String,fallback: Vector3) -> Vector3:
	var anchors: Dictionary=get_meta("village_services",{})
	return anchors.get(key,fallback)

func register_exploration_site(id: String,point: Vector3) -> void:
	exploration_sites.append({"id":id,"point":point})

func nearby_exploration() -> String:
	if flow==null or flow.phase!="adventure" or flow.lab_mode:return ""
	for site in exploration_sites:
		if player.position.distance_to(site.point)<3.2:return str(site.id)
	return ""

func explore_nearby() -> bool:
	var id: String=nearby_exploration()
	if id.is_empty():return false
	var key: String="loot/explore_"+id
	if WorldSeed.has_event(journey.data.world,key):
		message("Este marco já foi explorado nesta jornada.")
		return true
	if journey.data.items.size()>=preload("res://inventory.gd").CAPACITY:
		message("Inventário cheio. Liberte espaço antes de recolher o achado.")
		return true
	var backup: Dictionary=journey.data.duplicate(true)
	var uid: String="item_%d"%int(journey.data.next_item)
	var pool: String="mage" if id=="forest" else "blade" if id=="mountain" else "boss"
	var tier: int=1 if id=="forest" else 2
	var drop: Dictionary=preload("res://procedural/loot_generator.gd").generate(journey.data.world,key,pool,tier,uid)
	if drop.is_empty() or not preload("res://inventory.gd").valid_item(drop):
		message("O achado não pôde ser preparado.")
		return true
	journey.data.next_item+=1
	journey.data.items.append(drop)
	if not WorldSeed.mark_collected(journey.data.world,key):
		journey.data=backup
		return true
	if not save_progress():
		journey.data=backup
		return true
	message("Marco explorado • equipamento encontrado: "+preload("res://inventory.gd").title(drop))
	ui.refresh()
	return true

func make_player() -> CharacterBody3D:
	var body:=CharacterBody3D.new()
	body.collision_layer=2
	body.collision_mask=1|4
	body.floor_snap_length=0.35
	body.floor_max_angle=deg_to_rad(50.0)
	body.safe_margin=0.025
	var collider:=CollisionShape3D.new()
	var capsule:=CapsuleShape3D.new()
	capsule.radius=0.3
	capsule.height=1.95
	collider.shape=capsule
	collider.position.y=0.98
	body.add_child(collider)
	add_child(body)
	return body

# A newly created village may place an entrance or scenery near the player's
# saved position. Validate against actual walkable collision, not a hard-coded Y.
func prepare_player_spawn(point: Vector3) -> void:
	player.position=point
	player.velocity=Vector3.ZERO
	pending_ground_check=true
	spawn_recovery_done=false
	spawn_recovery_elapsed=0.0
	movement_stall_time=0.0
	spawn_recovery_center=point
	last_physics_position=point
	terrain_safety_cooldown=0.0

func find_walkable_spawn(point: Vector3,try_neighbors: bool=true) -> Vector3:
	var space: PhysicsDirectSpaceState3D=get_world_3d().direct_space_state
	var candidate_offsets: Array[Vector2]=[Vector2.ZERO]
	if try_neighbors:
		candidate_offsets.append_array([Vector2(1.2,0),Vector2(-1.2,0),Vector2(0,1.2),Vector2(0,-1.2),Vector2(2.5,0),Vector2(-2.5,0),Vector2(0,2.5),Vector2(0,-2.5),Vector2(3.5,3.5),Vector2(-3.5,3.5)])
	for offset in candidate_offsets:
		var x: float=point.x+offset.x
		var z: float=point.z+offset.y
		var query: PhysicsRayQueryParameters3D=PhysicsRayQueryParameters3D.create(Vector3(x,maxf(point.y+6.0,8.0),z),Vector3(x,-15.0,z),1)
		var hit: Dictionary=space.intersect_ray(query)
		if hit.is_empty() or Vector3(hit.normal).dot(Vector3.UP)<0.78:
			continue
		var result: Vector3=Vector3(x,Vector3(hit.position).y+0.085,z)
		var capsule: CollisionShape3D=player.get_child(0) as CollisionShape3D
		var probe: PhysicsShapeQueryParameters3D=PhysicsShapeQueryParameters3D.new()
		probe.shape=capsule.shape
		probe.transform=Transform3D(Basis.IDENTITY,result+capsule.position)
		probe.collision_mask=1 | 4
		probe.exclude=[player.get_rid()]
		if space.intersect_shape(probe,8).is_empty():
			return result
	# Do not pretend that a blocked position is a validated spawn. A primitive
	# floor is always available on the central village route.
	# If the collision world is still being synchronized, use an open central
	# route instead of retaining a potentially embedded position at a house.
	return Vector3(0,0.12,32)

func settle_player_on_ground() -> void:
	if flow==null or flow.phase!="adventure":
		pending_ground_check=false
		return
	var destination_point: Vector3=find_walkable_spawn(player.position)
	player.position=destination_point
	player.velocity=Vector3.ZERO
	player.reset_physics_interpolation()
	pending_ground_check=false
	last_physics_position=destination_point
	spawn_recovery_center=destination_point

# Only during initial spawn, not while the user intentionally runs into a wall.
func check_spawn_movement(delta: float,movement: Vector3) -> void:
	if flow==null or flow.phase!="adventure" or spawn_recovery_done:
		last_physics_position=player.position
		return
	spawn_recovery_elapsed+=delta
	if spawn_recovery_elapsed>8.0 or player.position.distance_to(spawn_recovery_center)>3.5:
		spawn_recovery_done=true
		return
	var displacement: float=Vector2(player.position.x-last_physics_position.x,player.position.z-last_physics_position.z).length()
	last_physics_position=player.position
	if movement.length()>0.25 and attack_time<0 and roll_time<0 and not techniques.busy() and (activity==null or not activity.locked()) and displacement<0.008:
		movement_stall_time+=delta
	else:
		movement_stall_time=0.0
	if movement_stall_time>0.65:
		print("EXO movement recovery: floor=",player.is_on_floor()," pos=",player.position," input=",movement)
		var safe: Vector3=find_walkable_spawn(spawn_recovery_center+Vector3(1.2,0,1.2))
		player.position=safe
		player.velocity=Vector3.ZERO
		player.reset_physics_interpolation()
		spawn_recovery_done=true
		movement_stall_time=0.0


func rescue_from_missing_adventure_floor(delta: float) -> void:
	# A rescue is a last resort, not a replacement for solid terrain collision.
	# Keep training, the prologue and legitimate jumps completely untouched.
	if flow==null or flow.phase!="adventure" or flow.lab_mode:
		return
	terrain_safety_cooldown=maxf(0.0,terrain_safety_cooldown-delta)
	if terrain_safety_cooldown>0.0 or player.is_on_floor():
		return
	if absf(player.position.x)>102.0 or player.position.z< -118.0 or player.position.z>102.0:
		return
	var landscape=preload("res://world/landscape.gd")
	var noise: FastNoiseLite=landscape.noise_for(journey.data.world)
	var expected_y: float=landscape.height_at(player.position.x,player.position.z,noise)
	if player.position.y>=expected_y-0.55:
		return
	var location: Vector3=find_walkable_spawn(Vector3(player.position.x,expected_y+0.12,player.position.z))
	if location.y<expected_y-0.25:
		location=find_walkable_spawn(village_anchor("camp",CAMP))
	player.position=location
	player.velocity=Vector3.ZERO
	player.reset_physics_interpolation()
	terrain_safety_cooldown=2.0
	spawn_recovery_done=true
	print("EXO adventure floor rescue: expected=",expected_y," restored=",location)

func set_paused(value: bool) -> void:
	if not value and health<=0:
		return
	get_tree().paused=value
	if value and is_instance_valid(audio_fx):audio_fx.stop_movement()
	if value and flow!=null:
		flow.meditating=false
	if not headless:
		Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED
	ui.show_menu(value)
	if value:
		for action in ["left","right","up","down","jump","sprint","dash","attack","skill_1","skill_2","skill_3","skill_4","skill_5","skill_6","interact","toggle_hands"]:
			Input.action_release(action)

func _physics_process(delta: float) -> void:
	if not simulation_enabled:
		return
	if flow!=null and not flow.tick(delta):
		return
	if pending_ground_check:
		settle_player_on_ground()
	elapsed+=delta
	combat_timer=maxf(0,combat_timer-delta)
	journey.data.seconds+=delta
	combo_timeout=maxf(0,combo_timeout-delta)
	shake=maxf(0,shake-delta*0.5)
	roll_cooldown=maxf(0,roll_cooldown-delta)
	invulnerability=maxf(0,invulnerability-delta)
	feedback_time=maxf(0,feedback_time-delta)
	interaction_cooldown=maxf(0,interaction_cooldown-delta)
	var axis:=Input.get_vector("left","right","up","down")
	var movement:=screen_direction(axis)
	if activity!=null and activity.locked():movement=Vector3.ZERO
	techniques.tick(delta)
	if Input.is_action_just_pressed("interact"):
		interact()
		if get_tree().paused:
			return
	if Input.is_action_just_pressed("toggle_hands"):martial.toggle()
	if Input.is_action_just_pressed("dash"):
		start_dash(movement)
	for i in range(techniques.DATA.size()):
		if Input.is_action_just_pressed("skill_%d" % (i+1)):
			techniques.cast(i)
	if Input.is_action_pressed("attack"):
		start_attack()
	var sprint:=Input.is_action_pressed("sprint")
	var speed: float=(6.8 if sprint else 4.4)*(1.08 if race_body()=="feline" else 1.0)
	speed*=1+equipment_stat("move_pct")
	if activity!=null and activity.aligning():
		var approach: Vector3=activity.approach_velocity(delta)
		player.velocity.x=approach.x;player.velocity.z=approach.z
	elif roll_time>=0:
		roll_time+=delta
		player.velocity.x=roll_direction.x*7.5
		player.velocity.z=roll_direction.z*7.5
		if roll_time>=ROLL_DURATION:
			roll_time=-1
			player.velocity.x=0
			player.velocity.z=0
	elif techniques.busy():
		techniques.move(movement)
	elif attack_time>=0:
		player.velocity.x=move_toward(player.velocity.x,movement.x*speed*.78,30*delta)
		player.velocity.z=move_toward(player.velocity.z,movement.z*speed*.78,30*delta)
	else:
		player.velocity.x=move_toward(player.velocity.x,movement.x*speed,24*delta)
		player.velocity.z=move_toward(player.velocity.z,movement.z*speed,24*delta)
	if not player.is_on_floor():
		player.velocity.y-=20*delta
	if Input.is_action_just_pressed("jump") and player.is_on_floor() and roll_time<0 and attack_time<0 and not techniques.busy():
		player.velocity.y=7.3*(1.1 if race_body() in ["hawk","raven"] else 1.0)
	player.move_and_slide()
	check_spawn_movement(delta,movement)
	rescue_from_missing_adventure_floor(delta)
	techniques.after_motion()
	update_attack(delta)
	if attack_time<0 and roll_time<0 and not techniques.busy():
		set_facing(facing)
	martial.before_pose(delta,movement)
	model.pose(elapsed,false,sprint,player.is_on_floor(),-1,roll_time/ROLL_DURATION if roll_time>=0 else -1,roll_side)
	if roll_time>=0:
		model.directional_roll(roll_time/ROLL_DURATION,roll_lateral,roll_forward)
	else:
		model.locomotion(player.get_real_velocity(),delta,sprint,player.is_on_floor(),attack_time<0 and not techniques.busy())
	if attack_time>=0:
		Arsenal.animate(model,attack_spec,combo_index,attack_time/attack_duration)
	elif roll_time<0 and not techniques.busy() and not martial.stowed() and martial.ready_weight>.01:
		Arsenal.animate(model,current_weapon(),0,-1)
	techniques.animate()
	Anatomy.animate(model,elapsed,player.get_real_velocity().length(),player.is_on_floor())
	if activity!=null:activity.pose()
	martial.finish(delta)
	for actor in enemies:
		if not trial_mode or actor.kind=="boss":
			actor.step(delta)
		if get_tree().paused:
			break
	update_hostile_shots(delta)
	update_effects(delta)
	update_quest(delta)
	update_camera()
	npc.pose(elapsed,false,false,true)
	badge.visible=journey.data.claimed and (flow==null or flow.phase=="adventure")
	fragment.visible=false
	fragment.rotation.y+=delta
	beacon.visible=flow==null or flow.has_destination()
	beacon.position=destination()+Vector3(0,.5+sin(elapsed*2)*0.09,0)
	audio_fx.steps(player.position,player.is_on_floor(),axis.length()>.05 and roll_time<0)
	ui.refresh()

func start_attack() -> bool:
	return combat.start_attack()

func update_attack(delta: float) -> void:
	combat.update_attack(delta)

func start_dash(movement: Vector3=Vector3.ZERO) -> bool:
	return combat.start_dash(movement)

func damage_player(amount: int,context: Dictionary={}) -> bool:
	return combat.damage_player(amount,context)

func enemy_defeated(actor: Node3D) -> void:
	if flow.phase!="adventure":return
	if trial_mode and actor.kind=="boss":call_deferred("finish_trial");return
	if actor.uid not in journey.data.defeated:
		inventory.drop_for(actor);journey.data.defeated.append(actor.uid)
	message("O Vigia caiu. As ruínas guardam sua memória." if actor.kind=="boss" else "Salteador afastado.")
	save_progress()

func save_progress() -> bool:
	if flow!=null and (flow.replaying or flow.lab_mode):
		return true
	var ok: bool=journey.write()
	if not ok:
		message(journey.status)
	return ok

func resume_checkpoint() -> void:
	combat_timer=0
	prepare_player_spawn(RUINS if journey.data.checkpoint=="ruins" else village_anchor("camp",CAMP))
	trial_mode=false
	apply_boon()
	health=max_health
	combo_index=0
	combo_timeout=0
	combo_queued=false
	attack_time=-1
	roll_time=-1
	roll_cooldown=0
	invulnerability=1.2
	hits=0
	techniques.reset()
	clear_hostile_shots()
	for effect in effects:
		effect.node.queue_free()
	effects.clear()
	for actor in enemies:
		actor.restore(actor.uid in journey.data.defeated)
	target=null
	model.pose(0,false,false,true)
	model.gait_phase=0
	model.rotation=Vector3.ZERO
	aim_offset=Vector2(0,-140)
	update_camera()
	mouse_aim(Vector2(0,-0.51))
	beacon.position=destination()+Vector3(0,.5,0)
	badge.visible=journey.data.claimed
	fragment.visible=false
	if flow!=null and flow.phase=="adventure":
		flow.apply_character()
	ui.refresh()

func new_journey() -> void:
	if flow!=null:
		flow.clear_actors()
		journey=JourneySave.new(save_path,world_seed_override)
		rebuild_region()
		journey.allow_reset_invalid=true
		flow.god.hide()
		resume_checkpoint()
		player.position=Vector3(90,0.03,7)
		pending_ground_check=false
		flow.Wardrobe.apply(model,Catalog.hero_profile(int(journey.data.hero)))
		for actor in enemies:
			actor.enabled=false
		save_progress()
		ui.cinematic("",false)
		ui.show_hero()
		return
	journey=JourneySave.new(save_path,world_seed_override)
	rebuild_region()
	resume_checkpoint()
	save_progress()
	ui.first_play=true
	message("Nova jornada. Fale com o Cronista usando E.")

func interact() -> void:
	if get_tree().paused or health<=0 or interaction_cooldown>0 or not player.is_on_floor() or attack_time>=0 or roll_time>=0 or techniques.busy():
		return
	interaction_cooldown=0.5
	flow.interact()

func rest(checkpoint: String) -> void:
	for actor in enemies:
		if actor.hp>0 and actor.position.distance_to(player.position)<7:
			message("Há inimigos próximos. Afaste-os antes de descansar.")
			return
	health=max_health
	techniques.mana=100
	techniques.stamina=100
	journey.data.checkpoint=checkpoint
	if save_progress():
		message("Descanso concluído. Marco de retorno salvo.")

func update_quest(delta: float) -> void:flow.update_quest(delta)
func objective() -> String:
	if flow==null:return ""
	return "Duelo de treino: vença o Vigia. Sem nova recompensa." if trial_mode else flow.objective()
func destination() -> Vector3:return CAMP if flow==null else Vector3(0,.03,-31) if trial_mode else flow.destination()
func interaction_hint() -> String:return "" if flow==null else flow.hint()

func enemy_orb(origin: Vector3, direction: Vector3, amount: int) -> void:
	combat.enemy_orb(origin,direction,amount)

func update_hostile_shots(delta: float) -> void:
	combat.update_hostile_shots(delta)

func clear_hostile_shots() -> void:
	combat.clear_hostile_shots()

func aim_line(origin: Vector3, direction: Vector3, length: float, duration: float, color: Color=Color("ba7caa")) -> void:
	var node:=block(origin+direction*length*0.5+Vector3(0,0.04,0),Vector3(0.1,0.03,length),color,false)
	node.rotation.y=atan2(-direction.x,-direction.z)
	effects.append({"node":node,"time":duration})

func add_sign(pos: Vector3, text: String, color: Color) -> void:
	# Building labels are proximity HUD areas instead of text through walls.
	var area:=preload("res://location_area.gd").new()
	add_child(area)
	var entry:=Vector3(pos.x,0,pos.z)
	var anchors: Dictionary=get_meta("village_services",{})
	if not anchors.is_empty():
		if text.contains("GUILDA"):entry=anchors.get("npc",entry)
		elif text.contains("POUSADA") or text.contains("DESCANSO"):entry=anchors.get("bed",entry)
		elif text.contains("PÁTIO") or text.contains("MEDITAÇÃO"):entry=anchors.get("mat",entry)
		area.setup(self,entry,text)
		return
	if text.contains("GUILDA DOS"):entry=Vector3(-12,0,34.8)
	elif text.contains("POUSADA"):entry=Vector3(12,0,35.3)
	elif text.contains("PÁTIO DE TREINO"):entry=Vector3(13,0,23.8)
	elif text.contains("GUILDA •"):entry=NPC_POS
	area.setup(self,entry,text)


func setup_inputs() -> void:
	for spec in [["toggle_hands",KEY_R],["left",KEY_A],["right",KEY_D],["up",KEY_W],["down",KEY_S],["jump",KEY_SPACE],["sprint",KEY_SHIFT],["dash",KEY_F],["skill_1",KEY_1],["skill_2",KEY_2],["skill_3",KEY_3],["skill_4",KEY_4],["skill_5",KEY_5],["skill_6",KEY_6],["interact",KEY_E]]:
		if not InputMap.has_action(spec[0]):
			InputMap.add_action(spec[0])
		var event := InputEventKey.new()
		event.physical_keycode = spec[1]
		InputMap.action_add_event(spec[0],event)
	for spec in [["attack",MOUSE_BUTTON_LEFT]]:
		if not InputMap.has_action(spec[0]):
			InputMap.add_action(spec[0])
		var event := InputEventMouseButton.new()
		event.button_index = spec[1]
		InputMap.action_add_event(spec[0],event)


func block(pos: Vector3, size: Vector3, color: Color, solid: bool) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material_override = material
	mesh.add_to_group("static_geometry")
	add_child(mesh)
	mesh.position = pos
	if solid:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		add_child(body)
		body.position = pos


	return mesh


func _input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event is InputEventMouseMotion and (headless or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED):
		mouse_aim(event.relative)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(ui):
		set_paused(true)
	elif what==NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(journey):
		if save_progress():
			get_tree().quit()
		else:
			set_paused(true)


func screen_direction(axis: Vector2) -> Vector3:
	return Vector3(axis.x+axis.y,0,axis.y-axis.x).normalized()*minf(1,axis.length())

func set_facing(direction: Vector3) -> void:
	if direction.length_squared() < 0.001:
		return
	aim_has_target=false
	facing = Vector3(direction.x,0,direction.z).normalized()
	if attack_time < 0 and roll_time < 0 and (techniques == null or not techniques.busy()):
		model.rotation.y = atan2(-facing.x,-facing.z)

func mouse_aim(relative: Vector2) -> void:
	if martial!=null:martial.aim_hold=.6
	if relative.length_squared() < 0.25:
		return
	aim_source = "mouse"
	var limit := get_viewport().get_visible_rect().size*0.42
	aim_offset = (aim_offset+relative*MOUSE_SENSITIVITY).clamp(-limit,limit)
	# The captured mouse drives a virtual aiming point around the character.
	# A minimum radius avoids sudden flips directly over the character.
	if aim_offset.length() < 24:
		aim_offset = aim_offset.normalized()*24 if aim_offset.length() > 0.01 else Vector2(0,-24)
	refresh_aim_target()

func refresh_aim_target() -> void:
	var point := camera.unproject_position(player.position+Vector3(0,1.1,0))+aim_offset
	var origin := camera.project_ray_origin(point)
	var ray := camera.project_ray_normal(point)
	if absf(ray.y) > 0.001:
		var target := origin+ray*((player.position.y+1.1-origin.y)/ray.y)
		set_facing(target-player.position)
		aim_point=target
		aim_has_target=true


func combat_actor_rids() -> Array[RID]:
	var result:Array[RID]=[player.get_rid()]
	for actor in enemies:
		if is_instance_valid(actor) and actor is CollisionObject3D:result.append(actor.get_rid())
	var inhabitants:Variant=get("residents")
	if inhabitants is Array:
		for actor in inhabitants:
			if is_instance_valid(actor) and actor is CollisionObject3D:result.append(actor.get_rid())
	return result

func can_hit(origin: Vector3, target: Vector3, direction: Vector3, distance: float, cone: float) -> bool:
	if absf(origin.y-target.y) > 1.25:
		return false
	var offset := target-origin
	offset.y = 0
	if offset.length() > distance or (offset.length() > 0.001 and offset.normalized().dot(direction) < cone):
		return false
	var query := PhysicsRayQueryParameters3D.create(origin+Vector3.UP,target+Vector3.UP,1|4)
	query.exclude=combat_actor_rids()
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func update_camera() -> void:
	var focus: Vector3=player.global_position+Vector3(0,0.8,0)
	var desired: Vector3=player.global_position+Vector3(10,11,10)
	var query:=PhysicsRayQueryParameters3D.create(focus,desired,1|4)
	query.exclude=[player.get_rid()]
	var obstruction: Dictionary=get_world_3d().direct_space_state.intersect_ray(query)
	camera.global_position=desired if obstruction.is_empty() else obstruction.position+obstruction.normal*0.45
	camera.look_at(focus)
	if graphics!=null and graphics.shake_enabled and shake>0:
		camera.position+=Vector3(sin(elapsed*97),cos(elapsed*121),0)*shake


func message(text: String) -> void:
	feedback = text
	feedback_time = 3.0


func spawn_arc(origin: Vector3, direction: Vector3, radius: float, color: Color, duration: float) -> void:
	var node := MeshInstance3D.new()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var angle := atan2(direction.x,direction.z)
	var segments: int=graphics.segments() if graphics!=null else 16
	for i in range(segments):
		var a := angle-1.0+2.0*float(i)/segments
		var b := angle-1.0+2.0*float(i+1)/segments
		var points := [Vector3(sin(a),0,cos(a))*radius,Vector3(sin(b),0,cos(b))*radius,Vector3(sin(b),0,cos(b))*(radius-0.1),Vector3(sin(a),0,cos(a))*(radius-0.1)]
		for index in [0,1,2,0,2,3]:
			surface.add_vertex(points[index])
	node.mesh = surface.commit()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	node.material_override = material
	add_child(node)
	node.position = origin+Vector3(0,0.035,0)
	effects.append({"node":node,"time":duration})


func update_effects(delta: float) -> void:
	for i in range(effects.size()-1,-1,-1):
		effects[i].time -= delta
		if effects[i].time <= 0:
			effects[i].node.queue_free()
			effects.remove_at(i)


func play_sound(kind: String) -> void:
	audio_fx.play_event(kind,"magic" if kind in ["boss_entry","boss_phase"] else "combat",.7)

func impact_feedback(strength: float) -> void:
	shake=minf(0.1,maxf(shake,strength))

func apply_boon() -> void:
	var profile:=current_profile()
	var race: Dictionary=Catalog.RACES[int(profile.get("race",0))]
	max_health=100+int(race.hp)+attribute("vitalidade")*2+(15 if has_passive("corpo_1") else 0)+(20 if int(profile.get("path",0))==2 else 0)+(20 if journey.data.boon=="vitality" else 0)
	health=mini(health,max_health)

func select_boon(id: String) -> bool:
	if not journey.choose_boon(id):
		message("O bônus legado não pôde ser registrado.")
		return false
	apply_boon()
	if id=="vitality":
		health=mini(max_health,health+20)
	message("Bônus legado salvo.")
	ui.refresh()
	return true

func begin_trial() -> bool:
	if journey.data.stage!=5:
		return false
	resume_checkpoint()
	trial_mode=true
	player.position=Vector3(0,0.03,-25)
	for actor in enemies:
		if actor.kind=="boss":
			actor.restore(false)
			target=actor
	set_paused(false)
	return true

func finish_trial() -> void:
	resume_checkpoint()
	ui.dialogue("Duelo concluído","Você venceu o Vigia novamente.\n\nEste duelo serve para testar o combate e as técnicas equipadas. Sua missão, moedas e recompensa continuam preservadas.")

func peak_power() -> bool:
	return flow!=null and flow.phase=="prologue"

func basic_multiplier() -> float:
	var profile:=current_profile()
	var race: Dictionary=Catalog.RACES[int(profile.get("race",0))]
	return (3.0 if peak_power() else 1.0)*(1.2 if journey.data.boon=="blade" else 1.0)*(1.1 if int(profile.get("path",0))==0 else 1.0)*(1+attribute("forca")*.01+race.damage)

func frost_duration() -> float:
	return (4.5 if journey.data.boon=="frost" else 3.0)+(1.0 if int(current_profile().get("path",0))==1 else 0.0)

func current_profile() -> Dictionary:
	if journey==null:
		return {}
	if journey.data.phase!="adventure":
		return Catalog.hero_profile(int(journey.data.hero))
	return journey.data.character

func current_weapon() -> Dictionary:
	if martial!=null and martial.bare():return preload("res://combat/unarmed.gd").spec()
	var item: Dictionary=inventory.equipped_item() if inventory!=null else {}
	if not item.is_empty() and item.ref==str(current_profile().get("weapon","sword")):return preload("res://procedural/loot_generator.gd").weapon(item)
	return Catalog.weapon(str(current_profile().get("weapon","sword")))

func race_body() -> String:
	return Catalog.RACES[int(current_profile().get("race",0))].body

func attribute(id: String) -> int:
	return int(journey.data.attributes.get(id,0))+int(equipment_stat(id)) if journey!=null and journey.data.phase=="adventure" else 0

func equipment_stat(id: String) -> float:
	if inventory==null or journey==null or journey.data.phase!="adventure":return 0
	return float(inventory.equipment_stats().get(id,0))
func equipment_element_bonus(element: int) -> float:
	if inventory==null or (martial!=null and martial.bare()):return 0
	var item: Dictionary=inventory.equipped_item()
	return equipment_stat("elemental_pct") if int(item.get("affinity",-1))==element and element>=0 else 0

func has_passive(id: String) -> bool:
	return journey!=null and journey.data.phase=="adventure" and id in journey.data.passives

func is_safe(point: Vector3) -> bool:
	return journey!=null and journey.data.phase=="adventure" and absf(point.x)<40 and point.z>=12

func can_configure() -> bool:
	if flow==null or flow.phase!="adventure" or health<=0 or combat_timer>0 or techniques.busy() or attack_time>=0 or roll_time>=0:
		return false
	if flow.lab_mode:
		return true
	for actor in enemies:
		if actor.hp>0 and actor.position.distance_to(player.position)<10:
			return false
	return true

func equip_weapon(id: String,uid: String="") -> bool:
	if not can_configure() or not journey.has_id(Catalog.WEAPONS,id) or (not flow.lab_mode and not inventory.owns_weapon(id)):
		message("Troque equipamento fora de combate e longe dos inimigos.")
		return false
	var previous: Dictionary=journey.data.character.duplicate(true)
	var old_equipped: String=journey.data.equipped
	if not flow.lab_mode:
		if uid.is_empty():
			for item in journey.data.items:
				if item.kind=="weapon" and item.ref==id:uid=item.uid;break
		var selected: Dictionary=inventory.find_item(uid)
		if selected.is_empty() or selected.kind!="weapon" or selected.ref!=id:return false
		journey.data.equipped=uid
	journey.data.character.weapon=id
	journey.data.character.hands_free=false
	if not save_progress():
		journey.data.character=previous
		journey.data.equipped=old_equipped
		return false
	Arsenal.equip(model,id)
	audio_fx.play_event("equip","combat",.35)
	return true

func equip_skill(id: String,slot: int) -> bool:
	if not can_configure() or slot<0 or slot>=journey.data.loadout.size() or not journey.has_id(Catalog.SKILLS,id) or (not flow.lab_mode and not cultivation.learned(id)):
		return false
	var previous: Array=journey.data.loadout.duplicate()
	var old: String=journey.data.loadout[slot]
	var existing: int=journey.data.loadout.find(id)
	if existing>=0:
		journey.data.loadout[existing]=old
	journey.data.loadout[slot]=id
	if not save_progress():
		journey.data.loadout=previous
		return false
	techniques.configure(journey.data.loadout)
	return true

func toggle_passive(id: String) -> bool:
	if not can_configure() or not journey.has_id(Catalog.PASSIVES,id) or (not flow.lab_mode and not cultivation.learned(id)):
		return false
	var previous: Array=journey.data.passives.duplicate()
	if id in journey.data.passives:
		journey.data.passives.erase(id)
	elif journey.data.passives.size()<Slots.PASSIVE:
		journey.data.passives.append(id)
	else:
		return false
	if not save_progress():
		journey.data.passives=previous
		return false
	apply_boon()
	return true

func assign_attribute(id: String) -> bool:
	if not can_configure() or id not in journey.ATTRIBUTES:
		return false
	var total:=0
	for value in journey.data.attributes.values():
		total+=int(value)
	if total>=6:
		return false
	journey.data.attributes[id]=int(journey.data.attributes[id])+1
	if not save_progress():
		journey.data.attributes[id]-=1
		return false
	apply_boon()
	return true

func choose_path(index: int) -> bool:
	if not can_configure() or index<0 or index>2:
		return false
	var previous: int=int(journey.data.character.path)
	journey.data.character.path=index
	if not save_progress():
		journey.data.character.path=previous
		return false
	apply_boon()
	return true
