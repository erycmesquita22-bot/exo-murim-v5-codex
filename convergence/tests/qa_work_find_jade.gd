extends SceneTree
const Planner=preload("res://genesis/world_planner.gd")
const Region=preload("res://genesis/region_data.gd")
const Occupancy=preload("res://convergence/martial_occupancy_r9.gd")
func _initialize():
 for seed_id in ["101","816204","707","18026"]:
  var atlas:Dictionary=Planner.read_atlas("res://genesis/atlas_seed_"+seed_id+".json") if seed_id in ["101","816204"] else Planner.plan(seed_id)
  for rid in range(88):
   var data=Region.new(atlas,rid)
   for plan in data.monumental_plans:
    if Occupancy.school_for_site(seed_id,str(plan.id),str(plan.get("school_id","")))=="exo_martial.school.mosteiro_jade":print("JADE ",seed_id," ",rid," ",plan.id)
 print("FIND_JADE_DONE")
 quit()
