extends RefCounted
# A connected terrain mesh: village valley, bamboo forest east, highlands west, northern ruins.
# No square boundary walls; all heights near existing mission targets remain exactly zero.
const WorldSeed=preload("res://procedural/world_state.gd")
const Paving=preload("res://world/paving.gd")
const Shadow=preload("res://ground_shadow.gd")
const Ground=preload("res://world/terrain_assets.gd")
const MIN_X=-104
const MAX_X=104
const MIN_Z=-120
const MAX_Z=104
const STEP=4
static func noise_for(w: Dictionary) -> FastNoiseLite:
	var n:=FastNoiseLite.new()
	n.seed=WorldSeed.stream(w,"landscape/height_v1","terrain").next()
	n.noise_type=FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency=.023
	n.fractal_type=FastNoiseLite.FRACTAL_FBM
	n.fractal_octaves=3
	return n
static func height_at(x: float,z: float,n: FastNoiseLite) -> float:
	# Safe plateau contains the guild, inn, training, patrol and boss arena.
	# The existing prologue battle has its own floor at x=90 and cannot collide with terrain.
	if x>=69 and absf(z)<=22:return -1.2
	if absf(x)<=9 and z>=-49 and z<=67:return 0.0
	var village: float=maxf(0,absf(x)-39)
	if z>=12 and z<=65:village=maxf(village,maxf(0,z-65)*.9)
	else:village=maxf(village,12-z if z<12 else z-65)
	var activity: float=clampf(village/14,0,1)
	# Flat, connected trails across the forest, hills and beyond the northern altar.
	var trail_distance: float=999
	if x>25:trail_distance=absf(z-10)
	if x< -25:trail_distance=absf(z-10)
	if z< -40:trail_distance=minf(trail_distance,absf(x))
	activity*=clampf((trail_distance-4)/11,0,1)
	var mountains: float=2.8 if x< -30 else 1.3 if z< -45 else 1.0
	return maxf(-.32,(.8+n.get_noise_2d(x,z)*2.1)*activity*mountains)
# Biome materials are selected using deterministic terrain noise, not global RNG.
# This classification is independent of loot generation and saves.
static func ground_kind(x: float,z: float,n: FastNoiseLite,plan: Dictionary) -> String:
	var height: float=height_at(x,z,n)
	var variation: float=n.get_noise_2d(x+731.0,z-517.0)
	var spots: float=n.get_noise_2d(x-271.0,z+383.0)
	# The west is rocky highland. The village stays walkable, with grass and earth.
	if x< -36.0:
		if height>3.8 or variation>.16:return "stone"
		if spots<-.24:return "gravel"
		return "grass_dry" if variation>.0 else "moss_stone"
	if z< -49.0:
		if variation>.08:return "moss_stone"
		return "stone" if spots<-.1 else "gravel"
	if x>33.0:
		if variation>.06:return "forest_soil"
		if spots<-.25:return "moss_stone"
		return "grass_lush"
	# Village and lowland: avoid a featureless monochromatic floor.
	if z>12.0 and z<75.0 and absf(x)<43.0:
		if variation>.27:return "earth"
		if spots<-.18:return "grass_dry" if str(plan.get("kind",""))=="empobrecida" else "grass_lush"
		return "grass_lush"
	if variation>.25:return "earth"
	if spots<-.28:return "grass_dry"
	return "grass_lush"

