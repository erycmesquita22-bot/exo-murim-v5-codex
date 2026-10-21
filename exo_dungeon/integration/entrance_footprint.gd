extends RefCounted
## Contrato explícito de reserva de terreno: APROVAÇÃO pertence ao WorldGenesis.
## Nenhuma API de topografia, vias ou muralhas é inventada aqui.
const FAMILIES:=["ruins","cavern","temple","sect_hideout","mine","tomb"]
static func request(descriptor: Dictionary,position: Vector3,facing: float=0.0) -> Dictionary:
 var family: String=str(descriptor.get("family",""))
 if family not in FAMILIES or not position.is_finite():return {}
 var large: bool=family in ["temple","ruins","sect_hideout"]
 var radius: float=14.0 if large else 10.0
 return {"schema":1,"type":"exo_dungeon_entrance_footprint",
  "world_id":str(descriptor.get("world_id","")),
  "world_seed":str(descriptor.get("world_seed","")),
  "region_id":int(descriptor.get("region_id",-1)),
  "location_id":str(descriptor.get("location_id","")),
  "family":family,
  "position":[position.x,position.y,position.z],"yaw_radians":facing,
  "clear_radius":radius,"clear_height":8.0 if large else 6.5,
  "min_path_width":4.0,"max_walkable_slope_degrees":24.0,
  "forbidden_surfaces":["river","deep_water","road","city_wall","steep_slope","impassable_terrain"],
  "requires_safe_return_point":true,
  "reservation_owner":"worldgen_authoritative"}
static func validate_result(spec: Dictionary,result: Variant) -> bool:
 if spec.is_empty() or not result is Dictionary:return false
 if result.get("approved",false)!=true:return false
 if str(result.get("location_id",""))!=str(spec.location_id):return false
 if int(result.get("region_id",-1))!=int(spec.region_id):return false
 if not result.get("clearance_checked",false) or not result.get("nav_access_checked",false):return false
 if not result.get("return_anchor_checked",false):return false
 var pos: Variant=result.get("return_position",null)
 if not pos is Array or pos.size()!=3:return false
 for coord in pos:
  if not (coord is float or coord is int) or not is_finite(float(coord)):return false
 return true
static func evaluate(spec: Dictionary,worldgen_callback: Callable) -> Dictionary:
 if spec.is_empty():return {"ok":false,"error":"bad_footprint"}
 if not worldgen_callback.is_valid():return {"ok":false,"error":"worldgen_validator_unavailable"}
 var feedback: Variant=worldgen_callback.call(spec.duplicate(true))
 if not validate_result(spec,feedback):return {"ok":false,"error":"placement_not_authorized"}
 return {"ok":true,"placement":feedback.duplicate(true)}
