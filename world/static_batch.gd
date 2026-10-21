extends RefCounted
# Immutable blocks combined once, in 10 m spatial cells. Physics and quality details stay independent.
static func apply(world: Node3D) -> void:
	var cells: Dictionary={}
	var sources:=world.get_tree().get_nodes_in_group("static_geometry")
	for node in sources:
		if node.get_parent()!=world or not node.visible or node.is_in_group("profile_detail"):continue
		if node.mesh==null:continue
		# Preserve authored UVs and textures; the palette-only batcher cannot carry
		# sampler state and would turn the new soil/road artwork into flat colours.
		if node.material_override is BaseMaterial3D and node.material_override.albedo_texture!=null:continue
		var key:=Vector2i(floori(node.position.x/10),floori(node.position.z/10))
		# Large ground slabs keep independent culling bounds.
		if node.get_aabb().size.length()>30:continue
		if not cells.has(key):cells[key]=[]
		cells[key].append(node)
	var material:=StandardMaterial3D.new();material.vertex_color_use_as_albedo=true;material.roughness=.88
	var removed:=0
	for key in cells:
		var nodes: Array=cells[key]
		if nodes.size()<2:continue
		var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for node in nodes:
			var tint: Color=node.material_override.albedo_color
			var arrays: Array=node.mesh.surface_get_arrays(0)
			var v: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var n: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
			var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
			for i in range(indices.size() if not indices.is_empty() else v.size()):
				var j: int=indices[i] if not indices.is_empty() else i
				st.set_color(tint);st.set_normal((node.basis*n[j]).normalized());st.add_vertex(node.transform*v[j])
		var combined:=MeshInstance3D.new();combined.name="StaticCell_%s_%s"%[key.x,key.y];combined.mesh=st.commit();combined.material_override=material;world.add_child(combined)
		for node in nodes:node.free();removed+=1
	world.set_meta("static_blocks_batched",removed)
