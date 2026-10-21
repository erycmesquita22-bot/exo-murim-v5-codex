extends RefCounted
# Small chamfered paving slabs. Geometry has thickness and chipped outlines, then joins static sector meshes.
static func place(w: Node3D,point: Vector3,size: Vector2,tint: Color,seed_value: int) -> void:
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value
	var hw:=size.x*.5;var hd:=size.y*.5;var cut:=minf(hw,hd)*.22
	var polygon: Array[Vector2]=[Vector2(-hw+cut,-hd),Vector2(hw-cut,-hd),Vector2(hw,-hd+cut),Vector2(hw,hd-cut),Vector2(hw-cut,hd),Vector2(-hw+cut,hd),Vector2(-hw,hd-cut),Vector2(-hw,-hd+cut)]
	for i in range(polygon.size()):polygon[i]+=Vector2(rng.randf_range(-.025,.025),rng.randf_range(-.025,.025))
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(polygon.size()):
		var a:=polygon[i];var b:=polygon[(i+1)%polygon.size()]
		var va:=Vector3(a.x,.025,a.y);var vb:=Vector3(b.x,.025,b.y)
		var ba:=Vector3(a.x*.95,-.025,a.y*.95);var bb:=Vector3(b.x*.95,-.025,b.y*.95)
		st.set_normal(Vector3.UP)
		for v in [Vector3(0,.025,0),va,vb]:st.add_vertex(v)
		st.set_normal(Vector3(a.x,0,a.y).normalized())
		for v in [va,ba,bb,va,bb,vb]:st.add_vertex(v)
	var mesh:=MeshInstance3D.new();mesh.mesh=st.commit();mesh.position=point
	var mat:=StandardMaterial3D.new();mat.albedo_color=tint.lightened(rng.randf_range(-.035,.035));mat.cull_mode=BaseMaterial3D.CULL_DISABLED;mesh.material_override=mat
	w.add_child(mesh);mesh.add_to_group("static_geometry")
