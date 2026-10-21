extends RefCounted
# Shared soft stamp: fixed architecture and moving contact shadows use no shadow atlas.
static var stamp: ImageTexture
static func place(parent: Node3D,point: Vector3,size: Vector2,opacity: float=.23) -> MeshInstance3D:
	if stamp==null:
		var image:=Image.create(128,128,false,Image.FORMAT_RGBA8)
		for y in range(128):
			for x in range(128):
				var uv:=Vector2(x/127.0,y/127.0)*2-Vector2.ONE
				var edge:=maxf(absf(uv.x),absf(uv.y))
				var alpha:=1.0-smoothstep(.55,1.0,edge)
				image.set_pixel(x,y,Color(.055,.075,.08,alpha))
		image.generate_mipmaps()
		stamp=ImageTexture.create_from_image(image)
	var plane:=MeshInstance3D.new()
	var mesh:=PlaneMesh.new()
	mesh.size=size
	plane.mesh=mesh
	plane.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material:=StandardMaterial3D.new()
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture=stamp
	material.albedo_color=Color(1,1,1,opacity)
	material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.no_depth_test=false
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	plane.material_override=material
	parent.add_child(plane)
	plane.position=point
	plane.name="SoftGroundShadow"
	return plane
