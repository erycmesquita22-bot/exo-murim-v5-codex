extends RefCounted
const Paving=preload("res://world/paving.gd")
const Shadow=preload("res://ground_shadow.gd")
const Landscape=preload("res://world/landscape.gd")
const Plan=preload("res://world/biome_plan.gd")

static func build(w: Node3D) -> void:
	if not w.journey.data.world.has("landscape_version"):w.journey.data.world.landscape_version=1
	var plan: Dictionary=Plan.create(w.journey.data.world)
	assert(Plan.safe_layout(plan))
	w.set_meta("landscape_plan",plan)
	w.set_meta("village_services",{})
	w.set_meta("village_level_design",{})
	if int(plan.get("version",1))>=2:
		Landscape.build(w,w.journey.data.world,plan)
		load("res://world/village_v2.gd").build(w,plan)
		build_ruins_and_arena(w)
		return
	Landscape.build(w,w.journey.data.world,plan)
	# Authored mission corridor and critical interaction points never move.
	w.block(Vector3(0,0.018,0),Vector3(5,0.036,80),Color("3b3b37"),false)
	w.block(Vector3(0,0.022,27),Vector3(20,0.045,18),Color("48453d"),false)
	w.block(Vector3(0,0.035,-29),Vector3(18,0.07,25),Color("3e5357"),false)
	# Courtyard buildings frame the square; doors face the open route.
	house(w,Vector3(-12,0,30),Vector3(7,3.4,6),"30363a",true)
	house(w,Vector3(12,0,31),Vector3(6,2.8,6),"3c3934",false)
	house(w,Vector3(-12,0,20),Vector3(5,2.7,5),"3e3e36",false)
	house(w,Vector3(13,0,20),Vector3(6,2.8,5),"42403a",false)
	# Birthplace profile varies neighborhoods and material prosperity, not quest coordinates.
	build_birthplace(w,plan)
	for garden in [Vector3(-7.8,0,35),Vector3(7.5,0,35),Vector3(-7.5,0,22.5)]:
		w.block(garden+Vector3(0,.045,0),Vector3(2.6,.08,2.4),Color("36493c"),false)
		for offset in [Vector3(-.65,0,-.4),Vector3(.25,0,.45)]:bamboo(w,garden+offset,2.1+offset.x*.3)
	w.add_sign(Vector3(-10,4.8,30),"GUILDA DOS AVENTUREIROS",Color("ecd197"))
	w.add_sign(Vector3(10,4.3,31),"POUSADA • ABRIGO",Color("e8d9b2"))
	w.add_sign(Vector3(10,4.1,20),"PÁTIO DE TREINO",Color("a5dacf"))
	# Contract board beside the guild representative.
	w.block(Vector3(-4.4,1.4,25.6),Vector3(1.6,1.5,0.2),Color("5c4634"),true)
	for x in [-4.95,-3.85]:
		w.block(Vector3(x,0.6,25.6),Vector3(0.14,1.2,0.16),Color("3e352e"),false)
	for x in [-4.8,-4.35,-3.95]:
		w.block(Vector3(x,1.55,25.47),Vector3(0.3,0.55,0.025),Color("dfd0a5"),false)
	preload("res://world/asset_library.gd").place(w,"well",Vector3(17,0,26),2.5)
	preload("res://world/asset_library.gd").place(w,"gong",Vector3(11,0,17),2.2)
	preload("res://world/asset_library.gd").place(w,"statue_monk",Vector3(-8,0,16.8),1.1)
	preload("res://world/asset_library.gd").place(w,"cart",Vector3(18,0,33),2.5)
	# Gate with layered roof and twin banners.
	Shadow.place(w,Vector3(.6,.098,16.1),Vector2(11,4),.25)
	for x in [-4,4]:
		w.block(Vector3(x,1.8,15),Vector3(0.55,3.6,0.65),Color("674a38"),true)
		w.block(Vector3(x,0.22,15),Vector3(0.95,0.44,1.05),Color("7b8073"),true)
		w.block(Vector3(x,2.65,15.4),Vector3(0.7,1.25,0.06),Color("295c60"),false)
		w.block(Vector3(x,2.7,15.44),Vector3(0.13,0.58,0.03),Color("d2b77d"),false)
	w.block(Vector3(0,3.6,15),Vector3(9.5,0.35,1),Color("634732"),false)
	roof(w,Vector3(0,3.85,15),10,2.5)
	w.add_sign(Vector3(0,4.8,15),str(plan.title).to_upper(),Color("e6d8af"))
	for pos in [Vector3(-6,0,28),Vector3(4.3,0,24.8),Vector3(-4,0,14),Vector3(4,0,14),Vector3(4,0,0),Vector3(-6,0,-7)]:
		lantern(w,pos)
	for x in [-2.8,2.8]:
		w.block(Vector3(x,.65,12),Vector3(.5,1.3,.5),Color("45605d"),false)
		w.block(Vector3(x,1.38,12),Vector3(.23,.15,.23),Color("69a8a7"),false)
	w.add_sign(Vector3(0,2.8,12),"LIMITE DA ALDEIA • ÁREA PROTEGIDA",Color("79b7ad"))
	# Sleeping mat is outside the inn, reachable without entering solid walls.
	w.block(Vector3(7.5,0.13,29),Vector3(1.4,0.26,2.2),Color("8b7455"),false)
	w.block(Vector3(7.5,0.29,29),Vector3(1.25,0.07,1.8),Color("3a6261"),false)
	w.block(Vector3(7.5,0.38,28.2),Vector3(1.15,0.15,0.4),Color("dbceaa"),false)
	w.add_sign(Vector3(7.5,2.1,29),"DESCANSO • E",Color("dfd1aa"))
	# Practice dummy and meditation platform.
	w.block(Vector3(6,.005,23),Vector3(3,.12,3),Color("9c8d70"),true)
	w.block(Vector3(6,.074,23),Vector3(1.5,.018,1.5),Color("497072"),false)
	w.block(Vector3(9.5,1,18),Vector3(0.45,2,0.45),Color("98744d"),true)
	w.block(Vector3(9.5,1.4,18),Vector3(1.5,0.22,0.3),Color("98744d"),false)
	# Stone paths with irregular paving, bamboo, pines and a quiet pond.
	var rng:=RandomNumberGenerator.new()
	rng.seed=preload("res://procedural/world_state.gd").stream(w.journey.data.world,"landscape/foliage_v1","village").next()
	for i in range(105):
		var x:=rng.randf_range(-22,22)
		var z:=rng.randf_range(-42,12)
		if absf(x)<7:
			continue
		var p:=Vector3(x,0,z)
		if i%3==0:
			bamboo(w,p,rng.randf_range(2,4))
		elif i%3==1:
			pine(w,p,rng.randf_range(0.8,1.3))
		else:
			var rock: MeshInstance3D=w.block(p+Vector3(0,0.28,0),Vector3(1,0.55,1.1),Color("6c7d6b"),false)
			rock.add_to_group("profile_detail")
			rock.set_meta("minimum_quality",1)
	for z in range(-39,39):
		for x in [-1,0,1]:
			Paving.place(w,Vector3(x*1.38+(sin(float(z)*1.3)*.09 if z>14 else 0),.055,z+.16*(abs(x)%2)),Vector2(1.26+(sin(float(z+x)*1.7)*.07 if z>14 else .04),.88),Color("736f60") if z>14 else Color("565c52"),int(w.journey.data.world.seed)+z*17+x)
	w.block(Vector3(-17,0.04,8),Vector3(10,0.07,9),Color("376d72"),false)
	for z in [4,12]:
		w.block(Vector3(-17,0.15,z),Vector3(10,0.3,0.4),Color("7b8170"),false)
	for x in [-22,-12]:
		w.block(Vector3(x,0.15,8),Vector3(0.4,0.3,8),Color("7b8170"),false)
	for x in [-19,-16,-13]:
		w.block(Vector3(x,0.085,8.3),Vector3(0.9,0.02,0.09),Color("6e9b93"),false)
	preload("res://world/village_composition.gd").build(w)
	build_ruins_and_arena(w)

