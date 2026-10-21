extends RefCounted
const Catalog=preload("res://catalog.gd")
const Anatomy=preload("res://anatomy.gd")
const Arsenal=preload("res://arsenal.gd")
const ExoIdentity=preload("res://exo_identity.gd")
const Skin3D=preload("res://exo_skin3d/appearance_adapter.gd")
const ROBES = ["303744","365987","3b6956","963f49","dedbd0","695183"]
const HAIRS = ["25242b","4c352d","9c5135","c9aa63","d8d8d3","344a76"]
const SKINS = ["efd5be","dbb399","c79670","a77853","7b503d","4e352c"]

static func piece(parent: Node,pos: Vector3,size: Vector3,color: Color) -> MeshInstance3D:
	var part:=MeshInstance3D.new()
	var mesh:=BoxMesh.new();mesh.size=size;part.mesh=mesh
	part.material_override=material(color)
	parent.add_child(part);part.position=pos
	return part

static func material(color: Color) -> StandardMaterial3D:
	var result:=StandardMaterial3D.new()
	result.albedo_color=color;result.roughness=.88
	return result

# A tailored four-sided frustum; flat normals keep the established angular art.
static func taper(parent: Node,pos: Vector3,top: Vector2,bottom: Vector2,height: float,color: Color) -> MeshInstance3D:
	var vertices: Array[Vector3]=[]
	for level in [0,1]:
		var size_value: Vector2=top if level==0 else bottom
		var y: float=height*.5 if level==0 else -height*.5
		for corner in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
			vertices.append(Vector3(corner.x*size_value.x*.5,y,corner.y*size_value.y*.5))
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in [[0,1,5,4],[1,2,6,5],[2,3,7,6],[3,0,4,7],[3,2,1,0],[4,5,6,7]]:
		var normal: Vector3=(vertices[face[1]]-vertices[face[0]]).cross(vertices[face[2]]-vertices[face[0]]).normalized()
		for index in [0,1,2,0,2,3]:
			st.set_normal(normal);st.add_vertex(vertices[face[index]])
	var part:=MeshInstance3D.new();part.mesh=st.commit();part.material_override=material(color)
	# SurfaceTool triangles use clockwise winding in Godot. Double-sided cloth also reads from below.
	part.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED
	parent.add_child(part);part.position=pos
	return part

static func strip(parent: Node,start: Vector3,end: Vector3,width: float,depth: float,color: Color) -> MeshInstance3D:
	var delta:=end-start
	var result:=piece(parent,(start+end)*.5,Vector3(width,delta.length(),depth),color)
	result.rotation.z=-atan2(delta.x,delta.y)
	return result

