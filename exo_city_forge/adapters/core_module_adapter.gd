extends RefCounted
const Composer=preload("res://exo_city_forge/runtime/city_composer.gd")
const Registry=preload("res://exo_city_forge/runtime/city_registry.gd")
const Validator=preload("res://exo_city_forge/runtime/urban_validator.gd")
const Exporter=preload("res://exo_city_forge/runtime/city_plan_export.gd")
var core: RefCounted
func initialize(context: RefCounted) -> bool:
 if context==null or not context.services.has_method("register_service"):return false
 core=context
 var ok: bool=bool(core.services.register_service("city_forge.plans","city_forge",self,["preview_city","compose_city","validate_city","export_city_plan","catalog_status","compatibility_status"],"0.4.0"))
 if not ok:core=null
 return ok
func preview_city(request: Dictionary) -> Dictionary:return Composer.compose(request)
func compose_city(request: Dictionary) -> Dictionary:return Composer.compose(request)
func validate_city(plan: Dictionary) -> Dictionary:return Validator.validate(plan)
func export_city_plan(plan: Dictionary) -> Dictionary:return Exporter.export_plan(plan)
func catalog_status() -> Dictionary:return Registry.status()
func compatibility_status() -> Dictionary:
 return {"reference":"C3 WORK CANDIDATO 01","contract_mode":"source_inspected_native_not_run","service":"city_forge.plans","engine_test":"NOT_RUN","c3_work_integrated_candidate":true,"c3_work_native_verified":false,"npc_owner":"LivingWorld","world_owner":"WorldGenesis","persistence_owner":"SaveCoordinator","side_effects":false}
func shutdown() -> void:core=null