static func build_birthplace(w: Node3D,plan: Dictionary) -> void:
	var style: String=str(plan.kind)
	var rng: RefCounted=preload("res://procedural/world_state.gd").stream(w.journey.data.world,"landscape/layout_v1","village/prosperity")
	for entry in plan.houses:
		var p:=Vector3(float(entry.x),0,float(entry.z))
		var s:=Vector3(float(entry.width),2.9 if style=="prospera" else 2.55,4.8)
		house(w,p,s,"514238",false,"village/home_%d"%int(entry.slot))
		# Plot identities are deliberate: fencing, crops and props stay off the traversable road.
		var outside: float=1.0 if p.x>0 else -1.0
		var garden:=p+Vector3(outside*3.5,0,0)
		if style!="empobrecida" and rng.below(3)>0:
			w.block(garden+Vector3(0,.055,0),Vector3(2,.11,2.7),Color("425e47"),false)
			bamboo(w,garden+Vector3(.4,0,.5),rng.between(2.1,3.3))
		if style=="prospera" and rng.below(2)==0:
			preload("res://world/asset_library.gd").place(w,"barrel_1",p+Vector3(outside*3,0,1.8),.6)
	for side in [-1,1]:
		var profile_color:=Color("69503c") if style=="empobrecida" else Color("cfaa67") if style=="prospera" else Color("789394") if style=="especial" else Color("75918a")
		w.block(Vector3(side*3.25,2.5,15.5),Vector3(.75,1.4,.12),profile_color,false)
	if style=="empobrecida":
		for i in range(9):
			var x: float=rng.between(-32.0,32.0)
			var z: float=rng.between(38.0,57.0)
			if absf(x)<5:continue
			var debris: MeshInstance3D=w.block(Vector3(x,.2,z),Vector3(rng.between(.3,.8),.4,rng.between(.3,.7)),Color("5f6258"),false)
			debris.rotation.y=rng.between(0,TAU)
	elif style=="prospera":
		for i in range(8):
			var x: float=(-1.0 if i%2==0 else 1.0)*rng.between(5.0,11.0)
			var z: float=rng.between(39.0,54.0)
			lantern(w,Vector3(x,0,z))
	elif style=="especial":
		for x in [-25,25]:
			w.block(Vector3(x,.52,54),Vector3(1.9,1.04,1.9),Color("667c78"),false)
			w.block(Vector3(x,1.18,54),Vector3(1.25,.22,1.25),Color("a2aa86"),false)
	# Common villages deliberately have fewer details; tier is not a power ranking.

