extends RefCounted
## EXO Character Refit 01. Procedural, original Murim voxel garments.
## One colour-vertex mesh per animated joint; meshes replace previous visuals rather
## than being added atop retained character costumes.
const PALETTES = ["293747","355987","296454","963f49","ddd9cb","6e4c83"]
const HAIR = ["211f24","48332a","9b5235","c5a160","dedbd3","304c70"]
static var SHARED_MATERIAL: StandardMaterial3D

static func _material() -> StandardMaterial3D:
	if SHARED_MATERIAL == null:
		SHARED_MATERIAL = StandardMaterial3D.new()
		SHARED_MATERIAL.vertex_color_use_as_albedo = true
		SHARED_MATERIAL.roughness = 0.88
		SHARED_MATERIAL.cull_mode = BaseMaterial3D.CULL_DISABLED
	return SHARED_MATERIAL

static func _box(st: SurfaceTool, at: Vector3, dims: Vector3, tint: Color) -> void:
	var h: Vector3 = dims * 0.5
	var v: Array[Vector3] = [
		Vector3(-h.x,-h.y,-h.z),Vector3(h.x,-h.y,-h.z),Vector3(h.x,h.y,-h.z),Vector3(-h.x,h.y,-h.z),
		Vector3(-h.x,-h.y,h.z),Vector3(h.x,-h.y,h.z),Vector3(h.x,h.y,h.z),Vector3(-h.x,h.y,h.z)]
	var faces: Array = [[0,1,2,3],[5,4,7,6],[1,5,6,2],[4,0,3,7],[3,2,6,7],[4,5,1,0]]
	for f in faces:
		var normal: Vector3 = (v[f[1]]-v[f[0]]).cross(v[f[2]]-v[f[0]]).normalized()
		for i in [0,1,2,0,2,3]:
			st.set_color(tint)
			st.set_normal(normal)
			st.add_vertex(at+v[f[i]])

static func _trapezoid(st: SurfaceTool, at: Vector3, top: Vector2, bottom: Vector2, height: float, tint: Color) -> void:
	var v: Array[Vector3] = []
	for layer in range(2):
		var side: Vector2 = top if layer==0 else bottom
		var y: float = height*0.5 if layer==0 else -height*0.5
		for c in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
			v.append(at+Vector3(c.x*side.x*.5,y,c.y*side.y*.5))
	for f in [[0,1,5,4],[1,2,6,5],[2,3,7,6],[3,0,4,7],[3,2,1,0],[4,5,6,7]]:
		var normal: Vector3 = (v[f[1]]-v[f[0]]).cross(v[f[2]]-v[f[0]]).normalized()
		for i in [0,1,2,0,2,3]:
			st.set_color(tint)
			st.set_normal(normal)
			st.add_vertex(v[f[i]])

static func _add_mesh(parent: Node3D, name_value: String, shapes: Array, owned: Array[Node]) -> void:
	if shapes.is_empty():return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for shape in shapes:
		if shape[0]=="box":_box(st,shape[1],shape[2],shape[3])
		else:_trapezoid(st,shape[1],shape[2],shape[3],shape[4],shape[5])
	var part:=MeshInstance3D.new()
	part.name=name_value
	part.mesh=st.commit()
	part.material_override=_material()
	parent.add_child(part)
	owned.append(part)

static func _b(boxes: Array, pos: Vector3, size: Vector3, tint: Color) -> void:
	boxes.append(["box",pos,size,tint])

static func _t(boxes: Array,pos:Vector3,top:Vector2,bottom:Vector2,height:float,tint:Color)->void:
	boxes.append(["taper",pos,top,bottom,height,tint])

