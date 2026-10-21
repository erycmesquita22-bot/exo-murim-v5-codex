extends RefCounted
const Catalog=preload("res://exo_interior_forge/runtime/interior_catalog.gd")
const Builder=preload("res://exo_interior_forge/runtime/interior_builder.gd")
static func build(region:Node3D,world:Node3D):
 if not bool(ProjectSettings.get_setting("exo_murim/convergence4/physical_interiors",true)):return
 var pending:Array=[]
 for lot in region.data.lots:
  if pending.size()>=3:break
  var model:Dictionary=lot.get("city_model",{})
  if not bool(model.get("interior_slot",false)) or str(lot.function) not in ["inn","herbalist","smithy","market","martial_school","shrine","administration"]:continue
  var context:Dictionary={"world_id":str(world.journey.data.world.id),"world_seed":str(world.journey.data.world.seed),"region_id":int(region.data.spec.id),"settlement_id":"city/%d"%int(region.data.spec.id),"lot_instance_id":str(lot.id),"building_local_id":str(lot.id),"template_id":str(model.archetype),"function":str(lot.function)}
  var key:String=str(lot.id)
  var saved:Dictionary=world.activation_v4.state().get("interiors",{}).get(key,{})
  var chosen:Dictionary=Catalog.select_or_reuse(context,saved)
  if not chosen.get("ok",false):continue
  var prefab:Dictionary=Catalog.load_prefab(str(chosen.receipt.prefab_id))
  if int(prefab.get("floors",1))>1:continue
  var root:Node3D=Builder.build(prefab);region.add_child(root)
  Builder.set_cutaway(root,true)
  root.position=Vector3(0,64,1000+pending.size()*80);root.visible=false
  var local:Vector3=root.get_node("InteriorSpawn").position
  var door:=Vector3(lot.door.x,region.data.height_at(lot.door)+.05,lot.door.y)
  pending.append({"source":"interior_forge_r2","region_id":int(region.data.spec.id),"persistent_id":str(chosen.receipt.building_instance_id),"site_id":key,"interior_id":str(prefab.id),"interior_entry_local":[local.x,local.y,local.z],"entrance_world":door,"return_world":door,"prepared_root":root,"context":context,"selection_receipt":chosen.receipt,"building":model})
 region.set_meta("interior_forge_pending",pending)
static func clear_capsule(space:PhysicsDirectSpaceState3D,feet:Vector3)->bool:
 var ray:Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(feet+Vector3.UP*.6,feet-Vector3.UP*1.2,1))
 if ray.is_empty():return false
 var shape:=CapsuleShape3D.new();shape.radius=.4;shape.height=1.9
 var q:=PhysicsShapeQueryParameters3D.new();q.shape=shape;q.collision_mask=1|4;q.transform=Transform3D(Basis.IDENTITY,ray.position+Vector3.UP*1.01)
 return space.intersect_shape(q).is_empty()
static func verify(region:Node3D)->Dictionary:
 var count:int=0
 var space:PhysicsDirectSpaceState3D=region.get_world_3d().direct_space_state
 for p in region.get_meta("interior_forge_pending",[]):
  var room:Node3D=p.prepared_root
  var at:Vector3=room.to_global(room.get_node("InteriorSpawn").position)
  if not clear_capsule(space,at) or not clear_capsule(space,region.to_global(p.entrance_world)):continue
  p["host_geometry_verified"]=true;region.monument_portals.append(p);count+=1
 region.set_meta("interior_forge_physical",{"prepared":region.get_meta("interior_forge_pending",[]).size(),"approved":count})
 return {"approved":count}
static func authorize(world:Node3D,portal:Dictionary,restoring:bool)->bool:
 if portal.get("source")!="interior_forge_r2" or not portal.get("host_geometry_verified",false):return false
 var live:bool=false
 for p in world.active_region.monument_portals:
  if p==portal:live=true;break
 if not live:return false
 var context:Dictionary=portal.context.duplicate(true)
 context.active_region_id=world.current_region;context.exterior_door_id=str(portal.site_id)+"/door";context.return_anchor_id=str(portal.site_id)+"/return";context.player_distance_m=0.0 if restoring else world.player.position.distance_to(portal.entrance_world)
 var grant:Dictionary={"allowed":true,"issuer":"city","building_instance_id":str(portal.selection_receipt.building_instance_id),"verified_by_host":true}
 var ticket:Dictionary=world.exo_core.services.invoke("interior_forge.candidates","prepare_interior",[context,portal.building,portal.selection_receipt,grant])
 return bool(ticket.get("ok",false))
