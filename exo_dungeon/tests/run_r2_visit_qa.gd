extends SceneTree
## Contrato nativo para recuperação, sem escrever disco próprio.
const Visit=preload("res://exo_dungeon/persistence/visit_recovery.gd")
const State=preload("res://exo_dungeon/persistence/dungeon_state.gd")
const Generator=preload("res://exo_dungeon/generator/dungeon_generator.gd")
var fails: Array[String]=[]
func _initialize() -> void:
 call_deferred("_run")
func check(condition: bool,label: String) -> void:
 if not condition:fails.append(label)
func _run() -> void:
 var req: Dictionary={"world_id":"RECOVERY","world_seed":1703,"region_id":18,"location_id":"tomb_01","family":"tomb","floors":2,"rooms_per_floor":10,"difficulty":3}
 var plan: Dictionary=Generator.generate(req)
 check(bool(plan.get("ok",false)),"cannot_generate")
 if not bool(plan.get("ok",false)):
  quit(1)
  return
 var state: Dictionary=State.blank()
 var prepared: Dictionary=Visit.prepare(plan,req,Vector3(12,3,17),Vector3(13,3,16))
 check(Visit.valid(prepared),"invalid_prepared")
 state.active_visit=prepared
 check(State.valid(state),"invalid_state")
 for phase in ["entering","inside","leaving","interrupted","recovery_required"]:
  var updated: Dictionary=Visit.with_phase(prepared,phase)
  check(Visit.valid(updated),"bad_phase:"+phase)
  check(Visit.recovery_report(updated).status=="RECOVERY_REQUIRED","recovery_not_required:"+phase)
 var corrupted: Dictionary=prepared.duplicate(true)
 corrupted.outside_position=[NAN,1,2]
 check(not Visit.valid(corrupted),"nan_accepted")
 corrupted=prepared.duplicate(true)
 corrupted.descriptor.location_id="WRONG"
 check(not Visit.valid(corrupted),"descriptor_mismatch")
 corrupted=prepared.duplicate(true)
 corrupted.generator_version=55
 check(not Visit.valid(corrupted),"bad_generator_version")
 var old: Dictionary={"dungeon_id":str(plan.id),"region_id":18,"outside_position":[13,3,16],"descriptor":req.duplicate(true)}
 check(Visit.valid(old),"v3_backward_recovery_missing")
 check(Visit.recovery_report(old).policy=="EXTERIOR_SAFE_SPAWN_ONLY","unsafe_legacy_recovery")
 var report: Dictionary={"suite":"r2_visit_contract_native","failures":fails,"status":"PASS" if fails.is_empty() else "FAIL"}
 print("DUNGEON_R2_VISIT_QA="+JSON.stringify(report))
 quit(0 if fails.is_empty() else 1)
