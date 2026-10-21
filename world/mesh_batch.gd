extends RefCounted
# Combine authored garment surfaces per animated joint using vertex colours.
# Waist panels, wrists and anatomical/weapon attachments keep their own transforms.
static var palette_material: StandardMaterial3D
static func apply(rig: Node3D) -> void:
	if palette_material==null:
		palette_material=StandardMaterial3D.new();palette_material.vertex_color_use_as_albedo=true;palette_material.roughness=.82
		palette_material.cull_mode=BaseMaterial3D.CULL_DISABLED
	var groups: Dictionary={}
	var meshes: Array[MeshInstance3D]=[]
	for node in rig.get_meta("garments",[]):
		if node is MeshInstance3D and node.mesh!=null and not node.has_meta("wrist_arm"):
			var parent: Node3D=node.get_parent()
			if not groups.has(parent):groups[parent]=[]
			groups[parent].append(node);meshes.append(node)
	var garments: Array=rig.get_meta("garments",[])
	var removed:=0
	for parent in groups:
		var nodes: Array=groups[parent]
		if nodes.size()<2:continue
		var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for node in nodes:
			var tint: Color=node.material_override.albedo_color
			for section in range(node.mesh.get_surface_count()):
				var data: Array=node.mesh.surface_get_arrays(section)
				var vertices: PackedVector3Array=data[Mesh.ARRAY_VERTEX]
				var normals: PackedVector3Array=data[Mesh.ARRAY_NORMAL]
				var indices: PackedInt32Array=data[Mesh.ARRAY_INDEX] if data[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
				var length_value: int=indices.size() if not indices.is_empty() else vertices.size()
				for i in range(length_value):
					var index: int=indices[i] if not indices.is_empty() else i
					surface.set_color(tint)
					surface.set_normal((node.basis.inverse().transposed()*normals[index]).normalized())
					surface.add_vertex(node.transform*vertices[index])
			# Preserve children such as trim, but release the individual material and draw call.
			node.mesh=null;node.material_override=null;removed+=1
		var merged:=MeshInstance3D.new();parent.add_child(merged);merged.name="BatchedClothing"
		merged.mesh=surface.commit();merged.material_override=palette_material;garments.append(merged)
	rig.set_meta("garments",garments);rig.set_meta("batched_surfaces",removed)
