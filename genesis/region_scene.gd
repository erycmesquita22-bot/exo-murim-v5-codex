extends Node3D
const Data=preload("res://genesis/region_data.gd")
var data: RefCounted
var gate_nodes: Array=[]
var pilot: Array=[]
var build_ms := 0.0
var triangles := 0
var meshes := 0
var asset_count := 0
var flat_collision_chunks := 0
var props: Array=[]
static var asset_cache: Dictionary={}
const COL="res://collection/"
const APPROVED_GROUND="res://textures/terrain_approved/"
const EXO_TERRAIN_R1=preload("res://genesis/terrain_dressing_r1.gd")
const EXO_TERRAIN_FORGE=preload("res://exo_terrain_forge/worldgen/terrain_texture_adapter.gd")
# Regional v6: civic riverbeds remain open; road bridge decks preserve route elevations.
func build(d: RefCounted,allowed: Array) -> void:
	var started := Time.get_ticks_usec();data=d;pilot=allowed
	name="Region_%02d"%int(d.spec.id)
	build_ground()
	build_rivers()
	build_river_road_decks()
	build_lots()
	build_plants()
	if data.worldgen_v4:preload("res://genesis/v4/landmarks.gd").build(self)
	build_plaza()
	build_gates()
	build_bounds()
	build_ms=(Time.get_ticks_usec()-started)/1000.0
func build_ground() -> void:
	# 32m chunks: 1m collision/render surface at roads and pads, 4m distant terrain.
	# Height is sampled once per chunk; mesh and physics share the exact same triangles.
	var texture: Texture2D=terrain_texture(data.spec.biome)
	var shader := Shader.new();shader.code=FileAccess.get_file_as_string("res://genesis/terrain.gdshader")
	var mat := ShaderMaterial.new();mat.shader=shader;mat.set_shader_parameter("ground_tex",texture);mat.set_shader_parameter("road_tex",load(APPROVED_GROUND+"trilha_terra.png"))
	mat.set_shader_parameter("macro_seed",float(int(data.noise.seed)%8191))
	EXO_TERRAIN_FORGE.apply_to_ground(mat,data)
	for i in range(4):
		var other: String=data.spec.biome
		if i<data.gates.size():
			var palette: Dictionary=data.gates[i].palette
			other=palette.b if palette.a==data.spec.biome else palette.a
		mat.set_shader_parameter("blend%d"%i,terrain_texture(other))
	for z in range(-256,256,32):
		for x in range(-256,256,32):
			var center := Vector2(x+16,z+16)
			var step := 1 if data.road_distance(center)<38 or data.pad_distance(center)<34 or center.length()<60 else 4
			var st := SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);st.set_custom_format(0,SurfaceTool.CUSTOM_RGBA_FLOAT)
			var faces := PackedVector3Array()
			var vertices: Dictionary={};var colors: Dictionary={};var blends: Dictionary={}
			var lowest:=INF;var highest:=-INF
			for zz in range(z,z+33,step):
				for xx in range(x,x+33,step):
					var p := Vector2(xx,zz)
					vertices[p]=Vector3(xx,stitched_height(p),zz)
					lowest=minf(lowest,vertices[p].y);highest=maxf(highest,vertices[p].y)
					var c: Color=data.color_at(p);c.a=1-smoothstep(3,6,data.road_distance(p));colors[p]=c;blends[p]=data.boundary_weights(p)
			for zz in range(z,z+32,step):
				for xx in range(x,x+32,step):
					var coords := [Vector2(xx,zz),Vector2(xx+step,zz),Vector2(xx,zz+step),Vector2(xx+step,zz+step)]
					for tri in [[0,1,2],[1,3,2]]:
						for k in tri:
							var p: Vector2=coords[k]
							st.set_color(colors[p]);st.set_uv(p/6.0);st.set_custom(0,blends[p])
							st.add_vertex(vertices[p]);faces.append(vertices[p])
					triangles+=2
			st.generate_normals();st.index()
			var mesh := MeshInstance3D.new();mesh.mesh=st.commit();mesh.material_override=mat
			mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mesh.add_to_group("exo_visual_terrain")
			add_child(mesh);meshes+=1
			var body := StaticBody3D.new();body.collision_layer=1
			var collision := CollisionShape3D.new()
			# A flat chunk has exactly the same top surface as a solid box. Keep
			# the rendered vertices and all non-flat/river collision triangles intact.
			if lowest==highest:
				var flat:=BoxShape3D.new();flat.size=Vector3(32,.4,32)
				collision.shape=flat;collision.position=Vector3(x+16,lowest-.2,z+16)
				flat_collision_chunks+=1
			else:
				var shape := ConcavePolygonShape3D.new();shape.set_faces(faces);shape.backface_collision=true
				collision.shape=shape
			body.add_child(collision);add_child(body)
