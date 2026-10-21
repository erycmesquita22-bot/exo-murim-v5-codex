extends SceneTree
const Planner=preload("res://genesis/world_planner.gd")
const Data=preload("res://genesis/region_data.gd")
const Region=preload("res://convergence/region.gd")
var failures:Array=[]
var samples:int=0
func _initialize():call_deferred("run")
func run():
 var host:=Node3D.new();root.add_child(host)
 var atlas:Dictionary=Planner.read_atlas("res://genesis/atlas_seed_816204.json")
 for rid in [26,48]:
  var data=Data.new(atlas,rid)
  var region=Region.new();host.add_child(region);region.build(data,range(88));region.integrate_perimeter()
  await physics_frame;await physics_frame
  var space:PhysicsDirectSpaceState3D=host.get_world_3d().direct_space_state
  var probe:=PhysicsShapeQueryParameters3D.new();var capsule:=CapsuleShape3D.new();capsule.radius=.26;capsule.height=1.9;probe.shape=capsule;probe.collision_mask=1|4
  for gate in data.gates:
   var perpendicular:Vector2=Vector2(-gate.p.y,gate.p.x).normalized()
   var half_width:float=minf(3.5,maxf(0.0,float(gate.width)*.5-.4))
   for side in [-1,0,1]:
    for k in range(3,126):
     samples+=1
     var p:Vector2=gate.p*float(k)/128.0+perpendicular*side*half_width
     var expected:Vector3=Vector3(p.x,data.height_at(p),p.y)
     var ray:=PhysicsRayQueryParameters3D.create(expected+Vector3(0,3,0),expected-Vector3(0,4,0),1)
     var hit:Dictionary=space.intersect_ray(ray)
     if hit.is_empty():failures.append({"region":rid,"p":str(p),"reason":"no_floor"});continue
     probe.transform=Transform3D(Basis.IDENTITY,hit.position+Vector3(0,1.04,0))
     if not space.intersect_shape(probe,1).is_empty():failures.append({"region":rid,"p":str(p),"reason":"capsule_blocked"})
  region.queue_free();await process_frame
 host.queue_free();await process_frame
 print("ROAD_CORRIDORS ",JSON.stringify({"samples":samples,"failures":failures}))
 quit(0 if failures.is_empty() else 1)
