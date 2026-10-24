extends Node
## EXO Climate & Atmosphere Forge 01

const WATERFALL_SHADER = preload("res://modules/exo_climate_atmosphere_forge_01/shaders/exo_waterfall.gdshader")

var world_root: Node3D
var shader_forge: Node
var attached := false
var weather_name := "clear"
var wind_strength: float = 0.35
var rain_intensity: float = 0.0
var fog_intensity: float = 0.10
var night_lighting_enabled := false

var rain_particles: GPUParticles3D
var leaves_particles: GPUParticles3D
var mist_particles: GPUParticles3D
var waterfall_root: Node3D
var lantern_root: Node3D
var tracked_camera: Camera3D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func attach_to_world(root: Node3D, linked_shader_forge: Node = null) -> bool:
	if root == null:
		return false
	world_root = root
	shader_forge = linked_shader_forge
	tracked_camera = _find_camera(root)
	_create_rain_particles()
	_create_leaf_particles()
	_create_mist_particles()
	_create_waterfall()
	_create_lanterns()
	attached = true
	set_weather("clear")
	return true

func _process(delta: float) -> void:
	if not attached:
		return
	if tracked_camera == null:
		tracked_camera = _find_camera(world_root)
	if tracked_camera != null:
		var anchor := tracked_camera.global_position
		if rain_particles != null:
			rain_particles.global_position = anchor + Vector3(0, 10.0, 0)
		if leaves_particles != null:
			leaves_particles.global_position = anchor + Vector3(0, 6.0, 0)
	if waterfall_root != null:
		waterfall_root.rotation_degrees.y += delta * 2.0
	_apply_scene_wind()

func _find_camera(node: Node) -> Camera3D:
	if node is Camera3D:
		return node as Camera3D
	for child in node.get_children():
		var found := _find_camera(child)
		if found != null:
			return found
	return null

func _create_rain_particles() -> void:
	rain_particles = GPUParticles3D.new()
	rain_particles.name = "EXORain"
	rain_particles.amount = 1800
	rain_particles.lifetime = 1.45
	rain_particles.one_shot = false
	rain_particles.visibility_aabb = AABB(Vector3(-18, -15, -18), Vector3(36, 30, 36))
	rain_particles.draw_pass_1 = QuadMesh.new()
	(rain_particles.draw_pass_1 as QuadMesh).size = Vector2(0.025, 0.7)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.76, 0.84, 0.94, 0.68)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rain_particles.material_override = m
	var proc := ParticleProcessMaterial.new()
	proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	proc.emission_box_extents = Vector3(16, 0.2, 16)
	proc.direction = Vector3(0, -1, 0)
	proc.initial_velocity_min = 10.0
	proc.initial_velocity_max = 14.0
	proc.gravity = Vector3(-1.2, -21.0, 0.5)
	proc.scale_min = 0.55
	proc.scale_max = 1.15
	proc.angle_min = -0.12
	proc.angle_max = 0.12
	rain_particles.process_material = proc
	world_root.add_child(rain_particles)

func _create_leaf_particles() -> void:
	leaves_particles = GPUParticles3D.new()
	leaves_particles.name = "EXOFallingLeaves"
	leaves_particles.amount = 140
	leaves_particles.lifetime = 8.0
	leaves_particles.one_shot = false
	leaves_particles.visibility_aabb = AABB(Vector3(-18, -8, -18), Vector3(36, 18, 36))
	var quad := QuadMesh.new()
	quad.size = Vector2(0.22, 0.12)
	leaves_particles.draw_pass_1 = quad
	var lm := StandardMaterial3D.new()
	lm.albedo_color = Color("b69c48")
	lm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	leaves_particles.material_override = lm
	var proc := ParticleProcessMaterial.new()
	proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	proc.emission_box_extents = Vector3(14, 0.2, 14)
	proc.direction = Vector3(0, -1, 0)
	proc.gravity = Vector3(0, -1.6, 0)
	proc.initial_velocity_min = 0.3
	proc.initial_velocity_max = 1.1
	proc.angular_velocity_min = -2.2
	proc.angular_velocity_max = 2.2
	proc.scale_min = 0.7
	proc.scale_max = 1.4
	proc.orbit_velocity_min = 0.1
	proc.orbit_velocity_max = 0.9
	leaves_particles.process_material = proc
	world_root.add_child(leaves_particles)

