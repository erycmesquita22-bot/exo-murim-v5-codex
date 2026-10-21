extends RefCounted
const Catalog=preload("res://exo_dungeon/layouts/room_catalog.gd")
const Rooms=preload("res://exo_dungeon/generator/room_planner.gd")
const Encounters=preload("res://exo_dungeon/encounters/encounter_planner.gd")
const Rewards=preload("res://exo_dungeon/encounters/reward_placement.gd")
const Traps=preload("res://exo_dungeon/encounters/trap_planner.gd")
const Validator=preload("res://exo_dungeon/generator/validator_v2.gd")
const GENERATOR_VERSION := 2
static func identity(spec: Dictionary) -> String:
 return "exo/dungeon/"+str(spec.get("world_id",""))+"/"+str(spec.get("region_id",-1))+"/"+str(spec.get("location_id",""))
static func _request_valid(spec: Dictionary) -> bool:
 if str(spec.get("world_id","")).is_empty() or str(spec.get("location_id","")).is_empty():return false
 if not spec.has("world_seed") or not spec.has("region_id"):return false
 if not Catalog.is_supported(str(spec.get("family",""))):return false
 if int(spec.get("floors",1))<1 or int(spec.get("floors",1))>4:return false
 if int(spec.get("rooms_per_floor",10))<5 or int(spec.get("rooms_per_floor",10))>24:return false
 if str(spec.get("world_id","")).length()>128 or str(spec.get("location_id","")).length()>128:return false
 if int(spec.get("difficulty",1))<1 or int(spec.get("difficulty",1))>200:return false
 return true
static func generate(spec: Dictionary) -> Dictionary:
 if not _request_valid(spec):return {"ok":false,"error":"invalid_dungeon_request"}
 var normalized: Dictionary={"world_id":str(spec.world_id),"world_seed":str(spec.world_seed),"region_id":int(spec.region_id),"location_id":str(spec.location_id),"family":str(spec.family),"floors":int(spec.get("floors",1)),"rooms_per_floor":int(spec.get("rooms_per_floor",11)),"difficulty":int(spec.get("difficulty",1))}
 var key: String="%s|%s|%s|%s|%s|v%d" % [normalized.world_id,normalized.world_seed,normalized.region_id,normalized.location_id,normalized.family,GENERATOR_VERSION]
 var last_error: String=""
 for attempt in range(3):
  var floors: Array=[];var all_rooms: Array=[];var all_links: Array=[]
  var success:=true
  for fi in range(normalized.floors):
   var floor: Dictionary=Rooms.make(fi,normalized.rooms_per_floor,key+"|a"+str(attempt),normalized.family,fi==normalized.floors-1)
   if not bool(floor.get("ok",false)):
    last_error=str(floor.get("reason","floor_failed"));success=false;break
   floors.append({"floor":fi,"entry":floor.entry,"goal":floor.goal})
   all_rooms.append_array(floor.rooms);all_links.append_array(floor.links)
   if fi>0:all_links.append({"a":floors[fi-1].goal,"b":floor.entry,"kind":"stairs_portal","requires":"","secret":false})
  if not success:continue
  var plan: Dictionary={"ok":true,"schema":1,"generator_version":GENERATOR_VERSION,"id":identity(normalized),"request":normalized,"attempt":attempt,"floors":floors,"rooms":all_rooms,"links":all_links,"entry":floors[0].entry,"objective":floors[floors.size()-1].goal}
  plan.encounters=Encounters.make(all_rooms,normalized.family,key,int(normalized.difficulty))
  plan.rewards=Rewards.make(all_rooms,normalized.family,key)
  plan.traps=Traps.make(all_rooms,key)
  plan.secrets=[]
  for room in all_rooms:
   if room.kind=="secret":plan.secrets.append({"id":"secret_"+str(room.id),"room":room.id,"clue":"environmental_marker"})
  var result: Dictionary=Validator.validate(plan)
  if bool(result.ok):
   plan.digest=JSON.stringify([plan.id,plan.rooms,plan.links,plan.encounters,plan.rewards,plan.traps]).sha256_text()
   return plan
  last_error=";".join(PackedStringArray(result.errors))
 return {"ok":false,"error":"generation_rejected","reason":last_error}
