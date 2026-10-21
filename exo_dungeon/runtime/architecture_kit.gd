extends RefCounted
## Voxel authorial por composição geométrica. Não importa recursos de terceiros.
## Ornamentos nunca ocupam o centro dos acessos de 3.2 m.
static func prism(root: Node3D,title: String,at: Vector3,scale: Vector3,material: Material,solid: bool=true) -> Node3D:
 var node:=Node3D.new()
 node.name=title
 node.position=at
 root.add_child(node)
 var visual:=MeshInstance3D.new()
 var mesh:=BoxMesh.new()
 mesh.size=scale
 visual.mesh=mesh
 visual.material_override=material
 node.add_child(visual)
 if solid:
  var body:=StaticBody3D.new()
  body.collision_layer=1
  body.collision_mask=0
  var collision:=CollisionShape3D.new()
  var shape:=BoxShape3D.new()
  shape.size=scale
  collision.shape=shape
  body.add_child(collision)
  node.add_child(body)
 return node
static func _column(root: Node3D,pos: Vector3,h: float,stone: Material,accent: Material) -> void:
 prism(root,"ColumnFoot",pos+Vector3(0,0.24,0),Vector3(1.35,0.48,1.35),stone)
 prism(root,"Column",pos+Vector3(0,h*0.5+0.4,0),Vector3(0.72,h,0.72),stone)
 prism(root,"ColumnCap",pos+Vector3(0,h+0.48,0),Vector3(1.5,0.45,1.5),accent)
static func _lantern(root: Node3D,pos: Vector3,wood: Material,accent: Material) -> void:
 prism(root,"LanternPedestal",pos+Vector3(0,0.55,0),Vector3(0.45,1.1,0.45),wood)
 prism(root,"LanternHousing",pos+Vector3(0,1.35,0),Vector3(0.9,0.65,0.9),accent,false)
 prism(root,"LanternRoof",pos+Vector3(0,1.77,0),Vector3(1.24,0.25,1.24),wood,false)
static func _shrine(root: Node3D,pos: Vector3,stone: Material,wood: Material,accent: Material) -> void:
 prism(root,"ShrineDais",pos+Vector3(0,0.24,0),Vector3(5.1,0.48,3.3),stone)
 prism(root,"ShrineAltar",pos+Vector3(0,1.05,0),Vector3(3.7,1.15,1.5),wood)
 prism(root,"ShrineRelic",pos+Vector3(0,1.9,0),Vector3(1.0,0.55,0.7),accent,false)
static func decorate(root: Node3D,room: Dictionary,family: String,stone: Material,wood: Material,accent: Material) -> void:
 var center:=Vector3(float(room.cx),float(room.floor)*12.0,float(room.cz))
 var w: float=float(room.width)
 var rim: float=w*0.5-2.0
 var kind: String=str(room.kind)
 # Ritmo por salão: quatro pilares monumentais só nas salas que exigem escala.
 if w>=18.0 and family not in ["cavern","mine"]:
  for x in [-rim,rim]:
   for z in [-rim,rim]:_column(root,center+Vector3(x,0,z),3.3,wood if family=="sect_hideout" else stone,accent)
 if family=="temple":
  for x in [-rim*0.6,rim*0.6]:
   _lantern(root,center+Vector3(x,0,-rim),wood,accent)
  if w>=20.0 and kind in ["shrine","boss","entrance"]:_shrine(root,center+Vector3(0,0,rim-3.5),stone,wood,accent)
  prism(root,"TempleCeremonialInlay",center+Vector3(0,0.03,0),Vector3(4.5,0.05,4.5),accent,false)
 elif family=="ruins":
  if w>=18.0:
   for side in [-1.0,1.0]:
    prism(root,"RuinedGallery",center+Vector3(side*rim,0.25,0),Vector3(0.8,0.5,w-7.0),stone)
  prism(root,"BrokenArchLeft",center+Vector3(-rim,1.7,-rim),Vector3(0.7,3.4,0.7),stone)
  prism(root,"BrokenArchTop",center+Vector3(-rim+1.0,3.4,-rim),Vector3(2.5,0.55,0.7),accent)
 elif family=="cavern":
  # Estalagmites quadradas periféricas, nunca no eixo principal.
  for x in [-rim,rim]:
   for z in [-rim,rim]:
    prism(root,"RockButtress",center+Vector3(x,0.9,z),Vector3(1.5,1.8,1.5),stone)
    prism(root,"StoneTip",center+Vector3(x,2.0,z),Vector3(0.72,0.8,0.72),accent)
  if w>=20.0:
   prism(root,"CaveDryLedge",center+Vector3(rim,0.35,0),Vector3(1.7,0.7,6.0),stone)
 elif family=="mine":
  for z in [-rim,rim]:
   for x in [-rim,rim]:
    prism(root,"MineBeam",center+Vector3(x,1.7,z),Vector3(0.62,3.4,0.62),wood)
  prism(root,"MineOreWall",center+Vector3(rim,0.7,-rim),Vector3(1.6,1.4,1.7),accent)
  if w>=18.0:
   for x in [-rim*0.5,rim*0.5]:
    prism(root,"MineTrack",center+Vector3(x,0.06,0),Vector3(0.25,0.12,w-6.0),wood,false)
 elif family=="sect_hideout":
  for x in [-rim,rim]:
   prism(root,"TrainingTarget",center+Vector3(x,1.0,-rim),Vector3(1.3,2.0,0.6),wood)
   prism(root,"TrainingBanner",center+Vector3(x,2.8,-rim),Vector3(0.65,1.5,0.25),accent,false)
  if w>=20.0 and kind in ["training","combat","boss"]:
   prism(root,"PracticePlatform",center+Vector3(0,0.22,rim-3.0),Vector3(7.0,0.44,4.2),wood)
 elif family=="tomb":
  for x in [-rim,rim]:
   for z in [-rim,rim]:_lantern(root,center+Vector3(x,0,z),stone,accent)
  if w>=20.0 and kind in ["boss","shrine"]:
   _shrine(root,center+Vector3(0,0,rim-3.5),stone,wood,accent)
  elif kind in ["treasure","secret"]:
   prism(root,"FuneraryStela",center+Vector3(0,1.5,rim),Vector3(2.0,3.0,0.7),stone)
 # Objetivo/entrada: uma identidade geométrica clara sem bloquear a passagem.
 if kind=="boss":
  prism(root,"BossArenaPerimeterN",center+Vector3(0,0.08,-rim+2.1),Vector3(5.5,0.16,0.35),accent,false)
  prism(root,"BossArenaPerimeterS",center+Vector3(0,0.08,rim-2.1),Vector3(5.5,0.16,0.35),accent,false)
 if kind=="entrance":
  prism(root,"EntranceFloorSeal",center+Vector3(0,0.04,0),Vector3(3.6,0.08,3.6),accent,false)
