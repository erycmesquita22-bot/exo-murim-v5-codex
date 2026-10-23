extends RefCounted
const Catalog=preload("res://catalog.gd")

static func piece(parent: Node3D,p: Vector3,s: Vector3,c: Color) -> MeshInstance3D:
	var node:=MeshInstance3D.new()
	var mesh:=BoxMesh.new()
	mesh.size=s
	node.mesh=mesh
	var material:=StandardMaterial3D.new()
	material.albedo_color=c
	material.metallic=0.65 if c.b>0.5 else 0.1
	material.roughness=0.55
	node.material_override=material
	parent.add_child(node)
	node.position=p
	return node

static func blade(parent: Node3D,length: float,width: float,color: Color) -> void:
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var back:=[Vector3(-width/2,0,-0.25),Vector3(0,0.04,-0.25),Vector3(width/2,0,-0.25),Vector3(0,-0.04,-0.25)]
	var front:=[Vector3(-width*.35,0,-length),Vector3(0,.03,-length),Vector3(width*.35,0,-length),Vector3(0,-.03,-length)]
	for i in range(4):
		var next: int=(i+1)%4
		for point in [back[i],front[i],front[next],back[i],front[next],back[next],front[i],Vector3(0,0,-length-.18),front[next]]:
			surface.add_vertex(point)
	surface.generate_normals()
	var node:=MeshInstance3D.new()
	node.mesh=surface.commit()
	var material:=StandardMaterial3D.new()
	material.albedo_color=color
	material.metallic=.75
	material.roughness=.36
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	node.material_override=material
	parent.add_child(node)

