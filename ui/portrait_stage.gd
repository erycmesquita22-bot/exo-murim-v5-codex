extends Control
const Wardrobe=preload("res://wardrobe.gd")
var world: Node3D
var rig: Node3D
var viewport: SubViewport
var camera: Camera3D
var dragging:=false
var last_level:=-1
var last_window:=Vector2i.ZERO
func _init(owner_world: Node3D,profile: Dictionary,dimensions: Vector2) -> void:
	world=owner_world
	custom_minimum_size=dimensions
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	viewport=SubViewport.new();add_child(viewport)
	viewport.own_world_3d=true
	viewport.transparent_bg=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	var image:=TextureRect.new();add_child(image)
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.texture=viewport.get_texture()
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_SCALE
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var env:=WorldEnvironment.new();viewport.add_child(env)
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color(0,0,0,0)
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("bbcddd")
	env.environment.ambient_light_energy=.4
	for spec in [[Vector3(-35,-35,0),Color("fff0d7"),1.4],[Vector3(-20,135,0),Color("91bedc"),.65]]:
		var light:=DirectionalLight3D.new();viewport.add_child(light)
		light.rotation_degrees=spec[0];light.light_color=spec[1];light.light_energy=spec[2]
	camera=Camera3D.new();viewport.add_child(camera)
	camera.position=Vector3(3.1,2.2,-5)
	camera.look_at_from_position(camera.position,Vector3(0,1,0))
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=3.7 if str(profile.get("weapon","sword")) in ["spear","halberd","scythe","greatsword","quarterstaff","arcane_staff"] else 2.85
	rig=world.Rig.new();viewport.add_child(rig)
	Wardrobe.apply(rig,profile)
	resized.connect(update_resolution)
func _ready() -> void:update_resolution()
func _process(_delta: float) -> void:
	if last_level!=world.graphics.level or last_window!=get_window().size:update_resolution()
func update_resolution() -> void:
	if not is_inside_tree():return
	last_level=world.graphics.level;last_window=get_window().size
	var detail: int=clampi(world.graphics.get_option("detail_distance"),0,2)
	var scale_value: float=maxf(1.0,float(last_window.y)/720.0)*[1.0,1.5,2.0][detail]
	var requested: Vector2=size*scale_value
	var cap:=minf(1.0,2048.0/maxf(requested.x,requested.y))
	viewport.size=Vector2i((requested*cap).max(Vector2(32,32)))
	viewport.msaa_3d=[Viewport.MSAA_DISABLED,Viewport.MSAA_2X,Viewport.MSAA_4X,Viewport.MSAA_8X][clampi(world.graphics.get_option("msaa"),0,3)]
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_LEFT:dragging=event.pressed
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			camera.size=clampf(camera.size+(-.2 if event.button_index==MOUSE_BUTTON_WHEEL_UP else .2),2.2,5)
		accept_event()
	if event is InputEventMouseMotion and dragging:
		rig.rotation.y-=event.relative.x*.012;accept_event()
