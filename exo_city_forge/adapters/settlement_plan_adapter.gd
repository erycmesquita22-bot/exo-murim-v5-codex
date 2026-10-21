extends RefCounted
## C3 WORK candidate-01: apply opt-in metadata only to Settlement.validate-approved parcels.
## Never change IDs, geometry, routes, function, form, spawn, NPCs, saves or physical scene.
const Composer=preload("res://exo_city_forge/runtime/city_composer.gd")
const Host=preload("res://exo_city_forge/adapters/worldgen_city_adapter.gd")
static func decorate_legacy(region: RefCounted,host_plan: Dictionary,profile_id: String) -> Dictionary:
 var original: Dictionary=host_plan.duplicate(true)
 if str(original.get("status",""))!="ready":return {"status":"blocked","reason":"legacy_invalid","plan":original}
 var Official: GDScript=load("res://genesis/settlements/settlement_planner.gd") as GDScript
 if Official==null or int(original.get("version",-1))!=int(Official.VERSION):return {"status":"blocked","reason":"unsupported_host_settlement_version","plan":original}
 var native_gates: Array=region.gates
 var native_rivers: Array=region.rivers
 if not Official.validate(original,native_gates,native_rivers,float(region.half),region.river_hub).is_empty():return {"status":"blocked","reason":"host_validation_failed","plan":original}
 var req: Dictionary=Host.request_from_region(region,profile_id)
 if bool(req.get("blocked_r7_contract",false)):return {"status":"blocked","reason":req.get("reason","r7_untrusted"),"plan":original}
 var city: Dictionary=Composer.compose(req)
 if str(city.get("status",""))!="ready":return {"status":"blocked","reason":city.get("errors",["city_plan_invalid"]),"plan":original}
 var enriched: Dictionary=original.duplicate(true)
 for i in range(enriched.get("lots",[]).size()):
  var lot: Dictionary=enriched.lots[i]
  var best: float=INF
  var sector: Dictionary={}
  for candidate in city.get("sectors",[]):
   var xy: Array=candidate.get("center",[])
   if xy.size()!=2:continue
   var nearest: float=lot.p.distance_squared_to(Vector2(float(xy[0]),float(xy[1])))
   if nearest<best:best=nearest;sector=candidate
  if sector.is_empty():return {"status":"blocked","reason":"no_matching_sector","plan":original}
  # Distinct metadata namespace. The *host* building ID and function remain authoritative.
  lot["city_forge_r4"]={"schema_version":1,"plan_version":"0.4.0","building_id":str(lot.id),"district_id":str(sector.get("district_id","")),"district_category":str(sector.get("category","")),"host_function":str(lot.function),"door":[lot.door.x,lot.door.y],"street_point":[lot.street_point.x,lot.street_point.y],"interior_slot":"reserved_unverified","authorized_state":"planned_semantic_only","host_geometry_verified":false,"crowd_path_approved":false,"npc_created":false}
 enriched["city_forge_r4"]={"schema_version":1,"mode":"authored_modular","profile_id":profile_id,"blueprint_id":str(city.get("blueprint_id","")),"semantic_only":true,"physical_authored_geometry":"NOT_IMPLEMENTED","crowd_zones_published":false}
 if not Official.validate(enriched,native_gates,native_rivers,float(region.half),region.river_hub).is_empty():return {"status":"blocked","reason":"host_revalidation_failed","plan":original}
 for i in range(original.lots.size()):
  var expected: Dictionary=original.lots[i]
  var actual: Dictionary=enriched.lots[i].duplicate(true)
  actual.erase("city_forge_r4")
  if JSON.stringify(expected)!=JSON.stringify(actual):return {"status":"blocked","reason":"authoritative_lot_modified","plan":original}
 var clean: Dictionary=enriched.duplicate(true)
 clean.erase("city_forge_r4")
 for i in range(clean.lots.size()):clean.lots[i].erase("city_forge_r4")
 if JSON.stringify(original)!=JSON.stringify(clean):return {"status":"blocked","reason":"authoritative_plan_modified","plan":original}
 return {"status":"ready","plan":enriched,"mode":"semantic_only_opt_in","native_qa":"NOT_RUN"}
