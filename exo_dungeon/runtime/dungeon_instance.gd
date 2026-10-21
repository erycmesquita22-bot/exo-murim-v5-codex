extends Node3D
## API de jogo isolada: colheita e abertura exigem um ator fisicamente proximo.
## O coordenador oficial aplica os deltas persistentes (nenhum save paralelo).
const Renderer=preload("res://exo_dungeon/runtime/dungeon_renderer.gd")
const Validator=preload("res://exo_dungeon/generator/connectivity_validator.gd")
const Forja=preload("res://exo_dungeon/integration/forja_visual_adapter.gd")
signal transition_requested(source_room: String,target_room: String,actor: Node3D)
signal key_collected(key_id: String,room_id: String,actor: Node3D)
signal gate_unlocked(gate_id: String,key_id: String,actor: Node3D)
var plan: Dictionary={}
var geometry: Node3D
var acquired_keys: Dictionary={}
var opened_gates: Dictionary={}
var portal_pending: Dictionary={}
var arrival_guard: Dictionary={}
func materialize(data: Dictionary,persisted: Dictionary={}) -> bool:
 var verified: Dictionary=Validator.validate(data)
 if not bool(verified.ok):return false
 clear_instance()
 plan=data.duplicate(true)
 acquired_keys={}
 opened_gates={}
 portal_pending={}
 arrival_guard={}
 for key_id in persisted.get("activated",{}):
  if str(key_id).begins_with("key_"):acquired_keys[str(key_id)]=true
 for gate_id in persisted.get("opened",{}):opened_gates[str(gate_id)]=true
 geometry=Renderer.build(plan,opened_gates)
 if geometry==null:return false
 add_child(geometry)
 for node in geometry.find_children("CollectibleKey_*","Node3D",true,false):
  if acquired_keys.has(str(node.get_meta("key_id",""))):node.queue_free()
 # Real interactive loot markers are derived exclusively from plan.rewards.
 # No item enters inventory here; only Inventory + Core Save can grant it.
 for reward in plan.get("rewards",[]):
  var reward_id: String=str(reward.get("id",""))
  if reward_id.is_empty() or persisted.get("reward_receipts",{}).has(reward_id):continue
  var target: Dictionary={}
  for room in plan.get("rooms",[]):
   if str(room.get("id",""))==str(reward.get("room","")):target=room;break
  if target.is_empty():continue
  var marker:=Node3D.new();marker.name="TreasureReward_"+reward_id
  marker.set_meta("exo_reward_id",reward_id)
  marker.set_meta("exo_reward_room",str(target.id))
  marker.position=Vector3(float(target.cx)+1.3,float(target.floor)*_floor_height()+0.7,float(target.cz)-1.3)
  var mesh:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=Vector3(1.25,1.1,1.0);mesh.mesh=box
  var mat:=StandardMaterial3D.new();mat.albedo_color=Color("b88138");mesh.material_override=mat
  marker.add_child(mesh);geometry.add_child(marker)
 for secret_id in persisted.get("activated",{}):
  if str(secret_id).begins_with("secret_"):reveal_secret(str(secret_id).substr(7))
 return true
func clear_instance() -> void:
 if is_instance_valid(geometry):
  remove_child(geometry)
  geometry.queue_free()
 geometry=null
 plan={}
 acquired_keys={}
 opened_gates={}
 portal_pending={}
 arrival_guard={}
func _floor_height() -> float:
 return float(plan.get("render_metrics",{}).get("floor_height",9.0))
func exit_anchor() -> Vector3:
 return transition_anchor(str(plan.get("entry","")))
func transition_anchor(room_id: String) -> Vector3:
 for room in plan.get("rooms",[]):
  if str(room.id)==room_id:return Vector3(float(room.cx),float(room.floor)*_floor_height()+0.2,float(room.cz))
 return Vector3.ZERO
func _near(actor: Node3D,where: Vector3,limit: float=3.4) -> bool:
 if not is_instance_valid(actor):return false
 return actor.global_position.distance_to(to_global(where))<=limit
