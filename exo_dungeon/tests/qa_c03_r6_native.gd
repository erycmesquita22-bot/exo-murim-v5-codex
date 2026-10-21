extends SceneTree
# R6 native suite. Must run under Godot 4.6.2 Compatibility, never under Python.
# All saves are in-memory mocks, never the user's user:// campaign.
const Generator=preload("res://exo_dungeon/generator/dungeon_generator.gd")
const State=preload("res://exo_dungeon/persistence/dungeon_state.gd")
const Visit=preload("res://exo_dungeon/persistence/visit_recovery.gd")
const Atomic=preload("res://exo_items/integration/atomic_reward_adapter.gd")
const WorldState=preload("res://procedural/world_state.gd")
const Instance=preload("res://exo_dungeon/runtime/dungeon_instance.gd")
class MockJourney:
 extends RefCounted
 var data: Dictionary={}
class MockHost:
 extends Node3D
 var journey: RefCounted
 var durable: Dictionary={}
 var fail_save:=false
 func save_progress() -> bool:
  if fail_save:return false
  durable=journey.get("data").duplicate(true)
  return true
var tested:=0
var failures: Array[String]=[]
func verify(ok: bool,label: String) -> void:
 tested+=1
 if not ok:failures.append(label)
func stage(domain_world: Node3D,source: String,items: Array,did: String,rid: String) -> bool:
 if items.is_empty():return false
 var root: Dictionary=domain_world.get("journey").get("data")
 if str(root.dungeon_genesis.active_visit.get("dungeon_id",""))!=did:return false
 return State.record_reward_receipt(root.dungeon_genesis,did,rid,"loot/"+source)
func make_host(request: Dictionary,plan: Dictionary,source: String) -> MockHost:
 var host:=MockHost.new()
 host.journey=MockJourney.new()
 var domain: Dictionary=State.blank()
 State.instance(domain,str(plan.id),int(plan.generator_version),str(plan.digest))
 domain.active_visit=Visit.prepare(plan,request,Vector3(3,2,5),Vector3(3,2,5))
 var root: Dictionary={"world":WorldState.create(101,"world_c03_r6_native"),"items":[],"pending_loot":[],"next_item":1,"dungeon_genesis":domain}
 host.journey.data=root
 var event_id: String="loot/"+source
 verify(WorldState.mark_pending(root.world,event_id,{"reward_id":"r6_test"}),"valid_pending_event")
 root.pending_loot.append({"source":source,"x":0.0,"y":0.0,"z":0.0,"region":14,"items":[{"kind":"material","ref":"iron","qty":2}]})
 host.durable=root.duplicate(true)
 return host
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var req: Dictionary={"world_id":"WORLD_NATIVE","world_seed":101,"region_id":14,"location_id":"cave_entrance_native","family":"cavern","floors":1,"rooms_per_floor":10,"difficulty":2,"generator_version":4}
 var first: Dictionary=Generator.generate(req)
 var again: Dictionary=Generator.generate(req)
 verify(bool(first.get("ok",false)),"generator_v4_ready")
 if not bool(first.get("ok",false)):finish();return
 verify(str(first.digest)==str(again.get("digest","")),"same_seed_same_layout")
 var other: Dictionary=req.duplicate(true)
 other.world_seed=102
 var changed: Dictionary=Generator.generate(other)
 verify(bool(changed.get("ok",false)),"different_seed_valid")
 verify(str(first.id)==str(changed.get("id","")),"same_region_location_stable_identity")
 verify(State.valid(State.blank()),"blank_state_valid")
 var entry:=Instance.new()
 get_root().add_child(entry)
 verify(entry.materialize(first,State.instance(State.blank(),str(first.id),4,str(first.digest))),"real_scene_materialized")
 if is_instance_valid(entry.geometry):
  verify(not entry.geometry.find_children("*","CollisionObject3D",true,false).is_empty(),"collision_objects_exist")
  verify(entry.plan.get("rooms",[]).size()>5,"not_empty_room")
 entry.queue_free()
 var source: String="dungeon/sha_r6_native/r001"
 var success:=make_host(req,first,source)
 var prepared: Dictionary=Atomic.prepare_pending(success.journey.data,source)
 verify(bool(prepared.get("ok",false)),"atomic_preflight")
 if bool(prepared.get("ok",false)):
  var receipt: Dictionary=Atomic.confirm_pending(success,source,str(prepared.fingerprint),Callable(self,"stage").bind(str(first.id),"r001"))
  verify(bool(receipt.get("ok",false)),"one_save_commit")
  verify(success.durable.get("items",[]).size()==1,"item_durable")
  verify(State.has_reward(success.durable.dungeon_genesis,str(first.id),"r001"),"dungeon_receipt_durable")
  verify(Atomic.inspect(success.durable,source).get("status","")=="collected","ledger_durable")
  verify(not Atomic.confirm_pending(success,source,str(prepared.fingerprint),Callable(self,"stage").bind(str(first.id),"r001")).get("ok",false),"replay_rejected")
 success.free()
 var failure:=make_host(req,first,"dungeon/failure_native/r002")
 var failed_plan: Dictionary=Atomic.prepare_pending(failure.journey.data,"dungeon/failure_native/r002")
 verify(bool(failed_plan.get("ok",false)),"failure_preflight")
 if bool(failed_plan.get("ok",false)):
  failure.fail_save=true
  var failed: Dictionary=Atomic.confirm_pending(failure,"dungeon/failure_native/r002",str(failed_plan.fingerprint),Callable(self,"stage").bind(str(first.id),"r002"))
  verify(not bool(failed.get("ok",false)),"io_failure_rejected")
  verify(not State.has_reward(failure.journey.data.dungeon_genesis,str(first.id),"r002"),"receipt_rolled_back")
  verify(failure.journey.data.items.is_empty(),"items_rolled_back")
  verify(failure.journey.data.pending_loot.size()==1,"pending_retained")
  verify(failure.durable.items.is_empty(),"disk_unchanged")
 failure.free()
 finish()
func finish() -> void:
 print("C03_R6_NATIVE="+JSON.stringify({"checks":tested,"failures":failures,"status":"PASS" if failures.is_empty() else "FAIL"}))
 quit(0 if failures.is_empty() else 1)