static func equip(rig: Node3D,id: String) -> void:
	for node in rig.get_meta("weapon_nodes", []):
		if is_instance_valid(node):
			node.visible = false
			if node.get_parent() != null:
				node.get_parent().remove_child(node)
			node.queue_free()
	for garment in rig.get_meta("garments",[]):
		if is_instance_valid(garment) and garment.has_meta("wrist_arm"):
			var wrist_parent: Node3D=rig.forearms[int(garment.get_meta("wrist_arm"))]
			if garment.get_parent()!=wrist_parent:garment.reparent(wrist_parent,false)
			garment.position=Vector3(0,-.125,0)
	rig.sword.hide()
	for arm in rig.arms:arm.get_child(0).show()
	for forearm in rig.forearms:forearm.get_child(0).show()
	rig.set_meta("fist_forearms",[])
	var nodes: Array[Node]=[]
	var spec:=Catalog.weapon(id)
	var root:=Node3D.new()
	# Retain the canonical forearm parent used by combat/save/QA contracts;
	# the Marker3D owns only the offset, not a second weapon hierarchy.
	var socket:Node3D=rig.get_meta("weapon_hand_r",rig.forearms[0])
	rig.forearms[0].add_child(root)
	root.transform=socket.transform if socket!=rig.forearms[0] else Transform3D(Basis(),Vector3(0,-.355,-.035))
	nodes.append(root)
	rig.set_meta("weapon_root",root)
	rig.set_meta("weapon_id",id)
	preload("res://convergence/visual_actor_r10.gd").notify_action(rig,"two_handed",int(spec.get("hands",1))==2)
	var metal:=Color("9eafb8")
	var gold:=Color("b49a5e")
	var wood:=Color("49392d")
	var dark:=Color("28353d")
	if spec.pose in ["blade","heavy","draw","thrust","reverse","dual"] and id!="spear":
		var length: float=1.65 if id=="greatsword" else .65 if id in ["dagger","twin_daggers"] else 1.2
		piece(root,Vector3(0,0,-.08),Vector3(.095,.09,.27),wood)
		piece(root,Vector3(0,0,-.24),Vector3(.4 if id!="katana" else .23,.075,.09),gold)
		blade(root,length,.25 if id=="greatsword" else .075 if id=="rapier" else .14,metal)
		piece(root,Vector3(0,-.005,-length*.6),Vector3(.022,.075,length*.35),Color("648c92"))
		if spec.pose=="reverse":
			root.rotation.x=PI
		if spec.pose=="dual":
			var off:=Node3D.new()
			rig.forearms[1].add_child(off)
			off.position=root.position
			piece(off,Vector3(0,0,-.08),Vector3(.095,.09,.24),wood)
			piece(off,Vector3(0,0,-.23),Vector3(.26,.065,.08),gold)
			blade(off,.65,.14,metal)
			nodes.append(off)
	elif spec.pose in ["thrust","pole","reap","staff","focus"]:
		piece(root,Vector3(0,0,-.55),Vector3(.08,.08,1.9),wood)
		for z in [-.15,-.35,-1.2]:
			piece(root,Vector3(0,0,z),Vector3(.11,.11,.12),gold)
		if id=="spear":
			var tip:=Node3D.new()
			root.add_child(tip)
			tip.position.z=-1.15
			blade(tip,.65,.23,metal)
		elif id=="halberd":
			piece(root,Vector3(.18,0,-1.25),Vector3(.55,.09,.5),metal)
			var tip:=Node3D.new()
			root.add_child(tip)
			tip.position.z=-1.28
			blade(tip,.55,.17,metal)
		elif id=="scythe":
			var tip:=Node3D.new()
			root.add_child(tip)
			tip.position.z=-1.35
			tip.rotation.y=PI/2
			blade(tip,1,.24,metal)
		elif id=="arcane_staff":
			piece(root,Vector3(0,0,-1.45),Vector3(.3,.2,.3),gold)
			piece(root,Vector3(0,0,-1.67),Vector3(.18,.18,.25),Color("6a9fb1"))
	elif spec.pose=="crush":
		piece(root,Vector3(0,0,-.4),Vector3(.1,.1,.9),wood)
		piece(root,Vector3(0,0,-.96),Vector3(.4,.37,.45),metal)
		for x in [-.26,.26]:
			piece(root,Vector3(x,0,-.96),Vector3(.16,.16,.2),gold)
	elif spec.pose=="fists":
		root.hide()
		# Gauntlets add shells to permanent Minecraft forearms; no disposable fake elbow.
		for i in range(2):
			var elbow: Node3D=rig.forearms[i]
			var shell:=piece(elbow,Vector3(0,-.27,0),Vector3(.285,.20,.29),metal)
			shell.set_meta("gauntlet_shell",true);nodes.append(shell)
			var band:=piece(elbow,Vector3(0,-.345,0),Vector3(.29,.055,.3),gold)
			band.set_meta("gauntlet_shell",true);nodes.append(band)
		rig.set_meta("fist_forearms",rig.forearms)
	elif spec.pose=="wand":
		piece(root,Vector3(0,0,-.3),Vector3(.065,.065,.7),wood)
		piece(root,Vector3(0,0,-.67),Vector3(.14,.14,.14),Color("7f88c3"))
	elif spec.pose in ["bow","crossbow"]:
		root.reparent(rig.torso,false)
		root.position = Vector3(-.06,.38,-.46) if spec.pose=="bow" else Vector3(-.04,.38,-.48)
		root.name="RangedFrame"
		if spec.pose=="bow":
			piece(root,Vector3.ZERO,Vector3(.095,.22,.1),gold)
			for side in [-1,1]:
				beam(root,Vector3(0,side*.08,0),Vector3(0,side*.4,.06),.07,wood)
				beam(root,Vector3(0,side*.4,.06),Vector3(0,side*.66,.19),.055,wood)
			var top:=beam(root,Vector3.ZERO,Vector3.UP,.014,Color("ded3b3"))
			var bottom:=beam(root,Vector3.ZERO,Vector3.UP,.014,Color("ded3b3"))
			root.set_meta("strings",[top,bottom])
		else:
			piece(root,Vector3(0,.03,-.3),Vector3(.14,.13,.9),wood)
			piece(root,Vector3(0,-.08,0),Vector3(.11,.22,.14),wood)
			for side in [-1,1]:
				beam(root,Vector3(0,.04,-.55),Vector3(side*.49,.04,-.43),.07,metal)
				beam(root,Vector3(side*.49,.04,-.43),Vector3(0,.06,-.2),.013,Color("ded3b3"))
		var ammo:=Node3D.new()
		root.add_child(ammo)
		piece(ammo,Vector3(0,.09,-.4),Vector3(.025,.025,.85),wood)
		piece(ammo,Vector3(0,.09,-.86),Vector3(.07,.04,.12),metal)
		root.set_meta("ammo",ammo)
		var muzzle:=Marker3D.new()
		root.add_child(muzzle)
		muzzle.position=Vector3(0,.09,-.94)
		root.set_meta("muzzle",muzzle)
	var carry_roots: Array=[root]
	if spec.pose=="dual":carry_roots.append(nodes[1])
	for item in carry_roots:
		# Weapons are built with their business end along local -Z.
		# -90 degrees aimed every long blade, staff and spear at the floor.
		# Each category has a deliberate forearm-relative carrying angle:
		# long/two-handed weapons upright; shorter blades diagonally forward.
		if spec.pose in ["heavy","pole","reap","staff","focus","crush"]:
			item.rotation.x=PI * 0.50
		elif spec.pose in ["blade","draw","thrust","dual"]:
			# The blade rises from the real wrist instead of crossing the back.
			item.rotation.x=PI * 0.46
		elif spec.pose=="reverse":
			item.rotation.x=-PI * 0.25
		# This local transform is restored by martial_motion when pose blends end.
		item.set_meta("grip_transform", item.transform)
	rig.set_meta("carry_roots",carry_roots)
	rig.set_meta("carry_sheath", null)
	# Back mount is attached to the actual torso so NPCs, previews, turns and
	# rolling use the same coordinate space. Only its scabbard is rendered.
	# No generic sheath for daggers, gauntlets, ranged or pole weapons.
	if id in ["sword", "katana", "rapier", "short_katana"]:
		var sleeve := Node3D.new()
		sleeve.name = "Scabbard_" + id
		rig.torso.add_child(sleeve)
		nodes.append(sleeve)
		var sheath_length: float = 1.08 if id == "sword" else 0.90 if id in ["katana", "rapier"] else 0.68
		var sheath_width: float = 0.105
		# +Z is the back of the Minecraft torso. The spine is at +0.125;
		# clothing extends beyond this. Keep the entire sheath behind +0.28,
		# not just its origin, and angle its tip laterally away from the body.
		var angle: float = 0.34
		sleeve.position = Vector3(0.10, 0.64, 0.385)
		sleeve.rotation = Vector3(-PI * 0.5, 0.0, angle)
		piece(sleeve, Vector3(0, 0, -0.14 - sheath_length * 0.5), Vector3(sheath_width, 0.085, sheath_length), Color("293c41"))
		piece(sleeve, Vector3(0, 0, -0.20), Vector3(sheath_width + 0.045, 0.105, 0.09), gold)
		# NPCs have no automatic stowing state: never display a sheath *and*
		# a drawn blade together by default. Player composition toggles it.
		sleeve.visible = false
		rig.set_meta("carry_sheath", sleeve)
	rig.set_meta("weapon_nodes",nodes)