func terrain_texture(biome: String) -> Texture2D:
	# Approved atlas tiles after periodic edge correction; original tiles remain intact.
	var files := {"grassland":"grama_prado","temperate_forest":"solo_floresta","bamboo_forest":"solo_bambuzal","dry_valley":"grama_seca","wetland":"grama_umida","rocky_highlands":"rocha_cinza","alpine":"grama_montanha","mixed_woodland":"grama_folhas_largas"}
	return load(APPROVED_GROUND+files[biome]+".png")
func chunk_step(center: Vector2) -> int:
	return 1 if data.road_distance(center)<38 or data.pad_distance(center)<34 or center.length()<60 else 4
func stitched_height(p: Vector2) -> float:
	# Fine/coarse edges share interpolation endpoints; no T-junction height cracks.
	if int(p.x)%32==0:
		var zcenter := floorf(p.y/32)*32+16
		if chunk_step(Vector2(p.x-16,zcenter))==4 or chunk_step(Vector2(p.x+16,zcenter))==4:
			var z0 := floorf(p.y/4)*4
			return lerpf(data.terrain_height_at(Vector2(p.x,z0)),data.terrain_height_at(Vector2(p.x,z0+4)),(p.y-z0)/4)
	if int(p.y)%32==0:
		var xcenter := floorf(p.x/32)*32+16
		if chunk_step(Vector2(xcenter,p.y-16))==4 or chunk_step(Vector2(xcenter,p.y+16))==4:
			var x0 := floorf(p.x/4)*4
			return lerpf(data.terrain_height_at(Vector2(x0,p.y)),data.terrain_height_at(Vector2(x0+4,p.y)),(p.x-x0)/4)
	return data.terrain_height_at(p)
func asset(path: String,pos: Vector3,yaw: float=0,scale_value: float=1,solid: bool=true) -> Node3D:
	if not asset_cache.has(path):
		var original: Node3D=load(COL+path).instantiate()
		var st := SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
		append_asset(st,original,Transform3D.IDENTITY)
		st.generate_normals();st.index()
		var mesh := st.commit()
		asset_cache[path]={"mesh":mesh,"shape":mesh.create_trimesh_shape()}
		original.free()
	var node := Node3D.new();add_child(node);node.position=pos;node.rotation.y=yaw;node.scale=Vector3.ONE*scale_value
	if not path.begins_with("10_ARQUITETURA_GLB/") and not path.ends_with("entrada_caverna_rochosa.glb"):
		node.position.y-=asset_cache[path].mesh.get_aabb().position.y*scale_value
	var visual := MeshInstance3D.new();visual.mesh=asset_cache[path].mesh
	var material := StandardMaterial3D.new();material.vertex_color_use_as_albedo=true;material.roughness=.9
	visual.material_override=material;visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;visual.add_to_group("exo_visual_architecture");node.add_child(visual)
	if solid:
		var body := StaticBody3D.new();body.collision_layer=4
		var shape := CollisionShape3D.new();shape.shape=asset_cache[path].shape;body.add_child(shape);node.add_child(body)
	asset_count+=1
	return node
func append_asset(st: SurfaceTool,node: Node3D,parent_transform: Transform3D) -> void:
	var local_transform := parent_transform*node.transform
	if node is MeshInstance3D:
		for surface in range(node.mesh.get_surface_count()):st.append_from(node.mesh,surface,local_transform)
	for child in node.get_children():
		if child is Node3D:append_asset(st,child,local_transform)
func box(pos: Vector3,size: Vector3,color: Color,solid: bool=true) -> Node3D:
	var node := MeshInstance3D.new();var mesh := BoxMesh.new();mesh.size=size;node.mesh=mesh
	var mat := StandardMaterial3D.new();mat.albedo_color=color;mat.roughness=.9;node.material_override=mat
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(node);node.position=pos
	if solid:
		var body := StaticBody3D.new();body.collision_layer=4;var shape := CollisionShape3D.new();var b := BoxShape3D.new();b.size=size;shape.shape=b
		body.add_child(shape);node.add_child(body)
	return node
