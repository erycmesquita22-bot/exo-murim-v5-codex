extends RefCounted
## Materialização arquitetônica V4: contornos não retangulares e malhas físicas agrupadas.
## Gerador V2/V3 continuam imutáveis; este renderer só recebe planos version=4.
const Blueprint=preload("res://exo_dungeon/layouts/architectural_blueprint.gd")
const Batch=preload("res://exo_dungeon/runtime/batched_geometry.gd")
const Catalog=preload("res://exo_dungeon/layouts/room_catalog.gd")
const STEP:=12.0
static func _mat(code: String,texture_name: String="") -> StandardMaterial3D:
 var material:=StandardMaterial3D.new()
 material.albedo_color=Color(code)
 material.roughness=1.0
 if not texture_name.is_empty():
  var path: String="res://exo_dungeon/assets/materials/"+texture_name+".png"
  if ResourceLoader.exists(path):
   material.albedo_color=Color.WHITE
   material.albedo_texture=load(path)
 return material
static func _item(parent: Node3D,title: String,at: Vector3,size: Vector3,material: Material,physical: bool=false) -> Node3D:
 var node:=Node3D.new()
 node.name=title
 node.position=at
 parent.add_child(node)
 var visual:=MeshInstance3D.new()
 var box:=BoxMesh.new()
 box.size=size
 visual.mesh=box
 visual.material_override=material
 node.add_child(visual)
 if physical:
  var body:=StaticBody3D.new()
  body.collision_layer=1
  body.collision_mask=0
  var col:=CollisionShape3D.new()
  var shape:=BoxShape3D.new()
  shape.size=size
  col.shape=shape
  body.add_child(col)
  node.add_child(body)
 return node
static func _dirs(plan: Dictionary) -> Dictionary:
 var room_map: Dictionary={}
 var openings: Dictionary={}
 for room in plan.rooms:
  room_map[str(room.id)]=room
  openings[str(room.id)]={}
 for link in plan.links:
  if str(link.kind)=="stairs_portal":continue
  var a: Dictionary=room_map[str(link.a)]
  var b: Dictionary=room_map[str(link.b)]
  var dx: int=int(b.gx)-int(a.gx)
  var dz: int=int(b.gz)-int(a.gz)
  var direction: String="east" if dx==1 else ("west" if dx==-1 else ("south" if dz==1 else "north"))
  var opposite: String={"east":"west","west":"east","north":"south","south":"north"}[direction]
  openings[str(link.a)][direction]=true
  openings[str(link.b)][opposite]=true
 return {"rooms":room_map,"doors":openings}
