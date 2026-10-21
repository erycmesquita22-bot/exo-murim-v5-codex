extends SceneTree
const Planner=preload("res://genesis/world_planner.gd")
const Region=preload("res://genesis/region_data.gd")
func _initialize():
 var rows:Array=[]
 var failures:Array=[]
 for seed_id in ["101","816204","707","18026"]:
  var atlas:Dictionary=Planner.read_atlas("res://genesis/atlas_seed_"+seed_id+".json") if seed_id in ["101","816204"] else Planner.plan(seed_id)
  var atlas_errors:Array=Planner.validate(atlas)
  if not atlas_errors.is_empty():failures.append({"seed":seed_id,"atlas":atlas_errors})
  for rid in range(88):
   var data=Region.new(atlas,rid)
   var errors:Array=data.validate()
   rows.append({"seed":seed_id,"region":rid,"errors":errors})
   if not errors.is_empty():failures.append(rows[-1])
 FileAccess.open("res://WORK_CHECKPOINT/world-scan.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"  "))
 print("WORLD_SCAN ",JSON.stringify({"regions":rows.size(),"failures":failures,"kind":"NATIVE_DATA_NOT_PHYSICAL_WALK"}))
 quit(0 if failures.is_empty() else 1)
