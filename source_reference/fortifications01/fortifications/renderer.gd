extends RefCounted
## Preview-grade 3D builder. Material/collision instances are for physical Work QA,
## not final architectural assets. Will be replaced by the modular Forja GLBs.
const WALL_WIDTH := 1.35
static func _box(parent: Node3D,position: Vector3,box_size: Vector3,tint: Color,collision: bool=false) -> void:
	var mesh:=BoxMesh.new();mesh.size=box_size
	var mat:=StandardMaterial3D.new();mat.albedo_color=tint;mat.roughness=.95
	var node:=MeshInstance3D.new();node.mesh=mesh;node.material_override=mat;node.position=position;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	if collision:
		var physics:=StaticBody3D.new();physics.collision_layer=4;parent.add_child(physics)
		var collider:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=box_size;collider.shape=shape;collider.position=position;physics.add_child(collider)
static func build_into(root: Node3D,plan: Dictionary,terrain: Callable=Callable()) -> Dictionary:
	if not (str(plan.get("status","")) in ["ready","partial"]):return {"ok":false,"reason":str(plan.get("errors",[]))}
	var holder:=Node3D.new();holder.name="EXO_Fortifications_%02d"%int(plan.get("region_id",0));holder.set_meta("fortifications_version",int(plan.get("version",1)));root.add_child(holder)
	var city: bool=str(plan.get("kind",""))=="city_wall"
	var stone: Color=Color("77756e") if city else Color("c4bba4")
	var tile: Color=Color("343e47") if city else Color("484c4f")
	var box:=BoxMesh.new();box.size=Vector3.ONE
	var mat:=StandardMaterial3D.new();mat.albedo_color=stone;mat.roughness=1.0
	var seg: Array=plan.get("segments",[])
	var multi:=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.mesh=box;multi.instance_count=seg.size()
	var physics:=StaticBody3D.new();physics.name="WallsCollision";physics.collision_layer=4;holder.add_child(physics)
	for i in range(seg.size()):
		var w: Dictionary=seg[i]
		var a: Vector2=w.a;var b: Vector2=w.b
		var direction: Vector2=b-a
		var distance: float=direction.length();var height: float=float(w.top)-float(w.base)
		var yaw: float=-atan2(direction.y,direction.x)
		var center:=Vector3((a.x+b.x)*.5,(float(w.base)+float(w.top))*.5,(a.y+b.y)*.5)
		var rot:=Basis(Vector3.UP,yaw)
		multi.set_instance_transform(i,Transform3D(rot.scaled(Vector3(distance,height,WALL_WIDTH)),center))
		var cs:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(distance,height,WALL_WIDTH);cs.shape=shape;cs.transform=Transform3D(rot,center);physics.add_child(cs)
	var batch:=MultiMeshInstance3D.new();batch.multimesh=multi;batch.material_override=mat;batch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;batch.name="WallsBatched";holder.add_child(batch)
	# Towers and gate architecture are prototypes with low-detail cubes.
	for tower in plan.get("towers",[]):
		var p: Vector2=tower.p;var y: float=float(tower.height)
		_box(holder,Vector3(p.x,y+4.35,p.y),Vector3(5.8,8.7,5.8),stone,true)
		_box(holder,Vector3(p.x,y+8.95,p.y),Vector3(7.6,1.1,7.6),tile,false)
	for opening in plan.get("openings",[]):
		if opening.type!="gate":continue
		var mid: Vector2=opening.point
		var tangent: Vector2=opening.get("tangent",Vector2.RIGHT)
		var half_width: float=float(opening.width)*.5
		var y: float=float(terrain.call(mid)) if terrain.is_valid() else 0.0
		var marker:=Node3D.new();marker.name="Gate_%s"%str(opening.source);marker.position=Vector3(mid.x,y,mid.y)
		marker.set_meta("opening_width_m",float(opening.width));holder.add_child(marker)
		# Preview posts remain NON-COLLIDING pending engine route/capsule QA.
		# The actual gap in wall collision remains fully accessible.
		for side in [-1.0,1.0]:
			var p: Vector2=mid+tangent*side*maxf(0,half_width-.7)
			var post_h: float=5.8 if city else 3.0
			_box(holder,Vector3(p.x,y+post_h*.5,p.y),Vector3(1.2,post_h,1.2),stone,false)
			_box(holder,Vector3(p.x,y+post_h+.3,p.y),Vector3(1.8,.6,1.8),tile,false)
		# Narrow city and courtyard gates can receive a clear-height beam.
		if half_width*2.0<=18.0:
			var length: float=2.0*maxf(0.0,half_width-1.0)
			var beam:=BoxMesh.new();beam.size=Vector3(length,.8,1.65)
			var bar:=MeshInstance3D.new();bar.mesh=beam
			var bar_mat:=StandardMaterial3D.new();bar_mat.albedo_color=tile;bar.material_override=bar_mat
			bar.position=Vector3(mid.x,y+(6.3 if city else 3.6),mid.y)
			bar.rotation.y=-atan2(tangent.y,tangent.x)
			holder.add_child(bar)
	return {"ok":true,"node":holder,"walls":seg.size(),"openings":plan.get("openings",[]).size(),"towers":plan.get("towers",[]).size()}