func collect_key(room_id: String,key_id: String,actor: Node3D) -> bool:
 if geometry==null or acquired_keys.has(key_id):return false
 var item_room: Dictionary={}
 for room in plan.get("rooms",[]):
  if str(room.id)==room_id and room.get("keys",[]).has(key_id):item_room=room;break
 if item_room.is_empty():return false
 var marker:=Vector3(float(item_room.cx)-2.4,float(item_room.floor)*_floor_height()+0.4,float(item_room.cz)+2.2)
 if not _near(actor,marker):return false
 acquired_keys[key_id]=true
 for node in geometry.find_children("CollectibleKey_*","Node3D",true,false):
  if str(node.get_meta("key_id",""))==key_id:node.queue_free()
 key_collected.emit(key_id,room_id,actor)
 return true
func unlock_gate(gate_id: String,actor: Node3D) -> bool:
 if geometry==null or opened_gates.has(gate_id):return false
 var location: Vector3=Vector3.ZERO
 var requirement: String=""
 for link in plan.get("links",[]):
  var a: String=str(link.a)
  var b: String=str(link.b)
  var pair_id: String=a+"~"+b if a<b else b+"~"+a
  if pair_id!=gate_id:continue
  requirement=str(link.get("requires",""))
  var room_map: Dictionary={}
  for room in plan.rooms:room_map[str(room.id)]=room
  var ra: Dictionary=room_map[a]
  var rb: Dictionary=room_map[b]
  location=Vector3((float(ra.cx)+float(rb.cx))*0.5,float(ra.floor)*_floor_height()+1.0,(float(ra.cz)+float(rb.cz))*0.5)
  break
 if requirement.is_empty() or not acquired_keys.has(requirement):return false
 if not _near(actor,location,3.4):return false
 opened_gates[gate_id]=true
 for node in geometry.find_children("LockedSeal_*","Node3D",true,false):
  if str(node.get_meta("gate_id",""))==gate_id:node.queue_free()
 gate_unlocked.emit(gate_id,requirement,actor)
 return true
func request_floor_transition(source_room: String,actor: Node3D) -> bool:
 # NUNCA teleporta por contato automatico; evita looping no portal de chegada.
 if geometry==null or not is_instance_valid(actor):return false
 var actor_id: int=actor.get_instance_id()
 if portal_pending.has(actor_id):return false
 if arrival_guard.has(actor_id):
  if _near(actor,transition_anchor(str(arrival_guard[actor_id])),4.0):return false
  arrival_guard.erase(actor_id)
 for link in plan.get("links",[]):
  if str(link.get("kind",""))!="stairs_portal":continue
  var a: String=str(link.a)
  var b: String=str(link.b)
  if source_room!=a and source_room!=b:continue
  var dst: String=b if source_room==a else a
  if not _near(actor,transition_anchor(source_room),3.0):return false
  portal_pending[actor_id]=true
  arrival_guard[actor_id]=dst
  transition_requested.emit(source_room,dst,actor)
  return true
 return false
func floor_destination(source_room: String) -> String:
 for link in plan.get("links",[]):
  if str(link.get("kind",""))!="stairs_portal":continue
  if str(link.a)==source_room:return str(link.b)
  if str(link.b)==source_room:return str(link.a)
 return ""
func acknowledge_floor_transition(actor: Node3D) -> void:
 if is_instance_valid(actor):portal_pending.erase(actor.get_instance_id())
func reveal_secret(room_id: String) -> bool:
 if geometry==null:return false
 var found:=false
 for node in geometry.find_children("SecretSeal_*","Node3D",true,false):
  if str(node.get_meta("secret_room",""))!=room_id:continue
  node.queue_free()
  found=true
 return found
func add_official_forja_decoration() -> Dictionary:
 if geometry==null:return {"status":"SKIPPED","reason":"no_active_geometry"}
 return Forja.decorate(geometry,plan)
