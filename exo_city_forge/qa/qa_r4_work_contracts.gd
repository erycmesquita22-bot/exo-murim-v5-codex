extends SceneTree
## Execute only within extracted C3 WORK+City R4 project.
const City=preload("res://exo_city_forge/adapters/core_module_adapter.gd")
func _initialize() -> void:
 var errors: Array=[]
 var Registry=preload("res://exo_core/module_registry.gd")
 var Services=preload("res://exo_core/service_registry.gd")
 var specs: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://exo_core/modules.json"))
 if not specs is Array:
  print(JSON.stringify({"status":"FAIL","reason":"manifest_missing"}));quit(1);return
 var registry=Registry.new()
 for spec in specs:
  if not registry.register(spec):errors.append("registered:"+str(spec.get("id","")))
 if not registry.resolve():errors.append_array(registry.errors)
 if not registry.modules.has("city_forge"):errors.append("city_forge_missing")
 var services=Services.new()
 var instance=City.new()
 # No fake C3 boot here: registry/service implementations are real; module boot needs Game.
 if not services.register_service("city_forge.plans","city_forge",instance,["preview_city","compose_city","validate_city","export_city_plan","catalog_status","compatibility_status"],"0.4.0"):
  errors.append("service_rejected")
 if not services.has_service("city_forge.plans"):errors.append("service_unavailable")
 var status: Variant=services.invoke("city_forge.plans","catalog_status")
 if not status is Dictionary or int(status.get("blueprints",0))!=14:errors.append("catalog_invoke_failed")
 print(JSON.stringify({"suite":"city_r4_work_registry_harness","status":"PASS" if errors.is_empty() else "FAIL","errors":errors,"actual_exo_core_boot":"NOT_RUN","version":Engine.get_version_info()}))
 quit(0 if errors.is_empty() else 1)
