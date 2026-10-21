extends RefCounted
## Core read-only service. WorldGenesis remains the only reservation/placement owner.
const Planner=preload("res://exo_monumental/generation/planner.gd")
var context:RefCounted
func initialize(core:RefCounted)->bool:
 context=core
 return core.services.register_service("monuments.plans","monumental_plans",self,["footprint","status","regional_receipts","available_stations"],"1.1.0")
func footprint(kind:String,yaw_quadrants:int=0)->Dictionary:
 return Planner.footprint(kind,yaw_quadrants)
func status()->Dictionary:
 var active:bool=context!=null and context.world!=null and is_instance_valid(context.world.active_region)
 var can_build:bool=bool(ProjectSettings.get_setting("exo_murim/r7/monuments_enabled",true))
 return {"registered":true,"worldgen_owner":"WorldGenesis","reservation_host":"WorldGenesis/RegionalData R7",
  "construction_authorized":can_build,"currently_loaded":active,"native_qa_approved":false,
  "approved_only_after_verified_receipt":true,"safe_for_commercial_release":false}
func regional_receipts(region_id:int)->Dictionary:
 if context==null or context.world==null or region_id<0 or region_id>=88:return {}
 var extension:Dictionary=context.world.extension().get("monumental_r7",{})
 return extension.get("regions",{}).get(str(region_id),{}).duplicate(true)
func available_stations()->Array:
 if context==null or context.world==null or not is_instance_valid(context.world.active_region):return []
 return context.world.active_region.monument_stations.duplicate(true)
func shutdown()->void:
 context=null
