extends RefCounted
# Presentation-only village level design: no quest positions, save writes or physical blockers.
# Streets, courtyards and town identity derive exclusively from the existing layout plan.
const WorldSeed=preload("res://procedural/world_state.gd")
const Paving=preload("res://world/paving.gd")
const Layout=preload("res://world/village_layout_v2.gd")
const Assets=preload("res://world/asset_library.gd")
const Ground=preload("res://world/terrain_assets.gd")

static func road_axis(z: float,pattern: String) -> float:
	var t: float=clampf((z-15.0)/41.0,0.0,1.0)
	if pattern=="rua_alta":return 3.2*sin(t*PI)
	if pattern=="patios":return -3.0*sin(t*PI)
	if pattern=="encruzilhada":return 2.2*sin((z-15.0)*.106)
	return 0.0

static func base_color(kind: String) -> Color:
	if kind=="empobrecida":return Color("6a6558")
	if kind=="prospera":return Color("8c7b65")
	if kind=="especial":return Color("6d7870")
	return Color("7a725f")

static func ground(w: Node3D,plan: Dictionary) -> void:
	var kind: String=str(plan.kind)
	var pattern: String=str(plan.pattern)
	var road_tint: Color=base_color(kind)
	w.set_meta("village_level_design",{"revision":1,"pattern":pattern,"birthplace":kind})
	# Continuous compacted-earth surface below the pavers: no detached stepping stones.
	for i in range(50):
		var z: float=14.0+float(i)*1.02
		var center: float=road_axis(z,pattern)
		Ground.textured_block(w,Vector3(center,.012,z),Vector3(5.15,.024,1.16),"trail")
		for lane in [-1,0,1]:
			if i%7==0 and lane==0:continue
			Paving.place(w,Vector3(center+float(lane)*1.37,.047,z),Vector2(1.25,.95),road_tint,int(z*59.0+lane*37.0))
	# Courtyard underlays are at ground level; no elevated slabs or floor colliders.
	var commons_z: float=39.0 if pattern=="cruzamento" else 48.0 if pattern=="encruzilhada" else 29.0 if pattern=="patios" else 54.0
	Ground.textured_block(w,Vector3(0,.011,commons_z),Vector3(12.1,.022,8.2),"gravel")
	for x in range(-5,6):
		for zi in range(-3,4):
			if (abs(x)+abs(zi))%9==0:continue
			Paving.place(w,Vector3(float(x)*1.03,.048,commons_z+float(zi)*1.10),Vector2(.99,1.05),road_tint.lightened(.02),x*197+zi*41+int(commons_z))
	# Branch to every house, service and interaction. Paths use the actual frontage.
	var cells: Array=plan.houses.duplicate(true)
	for role in ["guild","inn","training"]:
		cells.append(plan.sites[role])
	for cell in cells:
		var z: float=float(cell.z)
		var x: float=float(cell.x)
		var frontage: float=x+(4.9 if x<0.0 else -4.9)
		var origin: float=road_axis(z,pattern)
		var extent: float=absf(frontage-origin)
		var steps: int=maxi(2,int(ceilf(extent/1.12)))
		for i in range(steps+1):
			var t: float=float(i)/float(steps)
			var px: float=lerpf(origin,frontage,t)
			Ground.textured_block(w,Vector3(px,.018,z),Vector3(extent/float(steps)+.17,.027,2.55),"trail")
			if i%4!=0:
				Paving.place(w,Vector3(px,.052,z),Vector2(extent/float(steps)+.07,1.16),road_tint,int(px*129.0+z*47.0))
	# Per-building lot surrounds anchor the structure to terrain; decorative only.
	for cell in cells:
		var pos:=Vector3(float(cell.x),.013,float(cell.z))
		Ground.textured_block(w,pos,Vector3(float(cell.width)+3.6,.026,8.1),"grass_dry" if kind=="empobrecida" else "grass_lush")
		for side in [-1,1]:
			var outline_x: float=pos.x+float(side)*(float(cell.width)*.5+1.35)
			w.block(Vector3(outline_x,.032,pos.z),Vector3(.14,.055,6.9),Color("8b8068"),false)
	# A few planted soil patches break up the empty green floor without introducing collisions.
	var rng: RefCounted=WorldSeed.stream(w.journey.data.world,"landscape/art_v1","village/soil")
	for i in range(45):
		var x: float=rng.between(-39.0,39.0)
		var z: float=rng.between(17.0,67.0)
		if absf(x-road_axis(z,pattern))<6.7:continue
		var occupied: bool=false
		for cell in cells:
			if absf(x-float(cell.x))<float(cell.width)*.5+2.2 and absf(z-float(cell.z))<5.1:
				occupied=true
				break
		if occupied:continue
		var patch_size:=Vector3(rng.between(.6,1.6),.018,rng.between(.7,1.7))
		var patch: MeshInstance3D=Ground.textured_block(w,Vector3(x,.011,z),patch_size,"forest_soil")
		patch.rotation.y=rng.between(-.5,.5)