static func apply(rig: Node3D,profile: Dictionary) -> void:
	for item in rig.get_meta("garments",[]):
		if is_instance_valid(item):item.get_parent().remove_child(item);item.queue_free()
	var race: Dictionary=Catalog.RACES[int(profile.get("race",0))]
	rig.set_meta("surface","metal" if race.body=="mechanical" else "body")
	rig.set_meta("voice",int(profile.get("voice",0)))
	var garments: Array[Node]=[]
	var cloth_motion: Array[Dictionary]=[]
	var robe_index:=int(profile.get("robe",0))%ROBES.size()
	var robe:=Color(ROBES[robe_index]);var hair:=Color(HAIRS[int(profile.get("hair",0))%HAIRS.size()])
	var face:=Color(SKINS[int(profile.get("skin",0))%SKINS.size()])
	var trim:=Color("c9b784") if robe_index!=3 else Color("615b50")
	var ink:=robe.darkened(.58);var lining:=Color("dfdac9")
	var style:=int(profile.get("style",0))
	# Apply owner-attested EXO FighterArt; editable UV tailoring remains fallback.
	# Minecraft UV coordinates remain 64x64-compatible (4 texels per unit).
	var image: Image = ExoIdentity.paint(profile)
	var imported: String=str(profile.get("skin_file",""))
	var imported_ok:=false
	if imported.begins_with("user://exo_skins/") and FileAccess.file_exists(imported):
		var custom:=Image.new()
		if custom.load(imported)==OK and custom.get_width()==64 and custom.get_height()==64:
			image=custom
			imported_ok=true
	rig.skin.albedo_texture=ImageTexture.create_from_image(image);rig.skin.albedo_color=Color.WHITE
	# Original EXO BodyShapes are cosmetic only; hitboxes remain unchanged.
	if not rig.has_meta("exo_base_scale"):
		rig.set_meta("exo_base_scale", rig.scale)
	var body_scale: Vector3 = ExoIdentity.BODY_SCALE[clampi(int(profile.get("body",0)),0,6)]
	var base_scale: Vector3 = rig.get_meta("exo_base_scale")
	rig.scale = Vector3(base_scale.x*body_scale.x, base_scale.y*body_scale.y, base_scale.z*body_scale.z)
	rig.set_meta("robe_color",robe);rig.set_meta("skin_color",face)
	rig.torso.get_child(0).show()
	var head: Node3D=rig.torso.get_child(1);head.get_child(0).show()
	if imported_ok:
		# A player-supplied 64x64 PNG is rendered literally: no forced clothing,
		# haircut or facial parts pasted on top. Racial anatomy and weapons remain.
		rig.set_meta("garments",[])
		rig.set_meta("cloth_motion",[])
		Anatomy.apply(rig,int(profile.get("race",0)))
		Arsenal.equip(rig,str(profile.get("weapon","sword")))
		Skin3D.apply(rig,profile)
		return
	# Outfits 1 (treino) and 2 (faixas) reveal the original painted EXO
	# texture; long 3D robe panels are only used for kimono and tunica.
	if int(profile.get("outfit",0)) in [0, 3]:
		# Optional 3D Murim layers on top of the standard Minecraft cubical torso.
		garments.append(piece(rig.torso,Vector3(0,.73,.02),Vector3(.31,.10,.29),lining))
		garments.append(strip(rig.torso,Vector3(-.185,.715,-.18),Vector3(.12,.19,-.18),.065,.035,lining))
		garments.append(strip(rig.torso,Vector3(.18,.715,-.19),Vector3(-.13,.24,-.19),.082,.04,trim))
		garments.append(strip(rig.torso,Vector3(.16,.69,-.217),Vector3(-.14,.23,-.217),.018,.009,ink))
		# Broad fabric sash, tied knot, jade clasp, and hanging cords.
		garments.append(piece(rig.torso,Vector3(0,.13,0),Vector3(.46,.15,.325),ink))
		for y in [.08,.12,.17]:garments.append(piece(rig.torso,Vector3(0,y,-.168),Vector3(.46,.012,.014),robe.lightened(.12)))
		garments.append(piece(rig.torso,Vector3(.16,.13,-.20),Vector3(.11,.12,.07),trim))
		garments.append(piece(rig.torso,Vector3(.17,.13,-.242),Vector3(.05,.065,.02),Color("6da799")))
		for side in [-1,1]:
			var cord:=strip(rig.torso,Vector3(.17,.06,-.205),Vector3(.17+side*.045,-.22,-.22),.019,.019,trim)
			garments.append(cord)
		# Four independent split skirts, anchored at the waist, leave feet and strides readable.
		var long_robe: bool=robe_index in [1,3,4]
		var length_value: float=.66 if long_robe else .47
		for side in [-1,1]:
			for front in [-1,1]:
				var panel:=Node3D.new();rig.torso.add_child(panel);panel.position=Vector3(side*.115,.06,front*.13)
				garments.append(panel)
				var flap:=taper(panel,Vector3(0,-length_value*.5,front*.025),Vector2(.22,.07),Vector2(.29,.09),length_value,robe.darkened(.13 if front==1 else 0))
				piece(flap,Vector3(0,-length_value*.5+.025,-.048 if front==-1 else .048),Vector3(.29,.035,.012),trim)
				cloth_motion.append({"node":panel,"kind":"panel","side":side,"front":front})
		# Small shoulder folds and tapered sleeves instead of block epaulettes.
		for i in range(2):
			garments.append(piece(rig.arms[i],Vector3(0,-.19,0),Vector3(.27,.33,.27),robe))
			var cuff:=piece(rig.forearms[i],Vector3(0,-.125,0),Vector3(.268,.15,.28),ink)
			cuff.set_meta("wrist_arm",i);garments.append(cuff)
			garments.append(piece(cuff,Vector3(0,0,-.145),Vector3(.19,.026,.012),trim))
			# Cloth wrapped boots travel with each leg.
			garments.append(taper(rig.calves[i],Vector3(0,-.155,-.012),Vector2(.245,.27),Vector2(.225,.29),.30,Color("293236")))
			for y in [-.075,-.145,-.215]:garments.append(piece(rig.calves[i],Vector3(0,y,-.155),Vector3(.23,.016,.014),trim.darkened(.18)))
	# Optional 3D silhouette. A shaved hairstyle must actually be shaved.
	if int(profile.get("haircut",0)) == 3:
		rig.set_meta("garments",garments);rig.set_meta("cloth_motion",cloth_motion)
		Anatomy.apply(rig,int(profile.get("race",0)))
		Arsenal.equip(rig,str(profile.get("weapon","sword")))
		Skin3D.apply(rig,profile)
		return
	# Angular scalp, sideburns, asymmetric fringe. Hair is a silhouette, not a cap recolour.
	garments.append(taper(head,Vector3(0,.48,.025),Vector2(.35,.33),Vector2(.48,.435),.12,hair))
	for side in [-1,1]:
		garments.append(taper(head,Vector3(side*.222,.33,.08),Vector2(.075,.30),Vector2(.045,.22),.28,hair))
	var haircut: int = clampi(int(profile.get("haircut",0)),0,3)
	if haircut == 1:
		# Short upward spikes from the owner's EXO haircut category.
		for i in range(4):
			var spike := taper(head,Vector3(-.16+i*.105,.53,-.17),Vector2(.105,.10),Vector2(.025,.02),.16,hair.lightened(float(i)*.025))
			spike.rotation.z = -.22+float(i)*.13
			garments.append(spike)
	elif haircut == 2:
		# Asymmetric Murim fringe, without independent simulated strands.
		for i in range(5):
			var bang:=taper(head,Vector3(-.17+i*.089,.39-float(i)*.02,-.222),Vector2(.115,.065),Vector2(.03,.025),.21+float(i)*.025,hair)
			bang.rotation.z=-.24+float(i)*.12
			garments.append(bang)
	# Face is drawn on Minecraft skin; only hair can have a 3D silhouette.
	if style==0:
		garments.append(taper(head,Vector3(0,.60,.07),Vector2(.14,.14),Vector2(.21,.20),.20,hair))
		garments.append(piece(head,Vector3(0,.565,.07),Vector3(.22,.038,.21),trim))
		garments.append(piece(head,Vector3(.015,.61,.07),Vector3(.32,.025,.028),trim))
		ponytail(garments,cloth_motion,head,hair,trim,.32)
	elif style==1:
		for i in range(5):
			var strand:=taper(head,Vector3((i-2)*.085,.08+absf(i-2)*.025,.21),Vector2(.105,.12),Vector2(.06,.08),.68-absf(i-2)*.07,hair.lightened(.018*i))
			strand.rotation.x=-.10;garments.append(strand)
		garments.append(piece(head,Vector3(0,.36,.265),Vector3(.12,.05,.04),trim))
	else:
		garments.append(piece(head,Vector3(0,.37,.015),Vector3(.475,.07,.44),ink))
		garments.append(piece(head,Vector3(0,.37,-.213),Vector3(.095,.07,.025),trim))
		ponytail(garments,cloth_motion,head,hair,trim,.44)
		for side in [-1,1]:
			var tie:=piece(head,Vector3(side*.07,.21,.26),Vector3(.04,.28,.03),robe.lightened(.18));tie.rotation.z=side*.18;garments.append(tie)
	rig.set_meta("garments",garments);rig.set_meta("cloth_motion",cloth_motion)
	preload("res://world/mesh_batch.gd").apply(rig)
	Anatomy.apply(rig,int(profile.get("race",0)))
	Arsenal.equip(rig,str(profile.get("weapon","sword")))
	Skin3D.apply(rig,profile)

