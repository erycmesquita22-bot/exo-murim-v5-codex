extends RefCounted
var palette:Dictionary={}
func _material(hex_color: String) -> StandardMaterial3D:
 if palette.has(hex_color):return palette[hex_color]
 var mat:=StandardMaterial3D.new();mat.albedo_color=Color(hex_color);mat.roughness=1.0
 palette[hex_color]=mat
 return mat
func _cube(parent: Node3D,at: Vector3,size: Vector3,color: String,solid: bool=true) -> Node3D:
 var root:=Node3D.new();parent.add_child(root);root.position=at
 var instance:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=size;instance.mesh=mesh;instance.material_override=_material(color);instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;root.add_child(instance)
 if solid:
  var body:=StaticBody3D.new();body.collision_layer=4;root.add_child(body)
  var shape:=CollisionShape3D.new();var collider:=BoxShape3D.new();collider.size=size;shape.shape=collider;body.add_child(shape)
 return root
func _line(parent: Node3D,a: Vector2,b: Vector2,width: float,color: String,raise: float=.12) -> void:
 var d: Vector2=b-a
 var node: Node3D=_cube(parent,Vector3((a.x+b.x)*.5,raise,(a.y+b.y)*.5),Vector3(width,.19,d.length()),color,false)
 node.rotation.y=-atan2(d.x,d.y)
func _sector_floor(parent: Node3D,sector: Dictionary,color: String) -> void:
 var pts:=PackedVector2Array()
 for p in sector.footprint:pts.append(Vector2(float(p[0]),float(p[1])))
 var tris:=Geometry2D.triangulate_polygon(pts)
 if tris.is_empty():return
 var surf:=SurfaceTool.new();surf.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in tris:
  var point: Vector2=pts[i]
  surf.set_normal(Vector3.UP);surf.add_vertex(Vector3(point.x,-.09,point.y))
 var mesh:=surf.commit();var visual:=MeshInstance3D.new();visual.mesh=mesh;visual.material_override=_material(color)
 visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;parent.add_child(visual)
func build(parent: Node3D,b: Dictionary) -> Node3D:
 var root:=Node3D.new();parent.add_child(root);root.name=str(b.id).replace("/","_");root.position=Vector3(float(b.p[0]),0,float(b.p[1]));root.rotation.y=float(b.get("yaw",0.0))
 root.set_meta("building_id",str(b.id));root.set_meta("function",str(b.function));root.set_meta("interior_slot",bool(b.interior_slot));root.set_meta("entry_status","awaiting_physical_approval")
 var w: float=float(b.size[0]);var d: float=float(b.size[1]);var h: float=float(b.height)
 var scheme: String=str(b.function)
 var archetype: String=str(b.get("archetype","generic"))
 var wall: String="e6c78f" if scheme in ["market","inn","herbalist"] else "d9b18b" if scheme in ["smithy","warehouse"] else "e0d8b8" if scheme in ["administration","shrine"] else "a9a2a0" if scheme=="martial_school" else "d8b698"
 var roof: String="2e6f68" if scheme in ["residence","martial_school","shrine"] else "a04b37" if scheme in ["market","inn"] else "4b5960" if scheme in ["warehouse","smithy"] else "456e81"
 if archetype in ["straw_hut","farmstead_hut","animal_shed"]:wall="c9b692";roof="8a7541"
 if archetype in ["clay_house","kiln_hut"]:wall="af825f";roof="995d3b"
 if archetype in ["stilt_house","timber_house","granary","watch_hut"]:wall="ad936c";roof="74623e"
 if archetype in ["dojo_hut","small_shrine","council_hall"]:roof="377f78"
 _cube(root,Vector3(0,.14,0),Vector3(w,.28,d),"8a7963")
 _cube(root,Vector3(-w*.5+.22,h*.5,0),Vector3(.44,h,d),wall)
 _cube(root,Vector3(w*.5-.22,h*.5,0),Vector3(.44,h,d),wall)
 _cube(root,Vector3(0,h*.5,-d*.5+.22),Vector3(w,h,.44),wall)
 # Two front jambs. The 2.4m gap is actually traversable with colliders.
 var jamb: float=maxf(.4,(w-2.4)*.5)
 _cube(root,Vector3(-(2.4+jamb)*.5,h*.5,d*.5-.22),Vector3(jamb,h,.44),wall)
 _cube(root,Vector3((2.4+jamb)*.5,h*.5,d*.5-.22),Vector3(jamb,h,.44),wall)
 _cube(root,Vector3(0,h+.30,0),Vector3(w+1,.6,d+1),roof)
 _cube(root,Vector3(0,h+.70,0),Vector3(w*.83,.35,d*.85),roof)
 for x in [-w*.5+.55,w*.5-.55]:
  _cube(root,Vector3(x,h*.58,d*.5+.04),Vector3(.38,.42,.13),"554332",false)
 if scheme=="smithy":_cube(root,Vector3(w*.3,h+1.55,-d*.2),Vector3(.85,2,.85),"646366")
 if scheme=="martial_school":_cube(root,Vector3(0,h+.94,d*.20),Vector3(w*.44,.42,.4),"a8ba59",false)
 if scheme=="inn":_cube(root,Vector3(-w*.48,h*.65,d*.4),Vector3(.45,1.9,.4),"b45b32",false)
 # R3 original geometry recipes; restricted to authored standalone preview.
 # Host R13 architecture sees only official function; these extra shapes are NOT automatically imported there.
 if archetype=="stilt_house":
  _cube(root,Vector3(0,-.24,0),Vector3(w+.5,.55,d+.5),"73573a")
  for xx in [-w*.35,w*.35]:
   for zz in [-d*.35,d*.35]:_cube(root,Vector3(xx,-.8,zz),Vector3(.4,1.5,.4),"6c5138")
 if archetype=="granary":
  _cube(root,Vector3(w*.12,h+.85,-d*.12),Vector3(w*.42,1.15,d*.38),"b68c4c")
 if archetype=="animal_shed":
  for zz in [-d*.33,d*.33]:_cube(root,Vector3(w*.30,.9,zz),Vector3(.15,1.8,.15),"6b4b35")
 if archetype=="watch_hut":
  _cube(root,Vector3(0,h+1.3,0),Vector3(w*.65,1.0,d*.65),"685b41",false)
 if archetype in ["road_stall","tea_stall"]:
  _cube(root,Vector3(0,h+.85,d*.34),Vector3(w*.82,.38,d*.40),"b8563b",false)
 if archetype in ["herb_hut","loom_house"]:
  for xx in [-w*.25,w*.25]:_cube(root,Vector3(xx,.7,d*.57),Vector3(.52,.58,.52),"6c8b4d",false)
 if archetype=="kiln_hut":
  _cube(root,Vector3(-w*.3,h+.8,-d*.25),Vector3(.95,1.6,.95),"724e41",true)
 if archetype=="small_shrine":
  _cube(root,Vector3(0,1.2,d*.57),Vector3(1.1,1.3,.4),"bc9e68",false)
 if archetype=="council_hall":
  _cube(root,Vector3(0,h+.75,0),Vector3(w*.62,.5,d*.75),"386b65",false)
 if archetype=="dojo_hut":
  for xx in [-w*.25,w*.25]:_cube(root,Vector3(xx,.9,d*.70),Vector3(.22,1.8,.22),"926c44",false)

 return root
