extends RefCounted
const State=preload("res://exo_dungeon/persistence/dungeon_state.gd")
## Identificação estável. Descoberta deve vir do controlador de interação oficial.
static func clues(plan: Dictionary) -> Array:
 var out: Array=[]
 for secret in plan.get("secrets",[]):
  out.append({"secret_id":secret.id,"room_id":secret.room,"hint":"afresco_deslocado_ou_rachadura","interact_type":"inspect_wall"})
 return out
static func discover(state: Dictionary,plan: Dictionary,room_id: String) -> bool:
 var known:=false
 for secret in plan.get("secrets",[]):
  if str(secret.room)==room_id:known=true;break
 if not known:return false
 return State.mark(state,str(plan.id),"discovered",room_id)