static func decorate(w: Node3D,plan: Dictionary) -> void:
	var kind: String=str(plan.kind)
	var terrain=preload("res://world/landscape.gd")
	var noise: FastNoiseLite=terrain.noise_for(w.journey.data.world)
	var used: Dictionary={}
	for role in ["guild","inn","training"]:
		used[int(plan.sites[role].slot)]=true
	for cell in plan.houses:used[int(cell.slot)]=true
	# Vacant lots get coherent uses: gardens, yards or small marketplaces.
	var vacant: Array=[]
	for slot in range(16):
		if not used.has(slot):vacant.append(slot)
	for slot in vacant:
		if slot%3==0 and kind=="empobrecida":continue
		var cx: float=Layout.COLUMNS[slot%4]
		var cz: float=Layout.ROWS[int(slot/4)]
		if absf(cx)<18.0:
			vegetable_patch(w,Vector3(cx,0,cz),kind,slot)
		elif slot%2==0:
			quiet_grove(w,Vector3(cx,0,cz),slot)
		else:
			market_yard(w,Vector3(cx,0,cz),kind,slot)
	# Role-specific landmarks are set behind the service frontage, not atop interactions.
	var guild: Dictionary=plan.sites.guild
	var inn: Dictionary=plan.sites.inn
	var training: Dictionary=plan.sites.training
	var direction_guild: float=1.0 if float(guild.x)>0.0 else -1.0
	var direction_inn: float=1.0 if float(inn.x)>0.0 else -1.0
	var direction_training: float=1.0 if float(training.x)>0.0 else -1.0
	banner(w,Vector3(float(guild.x)+direction_guild*4.0,0,float(guild.z)-2.1),Color("ae6555"))
	banner(w,Vector3(float(inn.x)+direction_inn*4.0,0,float(inn.z)-2.0),Color("a8ad81"))
	# Training yard: visually framed but mat and approach remain completely clear.
	for dz in [-3.1,3.1]:
		w.block(Vector3(float(training.x)+direction_training*5.3,.035,float(training.z)+dz),Vector3(2.2,.07,.18),Color("968b70"),false)
	# A small foreground well/civic ornament remains out of the central road.
	var civic_z: float=17.1
	Assets.place(w,"well",Vector3(-8.5,terrain.surface_height(-8.5,civic_z,noise),civic_z),2.15)
	Assets.place(w,"cart",Vector3(9.4,terrain.surface_height(9.4,civic_z+1.5,noise),civic_z+1.5),2.1)
	# Side gardens and boundaries give the settlement a readable silhouette.
	for side in [-1,1]:
		for k in range(7):
			var z: float=18.5+float(k)*8.0
			var px: float=float(side)*40.0
			var elevation: float=terrain.surface_height(px,z,noise)
			if k%3==0:
				preload("res://world/village_composition.gd").bamboo(w,Vector3(px,elevation,z),2.9)
			else:
				w.block(Vector3(px,elevation+.35,z),Vector3(.24,.7,1.8),Color("806c4d"),false)
	# Village profile is reflected in architecture, not just house count.
	if kind=="empobrecida":
		for k in range(7):
			var px: float=(-35.0 if k%2==0 else 35.0)
			var pz: float=19.0+float(k)*7.2
			w.block(Vector3(px,terrain.surface_height(px,pz,noise)+.15,pz),Vector3(1.2,.3,1.0),Color("655e51"),false)
	elif kind=="prospera":
		for k in range(6):
			var pz: float=21.0+float(k)*7.9
			lantern_simple(w,Vector3(-6.8,0,pz))
			lantern_simple(w,Vector3(6.8,0,pz))
	elif kind=="especial":
		for px in [-10.0,10.0]:
			w.block(Vector3(px,.45,75.5),Vector3(1.5,.9,1.5),Color("546b6a"),false)
			w.block(Vector3(px,1.07,75.5),Vector3(1.7,.2,1.7),Color("b4a87f"),false)

