extends Node3D

var pelvis: Node3D
var torso: Node3D
var arms: Array[Node3D] = []
var legs: Array[Node3D] = []
var forearms: Array[Node3D] = []
var calves: Array[Node3D] = []
var pivot: Node3D
var skin: StandardMaterial3D
var sword: Node3D

func _init(tint: Color = Color.WHITE) -> void:
	pivot = Node3D.new()
	add_child(pivot)
	pivot.position.y = 1.0
	var content := Node3D.new()
	pivot.add_child(content)
	content.position.y = -1.0
	pelvis=Node3D.new()
	content.add_child(pelvis)
	pelvis.position=Vector3(0,.87,.09)
	preload("res://ground_shadow.gd").place(self,Vector3(0,.105,0),Vector2(.9,.65),.3)
	skin = StandardMaterial3D.new()
	skin.albedo_texture = load("res://assets/exo_skin.png")
	skin.albedo_color = tint
	skin.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	skin.cull_mode = BaseMaterial3D.CULL_DISABLED
	torso = Node3D.new()
	content.add_child(torso)
	torso.position.y = 0.75
	skin_part(torso,Vector3(0,0.375,0),Vector3(0.5,0.75,0.25),Vector2(16,16),Vector3(8,12,4))
	var head := Node3D.new()
	torso.add_child(head)
	head.position.y = 0.75
	skin_part(head,Vector3(0,0.25,0),Vector3(0.5,0.5,0.5),Vector2.ZERO,Vector3(8,8,8))
	for i in range(2):
		var arm := Node3D.new()
		torso.add_child(arm)
		arm.position = Vector3(-0.375 if i == 0 else 0.375,0.72,0)
		var arm_uv:=Vector2(40,16) if i == 0 else Vector2(32,48)
		skin_part(arm,Vector3(0,-.1875,0),Vector3(.25,.375,.25),arm_uv,Vector3(4,6,4),0)
		var elbow:=Node3D.new();elbow.name="Elbow_%d" % i
		arm.add_child(elbow);elbow.position=Vector3(0,-.375,0)
		skin_part(elbow,Vector3(0,-.1875,0),Vector3(.25,.375,.25),arm_uv,Vector3(4,6,4),6)
		forearms.append(elbow)
		arms.append(arm)
		var leg := Node3D.new()
		content.add_child(leg)
		leg.position = Vector3(-0.125 if i == 0 else 0.125,0.75,0)
		var leg_uv:=Vector2(0,16) if i == 0 else Vector2(16,48)
		skin_part(leg,Vector3(0,-.1875,0),Vector3(.25,.375,.25),leg_uv,Vector3(4,6,4),0)
		var knee:=Node3D.new();knee.name="Knee_%d" % i
		leg.add_child(knee);knee.position=Vector3(0,-.375,0)
		skin_part(knee,Vector3(0,-.1875,0),Vector3(.25,.375,.25),leg_uv,Vector3(4,6,4),6)
		calves.append(knee)
		legs.append(leg)
	sword = Node3D.new()
	forearms[0].add_child(sword)
	sword.position = Vector3(0,-0.265,-0.08)
	# Blade grip inherits the Minecraft wrist joint, so it follows elbow bends and rolls.
	sword_piece(Vector3(0,0,-0.07),Vector3(0.08,0.08,0.25),Color("372e37"))
	sword_piece(Vector3(0,0,-0.23),Vector3(0.34,0.07,0.08),Color("d6ae65"))
	sword_piece(Vector3(0,0,-0.65),Vector3(0.12,0.045,0.78),Color("cedce4"))
	sword_piece(Vector3(0,0,-1.07),Vector3(0.07,0.035,0.08),Color("eef9ff"))

func sword_piece(pos: Vector3, size: Vector3, color: Color) -> void:
	var part := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	part.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.4
	part.material_override = material
	sword.add_child(part)
	part.position = pos

