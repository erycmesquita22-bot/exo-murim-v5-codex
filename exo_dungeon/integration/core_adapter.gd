extends RefCounted
## Fachada sem alteração do EXO Core: serviço 'dungeons' já registrado no entrypoint.
static func generate_from_core(core: RefCounted,location_descriptor: Dictionary) -> Dictionary:
 var answer: Variant=core.services.invoke("dungeons","plan",[location_descriptor])
 if not answer is Dictionary:return {"ok":false,"error":"dungeon_service_unavailable"}
 return answer
