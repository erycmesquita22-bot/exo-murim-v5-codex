extends RefCounted
# Commercial-use environment by WizP. Keep the source license beside the asset.
static var catalog: Dictionary={}
static var shared_material: Material
static func ensure() -> void:
	if not catalog.is_empty():return
	var scene: Node3D=load("res://assets/asian_village/village.glb").instantiate()
	for node in scene.find_children("*","MeshInstance3D",true,false):
		catalog[str(node.name)]={"mesh":node.mesh,"basis":node.basis}
	scene.free()
static func place(parent: Node3D,id: String,point: Vector3,width: float,yaw: float=0) -> Node3D:
	ensure()
	var root:=Node3D.new();root.name="Asset_"+id;parent.add_child(root);root.position=point;root.rotation.y=yaw
	var source: Dictionary=catalog[id]
	var node:=MeshInstance3D.new();root.add_child(node);node.mesh=source.mesh;node.basis=source.basis
	var bounds: AABB=Transform3D(node.basis,Vector3.ZERO)*node.get_aabb()
	var factor:=width/maxf(bounds.size.x,.01)
	node.basis=node.basis.scaled(Vector3.ONE*factor)
	if id.begins_with("garden_bush"):
		var foliage:=StandardMaterial3D.new();foliage.albedo_color=Color("416b56");foliage.roughness=.95;node.material_override=foliage
	node.position=-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*factor
	root.set_meta("source","WizP / Stylized Asian Village")
	root.set_meta("asset_id",id)
	root.set_meta("bounds",AABB(Vector3(-width*.5,0,-bounds.size.z*factor*.5),bounds.size*factor))
	if id.begins_with("building_") or id=="shop":
		root.set_script(preload("res://world/asset_occlusion.gd"))
		root.visual=node;root.bounds=root.get_meta("bounds")
		root.tint=node.get_active_material(0).duplicate()
		root.tint.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
		node.material_override=root.tint
	return root
