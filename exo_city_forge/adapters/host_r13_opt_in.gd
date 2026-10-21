## LEGACY REFERENCE ONLY - do NOT wire this into C3 WORK. Use host_work_opt_in.gd.
extends RefCounted
## Only used by optional, auditable R13 patch. Legacy remains untouched on any failure.
const Decorator=preload("res://exo_city_forge/adapters/settlement_plan_adapter.gd")
static func try_decorate(region: RefCounted,base_plan: Dictionary) -> Dictionary:
 var mode: String=str(ProjectSettings.get_setting("exo_murim/city_forge/mode","legacy_procedural"))
 if mode!="authored_modular":return base_plan
 var spec: Dictionary=region.get("spec")
 var scale: String=str(spec.get("settlement_scale","city"))
 var default_profile: String="rural_farming_village" if scale=="village" else "agrarian_trade_town" if scale=="town" else "rich_commercial_city"
 var profile: String=str(ProjectSettings.get_setting("exo_murim/city_forge/profile",default_profile))
 var proposed: Dictionary=Decorator.decorate_legacy(region,base_plan,profile)
 if str(proposed.get("status",""))!="ready":
  push_warning("CityForge R13 pilot: kept official legacy city: "+str(proposed.get("reason","unknown")))
  return base_plan
 return proposed.plan
