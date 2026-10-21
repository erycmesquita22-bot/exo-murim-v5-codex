extends RefCounted
## Contexto opcional fornecido pelo Núcleo Narrativo; jamais cria fatos históricos.
static func attach(plan: Dictionary,verified_context: Dictionary) -> Dictionary:
 var out: Dictionary=plan.duplicate(true)
 out["narrative_context"]=verified_context.duplicate(true)
 return out
