extends SceneTree
const Atlas=preload("res://genesis/world_planner.gd")
const Region=preload("res://genesis/region_data.gd")
const Planner=preload("res://fortifications/planner.gd")
func _initialize() -> void:
 for seed in ["101","816204","707"]:
  var atlas: Dictionary=Atlas.read_atlas("res://genesis/atlas_seed_"+seed+".json") if seed in ["101","816204"] else Atlas.plan(seed)
  for spec in atlas.regions:
   if spec.kind=="settlement" and spec.settlement_scale=="city":
    var result: Dictionary=Planner.plan_region(Region.new(atlas,int(spec.id)))
    print("CITY_PLAN ",seed," ",spec.id," ",result.status," ",result.get("skipped",{})," margin=",result.get("reroute_margin",0))
 quit()