func build_river_road_decks() -> void:
	if data.spec.kind!="settlement" or data.rivers.is_empty():return
	var roads: Array=[]
	for g in data.gates:roads.append({"a":Vector2.ZERO,"b":g.p,"width":float(g.width)})
	for r in data.settlement_roads:roads.append(r)
	var used: Dictionary={}
	for road in roads:
		var delta: Vector2=road.b-road.a
		var count: int=maxi(1,int(ceil(delta.length()/1.5)))
		for i in range(count):
			var point: Vector2=road.a+delta*(float(i)+.5)/count
			if data.river_distance(point)>17.0:continue
			var key:=Vector2i(roundi(point.x),roundi(point.y))
			if used.has(key):continue
			used[key]=true
			var deck: Node3D=box(Vector3(point.x,data.height_at(point)-.22,point.y),Vector3(delta.length()/count+.08,.44,float(road.width)+1.0),Color("8d8877"))
			deck.name="EXORiverRoadDeck"
			deck.get_child(0).collision_layer=1
			deck.rotation.y=-atan2(delta.y,delta.x)
func build_rivers() -> void:
	for river in data.rivers:
		var st := SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var direction: Vector2=(river.p-data.river_hub).normalized()
		var perpendicular:Vector2 = Vector2(-direction.y,direction.x)*data.river_half_width(river)
		var length: float=river.p.distance_to(data.river_hub)
		var segments := int(ceil(length/2))
		for k in range(segments):
			var a: Vector2=data.river_hub.lerp(river.p,float(k)/segments)
			var b: Vector2=data.river_hub.lerp(river.p,float(k+1)/segments)
			# Culverts under engineered roads: water geometry continues below the road fill.
			for p in [a-perpendicular,a+perpendicular,b-perpendicular,a+perpendicular,b+perpendicular,b-perpendicular]:
				st.set_normal(Vector3.UP);st.set_uv(p/4);st.add_vertex(Vector3(p.x,data.river_level(river,p),p.y))
		var mesh := MeshInstance3D.new();mesh.mesh=st.commit()
		var mat := ShaderMaterial.new()
		mat.shader=preload("res://exo_visual/shaders/water.gdshader")
		mat.set_shader_parameter("flow_direction",direction)
		mesh.material_override=mat
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh.add_to_group("exo_visual_water")
		add_child(mesh)
func build_lots() -> void:
	for lot_index in range(data.lots.size()):
		var lot: Dictionary=data.lots[lot_index]
		var p := Vector3(lot.p.x,lot.height,lot.p.y)
		# Structural modules share one rotated root. Ground-level entrance +Z faces plaza.
		var root := Node3D.new();add_child(root);root.position=p;root.rotation.y=lot.yaw
		if lot.has("id"):
			root.name=str(lot.id);root.set_meta("building_id",lot.id);root.set_meta("function",lot.function);root.set_meta("district",lot.district);root.set_meta("form",lot.form)
		var parts: Array=[]
		if data.spec.kind=="settlement":
			parts.append(asset("10_ARQUITETURA_GLB/fundacao_pedra.glb",Vector3(0,-.81,0)))
			parts.append(asset("10_ARQUITETURA_GLB/painel_porta_livre.glb",Vector3(0,-.44,2)))
			parts.append(asset("10_ARQUITETURA_GLB/parede_reboco_claro.glb",Vector3(0,-.44,-2)))
			parts.append(asset("10_ARQUITETURA_GLB/parede_reboco_claro.glb",Vector3(-2,-.44,0),PI/2))
			parts.append(asset("10_ARQUITETURA_GLB/parede_reboco_claro.glb",Vector3(2,-.44,0),PI/2))
			parts.append(asset("10_ARQUITETURA_GLB/telhado_teal_4m.glb",Vector3(0,1.73,0)))
		elif data.spec.kind=="ruins":
			parts.append(asset("11_RUINAS_GLB/arco_portal_musgo.glb",Vector3.ZERO))
			parts.append(asset("11_RUINAS_GLB/coluna_ruina_musgo.glb",Vector3(-4,0,1)))
			parts.append(asset("11_RUINAS_GLB/altar_ruina_antigo.glb",Vector3(3,0,-3)))
		elif data.spec.kind=="dungeon_approach":
			# Exterior entry metadata is authored by the SAME regional WorldGen lot.
			# Only these physical entrances may request an instanced Dungeon.
			root.set_meta("exo_dungeon_location_id","cave_r%02d_l%02d" % [int(data.spec.id),lot_index])
			var cave := asset("09_TOPOGRAFIA_GLB/entrada_caverna_rochosa.glb",Vector3(0,-.3,0))
			cave.scale=Vector3(1.6,1.25,1)
			parts.append(cave)
			parts.append(asset("06_OBJETOS_GLB/masmorras/tocha_coluna.glb",Vector3(-4,0,3)))
			# Short traversable inspection chamber behind the cave mouth, inside this exterior's lot.
			# Open roof keeps the isometric avatar visible; this is not a separate procedural dungeon.
			for z in [-3.0,-6.3]:
				parts.append(asset("06_OBJETOS_GLB/masmorras/parede_masmorra.glb",Vector3(-1.65,0,z),PI/2))
				parts.append(asset("06_OBJETOS_GLB/masmorras/parede_masmorra.glb",Vector3(1.65,0,z),PI/2))
			parts.append(asset("06_OBJETOS_GLB/masmorras/parede_masmorra.glb",Vector3(0,0,-8.16)))
			parts.append(asset("06_OBJETOS_GLB/masmorras/bau_madeira.glb",Vector3(.95,0,-6.8),0,.5))
		else:
			parts.append(asset("09_TOPOGRAFIA_GLB/rocha_monolito_musgo.glb",Vector3.ZERO))
		for part in parts:
			var transform_value: Transform3D=part.transform
			part.reparent(root,false);part.transform=transform_value
		preload("res://ground_shadow.gd").place(self,p+Vector3(0,.025,0),Vector2(8,8),.32)
		if data.spec.kind=="settlement":root.set_meta("roof",parts[-1])
		props.append(root)