static func _room_sector(root: Node3D,room: Dictionary,family: String,door_sides: Dictionary,stone: Material,wood: Material,accent: Material) -> Dictionary:
 var plan: Dictionary=Blueprint.mask(room,family)
 var cells: Dictionary=plan.tiles
 var n: int=int(plan.n)
 var w: float=float(room.width)
 var cx: float=float(room.cx)
 var cz: float=float(room.cz)
 var y: float=float(room.floor)*STEP
 var h: float=float(Blueprint.FAMILY_PROFILES[family].ceiling)
 if str(room.kind)=="boss":h+=2.0
 var sector: Dictionary=Batch.begin(root,"Sector_"+str(room.id)+"_"+str(plan.shape))
 # Consolida filas de tiles em uma caixa de piso por intervalo, não por tile.
 for iz in range(n):
  var start: int=-1
  for ix in range(n+1):
   var inside: bool=ix<n and cells.has(Vector2i(ix,iz))
   if inside and start==-1:start=ix
   if not inside and start!=-1:
    var length: float=float(ix-start)*Blueprint.TILE
    var x: float=cx-w*0.5+float(ix+start)*Blueprint.TILE*0.5
    var z: float=cz-w*0.5+(float(iz)+0.5)*Blueprint.TILE
    Batch.add_box(sector,Vector3(x,y-0.25,z),Vector3(length,0.5,Blueprint.TILE),stone,"floor")
    start=-1
 var edge: Dictionary={}
 for boundary in Blueprint.contour_segments(plan,door_sides):
  var side: String=boundary.side
  var ix: int=int(boundary.x)
  var iz: int=int(boundary.z)
  var axis: int=iz if side in ["east","west"] else ix
  var offset: int=ix if side in ["east","west"] else iz
  if side in ["east","south"]:offset+=1
  var key: String=side+"|"+str(offset)
  if not edge.has(key):edge[key]=[]
  edge[key].append(axis)
 for key in edge.keys():
  var indices: Array=edge[key]
  indices.sort()
  var span_begin: int=int(indices[0])
  var previous: int=span_begin
  indices.append(99999)
  var chunks: PackedStringArray=key.split("|")
  var side: String=chunks[0]
  var offset: int=int(chunks[1])
  for i in range(1,indices.size()):
   var current: int=int(indices[i])
   if current==previous+1:
    previous=current
    continue
   var length: float=float(previous-span_begin+1)*Blueprint.TILE
   var mid: float=float(span_begin+previous+1)*Blueprint.TILE*0.5-w*0.5
   if side in ["east","west"]:
    Batch.add_box(sector,Vector3(cx-w*0.5+float(offset)*Blueprint.TILE,y+h*0.5,cz+mid),Vector3(0.55,h,length),stone,"walls")
   else:
    Batch.add_box(sector,Vector3(cx+mid,y+h*0.5,cz-w*0.5+float(offset)*Blueprint.TILE),Vector3(length,h,0.55),stone,"walls")
   span_begin=current
   previous=current
 # Marcas arquitetônicas são estruturais e coerentes, não adereços dispersos.
 var rim: float=w*0.5-2.0
 if family=="temple" or family=="tomb":
  for x in [-rim*0.44,rim*0.44]:
   for z in [-rim*0.44,rim*0.44]:
    if cells.has(Vector2i(floori((x+w*0.5)/2.0),floori((z+w*0.5)/2.0))):
     Batch.add_box(sector,Vector3(cx+x,y+h*0.40,cz+z),Vector3(0.8,h*0.8,0.8),wood,"columns")
 elif family=="mine":
  for z in [-rim*0.55,rim*0.55]:
   Batch.add_box(sector,Vector3(cx-3.0,y+1.7,cz+z),Vector3(0.55,3.4,0.55),wood,"supports")
   Batch.add_box(sector,Vector3(cx+3.0,y+1.7,cz+z),Vector3(0.55,3.4,0.55),wood,"supports")
 elif family=="sect_hideout" and w>=18:
  Batch.add_box(sector,Vector3(cx-rim*0.8,y+1.1,cz-rim*0.6),Vector3(0.6,2.2,3.4),wood,"barrack_divider")
 elif family=="ruins":
  Batch.add_box(sector,Vector3(cx-rim*0.65,y+1.1,cz+rim*0.65),Vector3(0.9,2.2,0.9),accent,"fallen_column")
 elif family=="cavern":
  for side in [-1.0,1.0]:
   Batch.add_box(sector,Vector3(cx+side*rim*0.7,y+0.8,cz+rim*0.45),Vector3(1.2,1.6,1.2),stone,"rock_buttresses")
 if str(room.kind)=="boss":
  Batch.add_box(sector,Vector3(cx,y+0.035,cz),Vector3(4.8,0.07,4.8),accent,"arena_mark",false)
 var metrics: Dictionary=Batch.finish(sector)
 for key_id in room.get("keys",[]):
  var item: Node3D=_item(root,"CollectibleKey_"+str(key_id),Vector3(cx-2.4,y+0.4,cz+2.2),Vector3(0.65,0.7,0.65),accent)
  item.set_meta("key_id",str(key_id))
 if str(room.kind) in ["treasure","secret"]:_item(root,"UnclaimedTreasureMarker",Vector3(cx,y+0.65,cz),Vector3(1.4,1.3,1.0),accent)
 if str(room.kind)=="trap":_item(root,"VisibleTrapMark",Vector3(cx,y+0.03,cz),Vector3(1.7,0.06,1.7),accent)
 return metrics
static func _id(a: String,b: String) -> String:
 return a+"~"+b if a<b else b+"~"+a
