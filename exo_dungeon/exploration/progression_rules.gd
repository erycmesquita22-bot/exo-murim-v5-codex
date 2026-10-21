extends RefCounted
## Exporta os requisitos existentes para o serviço de objetivos do EXO.
static func required_keys(plan: Dictionary) -> Dictionary:
 var mapping: Dictionary={}
 for room in plan.get("rooms",[]):
  for key_id in room.get("keys",[]):mapping[str(key_id)]=str(room.id)
 return mapping
static func locked_links(plan: Dictionary) -> Array:
 var out: Array=[]
 for link in plan.get("links",[]):
  if not str(link.get("requires","")).is_empty():out.append(link.duplicate(true))
 return out
