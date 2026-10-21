extends Node3D
const Kit = preload("res://godot/modular_kit.gd")
var gallery: Node3D
var camera: Camera3D
var label: Label
var mode := 1
var distance := 39.0
var angle := .7
var focus := Vector3(0,1,0)
var elapsed := 0.0
var insect_nodes: Array = []

func _ready() -> void:
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("c4c3b9")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("fff6df")
	environment.environment.ambient_light_energy = .5
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55,-35,0)
	sun.light_energy = 1.1
	sun.shadow_enabled = false
	add_child(sun)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 31
	camera.far = 180
	add_child(camera)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	label = Label.new()
	label.position = Vector2(18,14)
	label.add_theme_font_size_override("font_size",20)
	label.add_theme_color_override("font_color",Color("202722"))
	canvas.add_child(label)
	show_mode(1)
	if "--capture" in OS.get_cmdline_user_args(): capture_gallery()
	elif "--qa" in OS.get_cmdline_user_args(): run_physics_qa()

func ground(texture: String = "") -> void:
	var body := StaticBody3D.new()
	gallery.add_child(body)
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3(100,.2,100)
	shape.position.y = -.12
	body.add_child(shape)
	var plane := MeshInstance3D.new()
	plane.mesh = PlaneMesh.new()
	plane.mesh.size = Vector2(100,100)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("c4c3b9")
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if texture != "":
		mat.albedo_texture = load("res://textures/tiles/"+texture+".png")
		mat.albedo_color = Color.WHITE
		mat.uv1_scale = Vector3(24,24,24)
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	plane.material_override = mat
	body.add_child(plane)

func title_at(text: String, pos: Vector3) -> void:
	var tag := Label3D.new()
	tag.text = text
	tag.font_size = 44
	tag.outline_size = 0
	tag.pixel_size = .012
	tag.modulate = Color("253129")
	tag.no_depth_test = false
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	gallery.add_child(tag)
	tag.position = pos

func show_mode(value: int) -> void:
	mode = value
	if is_instance_valid(gallery):
		remove_child(gallery)
		gallery.free()
	gallery = Node3D.new()
	add_child(gallery)
	focus = Vector3(0,1,0)
	camera.size = 31
	angle = .7
	distance = 39
	insect_nodes.clear()
	ground()
	var heading := ""
	if mode == 1:
		heading = "5 casas • mesma geometria / 5 paletas"
		var positions := [Vector3(-10,0,-6),Vector3(0,0,-6),Vector3(10,0,-6),Vector3(-5,0,6),Vector3(5,0,6)]
		var colors: Array = Kit.PALETTES.keys()
		for i in range(5):
			var house := Kit.build_house(gallery,colors[i])
			positions[i] = positions[i].rotated(Vector3.UP,.7)
			house.position = positions[i]
			title_at(colors[i],positions[i]+Vector3(0,.1,4.1))
		camera.size = 28
		focus = Vector3(0,3,0)
	elif mode == 2:
		heading = "27 módulos de construção • escala real"
		var n := 0
		Kit.ensure()
		for item in Kit.catalog.values():
			if item.family != "architecture": continue
			var p := Vector3((n%7)*4.6-14,0,(n/7)*5-7)
			Kit.place(gallery,item.id,p,0,"ivory_charcoal",false)
			title_at(item.id,p+Vector3(0,.05,2.2))
			n += 1
		camera.size = 34
	elif mode == 3:
		heading = "Árvores, bambus, folhas, arbustos e mato • escala real"
		var n := 0
		for item in Kit.catalog.values():
			if item.family != "nature": continue
			var p := Vector3((n%6)*4.3-11,0,(n/6)*4.2-6)
			Kit.place(gallery,item.id,p,0,"",true)
			title_at(item.id,p+Vector3(0,.04,1.7))
			n += 1
		camera.size = 29
	elif mode == 4:
		heading = "Horta • 8 cultivos × 3 estágios visuais"
		var crop_ids := ["lettuce","cabbage","carrot","radish","onion","pumpkin","eggplant","cucumber"]
		for i in range(8):
			for stage in range(3):
				var p := Vector3(i*2.3-8,0,stage*2.6-2.6)
				Kit.place(gallery,"garden_bed_2x2",p,0,"",false)
				for offset in [Vector3(-.42,0,-.42),Vector3(.42,0,-.42),Vector3(-.42,0,.42),Vector3(.42,0,.42)]:
					Kit.place(gallery,crop_ids[i]+"_stage_"+str(stage+1),p+offset,0,"",false)
				title_at(crop_ids[i]+" • "+str(stage+1),p+Vector3(0,.05,1.05))
		camera.size = 21
	elif mode == 5:
		heading = "Detalhes • insetos ampliados ×20 para inspeção (arquivos em escala real)"
		var names := ["lantern_01","lantern_02","clay_jar","firewood_stack","fence_2m","fallen_log","stump","butterfly_01","butterfly_02","cicada","firefly"]
		for i in range(names.size()):
			var p := Vector3((i%6)*3.3-8,1 if i>6 else 0,(i/6)*4-2)
			var node := Kit.place(gallery,names[i],p,0,"ivory_charcoal" if i<5 else "",false)
			if i>6:
				node.scale = Vector3.ONE*20
				node.set_meta("phase",i)
				node.set_script(preload("res://godot/ambient_insect.gd"))
				node.species = "cicada" if names[i]=="cicada" else "firefly" if names[i]=="firefly" else "butterfly"
				node.anchor = p
				node.phase = i
				node.prepared = true
				insect_nodes.append(node)
			title_at(names[i],p+Vector3(0,-.9 if i>6 else 0,1.25))
		camera.size = 22
	elif mode == 6:
		heading = "64 texturas aprovadas • recortes dos atlas originais"
		var textures: Array = JSON.parse_string(FileAccess.get_file_as_string("res://textures/catalog.json"))
		for i in range(textures.size()):
			var mesh := MeshInstance3D.new()
			mesh.mesh = PlaneMesh.new()
			mesh.mesh.size = Vector2(1.95,1.95)
			var mat := StandardMaterial3D.new()
			mat.albedo_texture = load("res://"+textures[i].file)
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			mesh.material_override = mat
			gallery.add_child(mesh)
			mesh.position = Vector3((i%8)*2.2-7.7,.02,(i/8)*2.2-7.7)
		camera.size = 23
	label.text = "EXO MURIM • ASSETS MODULARES 01\n"+heading+"\n1 Casas · 2 Módulos · 3 Natureza · 4 Horta · 5 Detalhes · 6 Texturas\n← → girar câmera · roda do mouse aproximar · O abrir/fechar portas"
	update_camera()

