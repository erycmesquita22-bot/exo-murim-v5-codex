extends "res://validation_r3/support.gd"
func _initialize() -> void:call_deferred("run_module")
func run_module() -> void:
 await boot("user://exo_new_module_integration.json")
 var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://exo_core/module_template/example/manifest.json"))
 manifest.entrypoint="res://exo_core/module_template/example/module.gd"
 check(w.exo_core.registry.register(manifest),"new_module_manifest")
 check(w.exo_core.initialize_module("example"),"new_module_loaded_without_legacy_changes")
 check(w.exo_core.services.invoke("example.counter","count")==0,"new_service")
 check(w.exo_core.publish("equipment_changed","example/test/1",{"item_uid":w.journey.data.equipped}).ok,"consume_real_core_event")
 check(w.exo_core.publish("equipment_changed","example/test/1",{"item_uid":w.journey.data.equipped}).ok,"duplicate_safe")
 check(w.exo_core.services.invoke("example.counter","count")==1,"single_effect")
 check(w.save_progress(),"registered_domain_saved")
 var loaded=preload("res://journey_save.gd").new(w.journey.path)
 check(loaded.load_progress() and loaded.data.get("example",{}).get("count")==1,"new_domain_reload")
 var failed: Dictionary=manifest.duplicate(true);failed.id="failed_example";failed.optional_module=true;failed.services=["failed.example"];failed.entrypoint="res://exo_core/module_template/example/failing_module.gd"
 check(w.exo_core.registry.register(failed),"optional_failure_manifest")
 var before: Dictionary=w.journey.data.duplicate(true)
 check(not w.exo_core.initialize_module("failed_example"),"optional_initializer_refused")
 check(not w.exo_core.services.has_service("failed.example") and w.journey.data==before,"optional_initializer_rollback")
 await finish("exo_core_new_module")