static func animate(rig: Node3D,spec: Dictionary,index: int,progress: float) -> void:
	rig.set_meta("reference_attack",progress)
	var pose: String=spec.pose
	rig.set_meta("reference_pose",pose)
	rig.set_meta("motion_combo",index)
	if pose=="unarmed":
		preload("res://combat/unarmed.gd").legacy(rig,index,progress);return
	if pose=="fists":
		fist_pose(rig,index,progress)
		return
	if pose in ["bow","crossbow"]:
		ranged_pose(rig,pose,progress)
		return
	if progress<0:
		if pose in ["thrust","pole","reap","staff","focus"] and spec.hands==2:
			rig.arms[0].rotation.x+=.65
			rig.arms[1].rotation=Vector3(.75,-.35,.35)
		elif pose in ["bow","crossbow"]:
			rig.arms[0].rotation.x=1.15
			rig.arms[1].rotation=Vector3(1.1,-.3,.3)
		elif pose=="fists":
			rig.arms[0].rotation.x=.7
			rig.arms[1].rotation.x=.7
		_two_hand_grip(rig,spec)
		return
	var swing:=smoothstep(.15,.67,progress)
	var recovery:=1.0-smoothstep(.7,1.0,progress)
	var sign_value:=1.0 if index%2==0 else -1.0
	if pose in ["blade","draw","reverse","dual","reap","pole","staff"]:
		var weight:=1.3 if pose in ["reap","pole","staff"] else 1.0
		rig.torso.rotation.y=lerpf(-.55,.65,swing)*recovery*sign_value*weight
		var first:=1 if pose=="dual" and index%2==1 else 0
		rig.arms[first].rotation=Vector3(.45,lerpf(-1.3,1.3,swing)*sign_value,-.72)*recovery
		if pose in ["staff","pole","reap"]:
			rig.arms[1].rotation=Vector3(.95,lerpf(-.6,.65,swing)*sign_value,.4)*recovery
			rig.forearms[0].rotation.x=absf(-.25-.4*swing)
			rig.forearms[1].rotation.x=absf(-.55-.35*swing)
		if pose=="draw":
			rig.arms[0].rotation.y=lerpf(-1.5,1.5,smoothstep(.4,.65,progress))*recovery
	elif pose in ["heavy","crush"]:
		rig.arms[0].rotation=Vector3(lerpf(2.5,-.25,swing),-.15,-.15)*recovery
		rig.arms[1].rotation=Vector3(lerpf(2.0,-.05,swing) if pose=="heavy" else .35,.1,.25)*recovery
		rig.torso.rotation.x=lerpf(-.25,.35,swing)*recovery
		rig.forearms[0].rotation.x=absf(-.35-.45*swing)
		rig.forearms[1].rotation.x=absf(-.45-.5*swing)
	elif pose=="thrust":
		rig.arms[0].rotation=Vector3(lerpf(.35,1.55,swing),-.1,-.12)*recovery
		rig.torso.rotation.y=-.3*recovery
		rig.pivot.position.z=-sin(progress*PI)*.13
		if spec.hands==2:
			rig.arms[1].rotation=Vector3(1.1,-.5,.3)*recovery
	elif pose=="fists":
		var hand: int=index%2
		rig.arms[hand].rotation=Vector3(lerpf(.5,1.7,swing),.15*sign_value,-.1*sign_value)*recovery
		rig.arms[1-hand].rotation.x=.8
		rig.torso.rotation.y=sin(progress*PI)*.35*sign_value
		rig.forearms[hand].rotation.x=absf(-.2-.6*swing)
	elif pose=="bow":
		rig.arms[0].rotation=Vector3(1.4,0,-.15)
		rig.arms[1].rotation=Vector3(1.2,lerpf(.1,-1.0,smoothstep(0,.7,progress)),.25)*recovery
	elif pose=="crossbow":
		rig.arms[0].rotation=Vector3(1.2,0,-.15)
		rig.arms[1].rotation=Vector3(.95,-.5,sin(progress*PI)*.55)
	else:
		rig.arms[0].rotation=Vector3(1.1,.1,-.3)*recovery
		rig.arms[1].rotation.x=.55*recovery
	_two_hand_grip(rig,spec)