func build_plants() -> void:
	var tree: String="12_NATUREZA_GLB/arvore_baixa_prado.glb"
	if data.spec.biome=="bamboo_forest":tree="12_NATUREZA_GLB/bambu_alto_folhas.glb"
	elif data.spec.biome=="temperate_forest":tree="12_NATUREZA_GLB/arvore_alta_sombria.glb"
	elif data.spec.biome in ["alpine","rocky_highlands"]:tree="12_NATUREZA_GLB/pinheiro_escarpado.glb"
	for p in data.plants:
		# Vegetation roots below the surface avoid visible hovering. Thin trunk collider only.
		var pos := Vector3(p.p.x,p.height-.08,p.p.y)
		asset(tree,pos,p.yaw,p.scale,false)
		var trunk := StaticBody3D.new();trunk.collision_layer=4;var shape := CollisionShape3D.new();var cylinder := CylinderShape3D.new()
		cylinder.radius=.22*p.scale;cylinder.height=2*p.scale;shape.shape=cylinder;trunk.add_child(shape);add_child(trunk);trunk.position=pos+Vector3(0,p.scale,0)
	build_roadside_grass()
	# WorldGen R1: deterministic isometric foliage and grouped rocks.
	EXO_TERRAIN_R1.build(self,data)
	EXO_TERRAIN_FORGE.dress(self,data)

