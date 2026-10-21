extends RefCounted
## Verificador de planta, topologia, atalhos, progressao e objetos referenciados.
const SPACE := 16.0
static func _walk(plan: Dictionary,room_map: Dictionary,collect_keys: bool) -> Dictionary:
 var reached: Dictionary={str(plan.entry):true}
 var keys: Dictionary={}
 var loops: int=0
 var changed:=true
 while changed and loops<=room_map.size()*3:
  loops+=1
  changed=false
  if collect_keys:
   for rid in reached.keys():
    for key_id in room_map[rid].get("keys",[]):
     if not keys.has(str(key_id)):
      keys[str(key_id)]=true
      changed=true
  for link in plan.links:
   if bool(link.get("secret",false)):continue
   var requirement: String=str(link.get("requires",""))
   if not requirement.is_empty() and not keys.has(requirement):continue
   var a: String=str(link.a)
   var b: String=str(link.b)
   if reached.has(a) and not reached.has(b):
    reached[b]=true
    changed=true
   if reached.has(b) and not reached.has(a):
    reached[a]=true
    changed=true
 return {"rooms":reached,"keys":keys}
static func _validate_descriptors(items: Array,valid_rooms: Dictionary,label: String,errors: Array[String]) -> void:
 var ids: Dictionary={}
 for item in items:
  if not item is Dictionary or not item.has("id") or not item.has("room"):
   errors.append("malformed_"+label)
   continue
  var id: String=str(item.id)
  if id.is_empty() or ids.has(id):errors.append("duplicate_"+label+":"+id)
  ids[id]=true
  if not valid_rooms.has(str(item.room)):errors.append("bad_"+label+"_room:"+id)
