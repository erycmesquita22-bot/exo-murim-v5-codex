extends Node3D
var particles: Array[Dictionary] = []
var drawing: MeshInstance3D
var mat: StandardMaterial3D
var sounds: Dictionary = {}
var voices: Array[AudioStreamPlayer3D] = []
var voice_index := 0
var impacts := 0
var swings := 0
func _ready() -> void:
	drawing = MeshInstance3D.new()
	add_child(drawing)
	mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	drawing.material_override = mat
	drawing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for name in ["swing","impact","parry"]: sounds[name] = load("res://modules/combate_baiano/assets/"+name+".wav")
	for i in 6:
		var voice := AudioStreamPlayer3D.new()
		voice.max_distance = 25
		voice.unit_size = 5
		voice.volume_db = -10
		add_child(voice)
		voices.append(voice)
func sound(kind: String, at: Vector3) -> void:
	var voice := voices[voice_index%voices.size()]
	voice_index += 1
	voice.position = at
	voice.stream = sounds[kind]
	voice.play()
	if kind == "swing": swings += 1
func impact(at: Vector3, direction: Vector3, defended := false) -> void:
	impacts += 1
	sound("parry" if defended else "impact",at)
	var color := Color("e8cf87") if defended else Color("e9f5ed")
	for i in 10:
		var angle := TAU*float(i)/10
		var outward := Vector3(cos(angle),sin(angle),.3*sin(angle*3)).normalized()
		particles.append({"pos":at,"velocity":outward*(2.0+float(i%3)),"life":.18,"color":color,"dir":direction})
	# Short diagonal ink slashes, rather than gore or a full-screen flash.
	particles.append({"pos":at,"velocity":direction*1.3,"life":.24,"color":Color("26333c"),"dir":Vector3(.65,1,0)})
func _process(delta: float) -> void:
	for i in range(particles.size()-1,-1,-1):
		if particles[i].life <= delta: particles.remove_at(i)
	var mesh := ImmediateMesh.new()
	if not particles.is_empty():
		mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(particles.size()-1,-1,-1):
			var p: Dictionary = particles[i]
			p.life -= delta
			p.pos += p.velocity*delta
			p.velocity.y -= delta*4
			var tangent: Vector3 = p.velocity.normalized()*.12
			var side := Vector3.UP.cross(tangent).normalized()*.015
			var color: Color = p.color
			color.a = minf(1,p.life/.10)
			for v in [p.pos-tangent,p.pos+side,p.pos+tangent,p.pos-tangent,p.pos+tangent,p.pos-side]:
				mesh.surface_set_color(color)
				mesh.surface_add_vertex(v)
		mesh.surface_end()
	drawing.mesh = mesh
