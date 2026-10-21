extends RefCounted
# Physical City Forge schools feed the single existing LivingWorld/Martial owners.
static func bind(region:Node3D):
 var linked:Array=[]
 var space:PhysicsDirectSpaceState3D=region.get_world_3d().direct_space_state
 for lot in region.data.lots:
  if str(lot.function)!="martial_school" or not lot.has("city_model"):continue
  var point:Vector3=region.route_points[str(lot.id)][0]
  if not preload("res://convergence4/interiors.gd").clear_capsule(space,region.to_global(point)):continue
  var street:Vector3=region.route_points[str(lot.id)][-1]
  var ray:=PhysicsRayQueryParameters3D.create(region.to_global(point)+Vector3.UP,region.to_global(street)+Vector3.UP,1|4)
  if not space.intersect_ray(ray).is_empty():continue
  var site:String=str(lot.id)
  var school:String=preload("res://convergence/martial_occupancy_r9.gd").school_for_site(str(region.data.atlas.seed),site,"")
  var id:String="martial/city/"+site.sha256_text().substr(0,18)
  region.route_points[id]=region.route_points[site].duplicate()
  # Replace the school disciple workplace with its legitimate master occupation.
  for slot in region.assigned_slots:
   if str(slot.id)!=site:continue
   slot.role="master";slot.work_slot=id;slot.martial_site_id=site;slot.martial_school_id=school
   break
  region.monument_stations.append({"source":"city_forge_r4","host_geometry_verified":true,"kind":"master_station","capacity":1,"site_id":site,"station_id":site+"/master","world_position":point,"school_id":school})
  linked.append(site)
 region.set_meta("city_forge_teachers",linked)
