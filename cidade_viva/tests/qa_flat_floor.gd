extends "res://validation_r3/support.gd"
func _initialize():call_deferred("run_floor")
func run_floor():
 await boot("user://cidade_viva_flat_floor.json")
 check(await w.change_region(78),"flat_city_loaded")
 w.set_physics_process(false);w.encounters.set_physics_process(false)
 await frames(4)
 var r: Node3D=w.active_region
 check(r.flat_collision_chunks>0,"flat_chunks_use_simple_collision")
 var issues: Array=[];var samples:=0
 var points: Array=[]
 for z in range(-128,129,16):
  for x in range(-128,129,16):points.append(Vector2(x,z))
 for seam in [-96.0,-64.0,-32.0,0.0,32.0,64.0,96.0]:
  for epsilon in [-.01,0.0,.01]:points.append(Vector2(seam+epsilon,0));points.append(Vector2(0,seam+epsilon))
 for point in points:
  var height: float=r.data.terrain_height_at(point)
  var ray:=PhysicsRayQueryParameters3D.create(Vector3(point.x,height+3,point.y),Vector3(point.x,height-3,point.y),1)
  var hit: Dictionary=w.get_world_3d().direct_space_state.intersect_ray(ray)
  if hit.is_empty() or absf(float(hit.position.y)-height)>.001:issues.append(str(point))
  samples+=1
 check(issues.is_empty(),"same_surface_height_including_chunk_seams")
 facts={"flat_collision_chunks":r.flat_collision_chunks,"floor_samples":samples,"issues":issues,"tolerance_m":.001,"generation_unchanged":r.data.validate().is_empty()}
 check(facts.generation_unchanged,"original_region_contract_valid")
 await finish("cidade_viva_flat_floor")