static func validate(plan: Dictionary) -> Dictionary:
 var errors: Array[String]=[]
 var rooms: Dictionary={}
 var positions: Dictionary={}
 if not plan.has("rooms") or not plan.has("links") or not plan.has("entry") or not plan.has("objective"):
  return {"ok":false,"errors":["missing_schema_fields"]}
 if not plan.rooms is Array or not plan.links is Array:
  return {"ok":false,"errors":["invalid_collections"]}
 for room in plan.rooms:
  if not room is Dictionary or not room.has("id") or not room.has("floor") or not room.has("gx") or not room.has("gz"):
   errors.append("malformed_room")
   continue
  var id: String=str(room.id)
  if id.is_empty() or rooms.has(id):errors.append("duplicate_room:"+id)
  rooms[id]=room
  var loc: String="%s:%s:%s" % [room.floor,room.gx,room.gz]
  if positions.has(loc):errors.append("overlap:"+loc)
  positions[loc]=true
  var width: float=float(room.get("width",0))
  if width<8.0 or width>12.0:errors.append("invalid_room_width:"+id)
  if float(room.get("depth",0))!=width:errors.append("invalid_room_depth:"+id)
  if int(room.floor)<0 or int(room.floor)>3:errors.append("invalid_room_floor:"+id)
  if absf(float(room.get("cx",0))-int(room.gx)*SPACE)>0.001 or absf(float(room.get("cz",0))-int(room.gz)*SPACE)>0.001:
   errors.append("bad_center:"+id)
  if not room.get("keys",[]) is Array:errors.append("malformed_room_keys:"+id)
 if not rooms.has(str(plan.entry)) or not rooms.has(str(plan.objective)):
  errors.append("missing_entry_or_objective")
 if errors.size()>0:return {"ok":false,"errors":errors}
 var unique_keys: Dictionary={}
 for room in rooms.values():
  for key_id in room.get("keys",[]):
   var key_text: String=str(key_id)
   if key_text.is_empty() or unique_keys.has(key_text):errors.append("duplicate_key:"+key_text)
   unique_keys[key_text]=str(room.id)
 var edges: Dictionary={}
 var locks: Dictionary={}
 for link in plan.links:
  if not link is Dictionary or not link.has("a") or not link.has("b"):
   errors.append("malformed_link")
   continue
  var a: String=str(link.a)
  var b: String=str(link.b)
  if not rooms.has(a) or not rooms.has(b) or a==b:
   errors.append("missing_link_endpoint:"+a+"/"+b)
   continue
  var token: String=a+"~"+b if a<b else b+"~"+a
  if edges.has(token):errors.append("duplicate_link:"+token)
  edges[token]=true
  var ar: Dictionary=rooms[a]
  var br: Dictionary=rooms[b]
  var floor_diff: int=absi(int(ar.floor)-int(br.floor))
  var cell_distance: int=absi(int(ar.gx)-int(br.gx))+absi(int(ar.gz)-int(br.gz))
  if str(link.get("kind",""))=="stairs_portal":
   if floor_diff!=1:errors.append("invalid_floor_transition:"+token)
   if not str(link.get("requires","")).is_empty() or bool(link.get("secret",false)):
    errors.append("invalid_portal_conditions:"+token)
  elif str(link.get("kind",""))!="corridor" or floor_diff!=0 or cell_distance!=1:
   errors.append("invalid_corridor:"+token)
  if bool(link.get("secret",false)) and str(ar.kind)!="secret" and str(br.kind)!="secret":
   errors.append("unjustified_secret_link:"+token)
  var required: String=str(link.get("requires",""))
  if required.length()>100:errors.append("invalid_requirement:"+token)
  if not required.is_empty():
   locks[required]=true
   if not unique_keys.has(required):errors.append("missing_required_key:"+required)
 for key_id in unique_keys.keys():
  if not locks.has(key_id):errors.append("orphan_key:"+key_id)
 for room in rooms.values():
  if str(room.kind)=="secret":
   var has_secret_door:=false
   for edge in plan.links:
    if bool(edge.get("secret",false)) and (str(edge.a)==str(room.id) or str(edge.b)==str(room.id)):
     has_secret_door=true
     break
   if not has_secret_door:errors.append("orphan_secret:"+str(room.id))
 if errors.size()>0:return {"ok":false,"errors":errors}
 var walkthrough: Dictionary=_walk(plan,rooms,true)
 var reached: Dictionary=walkthrough.rooms
 if not reached.has(str(plan.objective)):errors.append("objective_unreachable_with_keys")
 for room in plan.rooms:
  if not reached.has(str(room.id)) and str(room.kind)!="secret":
   errors.append("required_room_unreachable:"+str(room.id))
 var before_keys: Dictionary=_walk(plan,rooms,false).rooms
 if not locks.is_empty() and before_keys.has(str(plan.objective)):
  errors.append("lock_can_be_bypassed")
 for key_id in locks.keys():
  var without_this: Dictionary=plan.duplicate(true)
  for room in without_this.rooms:
   if room.get("keys",[]).has(key_id):room["keys"].erase(key_id)
  var map_without: Dictionary={}
  for changed_room in without_this.rooms:map_without[str(changed_room.id)]=changed_room
  var without_key: Dictionary=_walk(without_this,map_without,true).rooms
  if not without_key.has(str(unique_keys[key_id])):errors.append("self_locked_key:"+key_id)
  for gated in plan.links:
   if str(gated.get("requires",""))!=key_id or bool(gated.get("secret",false)):continue
   var side_a: bool=without_key.has(str(gated.a))
   var side_b: bool=without_key.has(str(gated.b))
   if side_a==side_b:errors.append("ineffective_or_unreachable_gate:"+key_id)
 _validate_descriptors(plan.get("rewards",[]),rooms,"reward",errors)
 _validate_descriptors(plan.get("traps",[]),rooms,"trap",errors)
 _validate_descriptors(plan.get("encounters",[]),rooms,"encounter",errors)
 return {"ok":errors.is_empty(),"errors":errors,"reachable_rooms":reached.size(),"keys_obtained":walkthrough.keys.size(),"locks":locks.size()}
