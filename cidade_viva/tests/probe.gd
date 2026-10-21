extends SceneTree
const W=preload("res://genesis/world_planner.gd")
const D=preload("res://genesis/region_data.gd")
const P=preload("res://cidade_viva/planner.gd")
const F=preload("res://fortifications/planner.gd")
func _initialize():
 var a=W.read_atlas("res://genesis/atlas_seed_101.json")
 for spec in a.regions:
  if spec.kind!="settlement":continue
  var d=D.new(a,int(spec.id));var walls=F.plan_region(d) if spec.settlement_scale=="city" else {}
  var result=P.plan(d,walls)
  print(JSON.stringify({"rid":spec.id,"scale":spec.settlement_scale,"metrics":result.get("metrics",{}),"lot":d.lots[0] if not d.lots.is_empty() else {}}))
 quit()