static func missile(parent: Node3D,direction: Vector3,arrow: bool,color: Color) -> Node3D:
	var root:=Node3D.new()
	parent.add_child(root)
	root.rotation.y=atan2(-direction.x,-direction.z)
	piece(root,Vector3.ZERO,Vector3(.035,.035,.85) if arrow else Vector3(.15,.15,.35),Color("8a704b") if arrow else color)
	if arrow:
		piece(root,Vector3(0,0,-.47),Vector3(.09,.04,.15),Color("b3c0c3"))
		piece(root,Vector3(0,0,.3),Vector3(.13,.02,.2),color)
	return root

static func beam(parent: Node3D,a: Vector3,b: Vector3,width: float,color: Color) -> MeshInstance3D:
	var node:=piece(parent,Vector3.ZERO,Vector3(width,1,width),color)
	fit_beam(node,a,b)
	return node

static func fit_beam(node: Node3D,a: Vector3,b: Vector3) -> void:
	node.position=(a+b)*.5
	node.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
	node.scale.y=a.distance_to(b)

static func grip(rig: Node3D, index: int, target: Vector3) -> void:
	# Both Minecraft segments remain their original lengths. Do not stretch
	# the upper arm as previous ranged poses did: that separated sleeves,
	# wrists and hands from the player model in the menu and in gameplay.
	var arm: Node3D = rig.arms[index]
	var elbow: Node3D = rig.forearms[index]
	var offset: Vector3 = target - arm.position
	var distance: float = offset.length()
	if distance < 0.001:
		return
	var segment_length: float = 0.375
	var reach: float = clampf(distance,0.01, segment_length * 2.0 - 0.002)
	var aim: Vector3=offset.normalized()
	var pole: Vector3=Vector3.BACK - aim*aim.dot(Vector3.BACK)
	if pole.length_squared()<0.001:pole=Vector3.UP-aim*aim.dot(Vector3.UP)
	pole=pole.normalized()
	var along: float=reach*0.5
	var outward: float=sqrt(maxf(0.0,segment_length*segment_length-along*along))
	var elbow_point: Vector3=arm.position+aim*along+pole*outward
	var upper_direction: Vector3=(elbow_point-arm.position).normalized()
	var lower_direction: Vector3=(arm.position+aim*reach-elbow_point).normalized()
	arm.scale = Vector3.ONE
	elbow.scale = Vector3.ONE
	arm.quaternion = Quaternion(Vector3.DOWN,upper_direction)
	elbow.quaternion = Quaternion(Vector3.DOWN,arm.quaternion.inverse()*lower_direction)

