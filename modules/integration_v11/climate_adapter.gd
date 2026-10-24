extends "res://modules/exo_climate_atmosphere_forge_01/runtime/climate_forge.gd"
## Preserve authored V11 scenery. Original demo waterfall/poles use unrelated fixed coordinates.
var suspended := false
var cached_materials: Array[ShaderMaterial] = []
var uniforms: Dictionary = {}
var wind_dirty := true
var day: Dictionary = {}
var sun: DirectionalLight3D
var wind_scans := 0
func attach_to_world(root: Node3D, linked_shader_forge: Node = null) -> bool:
	sun = root.get("light") as DirectionalLight3D
	var environment_node := _find_world_environment(root)
	if environment_node != null:
		var env := environment_node.environment
		day = {"background":env.background_color,"ambient":env.ambient_light_energy,"sun":sun.light_energy if sun != null else .78}
	var ok := super.attach_to_world(root,linked_shader_forge)
	refresh_scene_bindings()
	return ok
func _create_rain_particles() -> void:
	super._create_rain_particles()
	(rain_particles.draw_pass_1 as QuadMesh).size = Vector2(.008,.55)
	var gradient := Gradient.new();gradient.offsets = PackedFloat32Array([0,.45,1]);gradient.colors = PackedColorArray([Color(1,1,1,0),Color(1,1,1,1),Color(1,1,1,0)])
	var texture := GradientTexture2D.new();texture.gradient = gradient;texture.width = 8;texture.height = 64;texture.fill_from = Vector2(.5,0);texture.fill_to = Vector2(.5,1)
	var material := rain_particles.material_override as StandardMaterial3D;material.albedo_texture = texture;material.albedo_color = Color(.70,.82,.94,.34)
func _create_mist_particles() -> void:
	super._create_mist_particles()
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0,.55,1])
	gradient.colors = PackedColorArray([Color(1,1,1,.85),Color(1,1,1,.18),Color(1,1,1,0)])
	var texture := GradientTexture2D.new();texture.gradient = gradient;texture.width = 128;texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL;texture.fill_from = Vector2(.5,.5);texture.fill_to = Vector2(1,.5)
	(mist_particles.material_override as StandardMaterial3D).albedo_texture = texture
func _create_leaf_particles() -> void:
	super._create_leaf_particles()
	# A pointed silhouette instead of an opaque rectangle; no change to authored vegetation.
	var outline: Array[Vector3] = [Vector3(-.12,0,0),Vector3(-.04,.055,0),Vector3(.06,.04,0),Vector3(.12,0,0),Vector3(.04,-.055,0),Vector3(-.06,-.04,0)]
	var surface := SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in outline.size():
		for vertex in [Vector3.ZERO,outline[i],outline[(i+1)%outline.size()]]: surface.add_vertex(vertex*.45)
	surface.generate_normals();leaves_particles.draw_pass_1 = surface.commit()
	(leaves_particles.material_override as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
func _create_waterfall() -> void:
	# The original prototype remains included, but requires an authored placement to join V11.
	pass
func _create_lanterns() -> void:
	lantern_root = Node3D.new();lantern_root.name = "ClimateLightsOnAuthoredLanterns";world_root.add_child(lantern_root)
func refresh_scene_bindings():
	cached_materials.clear();uniforms.clear();wind_dirty = true;wind_scans += 1
	for child in lantern_root.get_children(): child.queue_free()
	for mesh in world_root.find_children("*","MeshInstance3D",true,false):
		if "LANTERN" in str(mesh.name) and mesh.is_visible_in_tree():
			var box: AABB = mesh.get_aabb()
			var lamp := OmniLight3D.new();lamp.light_color = Color("f2c17b");lamp.light_energy = .85;lamp.omni_range = 5.2;lamp.shadow_enabled = false
			lantern_root.add_child(lamp);lamp.global_position = mesh.global_transform*(box.get_center()+Vector3(0,box.size.y*.30,0))
		var materials: Array = []
		if mesh.material_override != null: materials.append(mesh.material_override)
		elif mesh.mesh != null:
			for index in mesh.mesh.get_surface_count(): materials.append(mesh.mesh.surface_get_material(index))
		for material in materials:
			if material is ShaderMaterial and not cached_materials.has(material):
				var names: Array[String] = []
				for uniform in material.shader.get_shader_uniform_list(): names.append(str(uniform.name))
				if "wind_strength" in names or "wave_scale" in names:
					cached_materials.append(material);uniforms[material.get_instance_id()] = names
	_update_visuals()
func _apply_scene_wind() -> void:
	if not wind_dirty: return
	for material in cached_materials:
		var names: Array = uniforms[material.get_instance_id()]
		if "wind_strength" in names: material.set_shader_parameter("wind_strength",.18+wind_strength*.82)
		if "wave_scale" in names: material.set_shader_parameter("wave_scale",.25+wind_strength*.55)
	wind_dirty = false
func set_weather(preset: String) -> void:
	wind_dirty = true;super.set_weather(preset)
func set_wind_strength(value: float) -> void:
	wind_dirty = true;super.set_wind_strength(value)
func _process(delta: float) -> void:
	if suspended: return
	super._process(delta)
	if mist_particles != null and tracked_camera != null:
		var actor = world_root.get("actor")
		mist_particles.global_position = Vector3(tracked_camera.global_position.x,actor.global_position.y+.45 if actor != null else tracked_camera.global_position.y-1.5,tracked_camera.global_position.z)
func set_suspended(value: bool):
	if suspended == value: return
	suspended = value
	_update_visuals()
func _update_visuals() -> void:
	super._update_visuals()
	for particles in [rain_particles,leaves_particles,mist_particles]:
		if particles != null:
			particles.visible = not suspended
			if suspended: particles.emitting = false
	if lantern_root != null: lantern_root.visible = night_lighting_enabled and not suspended
func _apply_environment_fog() -> void:
	if world_root == null or day.is_empty(): return
	var node := _find_world_environment(world_root)
	if node == null: return
	var env := node.environment
	env.fog_enabled = not suspended and weather_name != "clear" and (fog_intensity > .04 or rain_intensity > .25)
	env.fog_density = .001+fog_intensity*.010+rain_intensity*.002
	var night := night_lighting_enabled and not suspended
	env.fog_light_color = Color(.11,.16,.25) if night else Color(.8,.86,.91)
	env.fog_sky_affect = .25 if night else 1.0
	if mist_particles != null: (mist_particles.material_override as StandardMaterial3D).albedo_color = Color(.24,.30,.40,.09) if night else Color(.85,.90,.95,.14)
	if leaves_particles != null: (leaves_particles.material_override as StandardMaterial3D).albedo_color = Color(.34,.27,.09,.9) if night else Color(.71,.61,.28,.95)
	env.background_color = Color("101b30") if night else day.background
	env.ambient_light_energy = float(day.ambient)*(.25 if night else 1.0)
	if sun != null: sun.light_energy = float(day.sun)*(.14 if night else 1.0)
