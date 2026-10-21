extends SceneTree
## Executar: godot --headless --path . --script res://cidade_viva/tests/qa_cidade_viva.gd
const World=preload("res://genesis/world_planner.gd")
const Region=preload("res://genesis/region_data.gd")
const Urban=preload("res://cidade_viva/planner.gd")
const Walls=preload("res://fortifications/planner.gd")
var checked:=0
var failed: Array=[]
func fail(message: String) -> void:
 failed.append(message);push_error(message)
func _initialize() -> void:
 for seed in ["101","816204","707","18026"]:
  var atlas: Dictionary=World.read_atlas("res://genesis/atlas_seed_"+seed+".json") if seed in ["101","816204"] else World.plan(seed)
  for region in atlas.regions:
   if region.kind!="settlement":continue
   var data:=Region.new(atlas,int(region.id))
   if data.settlement_plan.get("status","")!="ready":continue
   var wall: Dictionary=Walls.plan_region(data) if data.spec.settlement_scale=="city" else {"status":"not_applicable"}
   if data.spec.settlement_scale=="city" and wall.status!="ready":continue
   var before: String=JSON.stringify(data.settlement_plan)
   var a: Dictionary=Urban.plan(data,wall)
   var b: Dictionary=Urban.plan(data,wall)
   if a.status!="ready":fail(seed+"/"+str(region.id)+":not_ready");continue
   if JSON.stringify(a)!=JSON.stringify(b):fail(seed+"/"+str(region.id)+":nondeterministic")
   var defects: Array=Urban.validate(a,data,wall)
   if not defects.is_empty():fail(seed+"/"+str(region.id)+":"+str(defects))
   if before!=JSON.stringify(data.settlement_plan):fail(seed+"/"+str(region.id)+":mutated_genesis")
   if a.activity_pois.size()!=data.lots.size():fail(seed+"/"+str(region.id)+":poi_missing")
   checked+=1
 for id in [78,14,26]:
  var atlas: Dictionary=World.read_atlas("res://genesis/atlas_seed_101.json")
  var d:=Region.new(atlas,id)
  if d.spec.kind!="settlement":fail("regression_region_not_settlement:"+str(id))
 print("CIDADE_VIVA_QA ",JSON.stringify({"checked":checked,"failed":failed,"status":"PASS" if failed.is_empty() and checked>0 else "FAIL"}))
 quit(0 if failed.is_empty() and checked>0 else 1)
