extends SceneTree
const Game=preload("res://convergence/game.gd")
var w:Node3D
var failures:Array=[]
func check(ok:bool,label:String):
 print("JADE_CHECK ",label," ",ok)
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
 Engine.max_fps=0
 w=Game.new();w.load_on_start=false;w.save_path="user://work_jade.json";w.settings_path="user://work_jade.cfg";root.add_child(w);await process_frame
 w.flow.phase="creator"
 check(w.flow.create_character({"name":"Jade QA","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0,"weapon":"sword","outfit":0},101),"create")
 for i in range(1600):
  await physics_frame
  if w.current_region>=0 and not w.changing_region:break
 check(await w.change_region(15),"travel_jade_region")
 w.simulation_enabled=false
 for i in range(3):await physics_frame
 print("JADE_OCCUPANCY ",w.active_region.get_meta("exo_r9_martial_occupancy",{}))
 print("JADE_STATIONS ",w.active_region.monument_stations)
 check(not w.active_region.monument_portals.is_empty(),"real_portal")
 for portal in w.active_region.monument_portals:
  var pos:Vector3=portal.entrance_world
  var safe:Vector3=w.regional_spawn(w.active_region,pos)
  print("JADE_PORTAL ",portal," SAFE ",safe)
  check(safe.is_finite(),"door_capsule_and_floor")
  if safe.is_finite():
   w.player.position=safe
   check(bool(w._enter_institutional_interior(portal).get("ok",false)),"enter_official_interior")
   for i in range(4):await physics_frame
   check(bool(w._exit_institutional_interior().get("ok",false)),"exit_official_interior")
 check(not w.active_region.get_meta("exo_r9_martial_occupancy",{}).is_empty(),"master_physical_route")
 var master:Node3D
 var target:Vector3=Vector3.INF
 for station in w.active_region.monument_stations:
  if station.kind=="master_station":target=station.world_position
 for resident in w.residents:
  if resident.identity.get("martial_school_id","")=="exo_martial.school.mosteiro_jade":master=resident;break
 check(is_instance_valid(master),"real_living_world_master")
 if is_instance_valid(master):
  Engine.physics_ticks_per_second=5
  for tick in range(1000):
   await physics_frame
   for resident in w.residents:resident.step(.2,10,900.0+tick*.2)
   if master.arrived and master.position.distance_to(target)<.8:break
  print("JADE_MASTER_FINAL ",master.position," TARGET ",target," ACTIVITY ",master.activity_name," ROUTE ",master.route_index," ARRIVED ",master.arrived)
  check(master.arrived and master.position.distance_to(target)<.8,"master_physically_arrives")
 w.queue_free();await process_frame;await process_frame
 print("JADE_RESULT ",JSON.stringify({"failures":failures}))
 quit(0 if failures.is_empty() else 1)