static func build(w: Node3D,world_data: Dictionary,plan: Dictionary) -> void:
	var noise: FastNoiseLite=noise_for(world_data)
	var buckets: Dictionary={}
	for kind in Ground.TYPES:buckets[kind]=[]
	for x in range(MIN_X,MAX_X,STEP):
		for z in range(MIN_Z,MAX_Z,STEP):
			var a:=Vector3(x,height_at(float(x),float(z),noise),z)
			var b:=Vector3(x+STEP,height_at(float(x+STEP),float(z),noise),z)
			var c:=Vector3(x+STEP,height_at(float(x+STEP),float(z+STEP),noise),z+STEP)
			var d:=Vector3(x,height_at(float(x),float(z+STEP),noise),z+STEP)
			var surface: String=ground_kind(float(x)+STEP*.5,float(z)+STEP*.5,noise,plan)
			var vertices: Array=buckets[surface]
			for v in [a,d,b,b,d,c]:vertices.append(v)
	var mesh:=ArrayMesh.new()
	for kind in Ground.TYPES:
		var vertices: Array=buckets[kind]
		if vertices.is_empty():continue
		var st:=SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for v in vertices:
			# Stable world-space UV; adjoining triangles match exactly across chunks.
			st.set_uv(Vector2(v.x/2.75,v.z/2.75))
			st.add_vertex(v)
		st.generate_normals()
		var surface_index: int=mesh.get_surface_count()
		st.commit(mesh)
		mesh.surface_set_material(surface_index,Ground.material(str(kind)))
	var terrain:=MeshInstance3D.new()
	terrain.name="PersistentTerrain09_4"
	terrain.mesh=mesh
	w.add_child(terrain)
	var body:=StaticBody3D.new()
	body.name="TerrainCollider09_4"
	body.collision_layer=1
	w.add_child(body)
	var collision:=CollisionShape3D.new()
	var terrain_shape: ConcavePolygonShape3D=mesh.create_trimesh_shape()
	terrain_shape.backface_collision=true
	collision.shape=terrain_shape
	body.add_child(collision)
	# Keep physics identical to the approved 09.4.4 base: no decorative collider
	# is allowed to raise the feet or trap the player at the village entry.
	var safe_floor:=StaticBody3D.new()
	safe_floor.name="VillageSolidFloor09_4_4"
	safe_floor.collision_layer=1
	safe_floor.collision_mask=0
	w.add_child(safe_floor)
	var safe_box:=CollisionShape3D.new()
	var floor_shape:=BoxShape3D.new()
	floor_shape.size=Vector3(76.0,0.36,53.0)
	safe_box.shape=floor_shape
	safe_floor.add_child(safe_box)
	safe_floor.position=Vector3(0,-0.20,38.5)
	build_routes(w,world_data,plan)
	build_biomes(w,world_data,plan,noise)
	var sample_surface: Callable=func(x: float,z: float,n: FastNoiseLite) -> float:
		return surface_height(x,z,n)
	preload("res://world/terrain_props.gd").populate(w,world_data,plan,noise,sample_surface)

# The mesh and collision share the SAME sampled path surface, unlike the old floating
# stepping stones. This also supplies consistent walkability on uneven outer hills.
static func surface_height(x: float,z: float,n: FastNoiseLite) -> float:
	var x0: float=float(MIN_X)+floorf((x-float(MIN_X))/float(STEP))*float(STEP)
	var z0: float=float(MIN_Z)+floorf((z-float(MIN_Z))/float(STEP))*float(STEP)
	var u: float=clampf((x-x0)/float(STEP),0.0,1.0)
	var v: float=clampf((z-z0)/float(STEP),0.0,1.0)
	var a: float=height_at(x0,z0,n)
	var b: float=height_at(x0+float(STEP),z0,n)
	var c: float=height_at(x0+float(STEP),z0+float(STEP),n)
	var d: float=height_at(x0,z0+float(STEP),n)
	if u+v<=1.0:return a*(1.0-u-v)+b*u+d*v
	return c*(u+v-1.0)+b*(1.0-v)+d*(1.0-u)