static func brow_piece(garments: Array[Node],head: Node3D,pos: Vector3,side: int,hair: Color) -> void:
	var brow:=piece(head,pos,Vector3(.108,.02,.018),hair);brow.rotation.z=side*.10;garments.append(brow)

static func ponytail(garments: Array[Node],motion: Array[Dictionary],head: Node3D,hair: Color,trim: Color,length_value: float) -> void:
	var root:=Node3D.new();head.add_child(root);root.position=Vector3(0,.41,.23);garments.append(root)
	piece(root,Vector3(0,0,0),Vector3(.12,.07,.10),trim)
	var tail:=taper(root,Vector3(0,-length_value*.5,.055),Vector2(.16,.13),Vector2(.07,.08),length_value,hair);tail.rotation.x=.17
	motion.append({"node":root,"kind":"hair"})

static func animate_cloth(rig: Node3D,time: float,moving: bool) -> void:
	for item in rig.get_meta("cloth_motion",[]):
		var node: Node3D=item.node
		if not is_instance_valid(node):continue
		if item.kind=="hair":node.rotation.x=sin(time*(7 if moving else 1.4))*(.14 if moving else .035)
		else:
			var side: float=float(item.side)
			var front: float=float(item.front)
			node.rotation.x=sin(time*(8.5 if moving else 1.6)+side)*(.18 if moving else .015)+front*.07
			node.rotation.z=side*(.045+(.04 if moving else 0))
