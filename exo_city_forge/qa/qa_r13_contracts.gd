extends SceneTree
## Execute ONLY inside an isolated extracted R13 after CityForge files and manifest are installed.
const Adapter=preload("res://exo_city_forge/adapters/core_module_adapter.gd")
func _initialize() -> void:
 var problems: Array=[]
 var Registry=load("res://exo_core/module_registry.gd")
 var Services=load("res://exo_core/service_registry.gd")
 var Settlement=load("res://genesis/settlements/settlement_planner.gd")
 if Registry==null or Services==null or Settlement==null:
  print(JSON.stringify({"suite":"r13_core_harness","status":"BLOCKED","reason":"not_in_r13_host"}))
  quit(2)
  return
 var content: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://exo_core/modules.json"))
 if not content is Array:problems.append("manifest_not_array")
 else:
  var reg=Registry.new()
  for entry in content:
   if not reg.register(entry):problems.append("registry_rejected_"+str(entry.id))
  if not reg.resolve():problems.append("graph_invalid:"+str(reg.errors))
  var found: bool=false
  for entry in content:
   if str(entry.id)=="city_forge":found=true
  if not found:problems.append("city_forge_missing_manifest")
 # No invented Core runtime: only static Registry and ServiceRegistry are tested here.
 var services=Services.new()
 var provider: RefCounted=Adapter.new()
 if not services.register_service("city_forge.plans","city_forge",provider,["preview_city","compose_city","validate_city","export_city_plan","catalog_status","compatibility_status"],"0.1.0"):problems.append("registry_service_failed")
 var sample: Dictionary={"region_id":26,"region_seed":"816204","kind":"settlement","settlement_scale":"city","profile_id":"poor_martial_city","blueprint_id":"irregular_hillside","half_extent":256,"gates":[[0,-230]],"rivers":[],"monument_reservations":[],"mode":"authored_modular"}
 var result: Variant=services.invoke("city_forge.plans","compose_city",[sample])
 if not result is Dictionary or str(result.get("status",""))!="ready":problems.append("service_invoke_failed")
 print(JSON.stringify({"suite":"r13_core_harness_real_registry","status":"PASS" if problems.is_empty() else "FAIL","errors":problems,"full_c3_boot":"NOT_RUN","r13_settlement_version":Settlement.VERSION}))
 quit(0 if problems.is_empty() else 1)