func _create_mist_particles() -> void:
	mist_particles = GPUParticles3D.new()
	mist_particles.name = "EXOMist"
	mist_particles.amount = 95
	mist_particles.lifetime = 7.5
	mist_particles.one_shot = false
	mist_particles.visibility_aabb = AABB(Vector3(-24, -1, -24), Vector3(48, 6, 48))
	var quad := QuadMesh.new()
	quad.size = Vector2(2.5, 1.2)
	mist_particles.draw_pass_1 = quad
	var mm := StandardMaterial3D.new()
	mm.albedo_color = Color(0.85, 0.9, 0.95, 0.18)
	mm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mist_particles.material_override = mm
	var proc := ParticleProcessMaterial.new()
	proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	proc.emission_box_extents = Vector3(18, 0.4, 18)
	proc.direction = Vector3(0.2, 0.02, 0.1)
	proc.initial_velocity_min = 0.1
	proc.initial_velocity_max = 0.5
	proc.scale_min = 1.2
	proc.scale_max = 2.2
	proc.gravity = Vector3(0, 0.03, 0)
	mist_particles.process_material = proc
	mist_particles.position = Vector3(0, 0.3, -8)
	world_root.add_child(mist_particles)

func _create_waterfall() -> void:
	waterfall_root = Node3D.new()
	waterfall_root.name = "EXOWaterfallSet"
	world_root.add_child(waterfall_root)
	waterfall_root.position = Vector3(-12.8, 3.2, -17.5)
	var rock := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(5.0, 7.5, 4.5)
	rock.mesh = box
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color("5d6a6d")
	rm.roughness = 1.0
	rock.material_override = rm
	waterfall_root.add_child(rock)
	var fall := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(3.2, 5.6)
	fall.mesh = plane
	fall.position = Vector3(0.0, 0.2, 2.28)
	fall.rotation_degrees = Vector3(90, 0, 0)
	var wm := ShaderMaterial.new()
	wm.shader = WATERFALL_SHADER
	fall.material_override = wm
	waterfall_root.add_child(fall)
	var pool := MeshInstance3D.new()
	var pool_mesh := CylinderMesh.new()
	pool_mesh.top_radius = 1.7
	pool_mesh.bottom_radius = 1.9
	pool_mesh.height = 0.15
	pool.mesh = pool_mesh
	pool.position = Vector3(0.0, -2.75, 2.0)
	if shader_forge != null and shader_forge.has_method("make_water_material"):
		pool.material_override = shader_forge.make_water_material()
	waterfall_root.add_child(pool)
	var splash := GPUParticles3D.new()
	splash.amount = 70
	splash.lifetime = 1.8
	splash.one_shot = false
	splash.position = Vector3(0.0, -2.55, 2.05)
	splash.draw_pass_1 = QuadMesh.new()
	(splash.draw_pass_1 as QuadMesh).size = Vector2(0.45, 0.35)
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.92,0.95,1.0,0.55)
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	splash.material_override = sm
	var proc := ParticleProcessMaterial.new()
	proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	proc.emission_sphere_radius = 0.55
	proc.direction = Vector3(0,1,0)
	proc.initial_velocity_min = 0.5
	proc.initial_velocity_max = 1.8
	proc.gravity = Vector3(0,-1.8,0)
	proc.scale_min = 0.5
	proc.scale_max = 1.3
	splash.process_material = proc
	waterfall_root.add_child(splash)

func _create_lanterns() -> void:
	lantern_root = Node3D.new()
	lantern_root.name = "EXONightLanterns"
	world_root.add_child(lantern_root)
	for i in 5:
		var offset_z := -2.0 - float(i) * 6.0
		for side in [-1, 1]:
			var post := MeshInstance3D.new()
			var pole := CylinderMesh.new()
			pole.top_radius = 0.06
			pole.bottom_radius = 0.08
			pole.height = 1.8
			post.mesh = pole
			post.position = Vector3(side * 2.1, 0.9, offset_z)
			var pm := StandardMaterial3D.new()
			pm.albedo_color = Color("4a3724")
			pm.roughness = 1.0
			post.material_override = pm
			lantern_root.add_child(post)
			var bulb := MeshInstance3D.new()
			var sphere := SphereMesh.new()
			sphere.radius = 0.16
			sphere.height = 0.32
			bulb.mesh = sphere
			bulb.position = Vector3(side * 2.1, 1.62, offset_z)
			var bm := StandardMaterial3D.new()
			bm.albedo_color = Color("f4c87b")
			bm.emission_enabled = true
			bm.emission = Color("f4c87b")
			bm.emission_energy_multiplier = 1.8
			bulb.material_override = bm
			lantern_root.add_child(bulb)
			var light := OmniLight3D.new()
			light.position = Vector3(side * 2.1, 1.62, offset_z)
			light.light_color = Color("f2c17b")
			light.light_energy = 1.2
			light.omni_range = 5.2
			light.shadow_enabled = false
			lantern_root.add_child(light)
	lantern_root.visible = false

func set_weather(name: String) -> void:
	weather_name = name.to_lower()
	match weather_name:
		"clear":
			_apply_preset(0.28, 0.0, 0.05, false)
		"drizzle":
			_apply_preset(0.34, 0.32, 0.12, false)
		"rain":
			_apply_preset(0.42, 0.78, 0.22, false)
		"mist":
			_apply_preset(0.18, 0.0, 0.62, false)
		"storm":
			_apply_preset(0.80, 1.0, 0.44, false)
		"night":
			_apply_preset(0.22, 0.0, 0.16, true)
		_:
			_apply_preset(0.28, 0.0, 0.05, false)

