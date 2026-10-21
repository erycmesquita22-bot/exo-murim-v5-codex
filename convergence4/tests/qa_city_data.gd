extends SceneTree
func _initialize():call_deferred("run")
func run():
 var planner=preload("res://genesis/world_planner.gd")
 var data=preload("res://genesis/region_data.gd")
 var plan=preload("res://genesis/v4/world_plan.gd")
 var bad:Array=[]
 var count:int=0
 for seed in ["101","707","18026"]:
  var source:Dictionary=planner.read_atlas("res://genesis/atlas_seed_101.json") if seed=="101" else planner.plan(seed)
  var atlas:Dictionary=plan.decorate(source,"citytest")
  for r in atlas.regions:
   if r.kind!="settlement":continue
   var d:RefCounted=data.new(atlas,int(r.id))
   count+=1
   print("CITY_PLAN ",seed," ",r.id," ",r.settlement_scale," ",d.settlement_plan.get("status")," ",d.lots.size())
   if d.settlement_plan.get("status")!="ready":bad.append([seed,r.id])
 print("CITY_RESULT ",JSON.stringify({"count":count,"failures":bad}));quit(0 if bad.is_empty() else 1)
