extends RefCounted
# Read-only planner. Uses exclusively R7's verified, materialized stations and
# CityViva's street graph. Does not create NPCs, alter saves or assume a route.
const Catalog=preload("res://exo_martial/styles/martial_catalog.gd")
static func school_for_site(seed:String,site_id:String,existing:String) -> String:
 if not existing.is_empty():return existing if not Catalog.school(existing).is_empty() else ""
 var schools:Array=Catalog.schools()
 if schools.is_empty():return ""
 var digest:String=("R9|"+seed+"|"+site_id).sha256_text()
 return str(schools[digest.substr(0,7).hex_to_int()%schools.size()].id)

static func route_for_site(region:Node3D,master:Dictionary,gate:Dictionary) -> Dictionary:
 var target:Vector3=master.get("world_position",Vector3.INF)
 var door:Vector3=gate.get("world_position",Vector3.INF)
 if not target.is_finite() or not door.is_finite():return {"ok":false,"reason":"no_physical_anchor"}
 if target.distance_to(door)>160.0:return {"ok":false,"reason":"too_far"}
 var nearest:Dictionary={};var best:float=INF
 for lot in region.data.lots:
  if not region.route_points.has(str(lot.id)):continue
  var point:Vector3=region.route_points[str(lot.id)][-1]
  var d:float=point.distance_squared_to(door)
  if d<best:best=d;nearest=lot
 if nearest.is_empty() or best>125.0*125.0:return {"ok":false,"reason":"no_street_near_gate"}
 var home:String=str(nearest.id)
 var road:Vector3=region.route_points[home][-1]
 var home_anchor:Vector3=region.route_points[home][0]
 var street_waypoints:Array=region.navigator.route(home_anchor,road)
 if street_waypoints.is_empty():return {"ok":false,"reason":"street_disconnected"}
 # The street graph must actually anchor both ends; one-node paths are valid only
 # when the local physical approach segments also pass obstacle tests.
 if street_waypoints[0].distance_to(home_anchor)>10.0 or street_waypoints[-1].distance_to(road)>10.0:return {"ok":false,"reason":"street_endpoint_mismatch"}
 var space:PhysicsDirectSpaceState3D=region.get_world_3d().direct_space_state
 var legs:Array=[[home_anchor,street_waypoints[0]]]
 for index in range(1,street_waypoints.size()):legs.append([street_waypoints[index-1],street_waypoints[index]])
 legs.append([street_waypoints[-1],road])
 for segment in legs:
  var ray:=PhysicsRayQueryParameters3D.create(segment[0]+region.global_position+Vector3(0,1,0),segment[1]+region.global_position+Vector3(0,1,0),1|4)
  if not space.intersect_ray(ray).is_empty():return {"ok":false,"reason":"street_obstacle"}
 var approach:Array=physical_approach(region,road,door)
 if approach.is_empty():return {"ok":false,"reason":"no_physical_gate_approach"}
 var inside:Array=physical_approach(region,door,target)
 if inside.is_empty():return {"ok":false,"reason":"no_physical_master_approach"}
 var path:Array=approach.duplicate();path.append_array(inside.slice(1));path.reverse()
 return {"ok":true,"home_slot":home,"path":path}

# Bounded physical approach, attached to the existing street graph. No actor warp.
static func physical_approach(region:Node3D,a:Vector3,b:Vector3) -> Array:
 var space:PhysicsDirectSpaceState3D=region.get_world_3d().direct_space_state
 var step:float=2.0
 var origin:Vector2=Vector2(minf(a.x,b.x)-30.0,minf(a.z,b.z)-30.0)
 var extent:Vector2=Vector2(absf(a.x-b.x)+60.0,absf(a.z-b.z)+60.0)
 var size:Vector2i=Vector2i(ceili(extent.x/step)+1,ceili(extent.y/step)+1)
 if size.x*size.y>14000:return []
 var grid:=AStarGrid2D.new();grid.region=Rect2i(Vector2i.ZERO,size);grid.cell_size=Vector2(step,step);grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_NEVER;grid.update()
 var heights:Dictionary={}
 var shape:=BoxShape3D.new();shape.size=Vector3(step,1.7,step)
 var probe:=PhysicsShapeQueryParameters3D.new();probe.shape=shape;probe.collision_mask=1|4
 for z in range(size.y):
  for x in range(size.x):
   var id:=Vector2i(x,z)
   var flat:Vector2=origin+Vector2(x,z)*step
   var base:Vector3=Vector3(flat.x,region.data.height_at(flat),flat.y)+region.global_position
   var ray:=PhysicsRayQueryParameters3D.create(base+Vector3(0,6,0),base-Vector3(0,8,0),1)
   var floor_hit:Dictionary=space.intersect_ray(ray)
   if floor_hit.is_empty():grid.set_point_solid(id);continue
   var floor_at:Vector3=floor_hit.position+Vector3(0,.08,0)
   probe.transform=Transform3D(Basis.IDENTITY,floor_at+Vector3(0,.95,0))
   if not space.intersect_shape(probe,1).is_empty():grid.set_point_solid(id);continue
   heights[id]=floor_at-region.global_position
 var start:=Vector2i(roundi((a.x-origin.x)/step),roundi((a.z-origin.y)/step))
 var end:=Vector2i(roundi((b.x-origin.x)/step),roundi((b.z-origin.y)/step))
 if not heights.has(start) or not heights.has(end):return []
 var ids:Array[Vector2i]=grid.get_id_path(start,end)
 if ids.is_empty():return []
 var path:Array=[a]
 for id in ids:path.append(heights[id])
 path.append(b)
 # Capsule sweeps prove every segment, including both exact anchor connections.
 var capsule:=CapsuleShape3D.new();capsule.radius=.29;capsule.height=1.9
 probe.shape=capsule
 for i in range(1,path.size()):
  var from:Vector3=path[i-1]+region.global_position+Vector3(0,.98,0)
  var to:Vector3=path[i]+region.global_position+Vector3(0,.98,0)
  if absf(to.y-from.y)>1.2:return []
  probe.transform=Transform3D(Basis.IDENTITY,from);probe.motion=to-from
  var swept:PackedFloat32Array=space.cast_motion(probe)
  if swept.size()<2 or swept[0]<.999:return []
 return path