func update_camera() -> void:
	camera.position = focus+Vector3(sin(angle)*distance,distance*.75,cos(angle)*distance)
	camera.look_at(focus)

func _process(delta: float) -> void:
	elapsed += delta
	if Input.is_physical_key_pressed(KEY_LEFT): angle -= delta*.6
	if Input.is_physical_key_pressed(KEY_RIGHT): angle += delta*.6
	update_camera()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6]: show_mode(event.keycode-KEY_0)
		if event.keycode == KEY_O:
			for door in gallery.find_children("door_double","Node3D",true,false): door.set_open(not door.opened)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP: camera.size = maxf(5,camera.size-2)
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN: camera.size = minf(55,camera.size+2)

func capture_gallery() -> void:
	for value in range(1,7):
		show_mode(value)
		for frame in range(20): await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://qa/gallery_0%d.png" % value)
		print("CAPTURE ",value)
	get_tree().quit()

func run_physics_qa() -> void:
	var results: Array = []
	for width in [4,6,8]:
		for stories in [1,2]:
			if is_instance_valid(gallery):
				remove_child(gallery)
				gallery.free()
			gallery=Node3D.new()
			add_child(gallery)
			ground()
			var house := Kit.build_house(gallery,"ivory_charcoal",width,stories)
			await get_tree().physics_frame
			await get_tree().physics_frame
			for door in house.find_children("door_double","Node3D",true,false): door.set_open(true)
			var actor := preload("res://qa/walker.gd").new()
			actor.floor_snap_length=.4
			var shape := CollisionShape3D.new()
			shape.shape=CapsuleShape3D.new()
			shape.shape.radius=.25
			shape.shape.height=1.8
			shape.position.y=.9
			actor.add_child(shape)
			gallery.add_child(actor)
			var door_x: float=house.get_meta("door_x",0)
			actor.position=Vector3(door_x,.1,4)
			actor.direction=Vector3(0,0,-1)
			var frames:=0
			while frames<240 and actor.position.z>.8:
				await get_tree().physics_frame
				frames+=1
			var entered:=actor.position.z<.8 and actor.position.y>.3
			actor.direction=Vector3(0,0,1)
			var back:=0
			while back<240 and actor.position.z<3.5:
				await get_tree().physics_frame
				back+=1
			var exited:=actor.position.z>3.5
			for door in house.find_children("door_double","Node3D",true,false): door.set_open(false)
			actor.direction=Vector3(0,0,-1)
			for f in range(160): await get_tree().physics_frame
			var closed_blocks:=actor.position.z>2.1
			results.append({"width":width,"stories":stories,"entered":entered,"exited":exited,"closed_door_blocks":closed_blocks,"frames_entry":frames,"closed_stop":actor.position})
	var passed:=true
	for result in results:
		if not result.entered or not result.exited or not result.closed_door_blocks:passed=false
	FileAccess.open("res://qa/physics.json",FileAccess.WRITE).store_string(JSON.stringify({"results":results,"passed":passed,"engine":Engine.get_version_info()},"\t"))
	print("PHYSICS templates=",results.size()," passed=",passed)
	get_tree().quit(0 if passed else 1)
