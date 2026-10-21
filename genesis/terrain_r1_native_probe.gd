extends SceneTree
# EXECUÇÃO Nativa opcional: godot --headless --path <projeto> --script res://genesis/terrain_r1_native_probe.gd
# Prova compilação de GDScript/recursos, distribuição e determinismo, NÃO prova visual/FPS.
const Dressing=preload("res://genesis/terrain_dressing_r1.gd")
class ProbeData:
 extends RefCounted
 var spec: Dictionary={"region_seed":934821,"biome":"grassland","kind":"wild"}
 var plants: Array=[]
 func road_distance(p: Vector2) -> float:return absf(p.y)
 func pad_distance(p: Vector2) -> float:return maxf(0.0,p.distance_to(Vector2(80,55))-12.0)
 func river_distance(p: Vector2) -> float:return absf(p.x+85.0)
 func height_at(p: Vector2) -> float:return 6.0
 func terrain_height_at(p: Vector2) -> float:return 6.0
func _initialize() -> void:
 var one:=Node3D.new();get_root().add_child(one)
 var two:=Node3D.new();get_root().add_child(two)
 var data:=ProbeData.new()
 Dressing.build(one,data)
 Dressing.build(two,data)
 var result1: Dictionary=one.get_meta("dressing_r1",{})
 var result2: Dictionary=two.get_meta("dressing_r1",{})
 var failed: Array=[]
 if result1.is_empty():failed.append("not_generated")
 if result1!=result2:failed.append("counts_nondeterministic")
 if int(result1.get("foliage",0))<=0:failed.append("no_foliage")
 if int(result1.get("rocks",0))<=0:failed.append("no_rocks")
 if int(result1.get("foliage",0))>420:failed.append("foliage_over_budget")
 if int(result1.get("rocks",0))>90:failed.append("rocks_over_budget")
 if int(result1.get("rock_colliders",0))>10:failed.append("colliders_over_budget")
 for type_name in ["EXO_Dressing_R1_Foliage","EXO_Dressing_R1_Rocks"]:
  var a:=one.get_node_or_null(type_name) as MultiMeshInstance3D
  var b:=two.get_node_or_null(type_name) as MultiMeshInstance3D
  if a==null or b==null:
   failed.append("missing_multimesh_"+type_name);continue
  if a.multimesh.instance_count!=b.multimesh.instance_count:failed.append("instance_count_"+type_name)
  for index in range(a.multimesh.instance_count):
   var t: Transform3D=a.multimesh.get_instance_transform(index)
   if not t.is_equal_approx(b.multimesh.get_instance_transform(index)):
    failed.append("transform_nondeterminism");break
   var pos:=Vector2(t.origin.x,t.origin.z)
   if absf(pos.y)<8.5 or maxf(0.0,pos.distance_to(Vector2(80,55))-12.0)<9.0 or absf(pos.x+85.0)<11.0:
    failed.append("forbidden_placement");break
 print("EXO_TERRAIN_R1_NATIVE_PROBE ",JSON.stringify({"counts":result1,"failures":failed}))
 one.queue_free();two.queue_free()
 quit(0 if failed.is_empty() else 1)
