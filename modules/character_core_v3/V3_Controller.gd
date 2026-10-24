extends Node3D
# Character Core 4.0: responsive locomotion, jump, directional dash and cancellable combat.
# Legacy module path retained for Haneul compatibility; assets remain byte-identical.
const WALK_SPEED := 2.8
const RUN_SPEED := 7.6
const TRAVEL_SPEED := 16.5
var murim_speed_fx: CanvasLayer
var travel_mode := false
var travel_pending := false
const COMBAT_SPEED := 3.4
const GRAVITY := 23.0
const JUMP_SPEED := 8.2
const DODGE_DISTANCE := 3.6
var jump_buffer := 0.0
var coyote_time := 0.0
var dodge_cooldown := 0.0
var dodge_invulnerable := false
var jump_count := 0
var air_time := 0.0
var travel_pose_blend := 0.0
var air_pose_blend := 0.0
var guard_pose_blend := 0.0
var landing_weight := 0.0
var was_grounded := false
var hit_variant := "Hit_Reaction"
var action_rate := 1.0
var actor: CharacterBody3D
var visual: Node3D
var skeleton: Skeleton3D
var player: AnimationPlayer
var tree: AnimationTree
var graph: AnimationNodeBlendTree
var camera: Camera3D
var pivot: Node3D
var boom: SpringArm3D
var hud: Label
var focus_label: Label
var light: DirectionalLight3D
var target: Node3D
var target_visual: Node3D
var target_material: StandardMaterial3D
var target_origin := Vector3.ZERO
var target_hp := 100
var target_impulse := 0.0
var hit_pause := 0.0
var armed := false
var neutral := false
var locked := false
var yaw := 0.0
var pitch := -0.16
var camera_distance := 3.8
var move_input := Vector2.ZERO
var actual_speed := 0.0
var stance_blend := 0.0
var gait_blend := 0.0
var combat_blend := Vector2.ZERO
var combat_pace := 0.0
var cadence_blend := 1.0
var action_kind := ""
var action_time := 0.0
var action_duration := 1.0
var action_weight := 0.0
var action_slot := 0
var action_mix := 0.0
var action_mix_goal := 0.0
var attack_buffer := 0.0
var dodge_buffer := 0.0
var queued_after_draw := false
var action_direction := Vector3.FORWARD
var hit_delivered := false
var action_a: AnimationNodeAnimation
var action_b: AnimationNodeAnimation
var motion_config: Dictionary
var weapon_bone := -1
var offsets: Dictionary = {}
var equipment: Node
var simulation_time := 0.0
var validating := false
var test_frame := 0
var events: Array[Dictionary] = []
var trajectory: Array[Dictionary] = []
var validation_errors: Array[String] = []
var observed_clips: Dictionary = {}
var combo_chains := 0
var hits := 0
var max_anchor_error := 0.0
var max_turn_step := 0.0
var max_bone_step := 0.0
var pose_jumps: Array[Dictionary] = []
var previous_bones: Array[Quaternion] = []
var previous_actor := Vector3.ZERO
var max_speed_observed := 0.0
var replay_events: Dictionary = {}
var headless := false

func find_type(node: Node, kind: String) -> Node:
	if node.is_class(kind): return node
	for child in node.get_children():
		var value := find_type(child,kind)
		if value: return value
	return null

func material(color: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color)
	m.roughness = 0.95
	return m

func mesh_node(mesh: Mesh, mat: Material, position: Vector3, parent: Node) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = position
	parent.add_child(node)
	return node

func _ready() -> void:
	murim_speed_fx = load("res://modules/character_core_v3/murim_speed.gd").new()
	add_child(murim_speed_fx)
	validating = "--validate" in OS.get_cmdline_user_args()
	headless = DisplayServer.get_name() == "headless"
	configure_input()
	motion_config = JSON.parse_string(FileAccess.get_file_as_string("res://modules/character_core_v3/motion_config.json"))
	build_environment()
	initialize_character()
	pivot = Node3D.new()
	pivot.position = Vector3(0,1.65,0)
	add_child(pivot)
	boom = SpringArm3D.new()
	boom.spring_length = camera_distance
	boom.margin = .2
	boom.collision_mask = 1
	boom.add_excluded_object(actor.get_rid())
	pivot.add_child(boom)
	camera = Camera3D.new()
	camera.fov = 60
	camera.near = .10
	camera.position.x = .38
	boom.add_child(camera)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = Label.new()
	hud.position = Vector2(22,18)
	hud.add_theme_color_override("font_color",Color("f4eee0"))
	hud.add_theme_color_override("font_shadow_color",Color("20262a"))
	hud.add_theme_constant_override("shadow_offset_x",2)
	hud.add_theme_constant_override("shadow_offset_y",2)
	canvas.add_child(hud)
	focus_label = Label.new()
	focus_label.position = Vector2(22,470)
	canvas.add_child(focus_label)
	if OS.has_feature("mobile"): mobile_controls(canvas)
	if not validating and not headless: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if validating: configure_replay()
	if "--benchmark" in OS.get_cmdline_user_args(): call_deferred("benchmark")
	for i in skeleton.get_bone_count(): previous_bones.append(skeleton.get_bone_global_pose(i).basis.get_rotation_quaternion())
	print("V3_READY ",player.get_animation_list())