static func _add_rect_cells(cells: Dictionary,a: Vector2,b: Vector2,width: float) -> void:
 var lo_x: int=floori(minf(a.x,b.x)-width*0.5)
 var hi_x: int=ceili(maxf(a.x,b.x)+width*0.5)
 var lo_y: int=floori(minf(a.y,b.y)-width*0.5)
 var hi_y: int=ceili(maxf(a.y,b.y)+width*0.5)
 for z in range(lo_y,hi_y):
  for x in range(lo_x,hi_x):
   var center:=Vector2(float(x)+0.5,float(z)+0.5)
   var near: bool=false
   if absf(a.x-b.x)<0.01:
    near=absf(center.x-a.x)<=width*0.5 and center.y>=minf(a.y,b.y)-0.01 and center.y<=maxf(a.y,b.y)+0.01
   else:
    near=absf(center.y-a.y)<=width*0.5 and center.x>=minf(a.x,b.x)-0.01 and center.x<=maxf(a.x,b.x)+0.01
   if near:cells[Vector2i(x,z)]=true
static func _corridor_sector(root: Node3D,link: Dictionary,ra: Dictionary,rb: Dictionary,family: String,stone: Material,wood: Material,accent: Material,opened: Dictionary) -> Dictionary:
 var a:=Vector2(float(ra.cx),float(ra.cz))
 var b:=Vector2(float(rb.cx),float(rb.cz))
 var axis: Vector2=(b-a).normalized()
 var p: Vector2=a+axis*float(ra.width)*0.5
 var q: Vector2=b-axis*float(rb.width)*0.5
 var id: String=_id(str(link.a),str(link.b))
 var locked: bool=not str(link.get("requires","")).is_empty() or bool(link.get("secret",false))
 var style: Dictionary=Blueprint.corridor_profile(family,id,locked)
 var width: float=float(style.width)
 if locked:width=4.0
 var length: float=p.distance_to(q)
 var cells: Dictionary={}
 var bends: int=int(style.bend) if length>=13 else 0
 var route: Array=[p]
 if bends!=0:
  var perp:=Vector2(-axis.y,axis.x)*float(bends)
  route.append(p+axis*floorf(length*0.30))
  route.append(p+axis*floorf(length*0.30)+perp)
  route.append(q-axis*floorf(length*0.30)+perp)
  route.append(q-axis*floorf(length*0.30))
 route.append(q)
 for i in range(route.size()-1):
  _add_rect_cells(cells,route[i],route[i+1],width)
 # Recesso de exploração com sinal contextual no meio dos corredores mais longos.
 if length>=16 and bool(style.landmark) and not locked:
  var mid: Vector2=(p+q)*0.5+Vector2(-axis.y,axis.x)*float(bends)
  _add_rect_cells(cells,mid-Vector2(2,2),mid+Vector2(2,2),6.0)
 var sector: Dictionary=Batch.begin(root,"Gallery_"+id)
 var y: float=float(ra.floor)*STEP
 var bounds: Dictionary={}
 for tile in cells.keys():
  var z: int=tile.y
  if not bounds.has(z):bounds[z]=[]
  bounds[z].append(tile.x)
 for z in bounds.keys():
  var xs: Array=bounds[z]
  xs.sort()
  var first: int=int(xs[0])
  var prev: int=first
  xs.append(999999)
  for j in range(1,xs.size()):
   var current: int=int(xs[j])
   if current==prev+1:
    prev=current
    continue
   Batch.add_box(sector,Vector3((float(first+prev+1))*0.5,y-0.25,float(z)+0.5),Vector3(float(prev-first+1),0.5,1.0),stone,"corridor_floor")
   first=current
   prev=current
 # Trilhos ao longo do contorno, com vãos apenas na conexão com as salas.
 for tile in cells.keys():
  for item in [{"d":Vector2i.LEFT,"n":"w"},{"d":Vector2i.RIGHT,"n":"e"},{"d":Vector2i.UP,"n":"n"},{"d":Vector2i.DOWN,"n":"s"}]:
   if cells.has(tile+item.d):continue
   var location:=Vector2(float(tile.x)+0.5,float(tile.y)+0.5)
   var endpoint: bool=location.distance_to(p)<3.0 or location.distance_to(q)<3.0
   var entrance_end: Vector2=p if location.distance_to(p)<location.distance_to(q) else q
   var touching_door: bool=endpoint and absf((location-entrance_end).dot(axis))<1.8
   if touching_door:continue
   var wall_center:=Vector3(location.x,y+0.85,location.y)
   var dimensions:=Vector3(0.40,1.70,1.0)
   match str(item.n):
    "w":wall_center.x-=0.5
    "e":wall_center.x+=0.5
    "n":wall_center.z-=0.5;dimensions=Vector3(1.0,1.70,0.40)
    "s":wall_center.z+=0.5;dimensions=Vector3(1.0,1.70,0.40)
   Batch.add_box(sector,wall_center,dimensions,wood if family in ["mine","sect_hideout"] else stone,"gallery_guard")
 if length>=16 and bool(style.landmark) and not locked:
  Batch.add_box(sector,Vector3((p.x+q.x)*0.5,y+0.04,(p.y+q.y)*0.5),Vector3(2.0,0.08,2.0),accent,"landmark",false)
 var metrics: Dictionary=Batch.finish(sector)
 var middle:=Vector3((float(ra.cx)+float(rb.cx))*0.5,y+2.15,(float(ra.cz)+float(rb.cz))*0.5)
 var along_x: bool=absf(axis.x)>0.5
 if not str(link.get("requires","")).is_empty() and not opened.has(id):
  var gate: Node3D=_item(root,"LockedSeal_"+id,middle,Vector3(0.6,4.3,width) if along_x else Vector3(width,4.3,0.6),wood,true)
  gate.set_meta("gate_id",id)
  gate.set_meta("requires_key",str(link.requires))
 if bool(link.get("secret",false)):
  var hidden: String=str(link.a) if str(ra.kind)=="secret" else str(link.b)
  var seal: Node3D=_item(root,"SecretSeal_"+hidden,middle,Vector3(0.7,4.3,width) if along_x else Vector3(width,4.3,0.7),stone,true)
  seal.set_meta("secret_room",hidden)
 return metrics