func _apply_preset(wind_val: float, rain_val: float, fog_val: float, night_val: bool) -> void:
	wind_strength = clampf(wind_val, 0.0, 1.0)
	rain_intensity = clampf(rain_val, 0.0, 1.0)
	fog_intensity = clampf(fog_val, 0.0, 1.0)
	night_lighting_enabled = night_val
	_update_visuals()

func set_wind_strength(value: float) -> void:
	wind_strength = clampf(value, 0.0, 1.0)
	_update_visuals()

func set_rain_intensity(value: float) -> void:
	rain_intensity = clampf(value, 0.0, 1.0)
	_update_visuals()

func set_fog_intensity(value: float) -> void:
	fog_intensity = clampf(value, 0.0, 1.0)
	_update_visuals()

func set_night_lighting(enabled: bool) -> void:
	night_lighting_enabled = enabled
	_update_visuals()

func _update_visuals() -> void:
	if rain_particles != null:
		rain_particles.emitting = rain_intensity > 0.02
		rain_particles.amount = int(400 + rain_intensity * 2600.0)
		var rpm := rain_particles.process_material as ParticleProcessMaterial
		if rpm != null:
			rpm.initial_velocity_min = lerpf(8.0, 13.0, rain_intensity)
			rpm.initial_velocity_max = lerpf(11.0, 17.0, rain_intensity)
			rpm.gravity = Vector3(-wind_strength * 4.0, -21.0, 0.8)
	if leaves_particles != null:
		leaves_particles.emitting = wind_strength > 0.1
		var lpm := leaves_particles.process_material as ParticleProcessMaterial
		if lpm != null:
			lpm.initial_velocity_min = 0.2 + wind_strength * 0.8
			lpm.initial_velocity_max = 0.8 + wind_strength * 1.8
			lpm.orbit_velocity_max = 0.5 + wind_strength * 1.8
	if mist_particles != null:
		mist_particles.emitting = fog_intensity > 0.08 or rain_intensity > 0.3
		mist_particles.amount = int(30 + fog_intensity * 160.0)
		var mpm := mist_particles.process_material as ParticleProcessMaterial
		if mpm != null:
			mpm.initial_velocity_max = 0.2 + wind_strength * 0.7
	if lantern_root != null:
		lantern_root.visible = night_lighting_enabled
	if shader_forge != null:
		if shader_forge.has_method("set_cloud_amount"):
			shader_forge.set_cloud_amount(clampf(0.28 + rain_intensity * 0.45 + fog_intensity * 0.15, 0.0, 1.0))
		if shader_forge.has_method("set_fog"):
			shader_forge.set_fog(fog_intensity > 0.09 or rain_intensity > 0.2)
	_apply_scene_wind()
	_apply_environment_fog()
	print("EXO_CLIMATE preset=", weather_name, " wind=", snappedf(wind_strength,0.01), " rain=", snappedf(rain_intensity,0.01), " fog=", snappedf(fog_intensity,0.01), " night=", night_lighting_enabled)

func _apply_scene_wind() -> void:
	if world_root == null:
		return
	_recursive_apply_materials(world_root)

func _recursive_apply_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_node := node as MeshInstance3D
		var mats: Array = []
		if mesh_node.material_override != null:
			mats.append(mesh_node.material_override)
		elif mesh_node.mesh != null:
			for i in mesh_node.mesh.get_surface_count():
				var sm = mesh_node.mesh.surface_get_material(i)
				if sm != null:
					mats.append(sm)
		for mat in mats:
			if mat is ShaderMaterial:
				(mat as ShaderMaterial).set_shader_parameter("wind_strength", 0.18 + wind_strength * 0.82)
				(mat as ShaderMaterial).set_shader_parameter("wave_scale", 0.25 + wind_strength * 0.55)
	for child in node.get_children():
		_recursive_apply_materials(child)

func _apply_environment_fog() -> void:
	var env_node := _find_world_environment(world_root)
	if env_node == null or env_node.environment == null:
		return
	var env := env_node.environment
	env.fog_enabled = fog_intensity > 0.04 or rain_intensity > 0.25
	env.fog_density = 0.001 + fog_intensity * 0.010 + rain_intensity * 0.002
	env.fog_light_color = Color(0.80, 0.86, 0.91)
	env.fog_aerial_perspective = 0.18 + fog_intensity * 0.26
	env.fog_sun_scatter = 0.10
	if night_lighting_enabled:
		env.adjustment_enabled = true
		env.adjustment_saturation = 1.02
		env.glow_enabled = true
		env.glow_strength = 0.75

func _find_world_environment(root: Node) -> WorldEnvironment:
	if root is WorldEnvironment:
		return root as WorldEnvironment
	for child in root.get_children():
		var found := _find_world_environment(child)
		if found != null:
			return found
	return null
