extends Node3D
## Original runtime ink strokes and pulse geometry; no external assets.
var bursts: Array[Dictionary] = []
func material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mat.no_depth_test = false
	return mat
func orb(color: Color) -> Node3D:
	var group := Node3D.new()
	var ball := MeshInstance3D.new()
	var mesh := SphereMesh.new();mesh.radius = .13;mesh.height = .26;mesh.radial_segments = 12;mesh.rings = 6
	ball.mesh = mesh;ball.material_override = material(color)
	group.add_child(ball)
	for i in 2:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new();torus.inner_radius = .16;torus.outer_radius = .19;torus.rings = 16;torus.ring_segments = 6
		ring.mesh = torus;ring.material_override = material(Color(.04,.06,.08,.9) if i == 0 else Color(.95,.98,1,.85))
		ring.rotation = Vector3(PI*.5 if i else 0,0,.7)
		group.add_child(ring)
	return group
func burst(at: Vector3, direction: Vector3, color: Color, large := false):
	var group := Node3D.new();add_child(group);group.global_position = at
	var mat := material(color)
	for i in 9:
		var mesh := MeshInstance3D.new();var box := BoxMesh.new()
		box.size = Vector3(.022,.025,.30 if large else .17)
		mesh.mesh = box;mesh.material_override = mat
		mesh.rotation = Vector3(i*.73,i*1.41,i*.43)
		group.add_child(mesh)
		var v := Vector3(sin(i*2.4),cos(i*1.7),sin(i*.9))*1.7+direction*1.4
		mesh.set_meta("velocity",v)
	bursts.append({"node":group,"time":0.0,"material":mat,"color":color,"duration":.38 if large else .25})
func _process(delta: float):
	for i in range(bursts.size()-1,-1,-1):
		var data := bursts[i];data.time += delta
		var u: float = data.time/data.duration
		if u >= 1:
			data.node.queue_free();bursts.remove_at(i);continue
		for mesh in data.node.get_children(): mesh.position += mesh.get_meta("velocity")*delta;mesh.scale = Vector3.ONE*(1-u*.7)
		var color: Color = data.color;color.a = 1-u;data.material.albedo_color = color