static func vegetable_patch(w: Node3D,p: Vector3,kind: String,slot: int) -> void:
	Ground.textured_block(w,p+Vector3(0,.025,0),Vector3(6.0,.05,6.5),"earth")
	for k in range(4):
		var x: float=p.x-2.15+float(k)*1.4
		Ground.textured_block(w,Vector3(x,.060,p.z),Vector3(.62,.045,5.8),"earth")
		for n in range(6):
			var z: float=p.z-2.3+float(n)*.91
			var tint: Color=Color("6d8654") if (k+n+slot)%3==0 else Color("496f50")
			w.block(Vector3(x,.21,z),Vector3(.3,.30,.28),tint,false)
	if kind=="prospera":
		w.block(p+Vector3(0,.095,-3.25),Vector3(6.0,.19,.18),Color("ad9873"),false)

static func quiet_grove(w: Node3D,p: Vector3,slot: int) -> void:
	Ground.textured_block(w,p+Vector3(0,.025,0),Vector3(6.3,.05,6.3),"forest_soil")
	for offset in [Vector3(-1.8,0,-1.5),Vector3(1.8,0,1.5)]:
		preload("res://world/village_composition.gd").bamboo(w,p+offset,2.6+float(slot%3)*.3)
	w.block(p+Vector3(0,.19,0),Vector3(2.0,.38,.55),Color("827259"),false)

static func market_yard(w: Node3D,p: Vector3,kind: String,slot: int) -> void:
	Ground.textured_block(w,p+Vector3(0,.025,0),Vector3(6.4,.05,6.4),"gravel")
	for i in [-1,1]:
		w.block(p+Vector3(float(i)*2.0,1.25,-1.1),Vector3(.18,2.5,.18),Color("674d39"),false)
	w.block(p+Vector3(0,2.58,-1.1),Vector3(5.0,.27,2.6),Color("9c5146") if kind=="prospera" else Color("777b63"),false)
	Assets.place(w,"barrel_1",p+Vector3(-2.25,0,1.7),.72)
	Assets.place(w,"pot_1",p+Vector3(2.1,0,1.8),.6)

static func banner(w: Node3D,p: Vector3,tint: Color) -> void:
	w.block(p+Vector3(0,1.6,0),Vector3(.17,3.2,.17),Color("705239"),false)
	w.block(p+Vector3(.3,2.30,0),Vector3(.65,1.2,.065),tint,false)
	w.block(p+Vector3(.3,2.95,0),Vector3(.78,.10,.12),Color("a69872"),false)

static func lantern_simple(w: Node3D,p: Vector3) -> void:
	w.block(p+Vector3(0,1.3,0),Vector3(.16,2.6,.16),Color("775741"),false)
	w.block(p+Vector3(0,2.4,0),Vector3(.55,.68,.55),Color("d3a775"),false)
	for dy in [-.36,.36]:w.block(p+Vector3(0,2.4+dy,0),Vector3(.68,.13,.68),Color("50605a"),false)
