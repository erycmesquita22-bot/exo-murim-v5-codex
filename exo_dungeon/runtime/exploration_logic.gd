extends RefCounted
## Proposta de interação, sem alterar HUD/input/câmera oficiais.
## O personagem deve chamar o serviço ao pressionar seu controle de interação.
static func nearby(instance: Node3D,actor: Node3D) -> Dictionary:
 if not is_instance_valid(instance) or not is_instance_valid(actor):return {"kind":"none"}
 var g: Node3D=instance.get("geometry")
 if not is_instance_valid(g):return {"kind":"none"}
 var candidates: Array=[]
 for item in g.find_children("CollectibleKey_*","Node3D",true,false):
  if item.is_queued_for_deletion():continue
  candidates.append({"kind":"key","priority":0,"node":item,"at":item.global_position,"key_id":str(item.get_meta("key_id",""))})
 for item in g.find_children("LockedSeal_*","Node3D",true,false):
  if item.is_queued_for_deletion():continue
  candidates.append({"kind":"gate","priority":1,"node":item,"at":item.global_position,"gate_id":str(item.get_meta("gate_id",""))})
 for item in g.find_children("SecretSeal_*","Node3D",true,false):
  if item.is_queued_for_deletion():continue
  candidates.append({"kind":"secret","priority":2,"node":item,"at":item.global_position,"room_id":str(item.get_meta("secret_room",""))})
 for item in g.find_children("TreasureReward_*","Node3D",true,false):
  if item.is_queued_for_deletion():continue
  candidates.append({"kind":"reward","priority":3,"node":item,"at":item.global_position,"reward_id":str(item.get_meta("exo_reward_id","")),"room_id":str(item.get_meta("exo_reward_room",""))})
 for item in g.find_children("Transition_*","Area3D",true,false):
  candidates.append({"kind":"floor","priority":3,"node":item,"at":item.global_position,"room_id":str(item.get_meta("portal_source",""))})
 candidates.append({"kind":"exit","priority":4,"at":instance.to_global(instance.call("exit_anchor")+Vector3(0,0.7,0))})
 var best: Dictionary={"kind":"none"}
 var best_score:=100000.0
 for option in candidates:
  var distance: float=actor.global_position.distance_to(option.at)
  var max_distance:=3.2 if str(option.kind)!="exit" else 2.6
  if distance>max_distance:continue
  var score: float=distance+float(option.priority)*0.01
  if score<best_score:
   best_score=score
   best=option
 return best
