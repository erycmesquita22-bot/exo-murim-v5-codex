extends RefCounted
const Plan=preload("res://genesis/v4/world_plan.gd")
const Planner=preload("res://genesis/world_planner.gd")
static func propose(data:RefCounted)->Array:
 var result:Array=[]
 if not data.worldgen_v4 or str(data.spec.kind)=="settlement":return result
 var library:Array=data.atlas.worldgen_v4.get("landmark_templates",[])
 if library.is_empty():return result
 var rng:=RandomNumberGenerator.new();rng.seed=Planner.derive(data.spec.region_seed,"WG4/landmarks")
 for gate in data.gates:
  if result.size()>=4:break
  var along:Vector2=gate.p.normalized();var side:=Vector2(-along.y,along.x)
  for distance in [54.0,82.0,112.0,142.0]:
   var p:Vector2=along*(float(distance)+rng.randf_range(-4,4))+side*10.2*(1.0 if rng.randf()>.5 else -1.0)
   var h:float=data.height_at(p)
   if data.road_distance(p)<8.8 or data.river_distance(p)<15.0 or data.pad_distance(p)<10.0:continue
   if maxf(absf(data.height_at(p+Vector2(1,0))-h),absf(data.height_at(p+Vector2(0,1))-h))>.28:continue
   var clear:bool=true
   for other in result:
    if p.distance_to(other.p)<28:clear=false
   if not clear:continue
   var preference:int=int(data.worldgen_profile.get("landmark_preference",-1))
   var template:Dictionary=library[preference] if preference>=0 and preference<library.size() else library[int(rng.randi())%library.size()]
   result.append({"id":"wg4/r%02d/landmark/%02d"%[int(data.spec.id),result.size()],"p":p,"height":h,"yaw":rng.randf()*TAU,"template":template.duplicate(true),"approved":false})
   break
 return result
static func build(region:Node3D)->void:
 var nodes:Array=[]
 for point in region.data.landmarks:
  var at:=Vector3(point.p.x,float(point.height),point.p.y)
  # Original low-poly geometry; no solid objects in the walking corridor.
  var stone:Node3D=region.box(at+Vector3(0,.55,0),Vector3(.65,1.1,.5),Color("8d8c73"),true)
  stone.name="WG4_"+str(point.template.id);stone.rotation.y=float(point.yaw)
  var top:Node3D=region.box(at+Vector3(0,1.1,0),Vector3(.9,.16,.7),Color("605f4e"),true)
  top.rotation.y=stone.rotation.y
  if str(point.template.id)=="rest_stop":
   for x in [-1.0,1.0]:
    for z in [-.8,.8]:region.box(at+Vector3(x,1.1,z),Vector3(.1,2.2,.1),Color("725339"),true)
   region.box(at+Vector3(0,2.25,0),Vector3(2.7,.18,2.4),Color("4f6355"),true)
   region.box(at+Vector3(0,.42,.85),Vector3(1.7,.2,.4),Color("725339"),true)
  preload("res://ground_shadow.gd").place(region,at+Vector3.UP*.025,Vector2(1.4,1.4),.2)
  var label:=Label3D.new();label.text=str(point.template.title);label.font_size=24;label.pixel_size=.008;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.position=at+Vector3.UP*1.8;label.visibility_range_end=30.0;label.modulate=Color("e8d8a0");region.add_child(label)
  nodes.append({"id":str(point.id),"point":at+Vector3(1.3,.05,0),"title":str(point.template.title),"description":str(point.template.description),"approved":false,"label":label})
 region.set_meta("wg4_landmarks",nodes)
static func verify(region:Node3D)->Dictionary:
 var rows:Array=region.get_meta("wg4_landmarks",[])
 var accepted:int=0
 var capsule:=CapsuleShape3D.new();capsule.radius=.42;capsule.height=1.9
 var space:PhysicsDirectSpaceState3D=region.get_world_3d().direct_space_state
 for row in rows:
  var at:Vector3=region.to_global(row.point)
  var hit:Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(at+Vector3.UP*3,at-Vector3.UP*4,1))
  if hit.is_empty():continue
  var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collision_mask=1|4;query.transform=Transform3D(Basis.IDENTITY,hit.position+Vector3.UP*1.01)
  row.approved=space.intersect_shape(query).is_empty()
  if row.approved:row.point=region.to_local(hit.position)+Vector3.UP*.05;accepted+=1
 return {"checked":rows.size(),"approved":accepted,"owner":"WorldGenesis","rewards":false}
