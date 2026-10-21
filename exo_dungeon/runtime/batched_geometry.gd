extends RefCounted
## Surface batching por setor + UM único StaticBody3D/ConcavePolygonShape3D estático.
## Não cria Node3D/MeshInstance/StaticBody/Shape por bloco.
const CORNERS:=[
 [Vector3(-1,-1,1),Vector3(1,-1,1),Vector3(1,1,1),Vector3(-1,1,1)],
 [Vector3(1,-1,-1),Vector3(-1,-1,-1),Vector3(-1,1,-1),Vector3(1,1,-1)],
 [Vector3(-1,1,1),Vector3(1,1,1),Vector3(1,1,-1),Vector3(-1,1,-1)],
 [Vector3(-1,-1,-1),Vector3(1,-1,-1),Vector3(1,-1,1),Vector3(-1,-1,1)],
 [Vector3(1,-1,1),Vector3(1,-1,-1),Vector3(1,1,-1),Vector3(1,1,1)],
 [Vector3(-1,-1,-1),Vector3(-1,-1,1),Vector3(-1,1,1),Vector3(-1,1,-1)]
]
const NORMALS:=[Vector3.BACK,Vector3.FORWARD,Vector3.UP,Vector3.DOWN,Vector3.RIGHT,Vector3.LEFT]
static func begin(parent: Node3D,title: String) -> Dictionary:
 var sector:=Node3D.new()
 sector.name=title
 parent.add_child(sector)
 return {"node":sector,"surfaces":{},"collisions":PackedVector3Array(),"blocks":0,"solids":0}
static func add_box(sector: Dictionary,at: Vector3,size: Vector3,material: Material,material_key: String,solid: bool=true) -> void:
 if size.x<=0.01 or size.y<=0.01 or size.z<=0.01:return
 var surfaces: Dictionary=sector.surfaces
 if not surfaces.has(material_key):
  surfaces[material_key]={"material":material,"vertices":PackedVector3Array(),"normals":PackedVector3Array(),"uvs":PackedVector2Array()}
 var bucket: Dictionary=surfaces[material_key]
 var vertices: PackedVector3Array=bucket.vertices
 var normals: PackedVector3Array=bucket.normals
 var uvs: PackedVector2Array=bucket.uvs
 var collision_faces: PackedVector3Array=sector.collisions
 var uv_quad: Array=[Vector2.ZERO,Vector2(1,0),Vector2.ONE,Vector2(0,1)]
 for fi in range(6):
  var face: Array=CORNERS[fi]
  var positions: Array=[]
  for point in face:positions.append(at+Vector3(point.x*size.x*0.5,point.y*size.y*0.5,point.z*size.z*0.5))
  for idx in [0,1,2,0,2,3]:
   vertices.append(positions[idx])
   normals.append(NORMALS[fi])
   uvs.append(uv_quad[idx])
   if solid:collision_faces.append(positions[idx])
 bucket.vertices=vertices
 bucket.normals=normals
 bucket.uvs=uvs
 surfaces[material_key]=bucket
 sector.surfaces=surfaces
 sector.collisions=collision_faces
 sector.blocks=int(sector.blocks)+1
 if solid:sector.solids=int(sector.solids)+1
static func finish(sector: Dictionary) -> Dictionary:
 var node: Node3D=sector.node
 var surface_count:=0
 for key in sector.surfaces.keys():
  var data: Dictionary=sector.surfaces[key]
  var arrays: Array=[]
  arrays.resize(Mesh.ARRAY_MAX)
  arrays[Mesh.ARRAY_VERTEX]=data.vertices
  arrays[Mesh.ARRAY_NORMAL]=data.normals
  arrays[Mesh.ARRAY_TEX_UV]=data.uvs
  var array_mesh:=ArrayMesh.new()
  array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
  array_mesh.surface_set_material(0,data.material)
  var visual:=MeshInstance3D.new()
  visual.name="Batch_"+str(key)
  visual.mesh=array_mesh
  node.add_child(visual)
  surface_count+=1
 var triangles: PackedVector3Array=sector.collisions
 if triangles.size()>0:
  var body:=StaticBody3D.new()
  body.name="StaticSector"
  body.collision_layer=1
  body.collision_mask=0
  var shape:=ConcavePolygonShape3D.new()
  shape.set_faces(triangles)
  var collider:=CollisionShape3D.new()
  collider.shape=shape
  body.add_child(collider)
  node.add_child(body)
 return {"blocks_merged":int(sector.blocks),"solids_merged":int(sector.solids),"mesh_instances":surface_count,"static_bodies":1 if triangles.size()>0 else 0,"colliders":1 if triangles.size()>0 else 0}
