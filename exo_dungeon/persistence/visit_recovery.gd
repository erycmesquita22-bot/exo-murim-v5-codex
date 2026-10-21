extends RefCounted
## Protocolo R2 de checkpoint de instância. Os dados são gravados EXCLUSIVAMENTE
## pelo save coordinator oficial; este arquivo não abre arquivos nem grava saves.
const VISIT_SCHEMA:=2
const PHASES:=["entering","inside","leaving","interrupted","recovery_required"]
static func _coord_valid(value: Variant) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and absf(float(value))<=1000000.0
static func _integer_valid(value:Variant) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and value==int(value)
static func vector_valid(value: Variant) -> bool:
 if not value is Array or value.size()!=3:return false
 for component in value:
  if not _coord_valid(component):return false
 return true
static func array_vec(v: Vector3) -> Array:
 return [v.x,v.y,v.z]
static func vec_from(value: Array) -> Vector3:
 return Vector3(float(value[0]),float(value[1]),float(value[2]))
static func valid(visit: Variant) -> bool:
 if not visit is Dictionary:return false
 if visit.is_empty():return true
 # Dados V3 preexistentes continuam legíveis apenas como contexto de RECUPERAÇÃO,
 # nunca como autorização implícita de respawn interno.
 if not visit.has("visit_schema"):
  return visit.get("dungeon_id") is String and _integer_valid(visit.get("region_id")) and vector_valid(visit.get("outside_position",null))
 if (not _integer_valid(visit.get("visit_schema")) or visit.get("visit_schema")!=VISIT_SCHEMA):return false
 if not PHASES.has(str(visit.get("phase",""))):return false
 for key in ["dungeon_id","world_id","world_seed","location_id","plan_digest"]:
  if not visit.get(key) is String or str(visit[key]).is_empty() or str(visit[key]).length()>320:return false
 if not _integer_valid(visit.get("region_id")) or int(visit.region_id)<0 or int(visit.region_id)>999999:return false
 if not _integer_valid(visit.get("generator_version")) or not [2,3,4].has(int(visit.generator_version)):return false
 if not vector_valid(visit.get("outside_position",null)) or not vector_valid(visit.get("entrance_anchor",null)):return false
 if not visit.get("descriptor") is Dictionary:return false
 var descriptor: Dictionary=visit.descriptor
 if str(descriptor.get("world_id",""))!=str(visit.world_id):return false
 if str(descriptor.get("world_seed",""))!=str(visit.world_seed):return false
 if str(descriptor.get("location_id",""))!=str(visit.location_id):return false
 if int(descriptor.get("region_id",-1))!=int(visit.region_id):return false
 return true
static func prepare(plan: Dictionary,descriptor: Dictionary,anchor: Vector3,outside_actor_position: Vector3) -> Dictionary:
 if not anchor.is_finite() or not outside_actor_position.is_finite():return {}
 var request: Dictionary=plan.get("request",{})
 var result: Dictionary={
  "visit_schema":VISIT_SCHEMA,"phase":"entering",
  "dungeon_id":str(plan.get("id","")),"plan_digest":str(plan.get("digest","")),
  "world_id":str(request.get("world_id","")),"world_seed":str(request.get("world_seed","")),
  "location_id":str(request.get("location_id","")),"region_id":int(request.get("region_id",-1)),
  "generator_version":int(plan.get("generator_version",0)),
  "entrance_anchor":array_vec(anchor),"outside_position":array_vec(outside_actor_position),
  "descriptor":request.duplicate(true)}
 return result if valid(result) else {}
static func with_phase(visit: Dictionary,next_phase: String) -> Dictionary:
 if not PHASES.has(next_phase) or not valid(visit) or visit.is_empty():return {}
 var updated: Dictionary=visit.duplicate(true)
 if updated.has("visit_schema"):
  updated.phase=next_phase
 else:
  # Visita V3 anterior permanece como registro legado para saída segura.
  updated["phase"]="recovery_required"
 return updated if valid(updated) else {}
static func recovery_report(visit: Variant) -> Dictionary:
 if not valid(visit):return {"status":"REJECTED","reason":"invalid_visit_context"}
 if visit.is_empty():return {"status":"NONE"}
 return {
  "status":"RECOVERY_REQUIRED",
  "visit_schema":int(visit.get("visit_schema",1)),
  "phase":str(visit.get("phase","legacy_unknown")),
  "region_id":int(visit.region_id),
  "dungeon_id":str(visit.dungeon_id),
  "location_id":str(visit.get("location_id",visit.get("descriptor",{}).get("location_id",""))),
  "preferred_exterior_anchor":visit.get("entrance_anchor",visit.outside_position),
  "policy":"EXTERIOR_SAFE_SPAWN_ONLY",
  "requires_worldgen_safe_spawn_validation":true,
  "save_after_recovery":true
 }