# For two-handed melee weapons, both wrists must contact the same shaft.
# The primary grip is solved first; the secondary wrist targets a point on
# the real weapon instead of using a hard-coded floating shoulder pose.
static func _two_hand_grip(rig: Node3D, spec: Dictionary) -> void:
	var pose: String = str(spec.get("pose", ""))
	if int(spec.get("hands", 1)) != 2 or pose not in ["heavy", "thrust", "pole", "reap", "staff", "focus"]:
		return
	var root_value: Variant = rig.get_meta("weapon_root", null)
	if not (root_value is Node3D) or not is_instance_valid(root_value):
		return
	var weapon_root: Node3D = root_value as Node3D
	# Bring the primary wrist into a reproducible guard before placing the shaft.
	grip(rig, 0, Vector3(-0.10, 0.39, -0.43))
	# Position the off-hand on the actual shaft, not in empty space.
	var target_global: Vector3 = weapon_root.to_global(Vector3(0, 0, -0.21))
	grip(rig, 1, rig.torso.to_local(target_global))

static func ranged_pose(rig: Node3D,pose: String,progress: float) -> void:
	var root: Node3D=rig.get_meta("weapon_root")
	var release: float=Catalog.weapon(pose).hit
	var draw:=smoothstep(0,release,progress)*(1.0-smoothstep(release,release+.13,progress)) if progress>=0 else .15
	var recoil:=sin(clampf((progress-release)/.18,0,1)*PI) if progress>=0 else 0.0
	root.position = Vector3(-.06,.38,-.46) if pose=="bow" else Vector3(-.04,.38,-.48+recoil*.06)
	root.rotation=Vector3.ZERO
	grip(rig,0,root.position)
	if pose=="bow":
		var pull:=Vector3(0,0,.22+.24*draw)
		grip(rig,1,root.position+pull)
		var strings: Array=root.get_meta("strings")
		fit_beam(strings[0],Vector3(0,.66,.19),pull)
		fit_beam(strings[1],Vector3(0,-.66,.19),pull)
		var ammo: Node3D=root.get_meta("ammo")
		ammo.position=Vector3(pull.x,0,pull.z-.2)
	else:
		var support:=Vector3(.24,.34,-.5)
		if progress>.55:
			support=support.lerp(Vector3(-.12,.38,-.56),sin((progress-.55)/.45*PI))
		grip(rig,1,support)
	var loaded: Node3D=root.get_meta("ammo")
	loaded.visible=progress<0 or progress<release or progress>.92

static func fist_pose(rig: Node3D,index: int,progress: float) -> void:
	var elbows: Array=rig.get_meta("fist_forearms",[])
	if elbows.size()!=2:return
	for i in range(2):
		var side:=1.0 if i==0 else -1.0
		rig.arms[i].rotation=Vector3(.35,side*-.12,side*-.13)
		elbows[i].rotation=Vector3(1.55,0,0)
	# Stable feet and guard; shoulder leads the punch and elbow extends toward the aim.
	if progress<0:return
	var hit: float=Catalog.weapon("gauntlets").hit
	var extend:=smoothstep(.08,hit,progress)*(1.0-smoothstep(hit+.08,.96,progress))
	var hand:=index%2
	var side:=1.0 if hand==0 else -1.0
	if index==2:
		rig.arms[hand].rotation=Vector3(.35+extend*.72,-side*extend*.55,-side*(.13+extend*.38))
		elbows[hand].rotation.x=1.55-extend*.7
	else:
		rig.arms[hand].rotation.x=.35+extend*1.18
		elbows[hand].rotation.x=1.55*(1-extend)
		rig.arms[hand].rotation.y=-side*.12*(1-extend)
	rig.torso.rotation.y=side*extend*(.24 if index==2 else .12)
	rig.torso.rotation.x=-extend*.035