static func roof(w: Node3D,p: Vector3,width: float,depth: float) -> void:
	for i in range(5):
		var b: MeshInstance3D=w.block(p+Vector3(0,i*0.2,0),Vector3(width-i*0.38,0.2,depth-i*0.5),Color("20252a") if i%2==0 else Color("2b3035"),false)
		if i==0:
			for side in [-1,1]:
				w.block(p+Vector3(0,0.17,side*(depth/2-0.15)),Vector3(width,0.18,0.35),Color("a18a5a"),false)
	w.block(p+Vector3(0,1.03,0),Vector3(width-1.4,0.2,0.28),Color("70817b"),false)

static func legacy_house(w: Node3D,p: Vector3,s: Vector3,color: String,guild: bool) -> void:
	Shadow.place(w,p+Vector3(1.1,.095,1.6),Vector2(s.x+3.8,s.z+5.2),.32)
	w.block(p+Vector3(0,0.2,0),Vector3(s.x+0.6,0.4,s.z+0.6),Color("858577"),true)
	w.block(p+Vector3(0,s.y*0.5+0.4,0),s,Color(color),true)
	for x in [-s.x/2,s.x/2]:
		for z in [-s.z/2,s.z/2]:
			w.block(p+Vector3(x,s.y*0.5+0.4,z),Vector3(0.2,s.y,0.2),Color("654a37"),false)
	for z in [-1.5,1.5]:
		w.block(p+Vector3(s.x/2+0.04,1.8,z),Vector3(0.06,1.2,1.25),Color("d2bf93"),false)
		for bar in [-0.4,0,0.4]:
			w.block(p+Vector3(s.x/2+0.08,1.8,z+bar),Vector3(0.07,1.25,0.055),Color("5c4736"),false)
	w.block(p+Vector3(0,1.4,s.z/2+0.04),Vector3(1.5,2.1,0.06),Color("342e2b"),false)
	w.block(p+Vector3(0,2.9,s.z/2+0.08),Vector3(2.3,0.5,0.08),Color("28595b") if guild else Color("51443b"),false)
	roof(w,p+Vector3(0,s.y+0.5,0),s.x+1.7,s.z+1.7)

