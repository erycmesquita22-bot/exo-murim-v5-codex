extends Node3D
## Laboratorio independente; NAO carrega nenhum mapa da campanha nem o World Genesis.
const Planner = preload("res://forja/forja_planner.gd")
const Builder = preload("res://forja/forja_builder.gd")
const Kit = preload("res://godot/modular_kit.gd")
var region: Node3D
var camera: Camera3D
var info: Label
var show_city := false
var show_courtyards := false
var show_high := false
var current_seed := 880701

func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("202e2b")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("fff0dc")
	env.environment.ambient_light_energy = 0.65
	add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-54,-34,0)
	light.light_energy = 1.25
	add_child(light)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 96
	camera.far = 400
	add_child(camera)
	camera.position = Vector3(75,88,107)
	camera.look_at(Vector3(0,0,0))
	var ui := CanvasLayer.new()
	add_child(ui)
	info = Label.new()
	info.position = Vector2(25,20)
	info.add_theme_font_size_override("font_size",22)
	ui.add_child(info)
	_build(false)
	if "--capture" in OS.get_cmdline_user_args(): call_deferred("_capture")

func _capture() -> void:
	for mode in range(4):
		_build(mode == 1 or mode == 3, mode == 2, mode == 3)
		for frame in range(40): await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var output: String = "res://qa/captures/forja02_" + str(["aldeia", "cidade", "patios", "detalhes_alto"][mode]) + ".png"
		var error_code: int = get_viewport().get_texture().get_image().save_png(output)
		print("FORJA_CAPTURE ", output, " status=", error_code)
	get_tree().quit()

func _plane(parent: Node3D, position: Vector3, size: Vector2, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	mesh.mesh = PlaneMesh.new()
	mesh.mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	mesh.material_override = material
	parent.add_child(mesh)
	mesh.position = position

func _lot(id: String, cx: float, cz: float, yaw: int, district: String, role: String, stories: int, profile: String = "medium") -> Dictionary:
	return {"id": id, "center_x": cx, "center_z": cz, "ground_y": 0.0,
		"width_m": 13.0, "depth_m": 17.0, "yaw_quadrants": yaw,
		"district": district, "role": role, "max_stories": stories, "detail_profile": profile,
		"terrain_samples_y": [0.0, 0.0, 0.0, 0.0], "approach_clear": true}

func _build(city: bool, courtyards: bool = false, high: bool = false) -> void:
	show_city = city
	show_courtyards = courtyards
	show_high = high
	if is_instance_valid(region): region.queue_free()
	region = Node3D.new()
	region.name = "ForjaRegion"
	add_child(region)
	_plane(region, Vector3(0,-0.025,0), Vector2(110,90), Color("40543d"))
	_plane(region, Vector3(0,0,0), Vector2(104,4.0), Color("80715d"))
	var lots: Array = []
	if courtyards:
		for index in range(4):
			var x: float = float(index * 20 - 30)
			var lot: Dictionary = _lot("patio_%d" % index, x, -16.0 if index%2 == 0 else 16.0, 0 if index%2 == 0 else 2, "village", "dwelling", 2, "high")
			lot["width_m"] = 9.2
			lot["depth_m"] = 22.0
			# Encontra deterministamente um id de lote valido com a variante patio.
			for attempt in range(100):
				lot["id"] = "patio_%d_variant_%d" % [index,attempt]
				var candidate: Dictionary = Planner.plan_lot(current_seed,lot)
				if candidate["ok"] and candidate["plan"]["archetype"] == "courtyard": break
			lots.append(lot)
	elif city:
		var roles: Array = ["shop", "dwelling", "workshop", "tea_house", "dwelling", "shop", "tea_house", "workshop"]
		var index := 0
		for z in [-15.0, 15.0]:
			for x in [-30.0, -10.0, 10.0, 30.0]:
				lots.append(_lot("city_%d" % index, x, z, 0 if z < 0 else 2, "city", str(roles[index]), 2, "high" if high else "medium"))
				index += 1
	else:
		var roles: Array = ["dwelling", "dwelling", "shop", "workshop", "tea_house"]
		var points := [Vector2(-28,-15), Vector2(-9,-15), Vector2(10,-15), Vector2(-19,15), Vector2(19,15)]
		for index in range(points.size()):
			var p: Vector2 = points[index]
			lots.append(_lot("village_%d" % index, p.x, p.y, 0 if p.y < 0 else 2, "village", str(roles[index]), 1, "medium"))
	var result: Dictionary = Planner.plan_settlement(current_seed, lots, true)
	if result["ok"]:
		var assembled: Dictionary = Builder.build_batch(region, result)
		if assembled["ok"]:
			if city:
				Kit.place(region,"village_water_well",Vector3(-44,0,-7.5),0.0,"",false)
				Kit.place(region,"covered_market_stall",Vector3(43,0,7.4),0.0,"",false)
				Kit.place(region,"timber_handcart",Vector3(38,0,-8.2),0.0,"",false)
			elif not courtyards:
				Kit.place(region,"village_water_well",Vector3(0,0,8.0),0.0,"",false)
			for plan in result["plans"]:
				var anchor: Vector3 = Vector3(float(plan["origin_world"][0]),0,float(plan["origin_world"][2]))
				var world_approach: Vector3 = Vector3(float(plan["approach_local"][0]),0,float(plan["approach_local"][2])).rotated(Vector3.UP,float(plan["yaw_quadrants"])*PI/2)+anchor
				var on_road := Vector3(world_approach.x,0,0)
				var center := (world_approach+on_road)*0.5
				_plane(region, Vector3(center.x,0.012,center.z),Vector2(1.9,maxf(0.4,absf(world_approach.z))),Color("9b8866"))
			var region_name: String = "ALDEIA"
			if courtyards: region_name = "PATIOS"
			elif high: region_name = "CIDADE / DETALHES ALTOS"
			elif city: region_name = "CIDADE"
			info.text = "EXO FORJA 02 — " + region_name + "\n%d lotes / %d casas | seed %d\n1 aldeia · 2 cidade · 3 patios · 4 detalhes altos · R seed" % [lots.size(), int(assembled["count"]), current_seed]
		else:
			info.text = "ERRO DE MONTAGEM " + str(assembled)
	else:
		info.text = "ERRO DE PLANEJAMENTO " + str(result.get("rejections",[]))

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1: _build(false)
		elif event.keycode == KEY_2: _build(true)
		elif event.keycode == KEY_3: _build(false,true)
		elif event.keycode == KEY_4: _build(true,false,true)
		elif event.keycode == KEY_R:
			current_seed += 1
			_build(show_city,show_courtyards,show_high)
