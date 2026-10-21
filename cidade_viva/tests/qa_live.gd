extends "res://validation_r3/support.gd"
func _initialize():call_deferred("run_live")
func run_live():
 await boot("user://cidade_viva_physics_r2.json")
 check(await w.change_region(78),"city_with_urban_layer")
 w.set_physics_process(false)
 await frames(4)
 var r: Node3D=w.active_region
 var plan: Dictionary=r.get_meta("cidade_viva_plan",{})
 check(r.get_meta("cidade_viva",{}).get("rendered",false),"urban_rendered")
 check(plan.visuals.size()>60,"city_density_increased")
 var footprint_failures: Array=[];var count:=0
 var capsule:=CapsuleShape3D.new();capsule.height=1.9;capsule.radius=.28
 var detector_works:=false
 for body in r.get_node("EXOCidadeViva01").find_children("*","StaticBody3D",true,false):
  if not body.get_meta("urban_solid",false):continue
  var collision: CollisionShape3D=body.get_child(0)
  var control:=PhysicsShapeQueryParameters3D.new();control.shape=collision.shape;control.transform=collision.global_transform;control.collision_mask=4
  for hit in w.get_world_3d().direct_space_state.intersect_shape(control,32):
   if hit.collider==body:detector_works=true
  break
 check(detector_works,"positive_control_detects_real_urban_solid")
 # Sample complete shared routes, including individual frontage and square endpoints.
 var visited: Dictionary={}
 for actor in w.residents:
  for route in actor.routes.values():
   for i in range(route.size()):
    var a: Vector3=route[maxi(0,i-1)];var b: Vector3=route[i]
    var steps: int=maxi(1,int(ceil(a.distance_to(b)/.65)))
    for step in range(steps+1):
     var point: Vector3=a.lerp(b,float(step)/steps)
     var key: String=str((point*4).round())
     if visited.has(key):continue
     visited[key]=true
     var q:=PhysicsShapeQueryParameters3D.new();q.shape=capsule;q.collision_mask=4
     q.transform=Transform3D(Basis.IDENTITY,point+Vector3(0,.98,0))
     for hit in w.get_world_3d().direct_space_state.intersect_shape(q,32):
      if hit.collider.get_meta("urban_solid",false):footprint_failures.append({"npc":actor.identity.id,"point":str(point)})
     count+=1
 check(footprint_failures.is_empty(),"all_npc_routes_clear_of_urban_solids")
 var original: String=JSON.stringify(w.journey.data)
 var before: int=int(r.get_meta("cidade_viva").objects)
 var renderer=preload("res://cidade_viva/renderer.gd")
 var report: Dictionary=renderer.apply(r,r.get_meta("exo_architecture"))
 check(report.status=="ready" and int(report.objects)==before,"idempotent_urban_reapply")
 check(r.find_children("EXOCidadeViva01","Node3D",false,false).size()==1,"one_urban_layer")
 check(JSON.stringify(w.journey.data)==original,"urban_reapply_preserves_save")
 facts={"urban":report,"npcs":w.residents.size(),"unique_route_points":visited.size(),"physics_samples":count,"blocked":footprint_failures}
 await finish("cidade_viva_live")
