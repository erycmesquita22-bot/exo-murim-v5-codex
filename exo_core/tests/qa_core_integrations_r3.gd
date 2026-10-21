extends SceneTree
# Godot 4.6.2 native-only suite. Never point user:// at a live campaign.
const Registry=preload("res://exo_core/module_registry.gd")
const WorldState=preload("res://procedural/world_state.gd")
const SaveCoordinator=preload("res://exo_core/persistence/save_coordinator.gd")
const Monument=preload("res://exo_monumental/generation/planner.gd")
var checks:=0
var failures: Array[String]=[]
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures.append(label)
func _initialize() -> void:
 var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://exo_core/modules.json"))
 check(parsed is Array,"manifest_is_array")
 if not parsed is Array:finish();return
 var registry: RefCounted=Registry.new()
 for spec in parsed:
  check(registry.register(spec),"manifest_registration_"+str(spec.get("id","?")))
 check(registry.resolve(),"module_dependency_graph")
 for id in ["dungeon_genesis","exo_items","bestiary","martial_catalog","monumental_plans","creature_visuals","humanoid_presets"]:
  check(registry.modules.has(id),"declared_bridge_"+id)
 check(not Monument.footprint("martial_sect",5).get("ok",false),"unapproved_rotation_rejected")
 var path: String="user://c03_r3_backup_gate_fixture.json"
 var backup: String=path+".pre-corep01.json"
 var fixture: Dictionary={"version":4,"world":WorldState.create(101,"world_core_r3_a"),"character":{"name":"Tester"},"items":[]}
 var f:=FileAccess.open(path,FileAccess.WRITE)
 check(f!=null,"fixture_created")
 if f!=null:
  f.store_string(JSON.stringify(fixture));f.close()
  var coordinator: RefCounted=SaveCoordinator.new()
  check(coordinator._migration_backup(path),"new_backup_created")
  var other: Dictionary=fixture.duplicate(true)
  other.world.id="world_core_r3_another_campaign"
  f=FileAccess.open(backup,FileAccess.WRITE)
  if f!=null:f.store_string(JSON.stringify(other));f.close()
  check(not coordinator._migration_backup(path),"unrelated_campaign_backup_rejected")
  f=FileAccess.open(backup,FileAccess.WRITE)
  if f!=null:f.store_string("{broken");f.close()
  check(not coordinator._migration_backup(path),"malformed_backup_rejected")
  f=FileAccess.open(backup,FileAccess.WRITE)
  if f!=null:f.store_string(JSON.stringify(fixture));f.close()
  check(coordinator._migration_backup(path),"valid_backup_accepted")
  DirAccess.remove_absolute(backup)
  DirAccess.remove_absolute(path)
 finish()
func finish() -> void:
 print("C03_R3_CORE_INTEGRATIONS_QA "+JSON.stringify({"checks":checks,"failures":failures,"engine":"GODOT_NATIVE"}))
 quit(0 if failures.is_empty() else 1)