static func lantern(w: Node3D,p: Vector3) -> void:
	w.block(p+Vector3(0,1.25,0),Vector3(0.16,2.5,0.16),Color("634c37"),false)
	w.block(p+Vector3(0,2.3,0),Vector3(0.53,0.65,0.53),Color("e6b47a"),false)
	for y in [1.95,2.65]:
		w.block(p+Vector3(0,y,0),Vector3(0.65,0.12,0.65),Color("3e4e4e"),false)
	var light:=OmniLight3D.new()
	w.add_child(light)
	light.position=p+Vector3(0,2.3,0)
	light.light_color=Color("ffd5a2")
	light.light_energy=0.7
	light.omni_range=5
	light.add_to_group("profile_lights")
	light.set_meta("minimum_quality",1)

static func bamboo(w: Node3D,p: Vector3,height: float) -> void:
	if p.z>14:
		preload("res://world/village_composition.gd").bamboo(w,p,height);return
	Shadow.place(w,p+Vector3(.25,.091,.4),Vector2(1.8,1.6),.16)
	for offset in [Vector3.ZERO,Vector3(0.4,0,0.3)]:
		var stem: MeshInstance3D=w.block(p+offset+Vector3(0,height/2,0),Vector3(0.14,height,0.14),Color("6b8658"),offset==Vector3.ZERO)
		stem.add_to_group("profile_detail")
		stem.set_meta("minimum_quality",0)
		for y in [height*0.45,height*0.8]:
			w.block(p+offset+Vector3(0,y,0),Vector3(0.22,0.09,0.22),Color("a8ad72"),false)
		var leaf: MeshInstance3D=w.block(p+offset+Vector3(0,height*0.86,0),Vector3(1.5,0.12,0.5),Color("47745b"),false)
		leaf.rotation.y=height
		leaf.add_to_group("profile_detail")
		leaf.set_meta("minimum_quality",1)

static func pine(w: Node3D,p: Vector3,scale_value: float) -> void:
	Shadow.place(w,p+Vector3(.55,.09,.6),Vector2(3.6,3.2)*scale_value,.23)
	w.block(p+Vector3(0,1.1,0)*scale_value,Vector3(0.45,2.2,0.45)*scale_value,Color("68513d"),true)
	for i in range(3):
		w.block(p+Vector3(0,2.4+i*0.65,0)*scale_value,Vector3(3-i*0.65,0.9,3-i*0.65)*scale_value,Color("31574c").lightened(i*0.04),false)

