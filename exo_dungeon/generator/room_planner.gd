extends RefCounted
## Expansão espacial: árvore geradora ramificada, atalhos adicionais e papéis de salas.
const Catalog=preload("res://exo_dungeon/layouts/room_catalog.gd")
const DIRS=[Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]
const GRID_SPACING := 16.0
static func _key(v: Vector2i) -> String:
 return "%d:%d" % [v.x,v.y]
static func _edge_exists(edges: Array,a: String,b: String) -> bool:
 for edge in edges:
  if (edge.a==a and edge.b==b) or (edge.a==b and edge.b==a):return true
 return false
static func make(floor_number: int,count: int,seed_key: String,family: String,last_floor: bool) -> Dictionary:
 var rng:=RandomNumberGenerator.new();rng.seed=int(("rooms|"+seed_key+"|"+str(floor_number)).hash())
 var rooms: Array=[];var edges: Array=[];var occupied: Dictionary={}
 var origin:=Vector2i.ZERO
 var first: Dictionary={"id":"F%02d-R%02d" % [floor_number,0],"floor":floor_number,"gx":0,"gz":0,"cx":0.0,"cz":0.0,"width":10.0,"depth":10.0,"depth_graph":0,"parent":"","kind":"entrance","keys":[]}
 rooms.append(first);occupied[_key(origin)]=0
 for i in range(1,count):
  var options: Array=[]
  for candidate_index in range(rooms.size()):
   var room: Dictionary=rooms[candidate_index]
   for direction in DIRS:
    var next:Vector2i=Vector2i(int(room.gx),int(room.gz))+direction
    if abs(next.x)>10 or abs(next.y)>10 or occupied.has(_key(next)):continue
    options.append({"parent":candidate_index,"point":next})
  if options.is_empty():return {"ok":false,"reason":"no_free_cells"}
  if i==2:
   var deeper_options: Array=[]
   for choice in options:
    if int(rooms[int(choice.parent)].depth_graph)>=1:deeper_options.append(choice)
   if not deeper_options.is_empty():options=deeper_options
  var picked: Dictionary=options[rng.randi_range(0,options.size()-1)]
  var loc: Vector2i=picked.point;var parent: Dictionary=rooms[picked.parent]
  var room_id: String="F%02d-R%02d" % [floor_number,i]
  var width: float=float([8,10,12][rng.randi_range(0,2)])
  var room_new: Dictionary={"id":room_id,"floor":floor_number,"gx":loc.x,"gz":loc.y,"cx":loc.x*GRID_SPACING,"cz":loc.y*GRID_SPACING,"width":width,"depth":width,"depth_graph":int(parent.depth_graph)+1,"parent":parent.id,"kind":"common","keys":[]}
  rooms.append(room_new);occupied[_key(loc)]=i
  edges.append({"a":str(parent.id),"b":room_id,"kind":"corridor","requires":"","secret":false})
 # Fechamentos opcionais da malha criam circuitos sem remover a árvore base.
 for i in range(rooms.size()):
  for j in range(i+1,rooms.size()):
   var a: Dictionary=rooms[i];var b: Dictionary=rooms[j]
   if abs(int(a.gx)-int(b.gx))+abs(int(a.gz)-int(b.gz))!=1:continue
   if not _edge_exists(edges,str(a.id),str(b.id)) and rng.randf()<0.34:
    edges.append({"a":str(a.id),"b":str(b.id),"kind":"corridor","requires":"","secret":false})
 var goal_index:=1
 for i in range(2,rooms.size()):
  if int(rooms[i].depth_graph)>int(rooms[goal_index].depth_graph):goal_index=i
 var goal_id: String=str(rooms[goal_index].id)
 rooms[goal_index].kind="boss" if last_floor else "stairs"
 var family_bias: Dictionary=Catalog.profile(family)
 var candidates: Array=[]
 for i in range(1,rooms.size()):
  if i==goal_index:continue
  candidates.append(i)
  var roll:=rng.randf()
  if family=="mine" and roll<0.25:rooms[i].kind="resource"
  elif family=="cavern" and roll<0.20:rooms[i].kind="natural_hazard"
  elif family=="temple" and roll<0.25:rooms[i].kind="shrine"
  elif family=="sect_hideout" and roll<0.27:rooms[i].kind="training"
  elif family=="tomb" and roll<0.23:rooms[i].kind="trap"
  elif roll<0.27:rooms[i].kind="combat"
  elif roll<0.42:rooms[i].kind="treasure"
  elif roll<0.54:rooms[i].kind="rest"
  elif roll<0.65:rooms[i].kind="puzzle"
  elif roll<0.65+float(family_bias.trap_chance)*0.4:rooms[i].kind="trap"
 # Uma folha opcional pode ser camuflada sem interromper a rota principal.
 var main_path: Dictionary={goal_id:true};var current: String=goal_id
 while current!=str(rooms[0].id):
  var parent_id: String=""
  for room in rooms:
   if str(room.id)==current:parent_id=str(room.parent);break
  if parent_id.is_empty():break
  main_path[parent_id]=true;current=parent_id
 var secret_candidates: Array=[]
 for i in candidates:
  var rid: String=str(rooms[i].id)
  if main_path.has(rid):continue
  var children:=0
  for room in rooms:
   if str(room.parent)==rid:children+=1
  if children==0:secret_candidates.append(i)
 if not secret_candidates.is_empty() and rng.randf()<float(family_bias.get("secret_chance",0.62)):
  var secret_i: int=int(secret_candidates[rng.randi_range(0,secret_candidates.size()-1)])
  rooms[secret_i].kind="secret"
  for edge in edges:
   if edge.a==rooms[secret_i].id or edge.b==rooms[secret_i].id:edge.secret=true
 # Fechaduras relevantes: escolha um corte da ARVORE de salas, antes do boss.
 # Atalhos que cruzam o corte recebem a mesma exigencia, evitando desvios sem chave.
 if int(rooms[goal_index].depth_graph)>=3 and rng.randf()<0.78:
  var path_ids: Array=[goal_id]
  current=goal_id
  while current!=str(rooms[0].id):
   var next_parent: String=""
   for room in rooms:
    if str(room.id)==current:
     next_parent=str(room.parent)
     break
   if next_parent.is_empty():break
   current=next_parent
   path_ids.append(current)
  path_ids.reverse()
  var split_index: int=maxi(2,int(path_ids.size()/2))
  var lock_target: String=str(path_ids[split_index])
  var key_id: String="key_F%02d_%s" % [floor_number,lock_target]
  var subtree: Dictionary={lock_target:true}
  var growing:=true
  while growing:
   growing=false
   for room in rooms:
    if not subtree.has(str(room.id)) and subtree.has(str(room.parent)):
     subtree[str(room.id)]=true
     growing=true
  var before_gate: Array=[]
  for room in rooms:
   if not subtree.has(str(room.id)) and str(room.kind)!="secret":
    before_gate.append(room)
  # Preferir um ramo anterior, nao simplesmente entregar a chave na entrada.
  var key_room: Dictionary=rooms[0]
  var best_depth: int=-1
  for room in before_gate:
   var distance: int=int(room.depth_graph)
   if distance>best_depth and str(room.id)!=str(path_ids[split_index-1]):
    best_depth=distance
    key_room=room
  if best_depth<1:key_room=rooms[split_index-1]
  key_room["keys"].append(key_id)
  for edge in edges:
   if subtree.has(str(edge.a)) != subtree.has(str(edge.b)):
    edge.requires=key_id
 return {"ok":true,"floor":floor_number,"rooms":rooms,"links":edges,"entry":str(rooms[0].id),"goal":goal_id}
