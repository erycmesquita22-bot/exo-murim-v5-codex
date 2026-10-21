extends SceneTree
const WorldState=preload("res://procedural/world_state.gd")
const Migrations=preload("res://exo_core/persistence/migration_registry.gd")
const Ledger=preload("res://exo_core/persistence/receipt_ledger.gd")
const Save=preload("res://journey_save.gd")
var checks:=0
var failures: Array=[]
func test(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures.append(label)
func _initialize() -> void:
 var old: Dictionary=WorldState.create(101,"world_corep01_qa")
 var sample: Dictionary={"schema":1,"id":"world_legacy_qa","seed":101,"generation_version":1,"events":{"loot/old":{"status":"collected","item_uid":"item_4","legacy":true},"loot/wait":{"status":"pending","item_uid":"item_5"}}}
 test(WorldState.upgrade(sample),"legacy_upgrade")
 test(sample.schema==2 and sample.events.size()==1 and WorldState.has_event(sample,"loot/old"),"old_event_archived")
 test(Ledger.lookup(sample.claim_receipts,"loot/old").get("payload",{}).get("item_uid")=="item_4","legacy_payload_preserved")
 for i in range(100101):
  var key: String="loot/eco/r00/t00/m00/g%06d"%i
  if not WorldState.mark_collected(old,key):failures.append("insert_%d"%i);break
 test(old.claim_receipts.count==100101 and old.events.is_empty(),"100k_archived_without_event_cap")
 test(WorldState.valid(old),"100k_valid")
 test(not WorldState.mark_collected(old,"loot/eco/r00/t00/m00/g000000"),"old_kill_deduped")
 var duplicate_world: Dictionary=WorldState.create(102,"world_other_seed")
 test(WorldState.mark_collected(duplicate_world,"loot/eco/r00/t00/m00/g000000"),"seed_isolation")
 var core: Dictionary={"exo_core":{"schema":1,"sequence":1,"receipts":{"old/event":"a".repeat(64)},"module_versions":{}}}
 test(Migrations.upgrade(core),"core_v1_upgrade")
 test(Migrations.receipt(core.exo_core,"old/event").get("fingerprint")=="a".repeat(64),"core_receipt_preserved")
 var sav:=Save.new("user://core_persistence01p_qa.json",101)
 test(sav.write(),"native_save_write")
 var reread:=Save.new(sav.path)
 test(reread.load_progress(),"native_save_reopen")
 print("EXO_CORE_PERSISTENCE_01P_QA ",JSON.stringify({"checks":checks,"failures":failures,"engine":"godot_native"}))
 quit(0 if failures.is_empty() else 1)
