extends RefCounted
const PALETTES = {
	"ivory_charcoal":{"wood":"ffffff","plaster":"fff4df","roof":"c6c9c8","stone":"ffffff"},
	"ochre_terracotta":{"wood":"c7a58a","plaster":"dfbd82","roof":"d9916d","stone":"ddd4c6"},
	"gray_jade":{"wood":"d2a38c","plaster":"e5e7dd","roof":"7eaf9e","stone":"d6dedb"},
	"clay_slate":{"wood":"99928a","plaster":"d5b89b","roof":"b2b4bc","stone":"e1ddd5"},
	"cream_blue":{"wood":"bcbdb8","plaster":"fff0c3","roof":"88a6bf","stone":"dedfe2"}}
static var catalog: Dictionary = {}
static var cached: Dictionary = {}

static func ensure() -> void:
	if not catalog.is_empty(): return
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://catalog.json"))
	for item in doc.assets: catalog[item.id] = item

static func material_variant(source: Material, palette: String) -> Material:
	if source == null or palette.is_empty(): return source
	var role := source.resource_name
	var key := palette+"/"+role
	if cached.has(key): return cached[key]
	var mat := source.duplicate() as StandardMaterial3D
	if mat == null: return source
	if PALETTES[palette].has(role): mat.albedo_color = Color(PALETTES[palette][role])
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	cached[key] = mat
	return mat

static func place(parent: Node3D, id: String, position: Vector3, yaw: float = 0, palette: String = "", collision: bool = true) -> Node3D:
	ensure()
	assert(catalog.has(id),"Unknown asset "+id)
	var item: Dictionary = catalog[id]
	var node := (load("res://"+item.file) as PackedScene).instantiate() as Node3D
	node.name = id
	parent.add_child(node)
	node.position = position
	node.rotation.y = yaw
	for mesh in node.find_children("*","MeshInstance3D",true,false):
		if not palette.is_empty():
			for surface in range(mesh.mesh.get_surface_count()):
				mesh.set_surface_override_material(surface,material_variant(mesh.get_active_material(surface),palette))
		for surface in range(mesh.mesh.get_surface_count()):
			var active: Material = mesh.get_active_material(surface)
			if active is StandardMaterial3D: active.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		if collision and item.collision in ["triangle_static","box_leaf","box_static"]: mesh.create_trimesh_collision()
		elif collision and item.collision in ["trunk_only","stems_only"]:
			var mat: Material = mesh.get_active_material(0)
			if mat != null and mat.resource_name in ["bark","green"]: mesh.create_trimesh_collision()
	if collision and item.collision == "ramp_stairs":
		var body := StaticBody3D.new()
		node.add_child(body)
		var shape := CollisionShape3D.new()
		var ramp := ConvexPolygonShape3D.new()
		ramp.points = PackedVector3Array([Vector3(-1,0,0),Vector3(1,0,0),Vector3(-1,.4,0),Vector3(1,.4,0),Vector3(-1,0,.9),Vector3(1,0,.9)])
		shape.shape = ramp
		body.add_child(shape)
	if id.begins_with("tree_") or id.begins_with("bamboo_"): painted_shadow(node,Vector2(2.4,2.4))
	node.set_meta("asset_id",id)
	node.set_meta("palette",palette)
	return node

static func build_house(parent: Node3D, palette: String = "ivory_charcoal", width: int = 6, stories: int = 2) -> Node3D:
	assert(width in [4,6,8] and stories in [1,2],"Only roof-compatible validated templates are allowed")
	var root := Node3D.new()
	root.name = "House_"+palette
	parent.add_child(root)
	var xs: Array = []
	for i in range(width/2): xs.append(-width*.5+1+i*2)
	for x in xs:
		for z in [-1,1]:
			place(root,"foundation_2x2",Vector3(x,0,z),0,palette)
			if stories==2: place(root,"floor_wood_2x2",Vector3(x,3.0,z),0,palette)
	for floor_index in range(stories):
		var y := .4+floor_index*2.6
		for i in range(xs.size()):
			var doorway := floor_index==0 and i==xs.size()/2
			place(root,"wall_door_2m" if doorway else "wall_window_2m",Vector3(xs[i],y,2),0,palette)
			if doorway:
				var door := place(root,"door_double",Vector3(xs[i],y,2.01),0,palette,true)
				door.set_script(preload("res://godot/door.gd"))
				door.call_deferred("setup")
				root.set_meta("door_x",float(xs[i]))
			place(root,"wall_solid_2m",Vector3(xs[i],y,-2),PI,palette)
		for side in [-1,1]:
			for z in [-1,1]: place(root,"wall_window_2m",Vector3(side*width*.5,y,z),side*PI/2,palette)
	if stories==2: place(root,"balcony_2m",Vector3(width*.5,3,0),PI/2,palette)
	var top := .4+stories*2.6
	for x in xs:
		place(root,"roof_slope_2x2",Vector3(x,top,0),0,palette,false)
		place(root,"roof_slope_2x2",Vector3(x,top,0),PI,palette,false)
		place(root,"roof_eave_2m",Vector3(x,top,2),0,palette,false)
		place(root,"roof_eave_2m",Vector3(x,top,-2),PI,palette,false)
		place(root,"roof_ridge_2m",Vector3(x,top+1,0),0,palette,false)
	for side in [-1,1]:
		place(root,"roof_gable_4m",Vector3(side*width*.5,top,0),0,palette)
		for z in [-2.35,2.35]: place(root,"roof_end_ornament",Vector3(side*width*.5,top-.1,z),0 if side>0 else PI,palette,false)
		place(root,"roof_end_ornament",Vector3(side*width*.5,top+1.15,0),0 if side>0 else PI,palette,false)
	var door_x: float = root.get_meta("door_x",0.0)
	place(root,"stairs_2m",Vector3(door_x,0,2),0,palette)
	for x in [door_x-.85,door_x+.85]: place(root,"lantern_01",Vector3(x,2.15,2.2),0,palette,false)
	painted_shadow(root,Vector2(width+1,5))
	root.set_meta("width",width)
	root.set_meta("stories",stories)
	root.set_meta("palette",palette)
	root.set_meta("footprint",Vector2(width,4))
	return root

static func build_seeded_house(parent: Node3D, seed_value: int) -> Node3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var widths := [4,6,8]
	var colors: Array = PALETTES.keys()
	return build_house(parent,colors[rng.randi_range(0,4)],widths[rng.randi_range(0,2)],rng.randi_range(1,2))

static func painted_shadow(parent: Node3D, size: Vector2) -> void:
	var shadow := MeshInstance3D.new()
	shadow.name = "PaintedShadow"
	shadow.mesh = PlaneMesh.new()
	shadow.mesh.size = size
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://godot/ground_shadow.gdshader")
	shadow.material_override = mat
	parent.add_child(shadow)
	shadow.position.y = .007