static func house(w: Node3D,p: Vector3,s: Vector3,_color: String,guild: bool,persistent_id: String="") -> void:
	var library=preload("res://world/asset_library.gd")
	var id: String="building_2" if guild else "building_1" if s.x>=6 else "shop"
	# Source models were inspected from all four sides: every entrance faces local +Z.
	var yaw:=PI*.5 if p.x<0 else -PI*.5
	var node: Node3D=library.place(w,id,p,s.x+1.2,yaw)
	var bounds: AABB=node.get_meta("bounds")
	var forward:=Vector3(sin(yaw),0,cos(yaw))
	node.set_meta("entrance_direction",forward)
	node.set_meta("persistent_id",persistent_id if not persistent_id.is_empty() else "village/guild" if guild else "village/inn" if p.z>25 else "village/market" if p.x<0 else "village/training")
	# Fit the enclosed exterior body below the roof overhang, in model-local coordinates.
	var core:=Vector3(bounds.size.x*.71,2.8,bounds.size.z*.64)
	var body:=StaticBody3D.new();node.add_child(body);body.collision_layer=1;body.position.y=1.4
	var shape:=BoxShape3D.new();shape.size=core
	var collision:=CollisionShape3D.new();collision.shape=shape;body.add_child(collision)
	var shadow_size:=Vector2(bounds.size.z+.6,bounds.size.x+.7)
	Shadow.place(w,p+Vector3(.3,.095,.35),shadow_size,.22)
	var door:=p+forward*(bounds.size.z*.5+.35)
	node.set_meta("entrance_position",door)
	# Branches join each entrance to the existing central route, keeping quest positions intact.
	if int(w.get_meta("landscape_plan",{}).get("version",1))==1:
		var x: float=door.x
		var limit: float=5.7 if not persistent_id.is_empty() else 50.0
		var covered: float=0.0
		while absf(x)>2.0 and covered<limit:
			Paving.place(w,Vector3(x,.055,p.z),Vector2(1.30,1.65),Color("736f60"),int(p.z*29+x*7))
			x+=1.4 if x<0 else -1.4
			covered+=1.4
	for side in [-1,1]:
		var prop_point:=node.to_global(Vector3(side*bounds.size.x*.34,0,bounds.size.z*.51))
		library.place(w,"barrel_1" if side<0 else "pot_1",prop_point,.65 if side<0 else .48,yaw)
		library.place(w,"garden_bush_1",node.to_global(Vector3(side*bounds.size.x*.48,0,bounds.size.z*.36)),.85,yaw)


static func build_ruins_and_arena(w: Node3D) -> void:
	# Ruins retain the EXO palette and approved boss arena.
	for z in [-17,-27,-37]:
		for x in [-6,6]:
			Shadow.place(w,Vector3(x+.6,.099,z+.8),Vector2(3.3,3.6),.25)
			w.block(Vector3(x,0.25,z),Vector3(1.6,0.5,1.6),Color("7d8989"),true)
			w.block(Vector3(x,1.8,z),Vector3(0.9,3.2,0.9),Color("7b8d8f"),true)
			w.block(Vector3(x,3.55,z),Vector3(1.6,0.3,1.6),Color("b5aa86"),false)
			w.block(Vector3(x,1.7,z+0.5),Vector3(0.18,1.4,0.05),Color("79c6c8"),false)
	w.block(Vector3(0,3.9,-17),Vector3(13,0.5,1.2),Color("7f9590"),true)
	w.block(Vector3(0,0.5,-35),Vector3(2,1,2),Color("6b8078"),true)
	w.block(Vector3(0,1.06,-35),Vector3(2.3,0.16,2.3),Color("cfbc83"),false)
	w.add_sign(Vector3(0,5,-17),"RUÍNAS DO PANTEÃO",Color("a5dbd4"))
	w.add_sign(Vector3(-6,2.4,-15),"ÚLTIMO MARCO DA PATRULHA",Color("d6caa1"))
	# Separate prologue arena: the future world is not visible from here.
	w.block(Vector3(90,-0.4,0),Vector3(38,0.8,38),Color("393e45"),true)
	for x in [71,109]:
		w.block(Vector3(x,1.2,0),Vector3(0.6,2.4,38),Color("293943"),true)
	for z in [-19,19]:
		w.block(Vector3(90,1.2,z),Vector3(38,2.4,0.6),Color("293943"),true)
	for x in range(75,108,4):
		for z in range(-16,18,4):
			w.block(Vector3(x,0.035,z),Vector3(3.8,0.05,3.8),Color("464b50"),false)
	for x in [77,103]:
		for z in [-14,14]:
			w.block(Vector3(x,3.1,z),Vector3(1.3,6.2,1.3),Color("7d8582"),true)
			w.block(Vector3(x,6.3,z),Vector3(2.6,0.3,2.6),Color("baa879"),false)

