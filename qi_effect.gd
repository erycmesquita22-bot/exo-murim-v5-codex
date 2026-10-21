extends Node3D
var life:=.55
var clock:=0.0
var rings: Array[MeshInstance3D]=[]
func setup(color: Color,kind: String) -> void:
	var count:=2 if kind in ["projectile","cut","channel"] else 3
	for i in range(count):
		var node:=MeshInstance3D.new()
		var torus:=TorusMesh.new()
		torus.inner_radius=.45+i*.16
		torus.outer_radius=.48+i*.16
		torus.rings=32
		torus.ring_segments=5
		node.mesh=torus
		var material:=StandardMaterial3D.new()
		material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color=Color(color,.65)
		material.emission_enabled=true
		material.emission=color
		node.material_override=material
		add_child(node)
		node.rotation=Vector3(i*.25,0,i*.17)
		rings.append(node)
func _process(delta: float) -> void:
	clock+=delta
	var t:=clock/life
	for i in range(rings.size()):
		var node:=rings[i]
		node.scale=Vector3.ONE*(.4+t*(2+i*.4))
		node.rotation.y+=delta*(i+1)
		node.material_override.albedo_color.a=maxf(0,(1-t)*.65)
	if clock>=life:queue_free()
