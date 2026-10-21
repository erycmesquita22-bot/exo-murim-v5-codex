extends RefCounted
## Snapshot mínimo; plano regenerado pela seed, alterações guardadas pelo coordenador central.
const SCHEMA:=1
const Visit=preload("res://exo_dungeon/persistence/visit_recovery.gd")
static func blank() -> Dictionary:
 return {"schema":SCHEMA,"instances":{},"active_visit":{}}
static func _nonnegative_integer(value: Variant) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and int(value)==value and float(value)>=0.0
static func valid(state: Variant) -> bool:
 if not state is Dictionary or state.get("schema",-1)!=SCHEMA:return false
 if not state.get("instances") is Dictionary:return false
 if state.has("active_visit") and not Visit.valid(state.active_visit):return false
 for instance_id in state.instances:
  var state_i: Variant=state.instances[instance_id]
  if not state_i is Dictionary:return false
  for field in ["discovered","opened","activated","reward_receipts","bosses_defeated"]:
   if not state_i.get(field) is Dictionary:return false
  if not _nonnegative_integer(state_i.get("visits")) or not _nonnegative_integer(state_i.get("generator_version")):return false
  if not state_i.get("plan_digest","") is String:return false
 return true
static func instance(state: Dictionary,instance_id: String,generator_version: int,plan_digest: String="") -> Dictionary:
 var all_instances: Dictionary=state.instances
 if not all_instances.has(instance_id):
  all_instances[instance_id]={"generator_version":generator_version,"plan_digest":plan_digest,"discovered":{},"opened":{},"activated":{},"reward_receipts":{},"bosses_defeated":{},"visits":0}
 return all_instances[instance_id]
static func mark(state: Dictionary,instance_id: String,category: String,item_id: String) -> bool:
 if category not in ["discovered","opened","activated","bosses_defeated"] or item_id.is_empty() or item_id.length()>160:return false
 var item_state: Dictionary=instance(state,instance_id,1)
 item_state[category][item_id]=true
 return true
static func has_reward(state: Dictionary,instance_id: String,reward_id: String) -> bool:
 if not state.instances.has(instance_id):return false
 return state.instances[instance_id].reward_receipts.has(reward_id)
static func record_reward_receipt(state: Dictionary,instance_id: String,reward_id: String,receipt: String) -> bool:
 # O chamador tem que conceder o item pelo serviço oficial, dentro da mesma transação.
 # NÃO se trata de método de concessão de loot nem de autorização para duplicação.
 if reward_id.is_empty() or receipt.is_empty() or has_reward(state,instance_id,reward_id):return false
 var item_state: Dictionary=instance(state,instance_id,1)
 item_state.reward_receipts[reward_id]=receipt
 return true