func configure_input() -> void:
	for definition in [["left",KEY_A],["right",KEY_D],["forward",KEY_W],["backward",KEY_S],["run",KEY_SHIFT],["equip",KEY_E],["jump",KEY_SPACE],["travel",KEY_V],["speed_fx",KEY_F8],["dodge",KEY_Q],["hit",KEY_H],["neutral",KEY_N],["lock",KEY_TAB]]:
		if not InputMap.has_action(definition[0]): InputMap.add_action(definition[0])
		InputMap.action_erase_events(definition[0])
		var key := InputEventKey.new()
		key.physical_keycode = definition[1]
		InputMap.action_add_event(definition[0],key)
	if not InputMap.has_action("attack"): InputMap.add_action("attack")
	InputMap.action_erase_events("attack")
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("attack",mouse)
	for data in [["left",JOY_AXIS_LEFT_X,-1.0],["right",JOY_AXIS_LEFT_X,1.0],["forward",JOY_AXIS_LEFT_Y,-1.0],["backward",JOY_AXIS_LEFT_Y,1.0]]:
		var axis := InputEventJoypadMotion.new()
		axis.axis = data[1]
		axis.axis_value = data[2]
		InputMap.action_add_event(data[0],axis)

func build_environment() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("87939a")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("e6edf4")
	env.environment.ambient_light_energy = .78
	add_child(env)
	light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-48,-35,0)
	light.light_energy = .85
	light.shadow_enabled = false
	light.directional_shadow_max_distance = 30
	add_child(light)
	var floor_body := StaticBody3D.new()
	add_child(floor_body)
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(120,.2,120)
	collision.shape = box
	collision.position.y = -.1
	floor_body.add_child(collision)
	var plane := PlaneMesh.new()
	plane.size = Vector2(120,120)
	mesh_node(plane,material("596568"),Vector3.ZERO,floor_body)
	# A single mesh of court joints gives a speed/foot-contact reference, without changing the character.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for axis in 2:
		for line_index in range(-15,16):
			var pos := line_index*2.0
			var corners: Array[Vector3] = [Vector3(-30,.006,pos-.012),Vector3(30,.006,pos-.012),Vector3(30,.006,pos+.012),Vector3(-30,.006,pos+.012)]
			if axis == 1:
				for j in 4: corners[j] = Vector3(corners[j].z,.006,corners[j].x)
			for index in [0,1,2,0,2,3]: surface.add_vertex(corners[index])
	surface.generate_normals()
	var joints := material("3d484b")
	joints.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_node(surface.commit(),joints,Vector3.ZERO,self)
	target = StaticBody3D.new()
	target.position = Vector3(0,0,-9.5)
	add_child(target)
	var target_collision := CollisionShape3D.new()
	var cylinder_shape := CylinderShape3D.new()
	cylinder_shape.radius = .42
	cylinder_shape.height = 1.9
	target_collision.shape = cylinder_shape
	target_collision.position.y = .95
	target.add_child(target_collision)
	target_visual = Node3D.new()
	target.add_child(target_visual)
	add_contact_shadow(target)
	var post := CylinderMesh.new()
	post.top_radius = .23
	post.bottom_radius = .32
	post.height = 1.8
	post.radial_segments = 8
	target_material = material("51483d")
	mesh_node(post,target_material,Vector3(0,.9,0),target_visual)
	var ring := TorusMesh.new()
	ring.inner_radius = .34
	ring.outer_radius = .43
	ring.rings = 12
	ring.ring_segments = 8
	var ring_node := mesh_node(ring,material("b7a279"),Vector3(0,1.5,.05),target_visual)
	ring_node.rotation.x = PI/2
	var label := Label3D.new()
	label.text = "ALVO DE TREINO"
	label.font_size = 28
	label.pixel_size = .008
	label.position.y = 2.25
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	target.add_child(label)
	target_origin = target_visual.position

func animation_node(clip: String) -> AnimationNodeAnimation:
	var node := AnimationNodeAnimation.new()
	node.animation = clip
	return node

