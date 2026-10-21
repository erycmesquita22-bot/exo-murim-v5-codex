extends "res://main.gd"
# Isolated terrain adapter: original main.gd, make_player(), rig, wardrobe and combat files remain byte-identical.
# Only exploration locomotion is enabled here; no combat progression or journey saves are run.
const Planner=preload("res://genesis/world_planner.gd")
const RegionData=preload("res://genesis/region_data.gd")
const RegionScene=preload("res://genesis/region_scene.gd")
var atlas: Dictionary
var pilot: Dictionary
var active: Node3D
var current := -1
var loading := false
var ready_to_play := false
var label: Label
var curtain: ColorRect
var status: Label
var plan_cache: Dictionary={}
var cache_order: Array=[]
var cache_enabled := false
var prepared_scene: Node3D
var prepared_id := -1
var prepare_log: Array=[]
var transition_log: Array=[]
var visited: Dictionary={}
var qa_direction := Vector3.ZERO
var automated := false
var notices := ""
var last_gate := ""
var cooldown := 0.0
var demo_elapsed := 0.0
var aim := Vector2.ZERO
func _ready() -> void:
	setup_inputs()
	pilot=JSON.parse_string(FileAccess.get_file_as_string("res://genesis/pilot.json"))
	pilot.ids=pilot.ids.map(func(value):return int(value))
	atlas=Planner.read_atlas("res://genesis/"+pilot.atlas)
	var problems := Planner.validate(atlas)
	if not problems.is_empty():push_error("Invalid atlas: "+str(problems));return
	var sky := WorldEnvironment.new();environment=Environment.new();sky.environment=environment
	environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("25353f")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color("a4bac7");environment.ambient_light_energy=.62
	add_child(sky)
	sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-52,-28,0);sun.light_color=Color("ffecd0");sun.light_energy=.9;sun.shadow_enabled=false;add_child(sun)
	player=make_player();model=Rig.new();player.add_child(model);model.sword.visible=false
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=36;camera.current=true;camera.far=500;add_child(camera)
	var canvas := CanvasLayer.new();add_child(canvas)
	var panel := PanelContainer.new();panel.position=Vector2(20,18);panel.size=Vector2(620,104);canvas.add_child(panel)
	label=Label.new();label.add_theme_font_size_override("font_size",20);panel.add_child(label)
	status=Label.new();status.position=Vector2(24,650);status.add_theme_font_size_override("font_size",18);canvas.add_child(status)
	curtain=ColorRect.new();curtain.color=Color(0.025,.035,.045,1);curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);curtain.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.add_child(curtain)
	ready_to_play=await change_region(86,"")
func get_data(rid: int) -> RefCounted:
	if plan_cache.has(rid):return plan_cache[rid]
	return RegionData.new(atlas,rid)
