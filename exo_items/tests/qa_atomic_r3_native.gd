extends SceneTree
# Run ONLY in a COPY of EXO Core with the COMPLETE Core Persistence 01-P isolated patch.
# godot --headless --path <CORE_COPY_WITH_01P> --script res://exo_items/tests/qa_atomic_r3_native.gd
const Atomic = preload("res://exo_items/integration/atomic_reward_adapter.gd")
const WorldState = preload("res://procedural/world_state.gd")
class MockJourney:
 extends RefCounted
 var data: Dictionary = {}
class MockWorld:
 extends Node3D
 var journey: RefCounted
 var fail_save: bool = false
 var durable: Dictionary = {}
 func save_progress() -> bool:
  if fail_save: return false
  durable = journey.get("data").duplicate(true)
  return true
var checks: int = 0
var problems: Array = []
func verify(c: bool, what: String) -> void:
 checks += 1
 if not c: problems.append(what)
func setup_world(source: String="eco/r0/t0/m0/g0") -> MockWorld:
 var w: MockWorld = MockWorld.new()
 w.journey = MockJourney.new()
 var save: Dictionary = {"world":WorldState.create(73,"world_r3_native"),"items":[],"pending_loot":[],"next_item":1}
 w.journey.data = save
 var eid: String = "loot/"+source
 verify(WorldState.mark_pending(save.world,eid,{"source":source}),"create_pending")
 save.pending_loot.append({"source":source,"x":1.0,"y":0.2,"z":1.0,"region":0,"items":[{"kind":"material","ref":"iron","qty":2}]})
 w.durable=save.duplicate(true)
 return w
func _initialize() -> void:
 if not WorldState.new().has_method("mark_collected"):
  problems.append("Core Persistence 01-P absent. Do not run R3 transactions.")
  finish()
  return
 var w: MockWorld=setup_world()
 var pre: Dictionary=Atomic.prepare_pending(w.journey.data,"eco/r0/t0/m0/g0")
 verify(pre.get("ok",false),"prepare_material")
 if pre.get("ok",false):
  verify(w.journey.data.items.size()==0,"prepare_read_only")
  var commit: Dictionary=Atomic.confirm_pending(w,"eco/r0/t0/m0/g0",pre.fingerprint)
  verify(commit.get("ok",false) and commit.get("committed",false),"single_commit")
  verify(w.journey.data.items.size()==1,"one_item")
  verify(w.journey.data.pending_loot.size()==0,"drop_removed_at_commit")
  verify(Atomic.recover_pending(w.durable,"eco/r0/t0/m0/g0").get("action")=="already_committed","receipt_recovery")
  var replay: Dictionary=Atomic.confirm_pending(w,"eco/r0/t0/m0/g0",pre.fingerprint)
  verify(not replay.get("ok",false),"no_double_claim")
 w.free()
 var failing: MockWorld=setup_world("boss/first/g0")
 var fp: Dictionary=Atomic.prepare_pending(failing.journey.data,"boss/first/g0")
 verify(fp.get("ok",false),"prepare_before_save_error")
 if fp.get("ok",false):
  failing.fail_save=true
  verify(not Atomic.confirm_pending(failing,"boss/first/g0",fp.fingerprint).get("ok",false),"save_rejected")
  verify(failing.journey.data.pending_loot.size()==1 and failing.journey.data.items.is_empty(),"rollback_ram")
  failing.fail_save=false
  verify(Atomic.confirm_pending(failing,"boss/first/g0",fp.fingerprint).get("ok",false),"recovery_after_save_error")
 failing.free()
 var blocked: MockWorld=setup_world("dungeon/d0/room1/chest0")
 for k in range(24):
  blocked.journey.data.items.append({"uid":"item_%d"%(k+1),"kind":"material","ref":"iron","qty":99,"rarity":"Comum","affixes":[]})
 blocked.journey.data.next_item=25
 var r: Dictionary=Atomic.prepare_pending(blocked.journey.data,"dungeon/d0/room1/chest0")
 verify(not r.get("ok",false) and r.get("reason")=="inventory_full","full_inventory_no_claim")
 verify(blocked.journey.data.pending_loot.size()==1,"blocked_drop_retained")
 blocked.free()
 finish()
func finish() -> void:
 var summary: Dictionary={"checks":checks,"failures":problems,"status":"PASS" if problems.is_empty() else "FAIL"}
 print("QA_ATOMIC_R3_NATIVE "+JSON.stringify(summary))
 quit(0 if problems.is_empty() else 1)