func build_roadside_grass() -> void:
	# Three-level roadside gradient: bare road -> short sparse shoots -> small tufts.
	# Entirely visual; the geometry, pads, roads, houses and collision remain unchanged.
	if data.spec.biome in ["rocky_highlands", "alpine"]:return
	var rng := RandomNumberGenerator.new()
	rng.seed=int(data.noise.seed)+int(data.spec.id)*1031+7301
	var samples: Array=[]
	# No early break: collect the *whole* region before taking a bounded sample.
	for z in range(-240,241,6):
		for x in range(-240,241,6):
			var p := Vector2(float(x)+rng.randf_range(-2.8,2.8),float(z)+rng.randf_range(-2.8,2.8))
			var d: float=data.road_distance(p)
			if d<4.1 or d>19.0:continue
			if data.pad_distance(p)<7.5 or data.river_distance(p)<8.0:continue
			# Discrete clusters, not a carpet: presence increases away from the road.
			var presence: float=0.12 if d<7.0 else 0.28 if d<11.0 else 0.40
			if rng.randf()>presence:continue
			var h: float=data.terrain_height_at(p)
			if maxf(absf(data.terrain_height_at(p+Vector2(0.4,0))-h),absf(data.terrain_height_at(p+Vector2(0,0.4))-h))>0.25:continue
			var size_factor: float=rng.randf_range(0.52,0.78) if d<7.0 else rng.randf_range(0.72,1.10)
			samples.append({"rank":rng.randi(),"transform":Transform3D(Basis(Vector3.UP,rng.randf_range(0.0,TAU)).scaled(Vector3.ONE*size_factor),Vector3(p.x,h-.025,p.y)),"variation":rng.randf()})
	if samples.is_empty():return
	# Deterministic even distribution independent of scan order; capped for performance.
	samples.sort_custom(func(a,b):return int(a.rank)<int(b.rank))
	var count: int=mini(samples.size(),520)
	var st := SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Five narrow blades; height remains below the character's ankle/knee.
	for k in range(5):
		var a: float=float(k)*TAU/5.0
		var lateral := Vector3(cos(a),0.0,sin(a))
		var r: float=0.055+float(k%2)*0.018
		st.set_color(Color("465d29"));st.add_vertex(-lateral*r)
		st.set_color(Color("8ca955"));st.add_vertex(Vector3(lateral.x*0.055,0.23+float(k%3)*0.035,lateral.z*0.055))
		st.set_color(Color("536e33"));st.add_vertex(lateral*r)
	st.generate_normals()
	var grass_mesh := st.commit()
	var material := ShaderMaterial.new()
	material.shader=preload("res://exo_visual/shaders/grass_wind.gdshader")
	grass_mesh.surface_set_material(0,material)
	var multi := MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D
	multi.use_colors=true;multi.mesh=grass_mesh;multi.instance_count=count
	for i in range(count):
		var specimen: Dictionary=samples[i]
		multi.set_instance_transform(i,specimen.transform)
		var tint: float=lerpf(0.87,1.08,float(specimen.variation))
		multi.set_instance_color(i,Color(tint,tint,0.90+float(specimen.variation)*0.10))
	var group := MultiMeshInstance3D.new();group.name="RoadsideGrassVisual"
	group.multimesh=multi;group.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	group.add_to_group("exo_visual_grass")
	add_child(group)
func build_plaza() -> void:
	if data.spec.kind!="settlement":return
	# Fixtures are functional data from the settlement plan, not arbitrary decorations.
	if data.settlement_plan.get("status", "invalid")!="ready":return
	for fixture in data.settlement_plan.get("fixtures", []):
		var point: Vector2=fixture.p
		var file := "06_OBJETOS_GLB/objetos/poco.glb" if fixture.kind=="well" else "06_OBJETOS_GLB/objetos/poste_lanterna.glb"
		var pos := Vector3(point.x,data.height_at(point),point.y)
		asset(file,pos,0,1,true)
		if fixture.kind!="well":
			var warm:=OmniLight3D.new()
			warm.light_color=Color("ffd193")
			warm.light_energy=0.45
			warm.omni_range=6.0
			warm.shadow_enabled=false
			warm.position=pos+Vector3(0,2.4,0)
			warm.add_to_group("profile_lights")
			add_child(warm)
		preload("res://ground_shadow.gd").place(self,pos+Vector3(0,.025,0),Vector2(2,2),.25)
func build_gates() -> void:
	for g in data.gates:
		var handoff:Vector2=data.handoff_point(g)
		var inward: Vector2=-g.p.normalized();var point: Vector2=handoff+inward*1.5
		var pos := Vector3(point.x,data.height_at(point) if data.worldgen_v4 else g.height,point.y)
		var open: bool=g.neighbor in pilot
		var portal := asset("11_RUINAS_GLB/arco_portal_antigo.glb",pos,atan2(inward.x,inward.y),1.4,true)
		var label := Label3D.new();label.text=("REGIÃO %02d • E"%g.neighbor) if open else ("REGIÃO %02d • FORA DO PILOTO"%g.neighbor)
		label.font_size=40;label.pixel_size=.014;label.position=pos+Vector3(0,5,0);label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;add_child(label)
		if not open:box(pos+Vector3(0,1.3,0),Vector3(5,2.6,1) if absf(inward.y)>.7 else Vector3(1,2.6,5),Color("383f45"))
		gate_nodes.append({"contract":g,"point":pos,"open":open,"node":portal})
func build_bounds() -> void:
	# Keep a sealed perimeter. Transit occurs by E on a grounded arrival pad inside the border.
	for side in range(4):
		for t in range(-256,256,16):
			var p := Vector2(t+8,-256 if side==0 else 256) if side<2 else Vector2(-256 if side==2 else 256,t+8)
			box(Vector3(p.x,data.height_at(p)+2,p.y),Vector3(16,4,1) if side<2 else Vector3(1,4,16),Color("41494a"))
