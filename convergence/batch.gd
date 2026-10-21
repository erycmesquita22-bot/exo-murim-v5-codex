extends RefCounted
# Bake only static house visuals. Imported collision children remain live and doors
# have already been opened; material/UV/normal data and painted shadows are retained.
static func apply(house: Node3D) -> void:
	var groups: Dictionary={}
	var inverse: Transform3D=house.global_transform.affine_inverse()
	var sources: Array=house.find_children("*","MeshInstance3D",true,false)
	for source in sources:
		if source.mesh==null or not source.visible:continue
		for surface in range(source.mesh.get_surface_count()):
			var material: Material=source.get_active_material(surface)
			var part: Node=source
			var roof: bool=(inverse*source.global_transform).origin.y>=2.9
			while part!=house and part!=null:
				if str(part.get_meta("asset_id","")).begins_with("roof_"):roof=true
				part=part.get_parent()
			var key: String=str(material.get_instance_id() if material!=null else 0)+("/roof" if roof else "/body")
			if not groups.has(key):groups[key]={"material":material,"surfaces":[],"roof":roof}
			groups[key].surfaces.append({"mesh":source.mesh,"surface":surface,"transform":inverse*source.global_transform})
	var mesh:=ArrayMesh.new()
	var roof_mesh:=ArrayMesh.new()
	for group in groups.values():
		var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for part in group.surfaces:st.append_from(part.mesh,int(part.surface),part.transform)
		var destination: ArrayMesh=roof_mesh if group.roof else mesh
		st.index();st.commit(destination)
		destination.surface_set_material(destination.get_surface_count()-1,group.material)
	for source in sources:source.hide()
	var merged:=MeshInstance3D.new();merged.name="StaticHouseVisual";merged.mesh=mesh;merged.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;house.add_child(merged)
	var upper:=MeshInstance3D.new();upper.name="StaticRoofVisual";upper.mesh=roof_mesh;upper.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;house.add_child(upper)
	house.set_meta("combined_source_meshes",sources.size())
