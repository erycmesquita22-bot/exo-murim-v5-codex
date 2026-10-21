extends Node3D
## Galeria inspecionavel de TODOS os novos GLBs, sem World Genesis.
const Kit = preload("res://godot/modular_kit.gd")
var mesh_root: Node3D

func _ready() -> void:
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("222a2a")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("e9e4d6")
	environment.environment.ambient_light_energy = 0.78
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-53,-42,0)
	sun.light_energy = 1.4
	add_child(sun)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 89.0
	camera.far = 250
	camera.position = Vector3(55,78,79)
	add_child(camera)
	camera.look_at(Vector3(0,0,0))
	mesh_root = Node3D.new()
	add_child(mesh_root)
	var plate := MeshInstance3D.new()
	plate.mesh = PlaneMesh.new()
	plate.mesh.size = Vector2(82,63)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("394239")
	plate.material_override = mat
	mesh_root.add_child(plate)
	plate.position.y = -0.1
	# JSON raiz lista; tipagem Variant intencional, sem mutacao.
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://docs/ASSETS-02-MANIFEST.json"))
	if not (parsed is Array):
		push_error("Forja gallery manifest could not be read")
		return
	var assets: Array = parsed
	for i in range(assets.size()):
		var item: Dictionary = assets[i]
		var id: String = str(item["id"])
		var x: float = float(i % 6 - 2.5) * 12.0
		var z: float = float(int(float(i)/6.0) - 2.5) * 11.0
		var low_y: float = float(item["bounds_m"][0][1])
		Kit.place(mesh_root,id,Vector3(x,-low_y,z),0.0,"",false)
		var pedestal := MeshInstance3D.new()
		pedestal.mesh = BoxMesh.new()
		pedestal.mesh.size = Vector3(7.6,.16,7.6)
		pedestal.position = Vector3(x,-.14,z)
		mesh_root.add_child(pedestal)
		var label := Label3D.new()
		label.text = id.replace("_"," ")
		label.font_size = 27
		label.pixel_size = 0.007
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = Vector3(x,3.8,z)
		mesh_root.add_child(label)
	print("FORJA_GALLERY_MODELS ",assets.size())
