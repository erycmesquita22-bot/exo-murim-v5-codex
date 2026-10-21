extends RefCounted
static var foliage_material: StandardMaterial3D
static func bamboo(w: Node3D,p: Vector3,height: float) -> void:
	if foliage_material==null:
		foliage_material=StandardMaterial3D.new();foliage_material.vertex_color_use_as_albedo=true;foliage_material.roughness=.96;foliage_material.cull_mode=BaseMaterial3D.CULL_DISABLED
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for stem in range(3):
		var base:=Vector3((stem-1)*.32,0,(stem%2)*.26);var h:=height*(.82+stem*.09)
		for j in range(6):
			var a:=TAU*j/6;var b:=TAU*(j+1)/6
			var pts: Array[Vector3]=[base+Vector3(cos(a)*.055,0,sin(a)*.055),base+Vector3(cos(b)*.055,0,sin(b)*.055),base+Vector3(cos(b)*.045,h,sin(b)*.045),base+Vector3(cos(a)*.045,h,sin(a)*.045)]
			for i in [0,1,2,0,2,3]:st.set_normal(Vector3(cos(a),0,sin(a)));st.set_color(Color("71885b"));st.add_vertex(pts[i])
		for branch in range(5):
			var angle:=stem*1.7+branch*2.2;var start:=base+Vector3(0,h*(.40+branch*.12),0);var direction:=Vector3(cos(angle),.16,sin(angle))
			for leaf in range(5):
				var at:=start+direction*(.12+leaf*.12);var length_value:=.34+(leaf%2)*.13;var side:=Vector3(-direction.z,0,direction.x)
				var tip:=at+direction*length_value+side*((.25 if leaf%2==0 else -.25));tip.y-=.12
				var mid: Vector3=(at+tip)*.5+Vector3.UP*.035;var pts: Array[Vector3]=[at,mid+side*.075,tip,mid-side*.075]
				for i in [0,1,2,0,2,3]:st.set_normal(Vector3.UP);st.set_color(Color("49735a").lightened(leaf*.018));st.add_vertex(pts[i])
	var node:=MeshInstance3D.new();w.add_child(node);node.name="VillageBamboo";node.position=p;node.mesh=st.commit();node.material_override=foliage_material
	# The decorative leaves are passable; the three-stem bamboo base is solid.
	var trunk:=StaticBody3D.new()
	trunk.name="BambooTrunkCollider"
	trunk.collision_layer=1
	w.add_child(trunk)
	trunk.position=p+Vector3(0,height*.5,0)
	var collider:=CollisionShape3D.new()
	var shape:=BoxShape3D.new()
	shape.size=Vector3(.62,height,.56)
	collider.shape=shape
	trunk.add_child(collider)
static func build(w: Node3D) -> void:
	# A sloping apron continues the existing village ground beyond the collision boundary.
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var inner: Array[Vector3]=[Vector3(-26,-.05,14),Vector3(-26,-.05,45),Vector3(0,-.05,45),Vector3(26,-.05,45),Vector3(26,-.05,14)]
	var outer: Array[Vector3]=[Vector3(-43,-1.2,10),Vector3(-40,-.6,59),Vector3(0,-1.0,66),Vector3(42,-.7,59),Vector3(43,-1.2,10)]
	for j in range(4):
		var v: Array[Vector3]=[inner[j],inner[j+1],outer[j+1],outer[j]]
		for k in [0,1,2,0,2,3]:
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2(v[k].x/2.75,v[k].z/2.75))
			st.add_vertex(v[k])
	var terrain:=MeshInstance3D.new();w.add_child(terrain);terrain.name="VillageGroundApron";terrain.mesh=st.commit()
	terrain.material_override=preload("res://world/terrain_assets.gd").material("grass_lush")
	# Garden behind the training mat. Its opening faces the central route.
	for point in [Vector3(8.5,0,24.7),Vector3(8,0,26.0),Vector3(5,0,26.3),Vector3(-19,0,25),Vector3(-20,0,34),Vector3(20,0,36)]:bamboo(w,point,2.3)
	for i in range(9):
		var angle:=(-.1+i*.30)*PI
		var p:=Vector3(6+cos(angle)*1.9,.07,23+sin(angle)*1.8)
		w.block(p,Vector3(.42,.14,.30),Color("677467"),false).rotation.y=angle
	# Low garden fences define building plots without closing interaction routes.
	for side in [-1,1]:
		for z in [26,29,32,35]:
			w.block(Vector3(side*19,.5,z),Vector3(.13,1,.13),Color("68523c"),false)
		for y in [.32,.72]:w.block(Vector3(side*19,y,30.5),Vector3(.09,.09,9),Color("756044"),false)
	# Small rear grove beyond variable housing plots; no vegetation through house meshes.
	for x in [-38,-14,14,38]:
		bamboo(w,Vector3(x,0,69),3.2)