func pose(time: float, moving: bool, sprint: bool, grounded: bool, attack: float = -1, roll: float = -1, side: float = 1) -> void:
	preload("res://convergence/visual_actor_r10.gd").notify_action(self,"roll",roll>=0.0)
	set_meta("reference_grounded",grounded)
	set_meta("meditation_weight",0.0)
	set_meta("reference_attack",-1.0)
	set_meta("reference_speed",0.0)
	pivot.rotation = Vector3.ZERO
	pivot.position.y = 1.0
	pivot.position.x = 0.0
	pivot.position.z = 0.0
	for leg in legs:
		leg.position.y = 0.75
	torso.rotation = Vector3.ZERO
	for limb in arms+legs+forearms+calves:
		limb.rotation = Vector3.ZERO
		limb.scale=Vector3.ONE
	preload("res://wardrobe.gd").animate_cloth(self,time,moving)
	var breath := sin(time*1.6)*0.015
	if roll >= 0:
		pivot.rotation.z = -side*TAU*roll
		pivot.position.y = 1.0-sin(PI*roll)*0.35
		torso.rotation.x = -0.45
		legs[0].rotation.x = 0.7
		legs[1].rotation.x = 0.7
		arms[0].rotation.x = 0.7
		arms[1].rotation.x = 0.7
		for elbow in forearms:elbow.rotation.x=-.9
		for knee in calves:knee.rotation.x=-1.05
	elif not grounded:
		torso.rotation.x = -0.08
		legs[0].rotation.x = 0.42
		legs[1].rotation.x = -0.26
		arms[0].rotation.x = 0.3
		arms[1].rotation.x = 0.3
		for knee in calves:knee.rotation.x=-.4
		for elbow in forearms:elbow.rotation.x=-.25
	elif moving:
		var stride := cos(time*(13.0 if sprint else 8.5))*(1.05 if sprint else 0.65)
		legs[0].rotation.x = -stride
		legs[1].rotation.x = stride
		for i in range(2):
			calves[i].rotation.x=-maxf(0,(-stride if i==0 else stride))*.55
			forearms[i].rotation.x=-.22-absf(stride)*.23
		arms[0].rotation.x = stride*0.8+0.18
		arms[1].rotation.x = -stride*0.8+0.18
		torso.rotation.x = -0.18 if sprint else -0.06
	else:
		torso.rotation.x = -breath
		arms[0].rotation.z = -0.04-breath
		arms[1].rotation.z = 0.04+breath
	if attack >= 0 and roll < 0:
		# Anticipation, horizontal cut, then recovery to the locomotion layer.
		var swing := smoothstep(0.24,0.62,attack)
		var recovery := 1.0-smoothstep(0.68,1.0,attack)
		torso.rotation.y = lerpf(-0.5,0.65,swing)*recovery
		arms[0].rotation = Vector3(0.35,lerpf(-1.15,1.15,swing),-0.75)*recovery
		arms[1].rotation.x = 0.35*recovery

func skin_part(parent: Node3D, center: Vector3, size: Vector3, uv: Vector2, pixels: Vector3, segment_start: int = 0) -> void:
	var h := size * 0.5
	var w := pixels.x
	var d := pixels.z
	var height := pixels.y
	var faces := [
		[Vector3(-h.x,h.y,-h.z),Vector3(h.x,h.y,-h.z),Vector3(h.x,-h.y,-h.z),Vector3(-h.x,-h.y,-h.z)],
		[Vector3(h.x,h.y,h.z),Vector3(-h.x,h.y,h.z),Vector3(-h.x,-h.y,h.z),Vector3(h.x,-h.y,h.z)],
		[Vector3(h.x,h.y,-h.z),Vector3(h.x,h.y,h.z),Vector3(h.x,-h.y,h.z),Vector3(h.x,-h.y,-h.z)],
		[Vector3(-h.x,h.y,h.z),Vector3(-h.x,h.y,-h.z),Vector3(-h.x,-h.y,-h.z),Vector3(-h.x,-h.y,h.z)],
		[Vector3(-h.x,h.y,h.z),Vector3(h.x,h.y,h.z),Vector3(h.x,h.y,-h.z),Vector3(-h.x,h.y,-h.z)],
		[Vector3(-h.x,-h.y,-h.z),Vector3(h.x,-h.y,-h.z),Vector3(h.x,-h.y,h.z),Vector3(-h.x,-h.y,h.z)]]
	var sy:=float(segment_start)
	var rects := [Rect2(uv+Vector2(d,d+sy),Vector2(w,height)),Rect2(uv+Vector2(d+w+d,d+sy),Vector2(w,height)),Rect2(uv+Vector2(d+w,d+sy),Vector2(d,height)),Rect2(uv+Vector2(0,d+sy),Vector2(d,height)),Rect2(uv+Vector2(d,0),Vector2(w,d)),Rect2(uv+Vector2(d+w,0),Vector2(w,d))]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for f in range(6):
		var rect: Rect2 = rects[f]
		var coords := [rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)]
		for index in [0,1,2,0,2,3]:
			surface.set_normal([Vector3.FORWARD,Vector3.BACK,Vector3.RIGHT,Vector3.LEFT,Vector3.UP,Vector3.DOWN][f])
			surface.set_uv(coords[index]/64.0)
			surface.add_vertex(faces[f][index])
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.material_override = skin
	parent.add_child(mesh)
	mesh.position = center


func directional_roll(progress: float, lateral: float, forward: float) -> void:
	# Roll around an axis perpendicular to the travel direction in local space.
	pivot.rotation = Vector3.ZERO
	pivot.quaternion = Quaternion(Vector3(-forward,0,-lateral).normalized(),TAU*progress)

