extends SceneTree
## Godot nativo: godot --headless --path . --script res://exo_dungeon/tests/run_qa.gd
const Generator=preload("res://exo_dungeon/generator/dungeon_generator.gd")
const Validator=preload("res://exo_dungeon/generator/connectivity_validator.gd")
const State=preload("res://exo_dungeon/persistence/dungeon_state.gd")
const CoreQA=preload("res://exo_dungeon/tests/test_core_contract.gd")
const FAMILIES=["ruins","cavern","temple","sect_hideout","mine","tomb"]
var failures: Array[String]=[]
var samples:=0;var valid_plans:=0;var rejected_plans:=0;var distinct_digests: Dictionary={};var repaired_plans:=0;var floor_counts: Dictionary={};var gated_plans:=0;var secret_plans:=0;var worst_rooms:=0
func _initialize() -> void:
 call_deferred("_run")
func _require(ok: bool,description: String) -> void:
 if not ok and failures.size()<100:failures.append(description)
func _run() -> void:
 var began: int=Time.get_ticks_msec()
 for family in FAMILIES:
  for seed_index in range(1200):
   samples+=1
   var config: Dictionary={"world_id":"QA","world_seed":seed_index,"region_id":14+seed_index%88,"location_id":"LOCATION_%d" % (seed_index%7),"family":family,"floors":1+seed_index%4,"rooms_per_floor":8+seed_index%13,"difficulty":1+seed_index%12}
   var generated: Dictionary=Generator.generate(config)
   if not bool(generated.get("ok",false)):
    rejected_plans+=1;_require(false,"generation:%s:%d:%s" % [family,seed_index,str(generated)]);continue
   valid_plans+=1
   worst_rooms=maxi(worst_rooms,generated.rooms.size())
   floor_counts[str(config.floors)]=int(floor_counts.get(str(config.floors),0))+1
   var has_gate:=false
   for link in generated.links:
    if not str(link.get("requires","")).is_empty():has_gate=true
   if has_gate:gated_plans+=1
   if not generated.secrets.is_empty():secret_plans+=1
   var check: Dictionary=Validator.validate(generated)
   _require(bool(check.ok),"validation:%s:%d:%s" % [family,seed_index,str(check.errors)])
   var second: Dictionary=Generator.generate(config)
   _require(bool(second.get("ok",false)) and generated.digest==second.get("digest",null),"nondeterministic:%s:%d" % [family,seed_index])
   distinct_digests[str(generated.digest)]=true
   if seed_index==0:_hostile_tests(generated)
 _require(distinct_digests.size()>samples*0.97,"low_diversity")
 _state_tests()
 var core_contract: Dictionary=CoreQA.run()
 _require(bool(core_contract.ok),"core_contract:"+str(core_contract.get("errors",[])))
 var ms: int=Time.get_ticks_msec()-began
 var report: Dictionary={"suite":"DungeonGenesisNativeQA","engine":Engine.get_version_info().get("string","unknown"),"attempts":samples,"valid":valid_plans,"rejected":rejected_plans,"corrected":repaired_plans,"unique_digests":distinct_digests.size(),"cases_adversarial":54,"gated_plans":gated_plans,"plans_with_secret":secret_plans,"floor_counts":floor_counts,"max_rooms":worst_rooms,"duration_ms":ms,"failures":failures,"result":"PASS" if failures.is_empty() else "FAIL"}
 var log:=FileAccess.open("user://dungeon_genesis_qa_results.json",FileAccess.WRITE)
 if log!=null:log.store_string(JSON.stringify(report,"  "));log.close()
 print("DUNGEON_QA_REPORT="+JSON.stringify(report))
 quit(0 if failures.is_empty() else 1)
func _hostile_tests(original: Dictionary) -> void:
 var broken: Dictionary=original.duplicate(true)
 broken.links.clear()
 _require(not Validator.validate(broken).ok,"adversarial_disconnected")
 broken=original.duplicate(true);broken.rooms.append(broken.rooms[0].duplicate(true))
 _require(not Validator.validate(broken).ok,"adversarial_overlap")
 broken=original.duplicate(true);broken.links[0].a="GHOST_ROOM"
 _require(not Validator.validate(broken).ok,"adversarial_broken_endpoint")
 broken=original.duplicate(true)
 for link in broken.links:link.requires="unobtainable_key"
 _require(not Validator.validate(broken).ok,"adversarial_unreachable_lock")
 broken=original.duplicate(true);broken.rooms[0].width=999.0
 _require(not Validator.validate(broken).ok,"adversarial_oversized_room")
 broken=original.duplicate(true);broken.links.append(broken.links[0].duplicate(true))
 _require(not Validator.validate(broken).ok,"adversarial_duplicate_link")
 broken=original.duplicate(true);broken.rooms[0].cx=float(broken.rooms[0].cx)+0.25
 _require(not Validator.validate(broken).ok,"adversarial_bad_center")
 broken=original.duplicate(true);broken.links[0].kind="stairs_portal"
 _require(not Validator.validate(broken).ok,"adversarial_bad_stairs")
 broken=original.duplicate(true);broken.rewards.append({"id":"broken","room":"MISSING"})
 _require(not Validator.validate(broken).ok,"adversarial_missing_reward")
func _state_tests() -> void:
 var state: Dictionary=State.blank()
 _require(State.valid(state),"empty_state_valid")
 _require(State.mark(state,"d1","discovered","r1"),"discover")
 var entry: Dictionary=State.instance(state,"d1",1)
 entry.visits+=1
 _require(entry.discovered.has("r1"),"discovery_persisted")
 _require(State.record_reward_receipt(state,"d1","loot_1","receipt_001"),"first_receipt")
 _require(not State.record_reward_receipt(state,"d1","loot_1","receipt_002"),"duplicate_receipt")
 _require(State.has_reward(state,"d1","loot_1"),"receipt_visible")
 _require(State.valid(JSON.parse_string(JSON.stringify(state))),"state_json_roundtrip")
 var future: Dictionary=state.duplicate(true);future.schema=2
 _require(not State.valid(future),"reject_future_state")
 _require(not State.mark(state,"d1","illegal_domain","r1"),"reject_bad_field")
