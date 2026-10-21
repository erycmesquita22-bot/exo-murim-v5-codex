extends RefCounted
## MATERIALIZADOR DE LABORATÓRIO: blocos voxel ORIGINAIS e colisores reais.
## Sem dependência de assets externos. NÃO substitui a Forja no build comercial.
const HEIGHT_STEP:=9.0
const Catalog=preload("res://exo_dungeon/layouts/room_catalog.gd")
static func _material(hex: String,rough: float=1.0) -> StandardMaterial3D:
 var m:=StandardMaterial3D.new();m.albedo_color=Color(hex);m.roughness=rough;return m
static func _block(root: Node3D,name: String,center: Vector3,dimensions: Vector3,mat: Material,physical: bool=true) -> Node3D:
 var root_item:=Node3D.new();root_item.name=name;root_item.position=center;root.add_child(root_item)
 var mesh:=MeshInstance3D.new();mesh.name="Voxel";var box:=BoxMesh.new();box.size=dimensions;mesh.mesh=box;mesh.material_override=mat;root_item.add_child(mesh)
 if physical:
  var body:=StaticBody3D.new();body.name="Collider";body.collision_layer=1;root_item.add_child(body)
  var collider:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=dimensions;collider.shape=shape;body.add_child(collider)
 return root_item
static func _side_open(doors: Dictionary,side: String) -> bool:
 return bool(doors.get(side,false))
static func _wall(root: Node3D,center: Vector3,length: float,side: String,opened: bool,stone: Material) -> void:
 var along_x: bool=side in ["north","south"]
 var sx: float=length if along_x else 0.65
 var sz: float=0.65 if along_x else length
 if not opened:
  _block(root,"MurimWall",center+Vector3(0,2.15,0),Vector3(sx,4.3,sz),stone)
 else:
  var left: float=(length-3.2)*0.5
  if along_x:
   _block(root,"DoorSide",center+Vector3(-length*0.5+left*0.5,2.15,0),Vector3(left,4.3,sz),stone)
   _block(root,"DoorSide",center+Vector3(length*0.5-left*0.5,2.15,0),Vector3(left,4.3,sz),stone)
   _block(root,"Lintel",center+Vector3(0,3.85,0),Vector3(3.2,0.9,sz),stone)
  else:
   _block(root,"DoorSide",center+Vector3(0,2.15,-length*0.5+left*0.5),Vector3(sx,4.3,left),stone)
   _block(root,"DoorSide",center+Vector3(0,2.15,length*0.5-left*0.5),Vector3(sx,4.3,left),stone)
   _block(root,"Lintel",center+Vector3(0,3.85,0),Vector3(sx,0.9,3.2),stone)
static func _decorate(root: Node3D,room: Dictionary,family: String,stone: Material,wood: Material,accent: Material) -> void:
 var p:=Vector3(float(room.cx),float(room.floor)*HEIGHT_STEP,float(room.cz))
 var k: String=str(room.kind)
 if family=="cavern":
  _block(root,"MineralVein",p+Vector3(2,0.7,2),Vector3(0.9,1.4,0.9),accent)
  _block(root,"CaveBoulder",p+Vector3(-2,0.4,-2),Vector3(1.3,0.8,1.3),stone)
 elif family=="mine":
  for z in [-2.8,2.8]:
   _block(root,"MinePost",p+Vector3(3,1.7,z),Vector3(0.42,3.4,0.42),wood)
  _block(root,"OreStack",p+Vector3(-2,0.5,2),Vector3(1.1,1,1),accent)
 elif family=="temple":
  for x in [-3.0,3.0]:
   for z in [-3.0,3.0]:
    _block(root,"TemplePillar",p+Vector3(x,1.7,z),Vector3(0.55,3.4,0.55),stone)
 elif family=="sect_hideout":
  _block(root,"TrainingRack",p+Vector3(2.8,1.0,2.8),Vector3(0.25,2.0,1.4),wood)
 elif family=="tomb":
  _block(root,"CeremonialSlab",p+Vector3(2.6,0.45,2.4),Vector3(1.6,0.9,2.0),stone)
 elif family=="ruins":
  _block(root,"BrokenColumn",p+Vector3(-2,0.75,2),Vector3(0.9,1.5,0.9),stone)
 for room_key in room.get("keys",[]):
  var key_node: Node3D=_block(root,"CollectibleKey_"+str(room_key),p+Vector3(-2.4,0.4,2.2),Vector3(0.65,0.7,0.65),accent,false)
  key_node.set_meta("key_id",str(room_key))
 if k=="treasure" or k=="secret":
  _block(root,"UnclaimedTreasureMarker",p+Vector3(0,0.65,0),Vector3(1.4,1.3,1.0),accent)
 elif k=="boss":
  _block(root,"BossArenaGlyph",p+Vector3(0,0.06,0),Vector3(3.2,0.12,3.2),accent,false)
 elif k=="trap":
  _block(root,"VisibleTrapMark",p+Vector3(0,0.03,0),Vector3(1.5,0.06,1.5),accent,false)
 elif k=="stairs":
  _block(root,"FloorTransitionMarker",p+Vector3(0,0.14,0),Vector3(2.0,0.28,2.0),accent,false)