static func build_routes(w: Node3D,world_data: Dictionary,plan: Dictionary) -> void:
	var noise: FastNoiseLite=noise_for(world_data)
	var routes: Array=[
		[Vector2(0,66),Vector2(25,63),Vector2(48,63),Vector2(78,62)],
		[Vector2(0,10),Vector2(-25,10),Vector2(-50,10),Vector2(-72,12)],
		[Vector2(0,12),Vector2(0,-40),Vector2(0,-70),Vector2(0,-95)]
	]
	var palettes: Array=[Color("6f7761"),Color("837a68"),Color("737d74")]
	for index in range(routes.size()):
		var points: Array=routes[index]
		var tint: Color=palettes[index]
		var st:=SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for segment in range(points.size()-1):
			var first: Vector2=points[segment]
			var last: Vector2=points[segment+1]
			var distance: float=first.distance_to(last)
			var parts: int=maxi(1,int(ceilf(distance/1.45)))
			var heading: Vector2=(last-first).normalized()
			var outward: Vector2=Vector2(-heading.y,heading.x)
			for i in range(parts):
				var p0: Vector2=first.lerp(last,float(i)/float(parts))
				var p1: Vector2=first.lerp(last,float(i+1)/float(parts))
				var width: float=2.0
				var verts: Array[Vector3]=[]
				for q in [p0-outward*width,p0+outward*width,p1-outward*width,p1+outward*width]:
					verts.append(Vector3(q.x,surface_height(q.x,q.y,noise)+.13,q.y))
				var local_tint: Color=tint.lightened(.025*sin(float(i+segment*7)*1.3))
				for corner in [0,1,2,1,3,2]:
					st.set_uv(Vector2(verts[corner].x/2.75,verts[corner].z/2.75))
					st.add_vertex(verts[corner])
		st.generate_normals()
		var mesh: ArrayMesh=st.commit()
		var render:=MeshInstance3D.new()
		render.name="GroundedTrail_%d"%index
		render.mesh=mesh
		render.material_override=Ground.material("trail" if index!=1 else "gravel")
		w.add_child(render)
		var collision_body:=StaticBody3D.new()
		collision_body.name="TrailWalkable_%d"%index
		collision_body.collision_layer=1
		w.add_child(collision_body)
		var collision:=CollisionShape3D.new()
		var shape: ConcavePolygonShape3D=mesh.create_trimesh_shape()
		shape.backface_collision=true
		collision.shape=shape
		collision_body.add_child(collision)
	# Legacy corridor receives no new decorative overlays around critical patrol points.
	if int(plan.get("version",1))==1:
		for z in [18,24,30,36,42,48,54,60,64]:
			Paving.place(w,Vector3(0,.065,z),Vector2(3.5,2.15),Color("776c59"),z*13)
static func build_biomes(w: Node3D,world_data: Dictionary,plan: Dictionary,n: FastNoiseLite) -> void:
	var rng: RefCounted=WorldSeed.stream(world_data,"landscape/objects_v1","forest")
	for i in range(75):
		var x: float=rng.between(33,95)
		var z: float=rng.between(20,93)+float(plan.forest_offset)*.25
		if (x>69 and z<26) or absf(z-62)<7 or (x<42 and z<62):continue
		var p:=Vector3(x,height_at(x,z,n),z)
		if i%5==0:pine(w,p,rng.between(.7,1.0))
		else:bamboo(w,p,rng.between(2.6,4.7))
	var hills: RefCounted=WorldSeed.stream(world_data,"landscape/objects_v1","highlands")
	for i in range(65):
		var x: float=hills.between(-95,-36)
		var z: float=hills.between(-82,74)+float(plan.highland_offset)*.25
		if absf(z-10)<8 or (x> -43 and z>16 and z<62):continue
		var p:=Vector3(x,height_at(x,z,n),z)
		if i%3==0:
			var rock: MeshInstance3D=w.block(p+Vector3(0,.36,0),Vector3(hills.between(.6,2),.72,hills.between(.6,2)),Color("66736c"),false)
			rock.rotation.y=hills.between(0,TAU)
		else:pine(w,p,hills.between(.65,1.3))
	var ruins: RefCounted=WorldSeed.stream(world_data,"landscape/objects_v1","north_ruins")
	for i in range(34):
		var x: float=ruins.between(-36,36)
		var z: float=ruins.between(-113,-54)+float(plan.ruins_offset)*.2
		if absf(x)<6:continue
		var p:=Vector3(x,height_at(x,z,n),z)
		var body: MeshInstance3D=w.block(p+Vector3(0,ruins.between(.4,1.2),0),Vector3(ruins.between(.5,1.4),ruins.between(.8,2.4),ruins.between(.5,1.3)),Color("647975"),false)
		body.rotation.y=ruins.between(0,TAU)
	# Three landmarks with recognizable shapes and accessible clearings.
	for mark in [{"name":"BOSQUE DE BAMBU","at":Vector3(78,0,62),"color":Color("5a886e")},{"name":"PASSAGEM DAS MONTANHAS","at":Vector3(-72,0,12),"color":Color("847a65")},{"name":"RUÍNAS DISTANTES","at":Vector3(0,0,-95),"color":Color("69908e")}]:
		var at: Vector3=mark.at
		at.y=height_at(at.x,at.z,n)
		for side in [-1,1]:w.block(at+Vector3(side*2,1.0,0),Vector3(.35,2,.35),mark.color,false)
		w.block(at+Vector3(0,2.05,0),Vector3(4.3,.3,.4),mark.color,false)
		w.add_sign(at+Vector3(0,3.0,0),mark.name,Color("d1d8ba"))
		w.block(at+Vector3(0,.035,0),Vector3(4,.07,3),Color("5b6557"),false)
		w.register_exploration_site("forest" if at.x>0 else "mountain" if at.x<0 else "ruins",at)
	# Authored, seed-stable silhouettes: groves, outcroppings and ruined stonework.
	# Keep the 4 m arrival corridors clear; these are scenery, never barriers.
	build_scenic_biome_details(w,world_data,n)

