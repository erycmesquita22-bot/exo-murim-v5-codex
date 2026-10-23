extends RefCounted
## Runtime bake-once cache for the EXO authored Forja house.
## All geometry is kept from the original models; materials are baked into one atlas.
const Kit = preload("res://godot/modular_kit.gd")
static var cache: Dictionary = {}
const TILES_X: int = 8
const TILES_Y: int = 8
const TILE: int = 64

static func _atlas_material(source: Material, img: Image, slot: int) -> void:
	var col: Color = Color.WHITE
	var pixels: Image = null
	if source is StandardMaterial3D:
		col = (source as StandardMaterial3D).albedo_color
		var texture: Texture2D = (source as StandardMaterial3D).albedo_texture
		if texture != null:
			pixels = texture.get_image()
	if pixels != null:
		pixels = pixels.duplicate()
		pixels.convert(Image.FORMAT_RGBA8)
		pixels.resize(TILE, TILE, Image.INTERPOLATE_BILINEAR)
	else:
		pixels = Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
		pixels.fill(Color.WHITE)
	for y in range(TILE):
		for x in range(TILE):
			pixels.set_pixel(x,y,pixels.get_pixel(x,y)*col)
	img.blit_rect(pixels, Rect2i(0,0,TILE,TILE), Vector2i((slot%TILES_X)*TILE,(slot/TILES_X)*TILE))

static func _combine(root: Node3D) -> Dictionary:
	var atlas := Image.create(TILES_X*TILE,TILES_Y*TILE,false,Image.FORMAT_RGBA8)
	atlas.fill(Color(0,0,0,0))
	var slots: Dictionary = {}
	var positions := PackedVector3Array()
	var normals := PackedVector3Array()
	var texcoords := PackedVector2Array()
	var indices := PackedInt32Array()
	for visual in root.find_children("*","MeshInstance3D",true,false):
		if visual.name == "PaintedShadow": continue
		if visual.mesh == null: continue
		var transform_to_root: Transform3D = Transform3D.IDENTITY
		var cursor: Node3D = visual
		while cursor != root:
			transform_to_root = cursor.transform * transform_to_root
			cursor = cursor.get_parent() as Node3D
		var normal_basis: Basis = transform_to_root.basis.inverse().transposed()
		for s in range(visual.mesh.get_surface_count()):
			if visual.mesh.surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:continue
			var source: Material = visual.get_active_material(s)
			var key: String = str(source.get_instance_id()) if source != null else "empty"
			if not slots.has(key):
				var idx: int = slots.size()
				if idx >= TILES_X*TILES_Y:push_error("EXO AC atlas capacity exceeded");return {}
				slots[key] = idx
				_atlas_material(source, atlas, idx)
			var tile_id: int = slots[key]
			var tile_x: int = tile_id%TILES_X
			var tile_y: int = tile_id/TILES_X
			var arr: Array = visual.mesh.surface_get_arrays(s)
			var vv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var nn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL] if arr[Mesh.ARRAY_NORMAL] is PackedVector3Array else PackedVector3Array()
			var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] is PackedVector2Array else PackedVector2Array()
			var ii: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] is PackedInt32Array else PackedInt32Array()
			var base: int = positions.size()
			for i in range(vv.size()):
				positions.append(transform_to_root * vv[i])
				normals.append((normal_basis * nn[i]).normalized() if i < nn.size() else Vector3.UP)
				var u: Vector2 = uv[i] if i < uv.size() else Vector2(.5,.5)
				# Clamp mirrored/repeating source coordinates inside their atlas tile.
				# Half-texel margin prevents bleeding from adjacent tile.
				u = Vector2(clampf(u.x,0.008,0.992),clampf(u.y,0.008,0.992))
				texcoords.append(Vector2((tile_x+u.x)/float(TILES_X),(tile_y+u.y)/float(TILES_Y)))
			if ii.is_empty():
				for i in range(vv.size()):indices.append(base+i)
			else:
				for i in ii:indices.append(base+i)
	if positions.is_empty():return {}
	atlas.generate_mipmaps()
	var material := StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(atlas)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.roughness = .92
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = positions
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = texcoords
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	mesh.surface_set_material(0,material)
	return {"mesh":mesh,"material":material,"triangles":indices.size()/3,"materials_baked":slots.size()}

static func _lod_box(st: SurfaceTool,point: Vector3,size: Vector3,uv_center: Vector2) -> void:
	var cube := BoxMesh.new()
	cube.size = size
	var arrays: Array = cube.get_mesh_arrays()
	var vertex: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normal: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	for i in range(vertex.size()):
		st.set_normal(normal[i] if i<normal.size() else Vector3.UP)
		st.set_uv(uv_center)
		st.add_vertex(vertex[i]+point)

static func _distant(material: Material) -> Mesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_material(material)
	# Distant silhouette: base, wall body and recognizable roof.
	_lod_box(tool,Vector3(0,.12,0),Vector3(6,.24,4),Vector2(.19,.19))
	_lod_box(tool,Vector3(0,2.95,0),Vector3(5.8,5.5,3.9),Vector2(.31,.19))
	_lod_box(tool,Vector3(0,5.9,0),Vector3(6.6,1.15,4.8),Vector2(.55,.19))
	return tool.commit()

static func get_house() -> Dictionary:
	if cache.has("murim_blue/6/2"):return cache["murim_blue/6/2"]
	# Build original Forja ONCE then release its scene tree.
	var temporary_root := Node3D.new()
	var game_tree: SceneTree = Engine.get_main_loop() as SceneTree
	if game_tree != null:game_tree.root.add_child(temporary_root)
	var template: Node3D = Kit.build_house(temporary_root,"murim_blue",6,2,true)
	var result: Dictionary = _combine(template)
	if not result.is_empty():result["lod"] = _distant(result.material)
	temporary_root.free()
	if not result.is_empty():cache["murim_blue/6/2"] = result
	return result