func skill_pose(kind: int, time: float, landed: bool, landing_time: float) -> void:
	if kind==0:
		var progress := clampf(time/0.66,0,1)
		var swing := smoothstep(0.18,0.6,progress)
		var recover := 1.0-smoothstep(0.65,1,progress)
		torso.rotation.y = lerpf(-0.85,0.95,swing)*recover
		arms[0].rotation = Vector3(0.5,lerpf(-1.3,1.3,swing),-0.95)*recover
		arms[1].rotation.x = 0.5*recover
	elif kind==1:
		var recover := 1.0-smoothstep(0.5,0.72,time)
		torso.rotation.x = -0.10*recover
		arms[1].rotation = Vector3(1.25,0.15,0.1)*recover
		arms[0].rotation.x = 0.2*recover
	elif kind==2:
		if landed:
			var weight := 1.0-clampf(landing_time/0.28,0,1)
			pivot.position.y = 1.0-0.18*weight
			torso.rotation.x = -0.4*weight
			legs[0].rotation.x = 0.45*weight
			legs[1].rotation.x = 0.45*weight
			arms[0].rotation.x = 0.5*weight
			arms[1].rotation.x = 0.5*weight
		elif time<0.18:
			pivot.position.y = 0.82
			torso.rotation.x = -0.35
			arms[0].rotation.x = -0.4
			arms[1].rotation.x = -0.4
		else:
			torso.rotation.x = -0.28
			legs[0].rotation.x = 0.65
			legs[1].rotation.x = -0.3
			arms[0].rotation.x = 0.5
			arms[1].rotation.x = 0.5

var gait_phase := 0.0
var motion_local := Vector2.ZERO

func locomotion(real_velocity: Vector3, delta: float, sprint: bool, grounded: bool, arms_free: bool) -> void:
	var flat := Vector3(real_velocity.x,0,real_velocity.z)
	var speed := flat.length()
	set_meta("reference_speed",speed)
	var local: Vector3 = Basis(Vector3.UP,rotation.y).inverse()*flat
	motion_local = Vector2(local.x,-local.z)
	if not grounded or speed<0.06:
		return
	# The gait advances with distance actually covered, not with key presses.
	gait_phase += speed*delta*TAU/(1.8 if sprint else 1.3)
	var direction := motion_local.normalized()
	var swing := sin(gait_phase)*minf(1,speed/3.6)*(1.05 if sprint else 0.7)
	legs[0].rotation.x = -swing*direction.y
	legs[1].rotation.x = swing*direction.y
	calves[0].rotation.x=-maxf(0,-sin(gait_phase))*.62*minf(1,speed/3.6)
	calves[1].rotation.x=-maxf(0,sin(gait_phase))*.62*minf(1,speed/3.6)
	legs[0].rotation.z = -swing*direction.x*0.65
	legs[1].rotation.z = swing*direction.x*0.65
	legs[0].position.y = 0.75+maxf(0,sin(gait_phase))*0.05
	legs[1].position.y = 0.75+maxf(0,-sin(gait_phase))*0.05
	torso.rotation.x += -direction.y*(0.16 if sprint else 0.06)
	torso.rotation.z = -direction.x*0.06
	torso.rotation.y+=sin(gait_phase)*.055*minf(1,speed/3.6)
	# A single animation owner writes shoulder and elbow transforms.
	# Never overwrite the local-space elbow rotation after this call.
	preload("res://animation_library.gd").locomotion(self,gait_phase,sprint,arms_free,direction.y,speed,direction.x)

func combo_pose(index: int,progress: float) -> void:
	var swing:=smoothstep(0.16,0.64,progress)
	var recovery:=1.0-smoothstep(0.68,1.0,progress)
	if index==2:
		arms[0].rotation=Vector3(lerpf(2.2,-0.25,swing),-0.1,-0.2)*recovery
		arms[1].rotation=Vector3(1.65,-0.1,0.15)*recovery
		torso.rotation.x=lerpf(-0.16,0.20,swing)*recovery
		torso.rotation.y=0
	else:
		var sign_value:=1.0 if index==0 else -1.0
		torso.rotation.y=lerpf(-0.55,0.65,swing)*recovery*sign_value
		arms[0].rotation=Vector3(0.35,lerpf(-1.2,1.2,swing)*sign_value,-0.75)*recovery
		arms[1].rotation.x=0.35*recovery
	forearms[index%2].rotation.x=-.15-(1-recovery)*.55

func meditation_pose(time: float,weight: float) -> void:
	set_meta("meditation_weight",weight)
	pivot.position.y-=.43*weight
	torso.rotation.x=lerpf(torso.rotation.x,-.025+sin(time*1.7)*.012,weight)
	for i in range(2):
		var side:=1.0 if i==0 else -1.0
		legs[i].rotation=legs[i].rotation.lerp(Vector3(-1.18,side*.35,side*1.0),weight)
		calves[i].rotation.x=lerpf(calves[i].rotation.x,-1.55,weight)
		arms[i].rotation=arms[i].rotation.lerp(Vector3(.9,side*.25,-side*.25),weight)
		forearms[i].rotation.x=lerpf(forearms[i].rotation.x,-1.0,weight)
	for item in get_meta("cloth_motion",[]):
		if item.kind=="panel":item.node.rotation.x=lerpf(item.node.rotation.x,float(item.front)*.9,weight)

