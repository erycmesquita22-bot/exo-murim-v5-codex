extends SceneTree
const Game=preload("res://convergence/game.gd")
var w:Node3D
var checks:int=0
var failures:Array=[]
func check(ok:bool,label:String):
 checks+=1;print("WG4_CHECK ",label," ",ok)
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
 Engine.max_fps=0
 var reopen:bool="--reopen" in OS.get_cmdline_user_args()
 var legacy:bool="--legacy" in OS.get_cmdline_user_args()
 w=Game.new();w.load_on_start=reopen or legacy;w.save_path="user://legacy_saved.json" if legacy else "user://wg4_physical.json";w.settings_path="user://wg4_physical.cfg";root.add_child(w);await process_frame
 check(w.exo_core.ready,"core")
 if not reopen and not legacy:
  w.flow.phase="creator"
  check(w.flow.create_character({"name":"WG4 QA","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0,"weapon":"sword","outfit":0},101),"creator")
 for i in range(1800):
  await physics_frame
  if w.current_region>=0 and not w.changing_region:break
 w.ui.resume();w.simulation_enabled=true
 for i in range(20):await physics_frame
 w.simulation_enabled=false
 if legacy:
  check(not w.extension().has("worldgen_v4") and not w.active_region.data.worldgen_v4,"old_save_stays_c3")
  check(w.current_region==78 and w.martial_host_r8!=null,"old_region_and_services")
 elif reopen:
  check(w.extension().has("worldgen_v4") and int(w.extension().regional_version)==7,"v4_pin_reopened")
  var expected:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://wg4_expected.json"))
  check(w.current_region==int(expected.region),"reopened_region")
  check(w.active_region.data.digest()==str(expected.digest),"reopened_physical_digest")
  check(w.atlas.worldgen_v4==expected.worldgen,"frozen_generation_inputs")
  check(w.player.is_on_floor(),"reopened_ground")
 else:
  check(w.extension().has("worldgen_v4") and int(w.extension().regional_version)==7,"new_campaign_v4")
  var authored:int=0
  for r in w.atlas.regions:authored+=r.worldgen_v4.authorial.size()
  check(authored>0,"universal_library_consumed")
  print("WG4_AUTHORIAL_PROPOSALS ",authored)
  var target:int=-1
  for r in w.atlas.regions:
   if str(r.kind)=="wild" and str(r.biome)=="grassland":target=int(r.id);break
  check(target>=0,"open_region_available")
  check(await w.change_region(target),"open_region_build")
  w.simulation_enabled=false
  for i in range(5):await physics_frame
  var region:Node3D=w.active_region
  var d:RefCounted=region.data
  check(d.worldgen_v4 and region.gate_nodes.size()==d.gates.size(),"same_portal_count")
  check(not d.landmarks.is_empty(),"landmarks_proposed")
  print("WG4_LANDMARKS ",region.get_meta("wg4_landmark_verification",{}))
  var accepted:Dictionary={}
  for point in region.get_meta("wg4_landmarks",[]):
   if point.approved:accepted=point;break
  check(not accepted.is_empty(),"landmark_physical_approval")
  if not accepted.is_empty():
   w.player.position=accepted.point;w.player.velocity=Vector3.ZERO
   await physics_frame;w.player.move_and_slide();await physics_frame
   w.gate_cooldown=0;w.interaction_cooldown=0
   var before:Dictionary=w.journey.data.duplicate(true)
   w.interact()
   check(w.ui.modal.visible,"landmark_E_dialogue")
   check(w.journey.data==before,"landmark_no_fake_rewards")
   w.ui.resume()
  var samples:int=0;var blocked:int=0
  var shape:=CapsuleShape3D.new();shape.radius=.38;shape.height=1.8
  var space:PhysicsDirectSpaceState3D=w.get_world_3d().direct_space_state
  for gate in d.gates:
   var end:Vector2=d.handoff_point(gate)-gate.p.normalized()*12.0
   check(end.length()<gate.p.length()*.8,"shorter_handoff")
   for step in range(1,int(end.length()/2)):
    var p:Vector2=end*float(step)/float(int(end.length()/2))
    var hit:Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(p.x,d.height_at(p)+3,p.y),Vector3(p.x,d.height_at(p)-3,p.y),1))
    samples+=1
    if hit.is_empty():blocked+=1;continue
    var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1|4;query.transform=Transform3D(Basis.IDENTITY,hit.position+Vector3.UP*.98)
    var excluded:Array[RID]=[w.player.get_rid()]
    for enemy in w.enemies:
     if enemy is CollisionObject3D:excluded.append(enemy.get_rid())
    query.exclude=excluded
    if not space.intersect_shape(query).is_empty():blocked+=1
  print("WG4_ROAD_PHYSICS ",samples," blocked ",blocked)
  check(blocked==0,"road_capsule_corridors")
  # Use actual E gate handoff, not direct travel, for one connected neighbor.
  var node:Dictionary=region.gate_nodes[0]
  var start:Vector3=node.point-Vector3(node.point.x,0,node.point.z).normalized()*6.0
  var safe:Vector3=w.regional_spawn(region,start)
  check(safe.is_finite(),"gate_approach")
  if safe.is_finite():
   w.player.position=safe;w.player.velocity=Vector3.ZERO;await physics_frame;w.player.move_and_slide();await physics_frame
   w.gate_cooldown=0;w.interaction_cooldown=0
   var neighbor:int=int(node.contract.neighbor)
   w.interact()
   for i in range(1800):
    await physics_frame
    if w.current_region==neighbor and not w.changing_region:break
   check(w.current_region==neighbor,"actual_E_neighbor_transition")
   check(w.player.position.is_finite(),"arrival_finite")
  check(await w.change_region(target),"return_open_region")
  w.simulation_enabled=false
  check(w.save_progress(),"save_v4")
  FileAccess.open("user://wg4_expected.json",FileAccess.WRITE).store_string(JSON.stringify({"region":w.current_region,"digest":w.active_region.data.digest(),"worldgen":w.atlas.worldgen_v4}))
 w.queue_free();await process_frame;await process_frame
 print("WG4_PHYSICAL_RESULT ",JSON.stringify({"checks":checks,"failures":failures,"reopen":reopen,"legacy":legacy}))
 quit(0 if failures.is_empty() else 1)
