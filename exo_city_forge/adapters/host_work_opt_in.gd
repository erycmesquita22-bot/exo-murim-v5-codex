extends RefCounted
## C3 Work-only guarded hook. Default is strict no-op for all legacy saves and regions.
const Decorator=preload("res://exo_city_forge/adapters/settlement_plan_adapter.gd")
static func try_decorate(region: RefCounted,host_plan: Dictionary) -> Dictionary:
 var mode: String=str(ProjectSettings.get_setting("exo_murim/city_forge/mode","legacy_procedural"))
 if mode!="authored_modular":return host_plan
 if str(region.spec.get("kind",""))!="settlement":return host_plan
 if str(host_plan.get("status",""))!="ready":return host_plan
 var scale: String=str(region.spec.get("settlement_scale",""))
 var default_profile: String="rural_farming_village" if scale=="village" else "agrarian_trade_town" if scale=="town" else "rich_commercial_city"
 var profile: String=str(ProjectSettings.get_setting("exo_murim/city_forge/profile",default_profile))
 var result: Dictionary=Decorator.decorate_legacy(region,host_plan,profile)
 if str(result.get("status",""))!="ready":
  push_warning("EXO City Forge R4 opt-in safely kept original plan: "+str(result.get("reason","unknown")))
  return host_plan
 return result.plan