func prepare_neighbor(rid: int) -> void:
	if not cache_enabled or prepared_id==rid or loading:return
	var t := Time.get_ticks_usec()
	if is_instance_valid(prepared_scene):prepared_scene.free()
	plan_cache.clear();cache_order.clear()
	var d := RegionData.new(atlas,rid)
	plan_cache[rid]=d
	prepared_scene=RegionScene.new();prepared_scene.build(d,pilot.ids);prepared_id=rid
	prepare_log.append({"rid":rid,"ms":(Time.get_ticks_usec()-t)/1000.0,"static_memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC)})
func spawn_point(d: RefCounted,gate_id: String) -> Vector3:
	var p := Vector2.ZERO
	for g in d.gates:
		if g.id==gate_id:p=g.p-g.p.normalized()*10;break
	return Vector3(p.x,d.height_at(p)+.06,p.y)
func change_region(rid: int,gate_id: String) -> bool:
	if loading or rid not in pilot.ids:return false
	loading=true;curtain.visible=true
	await get_tree().process_frame
	var t := Time.get_ticks_usec();var old=current
	if prepared_id!=rid and is_instance_valid(prepared_scene):
		prepared_scene.free();prepared_scene=null;prepared_id=-1;plan_cache.clear()
	var data := get_data(rid)
	var errors: Array=data.validate()
	if not errors.is_empty():
		push_error("Regional validation "+str(rid)+": "+str(errors));loading=false;curtain.visible=false;return false
	var was_prepared := prepared_id==rid and is_instance_valid(prepared_scene)
	var candidate: Node3D
	if was_prepared:
		candidate=prepared_scene;prepared_scene=null;prepared_id=-1
	else:
		candidate=RegionScene.new();candidate.build(data,pilot.ids)
	# Build off-tree, then register collision before committing and destroying the prior region.
	candidate.position=Vector3(2048,0,0)
	add_child(candidate)
	candidate.visible=false
	await get_tree().physics_frame
	await get_tree().physics_frame
	var point := spawn_point(data,gate_id)
	# Validate support and capsule against real engine physics; no guessed fallback Y.
	var query := PhysicsRayQueryParameters3D.create(point+candidate.position+Vector3(0,4,0),point+candidate.position-Vector3(0,8,0),1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():candidate.free();loading=false;curtain.visible=false;push_error("No arrival floor");return false
	point.y=hit.position.y+.04
	var shape_query := PhysicsShapeQueryParameters3D.new();shape_query.shape=player.get_child(0).shape
	shape_query.transform=Transform3D(Basis.IDENTITY,point+candidate.position+Vector3(0,.98,0));shape_query.collision_mask=5
	if not get_world_3d().direct_space_state.intersect_shape(shape_query).is_empty():
		candidate.free();loading=false;curtain.visible=false;push_error("Blocked arrival capsule");return false
	if is_instance_valid(active):active.free()
	active=candidate;active.position=Vector3.ZERO;active.visible=true;current=rid;player.position=point;player.velocity=Vector3.ZERO
	await get_tree().physics_frame
	await get_tree().physics_frame
	model.pose(0,false,false,true);cooldown=1;last_gate=gate_id;visited[str(rid)]=true
	update_demo_camera(true)
	transition_log.append({"from":old,"to":rid,"gate":gate_id,"total_ms":(Time.get_ticks_usec()-t)/1000.0,"prepared":was_prepared,"scene_ms":candidate.build_ms,"static_memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"scene_count":1,"triangles":candidate.triangles})
	label.text="EXO WORLD GENESIS • SEED %s\n%02d — %s  |  Visitadas %d/7  |  Atlas: 88 externas\nWASD • Shift correr • Espaço saltar • E passagem • P pré-geração"%[str(atlas.seed),rid,str(pilot.labels[str(rid)]).to_upper(),visited.size()]
	loading=false;curtain.visible=false
	return true
func _physics_process(delta: float) -> void:
	if not ready_to_play or loading:return
	demo_elapsed+=delta;cooldown=maxf(0,cooldown-delta)
	var axis := Input.get_vector("left","right","up","down")
	var movement := screen_direction(axis) if not automated else qa_direction
	var sprint := Input.is_action_pressed("sprint") or automated
	var speed := 6.5 if sprint else 3.6
	player.velocity.x=move_toward(player.velocity.x,movement.x*speed,24*delta)
	player.velocity.z=move_toward(player.velocity.z,movement.z*speed,24*delta)
	if not player.is_on_floor():player.velocity.y-=20*delta
	if Input.is_action_just_pressed("jump") and player.is_on_floor():player.velocity.y=7.3
	player.move_and_slide()
	if movement.length()>.05:model.rotation.y=atan2(-movement.x,-movement.z)
	model.pose(demo_elapsed,false,sprint,player.is_on_floor())
	model.locomotion(player.get_real_velocity(),delta,sprint,player.is_on_floor(),true)
	for structure in active.props:
		if structure.has_meta("roof"):
			var roof: Node3D=structure.get_meta("roof")
			roof.visible=Vector2(player.position.x-structure.position.x,player.position.z-structure.position.z).length()>4.5
	update_demo_camera(false)
	var preload_target := -1
	var preload_distance := 42.0
	var hint := "Siga as trilhas até os arcos • Preparação antecipada: "+("ligada" if cache_enabled else "desligada")
	for gate in active.gate_nodes:
		var dist: float=Vector2(player.position.x,player.position.z).distance_to(Vector2(gate.point.x,gate.point.z))
		if gate.open and dist<preload_distance:
			preload_target=gate.contract.neighbor;preload_distance=dist
		if dist<8:
			hint="E — Viajar para região %02d"%gate.contract.neighbor if gate.open else "Saída reservada: região fora das sete demonstráveis"
			if gate.open and Input.is_action_just_pressed("interact") and cooldown<=0 and player.is_on_floor():
				change_region(gate.contract.neighbor,gate.contract.id);break
	if preload_target>=0:prepare_neighbor(preload_target)
	status.text=hint
	if player.position.y<active.data.center_h-100:push_error("Player fell below region");set_physics_process(false)
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_P:
			cache_enabled=not cache_enabled
			if not cache_enabled:
				plan_cache.clear();cache_order.clear()
				if is_instance_valid(prepared_scene):prepared_scene.free()
				prepared_scene=null;prepared_id=-1
		if event.keycode==KEY_ESCAPE:get_tree().quit()
	if event is InputEventMouseMotion:aim=event.position
func update_demo_camera(immediate: bool) -> void:
	if immediate:camera.size=36
	var target_pos := player.position+Vector3(17,24,20)
	camera.position=target_pos if immediate else camera.position.lerp(target_pos,.14)
	camera.look_at(player.position+Vector3(0,.7,0))
func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST:get_tree().quit()

func _exit_tree() -> void:
	if is_instance_valid(prepared_scene):prepared_scene.free()
