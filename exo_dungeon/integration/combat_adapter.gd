extends RefCounted
## Verifica se o bestiário existente atende aos descritores. Não instancia inimigo genérico.
static func filter_available(encounters: Array,available_tags: Array) -> Dictionary:
 var ready: Array=[];var blocked: Array=[]
 for encounter in encounters:
  var allowed: Array=[]
  for tag in encounter.allowed_tags:
   if tag in available_tags:allowed.append(tag)
  if allowed.is_empty():blocked.append({"id":encounter.id,"reason":"unavailable_enemy_profile"})
  else:
   var desc: Dictionary=encounter.duplicate(true);desc.allowed_tags=allowed;ready.append(desc)
 return {"ready":ready,"blocked":blocked}
