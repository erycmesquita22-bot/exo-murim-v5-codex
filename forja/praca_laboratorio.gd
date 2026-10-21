extends Node3D
## Praca autônoma para testar a passagem central e os objetos importados.
const Plaza = preload("res://forja/plaza_furnisher.gd")
var seed_value: int = 1101
var root_region: Node3D
var label: Label

func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("272f2a")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_energy = .77
	add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-48,-36,0)
	light.light_energy = 1.3
	add_child(light)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 36
	cam.position = Vector3(22,32,40)
	add_child(cam)
	cam.look_at(Vector3(0,0,0))
	var ui := CanvasLayer.new()
	add_child(ui)
	label = Label.new()
	label.position = Vector2(24,20)
	ui.add_child(label)
	_make()

func _make() -> void:
	if is_instance_valid(root_region): root_region.queue_free()
	root_region = Node3D.new()
	add_child(root_region)
	var ground := MeshInstance3D.new()
	ground.mesh = PlaneMesh.new()
	ground.mesh.size = Vector2(26,24)
	root_region.add_child(ground)
	var pavement := MeshInstance3D.new()
	pavement.mesh = PlaneMesh.new()
	pavement.mesh.size = Vector2(4,23)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("8b806b")
	pavement.material_override = mat
	pavement.position.y = .01
	root_region.add_child(pavement)
	var parcel := {"id":"plaza_lab","center_x":0.0,"center_z":0.0,"ground_y":0.0,
		"width_m":22.0,"depth_m":18.0,"yaw_quadrants":0,"role":"market_square",
		"terrain_samples_y":[0.0,0.0,0.0,0.0],"approach_clear":true}
	var plan: Dictionary = Plaza.plan_plaza(seed_value,parcel)
	if not plan["ok"]:
		label.text = "FORJA PRAÇA ERRO " + str(plan)
		return
	var outcome: Dictionary = Plaza.build_plaza(root_region,plan)
	label.text = "EXO FORJA 02 / PRAÇA\nSeed: %d | objetos: %d\nR: nova seed" % [seed_value,int(outcome.get("count",0))]

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_R:
		seed_value += 1
		_make()
