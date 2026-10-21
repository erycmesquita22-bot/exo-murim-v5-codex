extends SceneTree
func _initialize():
 var P=load("res://genesis/world_planner.gd");var D=load("res://genesis/region_data.gd")
 for seed_text in ["101","707","816204","9223372036854775807"]:
  var w=P.plan(seed_text)
  for spec in w.regions:
   if spec.kind!="settlement":continue
   var d=D.new(w,int(spec.id));var reach=0.0
   for l in d.lots:reach=maxf(reach,l.p.length()+9)
   if reach>175:print(seed_text," ",spec.id," reach ",reach)
 quit()
