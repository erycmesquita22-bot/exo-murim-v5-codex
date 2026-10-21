extends "res://validation_r3/support.gd"
func _initialize() -> void:call_deferred("run_core_integration")
func run_core_integration() -> void:
 await boot("user://core_physics_integration.json")
 check(w.exo_core.ready,"all_modules_initialized")
 var health: Dictionary=preload("res://exo_core/diagnostics/health_check.gd").run(w.exo_core)
 check(health.status=="PASS","health_check")
 check(w.exo_core.services.has_service("quests") and w.exo_core.services.has_service("appearance"),"services_real")
 check(await w.change_region(78),"city_78")
 await frames(4)
 var report: Dictionary=w.exo_core.architecture_status()
 check(report.status=="ready","complete_city_perimeter")
 var blocked: Array=[];var unsupported: Array=[];var samples:=0
 for gate in report.get("plan",{}).get("openings",[]):
  if gate.type!="gate":continue
  var p: Vector2=gate.point;var tangent: Vector2=gate.tangent;var normal:=Vector2(-tangent.y,tangent.x)
  for lateral in [-1.0,0.0,1.0]:
   for along in range(-4,5):
    var point: Vector2=p+tangent*lateral+normal*float(along)
    var h: float=w.active_region.data.height_at(point)
    var query:=PhysicsShapeQueryParameters3D.new();query.shape=w.player.get_child(0).shape;query.transform=Transform3D(Basis.IDENTITY,Vector3(point.x,h+1.08,point.y));query.collision_mask=4
    if not w.get_world_3d().direct_space_state.intersect_shape(query).is_empty():blocked.append(str(gate.source)+":"+str(point))
    var ray:=PhysicsRayQueryParameters3D.create(Vector3(point.x,h+3,point.y),Vector3(point.x,h-3,point.y),1)
    if w.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():unsupported.append(str(point))
    samples+=1
 check(blocked.is_empty(),"capsules_through_all_city_gates:"+str(blocked))
 check(unsupported.is_empty(),"gate_floor_support")
 facts["gate_capsule_samples"]=samples;facts["health"]=health
 await finish("exo_core_integration")