static func _gate_id(a: String,b: String) -> String:
 return a+"~"+b if a<b else b+"~"+a
static func build(plan: Dictionary,opened: Dictionary={}) -> Node3D:
 if not bool(plan.get("ok",false)):return null
 var root:=Node3D.new();root.name="DungeonGenesis_"+str(plan.request.family)
 var palette: Array=Catalog.profile(str(plan.request.family)).palette
 var ground: StandardMaterial3D=_material(str(palette[0]));var timber: StandardMaterial3D=_material(str(palette[1]));var accent: StandardMaterial3D=_material(str(palette[2]))
 var room_map: Dictionary={};var openings: Dictionary={}
 for room in plan.rooms:
  room_map[str(room.id)]=room;openings[str(room.id)]={}
 for link in plan.links:
  if str(link.kind)=="stairs_portal":continue
  var ra: Dictionary=room_map[str(link.a)];var rb: Dictionary=room_map[str(link.b)]
  var delta:=Vector2i(int(rb.gx)-int(ra.gx),int(rb.gz)-int(ra.gz))
  var left: String="east" if delta.x==1 else ("west" if delta.x==-1 else ("south" if delta.y==1 else "north"))
  var right: String="west" if left=="east" else ("east" if left=="west" else ("north" if left=="south" else "south"))
  openings[str(link.a)][left]=true;openings[str(link.b)][right]=true
 for room in plan.rooms:
  var node:=Node3D.new();node.name=str(room.id)+"_"+str(room.kind);root.add_child(node)
  var pos:=Vector3(float(room.cx),float(room.floor)*HEIGHT_STEP,float(room.cz))
  var size: float=float(room.width)
  _block(node,"WalkableFloor",pos+Vector3(0,-0.25,0),Vector3(size,0.5,size),ground)
  var door: Dictionary=openings[str(room.id)]
  _wall(node,pos+Vector3(0,0,-size*0.5),size,"north",_side_open(door,"north"),ground)
  _wall(node,pos+Vector3(0,0,size*0.5),size,"south",_side_open(door,"south"),ground)
  _wall(node,pos+Vector3(-size*0.5,0,0),size-0.65,"west",_side_open(door,"west"),ground)
  _wall(node,pos+Vector3(size*0.5,0,0),size-0.65,"east",_side_open(door,"east"),ground)
  _decorate(node,room,str(plan.request.family),ground,timber,accent)
 for link in plan.links:
  if str(link.kind)=="stairs_portal":continue
  var from: Dictionary=room_map[str(link.a)];var to: Dictionary=room_map[str(link.b)]
  var xa: float=float(from.cx);var za: float=float(from.cz)
  var xb: float=float(to.cx);var zb: float=float(to.cz)
  var from_p:=Vector2(xa,za);var to_p:=Vector2(xb,zb)
  var axis: Vector2=(to_p-from_p).normalized()
  var a_edge: Vector2=from_p+axis*float(from.width)*0.5
  var b_edge: Vector2=to_p-axis*float(to.width)*0.5
  var midpoint:=Vector3((a_edge.x+b_edge.x)*0.5,float(from.floor)*HEIGHT_STEP-0.25,(a_edge.y+b_edge.y)*0.5)
  var gap: float=a_edge.distance_to(b_edge)
  var dir_x: bool=absf(xa-xb)>0.01
  var size_corridor:=Vector3(gap,0.5,3.2) if dir_x else Vector3(3.2,0.5,gap)
  _block(root,"Corridor_"+str(link.a)+"_"+str(link.b),midpoint,size_corridor,ground)
  # Protecao lateral de pontes / passarelas: um ator nao despenca no vazio.
  var side_center_y: float=midpoint.y+1.1
  if dir_x:
   _block(root,"CorridorRail",Vector3(midpoint.x,side_center_y,midpoint.z-1.6),Vector3(gap,2.2,0.45),ground)
   _block(root,"CorridorRail",Vector3(midpoint.x,side_center_y,midpoint.z+1.6),Vector3(gap,2.2,0.45),ground)
  else:
   _block(root,"CorridorRail",Vector3(midpoint.x-1.6,side_center_y,midpoint.z),Vector3(0.45,2.2,gap),ground)
   _block(root,"CorridorRail",Vector3(midpoint.x+1.6,side_center_y,midpoint.z),Vector3(0.45,2.2,gap),ground)
  var required: String=str(link.get("requires",""))
  var gate_id: String=_gate_id(str(link.a),str(link.b))
  if not required.is_empty() and not opened.has(gate_id):
   var blocker: Node3D=_block(root,"LockedSeal_"+gate_id,midpoint+Vector3(0,2.15,0),Vector3(0.6,4.3,3.2) if dir_x else Vector3(3.2,4.3,0.6),timber)
   blocker.set_meta("gate_id",gate_id)
   blocker.set_meta("requires_key",required)
  if bool(link.get("secret",false)):
   var secret_room_id: String=str(link.a) if str(from.kind)=="secret" else str(link.b)
   var seal: Node3D=_block(root,"SecretSeal_"+secret_room_id,midpoint+Vector3(0,2.15,0),Vector3(0.7,4.3,3.2) if dir_x else Vector3(3.2,4.3,0.7),ground)
   seal.set_meta("secret_room",secret_room_id)
 for link in plan.links:
  if str(link.kind)!="stairs_portal":continue
  var source: Dictionary=room_map[str(link.a)];var target: Dictionary=room_map[str(link.b)]
  _block(root,"PortalEndpoint_"+str(source.id),Vector3(float(source.cx),float(source.floor)*HEIGHT_STEP+0.15,float(source.cz)),Vector3(2.5,0.3,2.5),accent,false)
  _block(root,"PortalArrival_"+str(target.id),Vector3(float(target.cx),float(target.floor)*HEIGHT_STEP+0.15,float(target.cz)),Vector3(2.5,0.3,2.5),accent,false)
  for pair in [{"src":source,"dst":target},{"src":target,"dst":source}]:
   var from_room: Dictionary=pair.src;var to_room: Dictionary=pair.dst
   var area:=Area3D.new();area.name="Transition_"+str(from_room.id);area.monitoring=false;area.collision_layer=0;area.collision_mask=0
   area.position=Vector3(float(from_room.cx),float(from_room.floor)*HEIGHT_STEP+0.7,float(from_room.cz))
   area.set_meta("portal_source",str(from_room.id));area.set_meta("portal_target",str(to_room.id))
   var cs:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(1.8,1.0,1.8);cs.shape=shape;area.add_child(cs)
   root.add_child(area)
 return root
