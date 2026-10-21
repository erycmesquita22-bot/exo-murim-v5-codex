extends RefCounted
const Catalog=preload("res://catalog.gd")
const Art=preload("res://arsenal.gd")

static func apply(rig: Node3D,race_index: int) -> void:
	for node in rig.get_meta("anatomy_nodes",[]):
		if is_instance_valid(node):
			node.get_parent().remove_child(node)
			node.queue_free()
	var nodes: Array[Node]=[]
	var animated: Array[Dictionary]=[]
	var race: Dictionary=Catalog.RACES[clampi(race_index,0,Catalog.RACES.size()-1)]
	var body: String=race.body
	var head: Node3D=rig.torso.get_child(1)
	rig.torso.scale=Vector3.ONE
	for limb in rig.arms+rig.legs:
		limb.scale=Vector3.ONE
	var fur:=Color("9c603b") if body=="fox" else Color("747b85") if body=="wolf" else Color("4d453a")
	if body in ["fox","wolf","feline","bear"]:
		for side in [-1,1]:
			var ear:=Art.piece(head,Vector3(side*.22,.58,.03),Vector3(.16,.27 if body in ["fox","wolf"] else .16,.14),fur)
			ear.rotation.z=-side*.2
			nodes.append(ear)
			nodes.append(Art.piece(ear,Vector3(0,0,-.078),Vector3(.07,.14,.025),Color("b99785")))
		if body!="bear":
			var tail:=Node3D.new()
			rig.pelvis.add_child(tail)
			tail.position=Vector3.ZERO
			nodes.append(tail)
			var last:=tail
			for i in range(4):
				var joint:=Node3D.new()
				last.add_child(joint)
				joint.position=Vector3(0,0,.19 if i>0 else 0)
				joint.rotation.x=-.12
				Art.piece(joint,Vector3(0,0,.1),Vector3(.2 if body=="fox" else .12,.2 if body=="fox" else .12,.24),Color("d3c2a0") if i==3 and body=="fox" else fur)
				last=joint
			animated.append({"node":tail,"kind":"tail","side":1})
		if body in ["wolf","feline","bear"]:
			for arm in rig.arms:
				for x in [-.08,0,.08]:
					var claw:=Art.piece(arm,Vector3(x,-.735,-.045),Vector3(.038,.22,.055),Color("bbb9a2"))
					claw.set_meta("claw",true)
					nodes.append(claw)
		if body=="bear":
			rig.torso.scale=Vector3(1.15,1.04,1.12)
			for arm in rig.arms:
				arm.scale=Vector3(1.12,1,1.12)
	elif body in ["hawk","raven"]:
		var feather:=Color("947452") if body=="hawk" else Color("30334c")
		for side in [-1,1]:
			var wing:=Node3D.new()
			rig.torso.add_child(wing)
			wing.position=Vector3(side*.23,.5,.2)
			nodes.append(wing)
			for i in range(4):
				var quill:=Art.piece(wing,Vector3(side*(.12+i*.12),-.1-i*.06,.04+i*.04),Vector3(.2,.5-i*.035,.09),feather.lightened(i*.04))
				quill.rotation.z=side*.35
			animated.append({"node":wing,"kind":"wing","side":side})
		for x in [-.12,0,.12]:
			nodes.append(Art.piece(head,Vector3(x,.62,.09),Vector3(.075,.24,.12),feather))
	elif body=="reptile":
		for side in [-1,1]:
			nodes.append(Art.piece(head,Vector3(side*.23,.55,.12),Vector3(.1,.21,.15),Color("687f60")))
		var tail:=Node3D.new()
		rig.pelvis.add_child(tail)
		tail.position=Vector3.ZERO
		nodes.append(tail)
		for i in range(4):
			Art.piece(tail,Vector3(0,-.04*i,.06+i*.19),Vector3(.23-i*.035,.17-i*.025,.23),Color("557255"))
		animated.append({"node":tail,"kind":"tail","side":1})
		for arm in rig.arms:
			nodes.append(Art.piece(arm,Vector3(0,-.24,-.15),Vector3(.26,.34,.065),Color("58745e")))
	elif body=="mechanical":
		for side in [-1,1]:
			nodes.append(Art.piece(rig.torso,Vector3(side*.3,.62,0),Vector3(.23,.19,.36),Color("62747b")))
		nodes.append(Art.piece(rig.torso,Vector3(0,.43,-.145),Vector3(.24,.27,.08),Color("394b5b")))
		nodes.append(Art.piece(rig.torso,Vector3(0,.43,-.2),Vector3(.12,.15,.04),Color("6ec9c4")))
	elif body=="arcane":
		var sigil:=Node3D.new()
		rig.torso.add_child(sigil)
		sigil.position=Vector3(0,.52,.33)
		nodes.append(sigil)
		for i in range(6):
			var a:=TAU*i/6.0
			Art.piece(sigil,Vector3(cos(a)*.39,sin(a)*.39,0),Vector3(.11,.11,.08),Color("8264b7"))
		animated.append({"node":sigil,"kind":"sigil","side":1})
	rig.set_meta("anatomy_nodes",nodes)
	rig.set_meta("anatomy_animated",animated)
	rig.set_meta("race_index",race_index)

static func animate(rig: Node3D,time: float,speed: float,grounded: bool) -> void:
	for node in rig.get_meta("anatomy_nodes",[]):
		if is_instance_valid(node) and node.get_meta("claw",false):
			node.visible=str(rig.get_meta("weapon_id","sword"))!="gauntlets"
			node.scale.y=.55
	for part in rig.get_meta("anatomy_animated",[]):
		if not is_instance_valid(part.node):
			continue
		match part.kind:
			"tail":
				part.node.rotation.y=sin(time*(3 if speed>.1 else 1.5))*.22
				part.node.rotation.x=.15+minf(.25,speed*.04)
			"wing":
				part.node.rotation.z=part.side*(.13+sin(time*(9 if not grounded else 2))*(.5 if not grounded else .06))
			"sigil":
				part.node.rotation.z=time*.6