static func apply(rig: Node3D, profile: Dictionary) -> void:
	var previous: Array=rig.get_meta("garments",[])
	for node in previous:
		if is_instance_valid(node):
			node.get_parent().remove_child(node)
			node.queue_free()
	# No legacy 3D wardrobe survives an update. Keep canonical skin & joints.
	var owned: Array[Node]=[]
	var cloth_motion: Array[Dictionary]=[]
	var color_index: int=posmod(int(profile.get("robe",0)),PALETTES.size())
	var robe: Color=Color(PALETTES[color_index])
	var ink: Color=robe.darkened(.42)
	var shade: Color=robe.darkened(.22)
	var light: Color=robe.lightened(.24)
	var trim: Color=Color("cfb477") if color_index!=4 else Color("75614a")
	var skin: Color=Color("efd5be")
	var outfit: int=clampi(int(profile.get("outfit",0)),0,3)
	var importing: bool=bool(profile.get("_refit_imported_skin",false))
	var head: Node3D=rig.torso.get_child(1)
	if not importing:
		var torso: Array=[]
		# EXO martial vest, fitted and shaded; colours are vertices of one mesh.
		if outfit != 2:
			_b(torso,Vector3(0,.385,.005),Vector3(.53,.70,.32),robe)
			_b(torso,Vector3(0,.74,-.015),Vector3(.42,.105,.36),shade)
			_b(torso,Vector3(-.14,.52,-.177),Vector3(.077,.43,.025),trim)
			_b(torso,Vector3(.10,.46,-.179),Vector3(.063,.47,.025),light)
			_b(torso,Vector3(0,.13,0),Vector3(.57,.155,.375),ink)
			_b(torso,Vector3(0,.14,-.205),Vector3(.47,.035,.018),trim)
			_b(torso,Vector3(.12,.14,-.23),Vector3(.13,.14,.042),Color("7ea99a"))
			_b(torso,Vector3(.12,.14,-.255),Vector3(.065,.08,.024),trim)
			if outfit==3:
				_b(torso,Vector3(0,.61,.185),Vector3(.56,.23,.08),shade)
		else:
			_b(torso,Vector3(0,.20,-.152),Vector3(.54,.22,.10),ink)
			_b(torso,Vector3(0,.15,-.22),Vector3(.32,.047,.015),trim)
		# Refined Murim shoulder silhouette; unlike separate armour, same joint mesh.
		_add_mesh(rig.torso,"Murim_Torso",torso,owned)
		for i in range(2):
			var sleeve: Array=[]
			var fore: Array=[]
			var boot: Array=[]
			var side: float=-1.0 if i==0 else 1.0
			if outfit!=2:
				_t(sleeve,Vector3(0,-.16,0),Vector2(.31,.30),Vector2(.27,.28),.30,robe)
				_b(sleeve,Vector3(0,-.036,-.165),Vector3(.28,.068,.027),trim)
				_b(sleeve,Vector3(side*.012,-.20,-.164),Vector3(.22,.095,.025),shade)
				_b(fore,Vector3(0,-.19,0),Vector3(.275,.29,.285),shade)
				_b(fore,Vector3(0,-.29,-.15),Vector3(.272,.051,.024),trim)
			else:
				_b(sleeve,Vector3(0,-.08,0),Vector3(.262,.14,.272),ink)
				_b(fore,Vector3(0,-.21,0),Vector3(.273,.19,.283),shade)
				_b(fore,Vector3(0,-.29,-.154),Vector3(.27,.037,.022),trim)
			_add_mesh(rig.arms[i],"Murim_Sleeve_%d"%i,sleeve,owned)
			_add_mesh(rig.forearms[i],"Murim_Cuff_%d"%i,fore,owned)
			_t(boot,Vector3(0,-.175,0),Vector2(.245,.28),Vector2(.25,.32),.35,ink)
			_b(boot,Vector3(0,-.33,-.055),Vector3(.255,.08,.35),shade)
			_b(boot,Vector3(0,-.13,-.154),Vector3(.25,.035,.025),trim)
			_add_mesh(rig.calves[i],"Murim_Boot_%d"%i,boot,owned)
		# Long robes are two independent front cloth panels that follow leg motion.
		if outfit in [0,3]:
			var hem_height:float=.45 if outfit==0 else .60
			for i in range(2):
				var panel:=Node3D.new()
				panel.name="Murim_Cloth_Panel_%d"%i
				rig.torso.add_child(panel)
				panel.position=Vector3(-.15 if i==0 else .15,.02,-.155)
				owned.append(panel)
				var patch: Array=[]
				_t(patch,Vector3(0,-hem_height*.5,0),Vector2(.21,.068),Vector2(.28,.09),hem_height,robe.darkened(.08 if i==0 else .18))
				_b(patch,Vector3(0,-hem_height+.035,-.065),Vector3(.26,.035,.02),trim)
				_add_mesh(panel,"Murim_Hem_%d"%i,patch,owned)
				cloth_motion.append({"node":panel,"kind":"panel","side":-1 if i==0 else 1,"front":-1})
			# Back cape: low-poly flat, connected to waist, not overlapping front skirt.
			var tail:=Node3D.new()
			tail.name="Murim_BackCloth"
			rig.torso.add_child(tail)
			tail.position=Vector3(0,.18,.20)
			owned.append(tail)
			var back: Array=[]
			_t(back,Vector3(0,-.32,0),Vector2(.38,.035),Vector2(.51,.06),.62,shade)
			_b(back,Vector3(0,-.62,.038),Vector3(.48,.029,.017),trim)
			_add_mesh(tail,"Murim_BackHem",back,owned)
			cloth_motion.append({"node":tail,"kind":"panel","side":0,"front":1})
		# Hair is distinct from skin paint, clean low-poly angular silhouette.
		var hair_index:int=posmod(int(profile.get("hair",0)),HAIR.size())
		var hair: Color=Color(HAIR[hair_index])
		var haircut:int=clampi(int(profile.get("haircut",0)),0,3)
		if haircut!=3:
			var cap: Array=[]
			_b(cap,Vector3(0,.505,0),Vector3(.525,.13,.53),hair)
			_b(cap,Vector3(0,.45,.22),Vector3(.52,.12,.07),hair.darkened(.14))
			if haircut in [0,2]:
				for j in range(4):
					var x:float=-.18+float(j)*.115
					_b(cap,Vector3(x,.41,-.268),Vector3(.115,.13+float(j%2)*.07,.05),hair)
			if haircut==1:
				for j in range(3):
					_b(cap,Vector3(-.15+float(j)*.15,.61,-.05),Vector3(.12,.14,.13),hair)
			_add_mesh(head,"Murim_Hair",cap,owned)
			var cosmetics:Dictionary=preload("res://exo_skin3d/profile_codec.gd").normalized(profile)
			if int(profile.get("style",0))==0 and str(cosmetics.get("accessories",{}).get("hair",""))!="topknot":
				var knot: Array=[]
				_b(knot,Vector3(0,.65,.09),Vector3(.21,.18,.19),hair)
				_b(knot,Vector3(0,.69,.09),Vector3(.25,.05,.21),trim)
				_add_mesh(head,"Murim_Topknot",knot,owned)
			elif int(profile.get("style",0))==1:
				var pony:=Node3D.new()
				pony.name="Murim_Ponytail"
				head.add_child(pony);pony.position=Vector3(0,.38,.28)
				owned.append(pony)
				var p: Array=[]
				_t(p,Vector3(0,-.20,.035),Vector2(.15,.14),Vector2(.10,.085),.39,hair)
				_b(p,Vector3(0,0,0),Vector3(.18,.052,.16),trim)
				_add_mesh(pony,"Murim_PonytailMesh",p,owned)
				cloth_motion.append({"node":pony,"kind":"hair"})
	rig.set_meta("garments",owned)
	rig.set_meta("cloth_motion",cloth_motion)
	rig.set_meta("exo_character_refit_version",1)
	rig.set_meta("exo_character_visual_owner","exo_character_refit01")

static func animate_cloth(rig: Node3D,time: float,moving: bool) -> void:
	for item in rig.get_meta("cloth_motion",[]):
		var node: Node3D=item.node
		if not is_instance_valid(node):continue
		if item.kind=="hair":
			node.rotation.x=sin(time*(5.5 if moving else 1.3))*(.11 if moving else .02)
		else:
			var side:float=float(item.side)
			node.rotation.x=sin(time*(7.5 if moving else 1.4)+side)*(.16 if moving else .015)+float(item.front)*.045
			node.rotation.z=side*(.04 if moving else .015)