func build_animation_tree() -> void:
	graph = AnimationNodeBlendTree.new()
	var free := AnimationNodeBlendSpace1D.new()
	free.min_space = 0
	free.max_space = 1
	free.sync = true
	free.add_blend_point(animation_node("Idle"),0)
	free.add_blend_point(animation_node("Walk"),.40)
	free.add_blend_point(animation_node("Run"),1)
	graph.add_node("Free",free,Vector2(0,0))
	var combat := AnimationNodeBlendSpace2D.new()
	combat.sync = true
	combat.add_blend_point(animation_node("Combat_Idle"),Vector2.ZERO)
	combat.add_blend_point(animation_node("Walk_Armed"),Vector2(0,-1))
	combat.add_blend_point(animation_node("Combat_Back"),Vector2(0,1))
	combat.add_blend_point(animation_node("Combat_Left"),Vector2(-1,0))
	combat.add_blend_point(animation_node("Combat_Right"),Vector2(1,0))
	graph.add_node("Combat",combat,Vector2(0,180))
	graph.add_node("CombatRun",animation_node("Run_Armed"),Vector2(0,300))
	graph.add_node("CombatPace",AnimationNodeBlend2.new(),Vector2(230,200))
	graph.connect_node("CombatPace",0,"Combat")
	graph.connect_node("CombatPace",1,"CombatRun")
	graph.add_node("Stance",AnimationNodeBlend2.new(),Vector2(450,0))
	graph.connect_node("Stance",0,"Free")
	graph.connect_node("Stance",1,"CombatPace")
	graph.add_node("Cadence",AnimationNodeTimeScale.new(),Vector2(660,0))
	graph.connect_node("Cadence",0,"Stance")
	action_a = animation_node("Combat_Idle")
	action_b = animation_node("Combat_Idle")
	graph.add_node("ActionA",action_a,Vector2(200,420))
	graph.add_node("ActionB",action_b,Vector2(200,560))
	graph.add_node("SeekA",AnimationNodeTimeSeek.new(),Vector2(430,420))
	graph.add_node("SeekB",AnimationNodeTimeSeek.new(),Vector2(430,560))
	graph.connect_node("SeekA",0,"ActionA")
	graph.connect_node("SeekB",0,"ActionB")
	graph.add_node("ActionMix",AnimationNodeBlend2.new(),Vector2(670,440))
	graph.connect_node("ActionMix",0,"SeekA")
	graph.connect_node("ActionMix",1,"SeekB")
	graph.add_node("Overlay",AnimationNodeBlend2.new(),Vector2(900,100))
	graph.add_node("TravelClip",animation_node("Travel_Run"),Vector2(400,-420))
	graph.add_node("TravelRate",AnimationNodeTimeScale.new(),Vector2(600,-420))
	graph.connect_node("TravelRate",0,"TravelClip")
	graph.add_node("TravelBlend",AnimationNodeBlend2.new(),Vector2(700,-200))
	graph.connect_node("TravelBlend",0,"Cadence")
	graph.connect_node("TravelBlend",1,"TravelRate")
	graph.add_node("AirClip",animation_node("Jump_Air"),Vector2(700,-550))
	graph.add_node("AirBlend",AnimationNodeBlend2.new(),Vector2(900,-200))
	graph.connect_node("AirBlend",0,"TravelBlend")
	graph.connect_node("AirBlend",1,"AirClip")
	graph.add_node("GuardClip",animation_node("Guard_Loop"),Vector2(900,-550))
	graph.add_node("GuardBlend",AnimationNodeBlend2.new(),Vector2(1100,-200))
	graph.connect_node("GuardBlend",0,"AirBlend")
	graph.connect_node("GuardBlend",1,"GuardClip")
	graph.connect_node("Overlay",0,"GuardBlend")
	graph.add_node("ActionSpeed",AnimationNodeTimeScale.new(),Vector2(800,440))
	graph.connect_node("ActionSpeed",0,"ActionMix")
	graph.connect_node("Overlay",1,"ActionSpeed")
	graph.add_node("LandingClip",animation_node("Land"),Vector2(1100,600))
	graph.add_node("LandingSeek",AnimationNodeTimeSeek.new(),Vector2(1300,600))
	graph.connect_node("LandingSeek",0,"LandingClip")
	graph.add_node("LandingBlend",AnimationNodeBlend2.new(),Vector2(1500,100))
	graph.connect_node("LandingBlend",0,"Overlay")
	graph.connect_node("LandingBlend",1,"LandingSeek")
	graph.connect_node("output",0,"LandingBlend")
	tree = AnimationTree.new()
	visual.add_child(tree)
	tree.tree_root = graph
	tree.anim_player = tree.get_path_to(player)
	tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	tree.active = true
	tree.set("parameters/Cadence/scale",1.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: camera_distance = clampf(camera_distance-.4,3.0,8.0)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: camera_distance = clampf(camera_distance+.4,3.0,8.0)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not locked:
		yaw -= event.relative.x*.003
		pitch = clampf(pitch-event.relative.y*.002,-.55,.32)

func forward_vector() -> Vector3:
	return visual.transform.basis.z.normalized()

func start_action(clip: String) -> void:
	var chained := action_kind.begins_with("Sword_Attack") and clip.begins_with("Sword_Attack")
	travel_mode = false
	travel_pending = false
	neutral = false
	tree.active = true
	action_kind = clip
	action_time = 0
	action_rate = 1.0
	if clip.begins_with("Sword_Attack"): action_rate = 1.20
	elif clip in ["Sword_Draw","Sword_Sheath"]: action_rate = 1.45
	elif clip == "Dodge": action_rate = 1.39
	action_duration = motion_config[clip].duration/action_rate
	tree.set("parameters/ActionSpeed/scale",action_rate)
	hit_delivered = false
	action_direction = forward_vector()
	if clip == "Dodge":
		dodge_cooldown = .54
		var input_dir := desired_direction()
		action_direction = input_dir if input_dir.length() > .1 else -visual.transform.basis.x
	var render_clip := clip
	if clip == "Hit_Reaction": render_clip = hit_variant if armed else "Hit_Unarmed"
	if clip == "Dodge":
		var local := visual.basis.inverse()*action_direction
		render_clip = ("Dodge_Right" if local.x > 0 else "Dodge_Left") if absf(local.x) > absf(local.z) else ("Dodge_Forward" if local.z > 0 else "Dodge_Back")
	if action_slot == 0:
		action_slot = 1
		action_b.animation = render_clip
		tree.set("parameters/SeekB/seek_request",0.0)
		action_mix_goal = 1
	else:
		action_slot = 0
		action_a.animation = render_clip
		tree.set("parameters/SeekA/seek_request",0.0)
		action_mix_goal = 0
	if chained:
		action_time = action_duration*.12
		tree.set("parameters/"+("SeekB" if action_slot == 1 else "SeekA")+"/seek_request",motion_config[clip].duration*.12)
	observed_clips[clip] = true
	observed_clips[render_clip] = true
	events.append({"time":simulation_time,"type":"action_start","clip":clip,"position":vec(actor.position)})

func desired_direction() -> Vector3:
	var basis := Basis(Vector3.UP,yaw)
	return (basis.x*move_input.x+basis.z*move_input.y).normalized()

func attack_request() -> void:
	attack_buffer = .38
	if action_kind.is_empty():
		if not armed:
			queued_after_draw = true
			start_action("Sword_Draw")
		else:
			attack_buffer = 0
			start_action("Sword_Attack_01")

func lunge_fraction(u: float) -> float:
	return smoothstep(.24,.52,u)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(tree): return
	simulation_time += delta
	if validating: replay_step()
	move_input = Input.get_vector("left","right","forward","backward")
	if Input.is_action_just_pressed("travel"): toggle_travel()
	if Input.is_action_just_pressed("speed_fx"): murim_speed_fx.enabled = not murim_speed_fx.enabled
	attack_buffer = maxf(0,attack_buffer-delta)
	dodge_buffer = maxf(0,dodge_buffer-delta)
	jump_buffer = maxf(0,jump_buffer-delta)
	dodge_cooldown = maxf(0,dodge_cooldown-delta)
	if actor.is_on_floor(): coyote_time = .12
	else: coyote_time = maxf(0,coyote_time-delta)
	if Input.is_action_just_pressed("jump"): jump_buffer = .15
	if Input.is_action_just_pressed("lock"):
		locked = not locked if can_lock_target() else false
		travel_mode = false
		travel_pending = false
		events.append({"time":simulation_time,"type":"lock","enabled":locked})
	if Input.is_action_just_pressed("equip") and action_kind.is_empty(): start_action("Sword_Sheath" if armed else "Sword_Draw")
	if Input.is_action_just_pressed("attack"): attack_request()
	if Input.is_action_just_pressed("dodge"): dodge_buffer = .22
	if Input.is_action_just_pressed("hit"): start_action("Hit_Reaction")
	if Input.is_action_just_pressed("neutral"):
		neutral = not neutral
		travel_mode = false
		travel_pending = false
		if neutral:
			action_kind = ""
			armed = false
			actor.velocity = Vector3.ZERO
			tree.active = false
			skeleton.reset_bone_poses()
			yaw = visual.rotation.y
		else: tree.active = true
	if hit_pause > 0:
		hit_pause -= delta
		update_camera(delta)
		update_target(delta)
		finish_frame(delta)
		return
	var old_time := action_time
	var kind_at_start := action_kind
	if not action_kind.is_empty():
		action_time += delta
		var u := action_time/action_duration
		if action_kind.begins_with("Sword_Attack") and u >= .53 and u <= .96 and attack_buffer > 0:
			attack_buffer = 0
			combo_chains += 1
			start_action({"Sword_Attack_01":"Sword_Attack_02","Sword_Attack_02":"Sword_Attack_03","Sword_Attack_03":"Sword_Attack_04","Sword_Attack_04":"Sword_Attack_05","Sword_Attack_05":"Sword_Attack_01"}[action_kind])
			old_time = 0
		elif dodge_buffer > 0 and dodge_cooldown <= 0 and ((action_kind.begins_with("Sword_Attack") and u >= .25) or (action_kind == "Hit_Reaction" and u >= .45)):
			dodge_buffer = 0
			start_action("Dodge")
			old_time = 0
		elif action_kind.begins_with("Sword_Attack") and u >= .70 and move_input.length() > .15:
			action_kind = ""
		elif u >= 1.0:
			var finished := action_kind
			action_kind = ""
			if finished == "Sword_Draw": armed = true
			if finished == "Sword_Sheath":
				armed = false
				if travel_pending:
					travel_mode = true
					travel_pending = false
			events.append({"time":simulation_time,"type":"action_end","clip":finished})
			if finished == "Sword_Draw" and (queued_after_draw or attack_buffer > 0):
				queued_after_draw = false
				start_action("Sword_Attack_01")
				old_time = 0
	elif dodge_buffer > 0 and dodge_cooldown <= 0:
		dodge_buffer = 0
		start_action("Dodge")
		old_time = 0
	var direction := desired_direction()
	var max_speed := COMBAT_SPEED if armed else WALK_SPEED
	if Input.is_action_pressed("run"): max_speed = RUN_SPEED if not locked else 5.4
	if travel_mode: max_speed = TRAVEL_SPEED
	var freedom := 1.0
	if not action_kind.is_empty():
		freedom = .85 if action_kind in ["Sword_Draw","Sword_Sheath"] else smoothstep(.45,.85,action_time/action_duration)*.75
		if action_kind == "Dodge": freedom = 0
	if neutral: freedom = 0
	var goal := direction*max_speed*freedom
	var acceleration := 38.0 if goal.length() > Vector2(actor.velocity.x,actor.velocity.z).length() else 46.0
	if travel_mode or Vector2(actor.velocity.x,actor.velocity.z).length() > RUN_SPEED+.1:
		acceleration = 12.0 if goal.length() > Vector2(actor.velocity.x,actor.velocity.z).length() else 24.0
	if not actor.is_on_floor(): acceleration *= .65
	actor.velocity.x = move_toward(actor.velocity.x,goal.x,acceleration*delta)
	actor.velocity.z = move_toward(actor.velocity.z,goal.z,acceleration*delta)
	var physical_action := Vector3.ZERO
	if action_kind.begins_with("Sword_Attack"):
		var distance := .68 if action_kind == "Sword_Attack_01" else .52
		physical_action = action_direction*distance*(lunge_fraction(action_time/action_duration)-lunge_fraction(old_time/action_duration))/delta
		if not hit_delivered and action_time/action_duration >= .39:
			hit_delivered = true
			try_hit()
	elif action_kind == "Dodge":
		physical_action = action_direction*DODGE_DISTANCE*(dash_fraction(action_time/action_duration)-dash_fraction(old_time/action_duration))/delta
	dodge_invulnerable = action_kind == "Dodge" and action_time >= .04 and action_time <= .25
	if jump_buffer > 0 and coyote_time > 0 and action_kind != "Dodge" and not neutral:
		jump_buffer = 0
		coyote_time = 0
		actor.velocity.y = JUMP_SPEED
		jump_count += 1
		# Jump cancels recovery without letting the attack restart in mid-air.
		if action_kind.begins_with("Sword_Attack") and action_time/action_duration > .45: action_kind = ""
		events.append({"time":simulation_time,"type":"jump"})
	elif actor.is_on_floor(): actor.velocity.y = -.2
	else: actor.velocity.y -= GRAVITY*delta
	actor.floor_snap_length = 0.0 if actor.velocity.y > 0 else .4
	var locomotion_velocity := actor.velocity
	actor.velocity += physical_action
	actor.move_and_slide()
	if actor.is_on_floor():
		if not was_grounded and air_time > .15:
			landing_weight = 1.0
			tree.set("parameters/LandingSeek/seek_request",0.0)
		air_time = 0
	else: air_time += delta
	was_grounded = actor.is_on_floor()
	landing_weight = move_toward(landing_weight,0,delta*6)
	actor.velocity.x = locomotion_velocity.x
	actor.velocity.z = locomotion_velocity.z
	var real := actor.get_real_velocity()
	actual_speed = Vector2(real.x,real.z).length()
	max_speed_observed = maxf(max_speed_observed,actual_speed)
	var facing := direction
	if locked:
		facing = (target.position-actor.position)*Vector3(1,0,1)
		facing = facing.normalized()
	if not action_kind.is_empty() and action_kind not in ["Sword_Draw","Sword_Sheath"]: facing = forward_vector()
	if facing.length() > .1 and not neutral:
		var before := visual.rotation.y
		visual.rotation.y = rotate_toward(visual.rotation.y,atan2(facing.x,facing.z),(lerpf(16.0,8.0,smoothstep(RUN_SPEED,TRAVEL_SPEED,actual_speed)) if actual_speed > 3 else 20.0)*delta)
		max_turn_step = maxf(max_turn_step,absf(angle_difference(before,visual.rotation.y)))
	update_animation(delta)
	update_target(delta)
	update_camera(delta)
	finish_frame(delta)

func update_animation(delta: float) -> void:
	if neutral: return
	var a := 1-exp(-delta*20)
	gait_blend = lerpf(gait_blend,(.4*clampf(actual_speed/WALK_SPEED,0,1) if actual_speed <= WALK_SPEED else lerpf(.4,1.0,clampf((actual_speed-WALK_SPEED)/(RUN_SPEED-WALK_SPEED),0,1))),a)
	var stance_goal := armed
	if action_kind == "Sword_Draw" and action_time/action_duration >= .60: stance_goal = true
	elif action_kind == "Sword_Sheath" and action_time/action_duration >= .45: stance_goal = false
	stance_blend = move_toward(stance_blend,1.0 if stance_goal else 0.0,delta*6)
	var real := actor.get_real_velocity()
	var local := visual.transform.basis.inverse()*Vector3(real.x,0,real.z)
	var combat_input := Vector2(local.x,-local.z)/COMBAT_SPEED
	var cadence := 1.0
	if actual_speed > .10:
		var stride := lerpf(1.55,3.9,smoothstep(WALK_SPEED,RUN_SPEED,actual_speed))
		cadence = clampf(actual_speed/stride,.35,2.3)
	tree.set("parameters/Free/blend_position",gait_blend)
	combat_blend = combat_blend.lerp(combat_input.limit_length(1),a)
	combat_pace = lerpf(combat_pace,smoothstep(COMBAT_SPEED,RUN_SPEED,actual_speed),a)
	cadence_blend = lerpf(cadence_blend,cadence,a)
	tree.set("parameters/Combat/blend_position",combat_blend)
	tree.set("parameters/CombatPace/blend_amount",combat_pace)
	tree.set("parameters/Stance/blend_amount",stance_blend)
	tree.set("parameters/Cadence/scale",cadence_blend)
	var goal_weight := 0.0
	if not action_kind.is_empty():
		goal_weight = 1.0-smoothstep(.84,1.0,action_time/action_duration)
	action_weight = move_toward(action_weight,goal_weight,delta/0.055)
	action_mix = move_toward(action_mix,action_mix_goal,delta/.075)
	tree.set("parameters/ActionMix/blend_amount",action_mix)
	tree.set("parameters/Overlay/blend_amount",action_weight)
	travel_pose_blend = move_toward(travel_pose_blend,smoothstep(7.6,14.0,actual_speed) if travel_mode else 0.0,delta*4)
	air_pose_blend = move_toward(air_pose_blend,1.0 if not actor.is_on_floor() and air_time > .04 else 0.0,delta*8)
	guard_pose_blend = move_toward(guard_pose_blend,1.0 if motion_guarding() else 0.0,delta*10)
	tree.set("parameters/TravelBlend/blend_amount",travel_pose_blend)
	tree.set("parameters/TravelRate/scale",lerpf(.85,1.3,smoothstep(7.6,16.5,actual_speed)))
	var air_node := tree.tree_root.get_node("AirClip") as AnimationNodeAnimation
	var landing_node := tree.tree_root.get_node("LandingClip") as AnimationNodeAnimation
	var air_clip := "Jump_Armed" if armed else "Jump_Air"
	var landing_clip := "Land_Armed" if armed else "Land"
	if air_node.animation != air_clip: air_node.animation = air_clip
	if landing_node.animation != landing_clip: landing_node.animation = landing_clip
	tree.set("parameters/AirBlend/blend_amount",air_pose_blend)
	tree.set("parameters/GuardBlend/blend_amount",guard_pose_blend)
	tree.set("parameters/LandingBlend/blend_amount",landing_weight*.65 if action_kind.is_empty() else 0.0)
	tree.advance(delta)
	apply_motion_pose(delta)
	apply_weapon_anchor()

func weapon_mode() -> String:
	if action_kind in ["Sword_Draw","Sword_Sheath"]:
		var u := clampf(action_time/action_duration,0,1)
		if action_kind == "Sword_Sheath": u = 1-u
		return "waist" if u < .22 else ("L" if u < .60 else "R")
	return "R" if armed else "waist"

func expected_weapon(mode: String) -> Transform3D:
	if mode == "waist":
		var parent := skeleton.get_bone_parent(weapon_bone)
		return skeleton.get_bone_global_pose(parent)*skeleton.get_bone_rest(weapon_bone)
	return skeleton.get_bone_global_pose(skeleton.find_bone("hand_"+mode))*offsets[mode]

func apply_weapon_anchor() -> void:
	var expected := expected_weapon(weapon_mode())
	var parent := skeleton.get_bone_parent(weapon_bone)
	skeleton.set_bone_pose(weapon_bone,skeleton.get_bone_global_pose(parent).affine_inverse()*expected)
	skeleton.force_update_all_bone_transforms()
	max_anchor_error = maxf(max_anchor_error,skeleton.get_bone_global_pose(weapon_bone).origin.distance_to(expected.origin))

func try_hit() -> void:
	var relative := (target.position-actor.position)*Vector3(1,0,1)
	if relative.length() <= 1.7 and forward_vector().dot(relative.normalized()) > .35:
		var damage := 30 if action_kind == "Sword_Attack_02" else 20
		target_hp = maxi(0,target_hp-damage)
		target_impulse = 1.0
		hit_pause = .025
		hits += 1
		events.append({"time":simulation_time,"type":"hit","damage":damage,"target_hp":target_hp,"distance":relative.length()})
	else: events.append({"time":simulation_time,"type":"miss","distance":relative.length()})

func update_target(delta: float) -> void:
	target_impulse = move_toward(target_impulse,0,delta*3.5)
	target_visual.rotation.z = sin(simulation_time*46)*target_impulse*.07
	target_material.albedo_color = Color("51483d").lerp(Color("e9cf86"),target_impulse)

func update_camera(delta: float) -> void:
	if locked and not neutral:
		var dir := (target.position-actor.position)*Vector3(1,0,1)
		yaw = lerp_angle(yaw,atan2(-dir.x,-dir.z),1-exp(-delta*4))
	pivot.position = pivot.position.lerp(actor.position+Vector3(0,1.65,0),1-exp(-delta*12))
	pivot.rotation.y = yaw
	boom.rotation.x = pitch
	var travel_ratio := smoothstep(RUN_SPEED,TRAVEL_SPEED,actual_speed)
	boom.spring_length = lerpf(boom.spring_length,camera_distance+travel_ratio*.8,1-exp(-delta*5))
	camera.fov = lerpf(camera.fov,lerpf(72.0,80.0,travel_ratio) if actual_speed > 5 else 64.0,1-exp(-delta*5))

func finish_frame(delta: float) -> void:
	murim_speed_fx.update_speed(actual_speed,travel_mode and not neutral,delta)
	hud.text = "EXO-MURIM   /   PÁTIO DE TREINO\nWASD mover · Shift correr · V viagem · Mouse câmera · E arma\nClique golpe · Espaço pular · Q esquiva · Tab foco · Esc cursor · N V4"
	focus_label.text = ("FOCO  ·  ALVO %d/100" % target_hp) if locked else ""
	if validating:
		for i in skeleton.get_bone_count():
			var pose := skeleton.get_bone_global_pose(i)
			if not pose.is_finite(): validation_errors.append("Nonfinite bone pose")
			var rotation := pose.basis.get_rotation_quaternion()
			if i != weapon_bone and test_frame > 10 and test_frame < 900:
				var step := previous_bones[i].angle_to(rotation)
				max_bone_step = maxf(max_bone_step,step)
				if step > .6: pose_jumps.append({"frame":test_frame,"clip":action_kind,"bone":skeleton.get_bone_name(i),"step_rad":step})
			previous_bones[i] = rotation
		if test_frame%6 == 0:
			trajectory.append({"time":simulation_time,"position":vec(actor.position),"speed":actual_speed,"gait":gait_blend,"action":action_kind,"phase":action_time/action_duration,"weight":action_weight,"facing":visual.rotation.y,"camera":vec(camera.global_position),"weapon":weapon_mode()})
		if test_frame in [60,150,320,380,414,450,500,580,730,900]: call_deferred("capture", "sequence_%04d" % test_frame)
		if test_frame >= 1030: call_deferred("finish_validation")

func vec(value: Vector3) -> Array:
	return [value.x,value.y,value.z]

func configure_replay() -> void:
	# All commands pass through the same InputMap path as keyboard play.
	replay_events = {36:[["forward",true]],96:[["run",true]],174:[["run",false],["forward",false]],186:[["right",true]],222:[["right",false]],240:[["lock",true],["equip",true]],241:[["lock",false],["equip",false]],318:[["forward",true]],360:[["forward",false],["attack",true]],361:[["attack",false]],387:[["attack",true]],388:[["attack",false]],444:[["left",true],["dodge",true]],445:[["dodge",false]],477:[["left",false]],492:[["hit",true]],493:[["hit",false]],528:[["backward",true]],552:[["backward",false],["right",true]],576:[["right",false]],600:[["lock",true],["run",true],["forward",true]],601:[["lock",false]],720:[["forward",false],["backward",true]],780:[["backward",false],["run",false]],798:[["equip",true]],799:[["equip",false]],900:[["neutral",true]],901:[["neutral",false]],990:[["neutral",true]],991:[["neutral",false]]}

func replay_step() -> void:
	test_frame += 1
	if test_frame in [920,940,960] and not headless:
		var old_mode := Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		var motion := InputEventMouseMotion.new()
		motion.relative = Vector2(90,-8)
		_unhandled_input(motion)
		Input.mouse_mode = old_mode
		events.append({"time":simulation_time,"type":"mouse_orbit","yaw":yaw,"pitch":pitch})
	if replay_events.has(test_frame):
		for command in replay_events[test_frame]:
			if command[1]: Input.action_press(command[0])
			else: Input.action_release(command[0])

func finish_validation() -> void:
	validating = false
	set_physics_process(false)
	if not headless: await neutral_comparison()
	if max_speed_observed < 4.0: validation_errors.append("Sprint did not reach target speed")
	if combo_chains < 1: validation_errors.append("Buffered combo did not chain")
	if hits < 2: validation_errors.append("Two training hits were not observed")
	if max_anchor_error > .0001: validation_errors.append("Weapon anchor drift")
	if max_turn_step > .25: validation_errors.append("Facing snapped")
	if max_bone_step > .55: validation_errors.append("Large single-tick pose discontinuity")
	var report := {"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"device":RenderingServer.get_video_adapter_name(),"simulation_seconds":simulation_time,"physics_frames":test_frame,"clips":observed_clips.keys(),"max_speed_m_s":max_speed_observed,"combo_chains":combo_chains,"target_hits":hits,"target_hp":target_hp,"max_anchor_error_m":max_anchor_error,"max_facing_step_rad":max_turn_step,"max_bone_step_rad":max_bone_step,"pose_jumps":pose_jumps,"events":events,"trajectory":trajectory,"errors":validation_errors,"movie_fixed_step":OS.get_cmdline_args().has("--write-movie"),"android":"not tested"}
	var file := FileAccess.open("res://qa/reports/gameplay_validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("V3_VALIDATION ",JSON.stringify({"errors":validation_errors,"hits":hits,"combos":combo_chains,"max_speed":max_speed_observed,"anchor":max_anchor_error,"bone_step":max_bone_step}))
	get_tree().quit(0 if validation_errors.is_empty() else 1)

func capture(name: String) -> void:
	if headless: return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://qa/captures/"+name+".png")

func mobile_controls(canvas: CanvasLayer) -> void:
	var layer := Control.new()
	canvas.add_child(layer)
	for definition in [["←","left",20,415],["→","right",160,415],["↑","forward",90,345],["↓","backward",90,415],["Correr","run",20,275],["Pular","jump",915,345],["Golpe","attack",815,415],["Esquiva","dodge",715,415],["Arma","equip",815,345],["Foco","lock",715,345]]:
		var button := Button.new()
		button.text = definition[0]
		button.position = Vector2(definition[2],definition[3])
		button.size = Vector2(68,58)
		button.button_down.connect(func():Input.action_press(definition[1]))
		button.button_up.connect(func():Input.action_release(definition[1]))
		layer.add_child(button)
	var touch := TouchScreenButton.new()
	# Camera orbit uses drag on the right half of the viewport.

func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag and event.position.x > get_viewport().get_visible_rect().size.x*.4 and not locked:
		yaw -= event.relative.x*.004
		pitch = clampf(pitch-event.relative.y*.003,-.55,.32)

func neutral_comparison() -> void:
	tree.active = false
	player.stop()
	skeleton.reset_bone_poses()
	actor.position = Vector3.ZERO
	visual.rotation.y = 0
	camera.reparent(self)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.45
	camera.h_offset = 0
	target.visible = false
	light.light_energy = 0
	hud.visible = false
	focus_label.visible = false
	for angle in [0,90,180,35]:
		var rad := deg_to_rad(float(angle))
		camera.position = Vector3(6*sin(rad),2.875,6*cos(rad))
		camera.look_at(Vector3(0,1.345,0))
		await capture("godot_final_%03d" % angle)
		visual.visible = false
		var reference: Node3D = load("res://qa/reference/Reference_No_Scabbard.glb").instantiate()
		reference.rotation.x = -PI/2
		reference.position.y = -.125
		actor.add_child(reference)
		for node in reference.find_children("*","MeshInstance3D",true,false):
			for surface in node.mesh.get_surface_count():
				var mat := node.mesh.surface_get_material(surface) as BaseMaterial3D
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		await capture("godot_reference_%03d" % angle)
		actor.remove_child(reference)
		reference.queue_free()
		visual.visible = true

func benchmark() -> void:
	Input.action_press("right")
	Input.action_press("run")
	for f in 30: await get_tree().process_frame
	var start := Time.get_ticks_usec()
	var frames := 180
	var sum_delta := 0.0
	var draw_calls := 0.0
	for f in frames:
		await get_tree().process_frame
		sum_delta += get_process_delta_time()
		draw_calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var seconds := (Time.get_ticks_usec()-start)/1000000.0
	var report := {"frames":frames,"wall_seconds":seconds,"wall_fps":frames/seconds,"mean_process_delta_ms":sum_delta/frames*1000,"mean_draw_calls":draw_calls/frames,"renderer":RenderingServer.get_current_rendering_method(),"device":RenderingServer.get_video_adapter_name(),"fixed_step_movie":false,"note":"Linux virtual Xorg, Mesa llvmpipe CPU/software; no physical GPU or Android; v-sync unavailable"}
	FileAccess.open("res://qa/reports/render_benchmark.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("BENCHMARK ",JSON.stringify(report))
	get_tree().quit()

func add_contact_shadow(parent: Node3D) -> void:
	var image := Image.create(64,64,false,Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var distance := Vector2((x-31.5)/31.5,(y-31.5)/31.5).length_squared()
			image.set_pixel(x,y,Color(0,0,0,.24*pow(maxf(0,1-distance),1.8)))
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = ImageTexture.create_from_image(image)
	var plane := PlaneMesh.new()
	plane.size = Vector2(1.25,.90)
	var shadow := mesh_node(plane,mat,Vector3(0,.014,0),parent)
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

# A front-loaded ease-out makes the dash accelerate immediately, then brake.
func dash_fraction(u: float) -> float:
	return 1.0-pow(1.0-clampf(u,0,1),2.0)

func rotate_pose(bone_name: String, axis: Vector3, angle: float) -> void:
	var index := skeleton.find_bone(bone_name)
	if index >= 0:
		skeleton.set_bone_pose_rotation(index,skeleton.get_bone_pose_rotation(index)*Quaternion(axis,angle))

func apply_motion_pose(_delta: float) -> void:
	# Dedicated clips now provide air, landing and four directional dodge poses.
	if action_kind.is_empty() and travel_pose_blend < 1.0:
		rotate_pose("spine",Vector3.RIGHT,-.15*smoothstep(3.5,RUN_SPEED,actual_speed)*(1-travel_pose_blend))

func toggle_travel() -> void:
	if travel_mode or travel_pending:
		travel_mode = false
		travel_pending = false
		return
	if not action_kind.is_empty(): return
	locked = false
	neutral = false
	tree.active = true
	if armed:
		start_action("Sword_Sheath")
		travel_pending = true
	else:
		travel_mode = true

# Shared construction contract for player and inherited combat opponent.
func initialize_character() -> void:
	actor = CharacterBody3D.new()
	actor.name = "Character"
	add_child(actor)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = .34
	capsule.height = 2.65
	shape.shape = capsule
	shape.position.y = 1.325
	actor.add_child(shape)
	actor.floor_snap_length = .4
	actor.floor_constant_speed = true
	actor.floor_max_angle = deg_to_rad(46)
	actor.safe_margin = .025
	add_contact_shadow(actor)
	visual = load("res://modules/character_core_v3/assets/EXO_Character_Core01.glb").instantiate()
	visual.position.y = -.125
	visual.rotation.y = PI
	actor.add_child(visual)
	player = find_type(visual,"AnimationPlayer") as AnimationPlayer
	skeleton = find_type(visual,"Skeleton3D") as Skeleton3D
	assert(player and skeleton)
	install_motion_library()
	for clip in motion_config:
		assert(player.has_animation(clip),"Missing clip "+clip)
		var anim := player.get_animation(clip)
		anim.length = motion_config[clip].duration
		anim.loop_mode = Animation.LOOP_LINEAR if motion_config[clip].loop else Animation.LOOP_NONE
	equipment = load("res://modules/character_core_v3/equipment_slots.gd").new()
	add_child(equipment)
	equipment.configure(skeleton)
	weapon_bone = skeleton.find_bone("weapon")
	var grip_rest := skeleton.get_bone_global_rest(weapon_bone)
	for side in ["L","R"]:
		var x := -.515 if side == "L" else .515
		var hand := skeleton.find_bone("hand_"+side)
		offsets[side] = skeleton.get_bone_global_rest(hand).affine_inverse()*Transform3D(grip_rest.basis,Vector3(x,1.245,.08))
	build_animation_tree()

func can_lock_target() -> bool:
	return true

func install_motion_library() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://modules/motion_core_03/motion_config.json"))
	motion_config.merge(config,true)
	var extension: AnimationLibrary = load("res://modules/motion_core_03/motion_library.tres")
	var combined := AnimationLibrary.new()
	var existing := player.get_animation_library("")
	for name in existing.get_animation_list(): combined.add_animation(name,existing.get_animation(name))
	var bone_path := str(player.get_node(player.root_node).get_path_to(skeleton))
	for name in extension.get_animation_list():
		var animation := extension.get_animation(name).duplicate() as Animation
		for track in animation.get_track_count():
			var old := animation.track_get_path(track)
			if old.get_subname_count() > 0:
				animation.track_set_path(track,NodePath(bone_path+":"+str(old.get_subname(0))))
		if combined.has_animation(name): combined.remove_animation(name)
		combined.add_animation(name,animation)
	player.remove_animation_library("")
	player.add_animation_library("",combined)

func motion_guarding() -> bool:
	return false
