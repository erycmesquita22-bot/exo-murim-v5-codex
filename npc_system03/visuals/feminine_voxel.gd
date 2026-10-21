extends RefCounted
# Authored parametric, scene-independent *preview* of original voxel robe pieces.
# Does NOT bind bones, replace the 64x64 skin or imply commercial approval of legacy assets.
static func _block(parent: Node3D, size: Vector3, offset: Vector3, color: Color) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	mesh.material = material
	var item: MeshInstance3D = MeshInstance3D.new()
	item.mesh = mesh
	item.position = offset
	parent.add_child(item)
	return item

static func build_preview(variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "NPC03_FeminineRobePreview"
	var colors: Array = [Color("832637"), Color("314e68"), Color("5b3d79"),
		Color("3c6253"), Color("934d26"), Color("394653")]
	var robe: Color = colors[posmod(variant, colors.size())]
	var border: Color = Color("d7b88b")
	# Full voxel character concept; jointed visual preview is NOT rigged gameplay geometry.
	var skin: Color = Color("bd8767")
	var hair: Color = Color("232733")
	_block(root, Vector3(0.58, 0.55, 0.55), Vector3(0.0, 1.96, 0.0), skin) # head
	_block(root, Vector3(0.64, 0.16, 0.64), Vector3(0.0, 2.27, 0.0), hair) # hair cap
	_block(root, Vector3(0.19, 0.51, 0.23), Vector3(-0.32, 1.97, 0.10), hair) # side hair
	_block(root, Vector3(0.19, 0.51, 0.23), Vector3(0.32, 1.97, 0.10), hair)
	_block(root, Vector3(0.68, 0.66, 0.34), Vector3(0.0, 1.42, 0.0), robe) # bodice
	_block(root, Vector3(0.78, 0.12, 0.39), Vector3(0.0, 1.09, 0.0), border) # sash
	_block(root, Vector3(0.90, 0.73, 0.47), Vector3(0.0, 0.68, 0.0), robe) # skirt
	_block(root, Vector3(0.92, 0.08, 0.49), Vector3(0.0, 0.33, 0.0), border) # hem
	_block(root, Vector3(0.21, 0.63, 0.35), Vector3(-0.47, 1.40, 0.0), robe) # arms
	_block(root, Vector3(0.21, 0.63, 0.35), Vector3(0.47, 1.40, 0.0), robe)
	_block(root, Vector3(0.25, 0.31, 0.27), Vector3(-0.25, 0.18, 0.0), robe) # boot
	_block(root, Vector3(0.25, 0.31, 0.27), Vector3(0.25, 0.18, 0.0), robe)
	_block(root, Vector3(0.12, 0.12, 0.46), Vector3(-0.37, 1.74, 0.0), border)
	_block(root, Vector3(0.12, 0.12, 0.46), Vector3(0.37, 1.74, 0.0), border)
	return root
