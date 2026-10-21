extends Node3D
## Laboratorio autonomo: modos 1 muralhas, 2 cla, 3 templo, 4 treinamento,
## 5 fazenda, 6 celeiro, 7 guilda. R varia a seed.
const Fort = preload("res://forja/fortification_planner.gd")
const Wall = preload("res://forja/fortification_builder.gd")
const Civic = preload("res://forja/civic_planner.gd")
const Builder = preload("res://forja/civic_builder.gd")
const Compound = preload("res://forja/compound_assembler.gd")
const Green = preload("res://forja/green_buffer_v3.gd")
var subject: Node3D
var camera: Camera3D
var label: Label
var current_seed: int = 880701
var mode: int = 1

func _ready() -> void:
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("23332b")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("ffe5b8")
	environment.environment.ambient_light_energy = .7
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-53.0,-33.0,0.0)
	light.light_energy = 1.3
	add_child(light)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 54.0
	camera.far = 200.0
	add_child(camera)
	camera.position = Vector3(45,54,65)
	camera.look_at(Vector3.ZERO)
	var ui := CanvasLayer.new()
	add_child(ui)
	label = Label.new()
	label.position = Vector2(22,20)
	label.add_theme_font_size_override("font_size",19)
	ui.add_child(label)
	build_mode()
	if "--capture" in OS.get_cmdline_user_args(): call_deferred("capture_gallery")

func lot(role: String) -> Dictionary:
	var result: Dictionary = {"id":"forja_03_"+role,"center_x":0.0,"center_z":0.0,"ground_y":0.0,
		"width_m":32.0,"depth_m":36.0,"yaw_quadrants":0,
		"terrain_samples_y":[0.0,0.0,0.0,0.0],"approach_clear":true,"detail_profile":"high"}
	if role == "fort":
		result["style"] = ["stone","wood","battlement"][int(current_seed%3)]
		result["back_gate"] = true
	else:result["role"] = role
	return result

func build_mode() -> void:
	if is_instance_valid(subject):subject.queue_free()
	subject = Node3D.new()
	subject.name = "EXO_Forja03_Inspection"
	add_child(subject)
	var ground := MeshInstance3D.new()
	var gmesh := PlaneMesh.new()
	gmesh.size = Vector2(60,60)
	ground.mesh = gmesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("576b43")
	mat.roughness = 1.0
	ground.material_override = mat
	subject.add_child(ground)
	ground.position.y = -.03
	var entry: Dictionary
	var built: Dictionary
	var name: String
	if mode == 8:
		var compound_lot: Dictionary = lot("sect_hall")
		compound_lot["style"] = "auto"
		entry = Compound.plan_compound(current_seed,compound_lot)
		built = Compound.build_compound(subject,entry) if entry["ok"] else entry
		name = "CLA MURADO"
	elif mode == 9:
		var forest_lot: Dictionary = lot("green")
		forest_lot["biome"] = "mixed"
		forest_lot["road_clear"] = true
		forest_lot["density"] = .95
		entry = Green.plan(current_seed,forest_lot)
		built = Green.build(subject,entry) if entry["ok"] else entry
		name = "FAIXA VERDE"
	elif mode == 1:
		entry = Fort.plan_fort(current_seed,lot("fort"))
		built = Wall.build(subject,entry["plan"]) if entry["ok"] else entry
		name = "FORTIFICACAO"
	else:
		var roles: Array[String] = ["sect_hall","temple","martial_school","farmstead","granary","guild_hall"]
		var role: String = roles[mode-2]
		entry = Civic.plan_civic(current_seed,lot(role))
		built = Builder.build(subject,entry["plan"]) if entry["ok"] else entry
		name = role.to_upper()
	label.text = "EXO FORJA 03 · " + name + "\nSeed: " + str(current_seed) + " · " + str(built) if not built.get("ok",false) else "EXO FORJA 03 · " + name + "\nSeed: " + str(current_seed) + " | 1-9 cenarios | R nova seed"

func capture_gallery() -> void:
	for k in range(1,10):
		mode = k
		build_mode()
		for frame in range(24):await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var path: String = "res://qa/captures/forja03_" + str(k) + ".png"
		var code: int = get_viewport().get_texture().get_image().save_png(path)
		print("FORJA03_CAPTURE ", path, " status=",code)
	get_tree().quit()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			mode = event.keycode - KEY_1 + 1
			build_mode()
		elif event.keycode == KEY_R:
			current_seed += 1
			build_mode()