static func build_scenic_biome_details(w: Node3D,world_data: Dictionary,n: FastNoiseLite) -> void:
	var deco: RefCounted=WorldSeed.stream(world_data,"landscape/art_v1","outer_landmarks")
	# Bamboo destination: a small clearing marked by shade, herb beds and wind stones.
	for i in range(14):
		var angle: float=TAU*float(i)/14.0
		var radius: float=deco.between(7.5,12.0)
		var x: float=78.0+cos(angle)*radius
		var z: float=62.0+sin(angle)*radius
		if absf(z-62.0)<3.0:continue
		bamboo(w,Vector3(x,surface_height(x,z,n),z),deco.between(2.8,4.4))
	for shift in [-1,1]:
		var fx: float=78.0+float(shift)*5.5
		var fz: float=70.0
		var fy: float=surface_height(fx,fz,n)
		w.block(Vector3(fx,fy+.045,fz),Vector3(3.0,.09,3.0),Color("4e5844"),false)
		for k in range(3):
			w.block(Vector3(fx-.85+float(k)*.82,fy+.19,fz),Vector3(.4,.27,2.2),Color("577958"),false)
	# Western pass: rocks on either side of the track, no road obstruction.
	for side in [-1,1]:
		for layer in range(4):
			var x: float=-72.0+float(layer-2)*4.2
			var z: float=12.0+float(side)*(5.8+float(layer%2)*1.7)
			var y: float=surface_height(x,z,n)
			w.block(Vector3(x,y+.40,z),Vector3(2.3,.80,2.1),Color("737969").lightened(float(layer)*.025),false)
			w.block(Vector3(x,y+1.1,z),Vector3(1.1,.65,1.25),Color("899080"),false)
	# Northern ruins: recognizable fragments flank the actual walkable approach.
	for side in [-1,1]:
		var px: float=float(side)*8.0
		for i in range(3):
			var z: float=-89.0-float(i)*6.0
			var ground: float=surface_height(px,z,n)
			var h: float=1.8+float((i+1)%3)*.65
			w.block(Vector3(px,ground+.22,z),Vector3(1.8,.44,1.8),Color("68746d"),false)
			w.block(Vector3(px,ground+.42+h*.5,z),Vector3(.9,h,.9),Color("819085"),false)
			w.block(Vector3(px,ground+.42+h+.12,z),Vector3(1.4,.24,1.4),Color("afa882"),false)

static func bamboo(w: Node3D,p: Vector3,height: float) -> void:
	# Same square voxel material language as the base game, no region dependency cycle.
	Shadow.place(w,p+Vector3(.25,.08,.3),Vector2(1.8,1.5),.15)
	for branch in range(2):
		var offset:=Vector3(branch*.29,0,branch*.26)
		var stem: MeshInstance3D=w.block(p+offset+Vector3(0,height*.5,0),Vector3(.12,height,.12),Color("668259"),branch==0)
		stem.add_to_group("profile_detail");stem.set_meta("minimum_quality",0)
		for y in [height*.48,height*.79]:
			w.block(p+offset+Vector3(0,y,0),Vector3(.2,.08,.2),Color("9ba773"),false)
		var leaves: MeshInstance3D=w.block(p+offset+Vector3(0,height*.86,0),Vector3(1.5,.11,.46),Color("416d55"),false)
		leaves.rotation.y=float(branch)*1.2
		leaves.add_to_group("profile_detail");leaves.set_meta("minimum_quality",1)

static func pine(w: Node3D,p: Vector3,size: float) -> void:
	Shadow.place(w,p+Vector3(.45,.09,.45),Vector2(3,3)*size,.2)
	w.block(p+Vector3(0,1.1*size,0),Vector3(.42,2.2,.42)*size,Color("64513f"),true)
	for i in range(3):
		var node: MeshInstance3D=w.block(p+Vector3(0,(2.0+i*.65)*size,0),Vector3(3.0-i*.7,.8,3.0-i*.7)*size,Color("304e40").lightened(i*.06),false)
		node.add_to_group("profile_detail");node.set_meta("minimum_quality",0)