static func build(plan: Dictionary,opened: Dictionary={}) -> Node3D:
 if int(plan.get("generator_version",0))!=4 or not bool(plan.get("ok",false)):return null
 var family: String=str(plan.request.family)
 if not Blueprint.FAMILY_PROFILES.has(family):return null
 var root:=Node3D.new()
 root.name="DungeonR2_"+family
 var palette: Array=Catalog.profile(family).palette
 var tex: String={"temple":"temple_paving","cavern":"cave_rock","tomb":"tomb_relief"}.get(family,"stone_tile")
 var floor_mat: Material=_mat(str(palette[0]),tex)
 var wood: Material=_mat(str(palette[1]),"timber_grain")
 var accent: Material=_mat(str(palette[2]),"roof_tile")
 var graphs: Dictionary=_dirs(plan)
 var stats: Dictionary={"blocks_merged":0,"solids_merged":0,"mesh_instances":0,"static_bodies":0,"colliders":0,"sectors":0}
 for room in plan.rooms:
  var r: Dictionary=_room_sector(root,room,family,graphs.doors[str(room.id)],floor_mat,wood,accent)
  for metric in r.keys():stats[metric]=int(stats[metric])+int(r[metric])
  stats.sectors=int(stats.sectors)+1
 for link in plan.links:
  if str(link.kind)=="stairs_portal":continue
  var result: Dictionary=_corridor_sector(root,link,graphs.rooms[str(link.a)],graphs.rooms[str(link.b)],family,floor_mat,wood,accent,opened)
  for metric in result.keys():stats[metric]=int(stats[metric])+int(result[metric])
  stats.sectors=int(stats.sectors)+1
 for link in plan.links:
  if str(link.kind)!="stairs_portal":continue
  var source: Dictionary=graphs.rooms[str(link.a)]
  var target: Dictionary=graphs.rooms[str(link.b)]
  for pair in [{"src":source,"dst":target},{"src":target,"dst":source}]:
   var from_room: Dictionary=pair.src
   var to_room: Dictionary=pair.dst
   var pos:=Vector3(float(from_room.cx),float(from_room.floor)*STEP+0.7,float(from_room.cz))
   _item(root,"PortalMarker",pos-Vector3(0,0.50,0),Vector3(2.5,0.28,2.5),accent)
   var area:=Area3D.new()
   area.name="Transition_"+str(from_room.id)
   area.position=pos
   area.monitoring=false
   area.collision_layer=0
   area.collision_mask=0
   area.set_meta("portal_source",str(from_room.id))
   area.set_meta("portal_target",str(to_room.id))
   root.add_child(area)
   var col:=CollisionShape3D.new()
   var shape:=BoxShape3D.new()
   shape.size=Vector3(1.8,1.0,1.8)
   col.shape=shape
   area.add_child(col)
 root.set_meta("batch_stats",stats)
 return root
