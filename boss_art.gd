extends Node3D

var actor: Node3D
var gem: MeshInstance3D
var cape: Node3D
var crown: Array[MeshInstance3D]=[]

func _init(owner_actor: Node3D) -> void:
	actor=owner_actor
	var rig: Node3D=actor.rig
	box(rig.torso,Vector3(0,1.06,0),Vector3(0.68,0.23,0.62),Color("293247"))
	box(rig.torso,Vector3(0,0.91,-0.32),Vector3(0.57,0.08,0.05),Color("e5c780"))
	for side in [-1,1]:
		box(rig.torso,Vector3(side*0.46,0.70,0),Vector3(0.36,0.22,0.43),Color("343951"))
		box(rig.torso,Vector3(side*0.46,0.81,0),Vector3(0.39,0.04,0.46),Color("d7b574"))
		for step in range(2):
			var horn:=box(rig.torso,Vector3(side*(0.27+step*0.08),1.30+step*0.12,0),Vector3(0.09,0.32-step*0.08,0.10),Color("d7b574"))
			horn.rotation.z=-side*0.25
	box(rig.torso,Vector3(0,0.43,-0.15),Vector3(0.46,0.48,0.08),Color("31364c"))
	gem=box(rig.torso,Vector3(0,0.50,-0.205),Vector3(0.16,0.22,0.04),Color("bd9df2"))
	gem.rotation.z=PI/4
	cape=Node3D.new()
	rig.torso.add_child(cape)
	cape.position=Vector3(0,0.7,0.21)
	for i in range(3):
		box(cape,Vector3(0,-0.15-i*0.3,0.06+i*0.05),Vector3(0.65-i*0.05,0.3,0.05),Color("423749"))
		box(cape,Vector3(0,-0.29-i*0.3,0.08+i*0.05),Vector3(0.65-i*0.05,0.025,0.03),Color("c5a477"))
	for i in range(6):
		var rune:=box(rig,Vector3.ZERO,Vector3(0.08,0.18,0.05),Color("c7a8ef"))
		rune.add_to_group("profile_detail")
		rune.set_meta("minimum_quality",2)
		crown.append(rune)

func box(parent: Node3D,pos: Vector3,size: Vector3,color: Color) -> MeshInstance3D:
	var node:=MeshInstance3D.new()
	var mesh:=BoxMesh.new()
	mesh.size=size
	node.mesh=mesh
	var material:=StandardMaterial3D.new()
	material.albedo_color=color
	material.roughness=0.55
	node.material_override=material
	parent.add_child(node)
	node.position=pos
	return node

func step(time: float,phase_two: bool,flash: float) -> void:
	var material: StandardMaterial3D=gem.material_override
	material.albedo_color=Color("ffc77e") if phase_two else Color("bda0f0")
	material.emission_enabled=true
	material.emission=material.albedo_color
	material.emission_energy_multiplier=0.7 if phase_two else 0.3
	cape.rotation.x=0.12+sin(time*2)*0.08
	for i in range(crown.size()):
		var angle:=time*0.8+TAU*i/crown.size()
		crown[i].position=Vector3(cos(angle)*0.8,2.4+sin(angle*2)*0.08,sin(angle)*0.8)
		crown[i].rotation.y=-angle
	if flash>0:
		material.albedo_color=Color.WHITE
