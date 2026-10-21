extends RefCounted
# Optional environmental meshes: instance lightweight grass; solid rocks have physics.
# All placements arrive with the ground y sampled from the existing collider mesh.
const Ground=preload("res://world/terrain_assets.gd")
static var tuft_mesh: ArrayMesh
static var tuft_material: StandardMaterial3D

static func _ensure_tufts() -> void:
	if tuft_mesh!=null:return
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for angle in [0.0,PI*.5]:
		var along:=Vector3(cos(angle),0,sin(angle))
		var side:=along*.20
		for poly in [[-side,Vector3(0,.31,0),side],[side,Vector3(0,.21,0),-side]]:
			for vertex in poly:
				st.set_color(Color("739464"))
				st.set_normal(Vector3.UP)
				st.add_vertex(vertex)
	tuft_mesh=st.commit()
	tuft_material=StandardMaterial3D.new()
	tuft_material.vertex_color_use_as_albedo=true
	tuft_material.cull_mode=BaseMaterial3D.CULL_DISABLED
	tuft_material.roughness=1.0
	tuft_material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	tuft_mesh.surface_set_material(0,tuft_material)

static func populate(w: Node3D,world_data: Dictionary,plan: Dictionary,noise: FastNoiseLite,surface_sample: Callable) -> void:
	_ensure_tufts()
	var WorldSeed=preload("res://procedural/world_state.gd")
	var rng: RefCounted=WorldSeed.stream(world_data,"terrain/foliage_v1","visible_tufts")
	var positions: Array[Vector3]=[]
	for i in range(550):
		var x: float=rng.between(-99.0,99.0)
		var z: float=rng.between(-114.0,98.0)
		# No foliage in the prologue arena or the village main circulation corridor.
		if x>68.0 and absf(z)<26.0:continue
		if absf(x)<8.0 and z>9.0 and z<72.0:continue
		# Forest and grassland have higher tuft density than exposed highlands/ruins.
		if x< -36.0 and i%3!=0:continue
		if z< -48.0 and i%4!=0:continue
		var p:=Vector3(x,float(surface_sample.call(x,z,noise))+.025,z)
		positions.append(p)
	if not positions.is_empty():
		var batch:=MultiMesh.new()
		batch.transform_format=MultiMesh.TRANSFORM_3D
		batch.use_colors=true
		batch.mesh=tuft_mesh
		batch.instance_count=positions.size()
		for i in range(positions.size()):
			var yaw: float=float(i)*2.399963
			var scale_value: float=.7+float(i%7)*.085
			var basis:=Basis().rotated(Vector3.UP,yaw).scaled(Vector3(scale_value,scale_value,scale_value))
			batch.set_instance_transform(i,Transform3D(basis,positions[i]))
			batch.set_instance_color(i,Color("b5c5a4") if i%5==0 else Color.WHITE)
		var node:=MultiMeshInstance3D.new()
		node.name="TerrainGrassTufts_LowCost"
		node.multimesh=batch
		w.add_child(node)
	# Larger outcrops are gameplay obstacles, unlike small decorative grass.
	var stone_rng: RefCounted=WorldSeed.stream(world_data,"terrain/rocks_v1","physical_boulders")
	for i in range(28):
		var x: float=stone_rng.between(-94.0,94.0)
		var z: float=stone_rng.between(-110.0,96.0)
		if (x>67.0 and absf(z)<28.0) or (absf(x)<45.0 and z>11.0 and z<75.0):continue
		if (x< -25.0 and absf(z-10.0)<8.0) or (x>25.0 and absf(z-62.0)<8.0):continue
		var diameter: float=stone_rng.between(.85,1.75)
		var height_value: float=stone_rng.between(.55,1.10)
		var y: float=float(surface_sample.call(x,z,noise))
		var size:=Vector3(diameter,height_value,diameter*.87)
		var boulder: MeshInstance3D=Ground.textured_block(w,Vector3(x,y+height_value*.42,z),size,"moss_stone" if i%4==0 else "stone",true)
		boulder.rotation.y=stone_rng.between(-.45,.45)
		boulder.name="TerrainBoulder_Collidable"
