extends SceneTree
## R7 native QA; must be invoked after Godot Editor --import in Compatibility.
## A FAIL exits non-zero. No successful claims unless this actually executes.
const World = preload("res://genesis/world_planner.gd")
const Data = preload("res://genesis/region_data.gd")
const Builder = preload("res://exo_monumental/runtime/builder.gd")
const Portal = preload("res://exo_monumental/integration/interior_bridge.gd")
var failures:Array=[]
var attempts:=0
var placed:=0
var rejected:=0
func _initialize() -> void:
 call_deferred("run_tests")
func check(ok:bool,code:String) -> void:
 attempts+=1
 if not ok:failures.append(code)
func run_tests() -> void:
 for seed in [101,816204,707,18026]:
  var atlas:Dictionary=World.plan(str(seed))
  check(World.validate(atlas).is_empty(),"atlas_%d"%seed)
  for rid in [14,26,78]:
   var d:RefCounted=Data.new(atlas,rid)
   check(d.validate().is_empty(),"region_%d_%d"%[seed,rid])
   var second:RefCounted=Data.new(atlas,rid)
   check(JSON.stringify(d.monumental_plans)==JSON.stringify(second.monumental_plans),"determinism_%d_%d"%[seed,rid])
   for k in range(d.monumental_plans.size()):
    var plan:Dictionary=d.monumental_plans[k]
    var receipt:Dictionary=d.monumental_receipts[k]
    placed+=1
    check(Builder.validate_receipt(plan,receipt),"receipt_%d_%d"%[seed,rid])
    var portal:Dictionary=Portal.from_plan(plan)
    check(bool(portal.get("ok",false)),"portal_rotation_%d_%d"%[seed,rid])
   rejected+=d.monumental_rejections.size()
 # invalid/missing owner receipts must be refused, never treated as approvals.
 var bad:Dictionary={"ok":true,"id":"x","site_id":"x","bounds":{}}
 check(not Builder.validate_receipt(bad,{"approved":true,"authority":"WorldGenesis"}),"fake_receipt_rejected")
 print("R7 NATIVE QA checks=%d placed=%d rejected=%d FAIL=%d"%[attempts,placed,rejected,failures.size()])
 if not failures.is_empty():
  for fail in failures:push_error(str(fail))
 quit(1 if not failures.is_empty() else 0)
