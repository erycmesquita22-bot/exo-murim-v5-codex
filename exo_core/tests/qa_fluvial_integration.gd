extends "res://validation_r3/support.gd"
const OUT="res://exo_core/evidence/fluvial_integrated/"
func _initialize():call_deferred("run_fluvial")
func clear_sphere(p: Vector3,mask: int,radius: float=.3) -> bool:
 var q:=PhysicsShapeQueryParameters3D.new();var shape:=SphereShape3D.new();shape.radius=radius
 q.shape=shape;q.transform=Transform3D(Basis.IDENTITY,p);q.collision_mask=mask
 return w.get_world_3d().direct_space_state.intersect_shape(q).is_empty()
func player_clear(p: Vector2,h: float) -> bool:
 var q:=PhysicsShapeQueryParameters3D.new();q.shape=w.player.get_child(0).shape
 q.transform=Transform3D(Basis.IDENTITY,Vector3(p.x,h+1.08,p.y));q.collision_mask=4
 return w.get_world_3d().direct_space_state.intersect_shape(q).is_empty()
func shot(label: String) -> void:
 RenderingServer.render_loop_enabled=true
 for i in range(6):await process_frame
 await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png(OUT+label+".png")==OK,"capture_"+label)
 RenderingServer.render_loop_enabled=false
func run_fluvial():
 RenderingServer.render_loop_enabled=false
 DirAccess.make_dir_recursive_absolute(OUT);root.size=Vector2i(1600,1000)
 await boot("user://exo_fluvial_integrated_v3.json")
 w.set_physics_process(false);w.ui.hide();w.encounters.set_physics_process(false)
 facts["cities"]=[]
 for rid in [14,26]:
  check(await w.change_region(rid),"real_city_loaded_"+str(rid))
  w.set_physics_process(false);w.encounters.set_physics_process(false)
  await frames(4)
  var status: Dictionary=w.exo_core.architecture_status()
  check(status.status=="ready","complete_perimeter_"+str(rid))
  if status.status!="ready":continue
  var d=w.active_region.data
  check(d.validate().is_empty(),"genesis_constraints_"+str(rid)+":"+str(d.validate()))
  check(w.active_region.find_children("EXO_RiverGate_*","Node3D",true,false).size()==status.plan.river_gates.size(),"one_instance_per_crossing_"+str(rid))
  var wet_blocked: Array=[];var road_blocked: Array=[];var floor_missing: Array=[];var wet_samples:=0;var road_samples:=0
  for gate in status.plan.river_gates:
   var river: Dictionary=d.rivers[int(gate.river_index)]
   var flow: Vector2=(river.p-d.river_hub).normalized()
   var crossing: Vector2=Geometry2D.get_closest_point_to_segment(gate.point,d.river_hub,river.p)
   var side:=Vector2(-flow.y,flow.x)
   for along in range(-12,13,2):
    for lateral in [-1.7,0.0,1.7]:
     var p: Vector2=crossing+flow*along+side*lateral
     var level: float=d.river_level(river,p)
     if not clear_sphere(Vector3(p.x,level+.6,p.y),5):wet_blocked.append(str(p))
     wet_samples+=1
   var roads: Array=d.settlement_roads.duplicate()
   for g in d.gates:roads.append({"a":Vector2.ZERO,"b":g.p,"width":g.width})
   for road in roads:
    var hit=Geometry2D.segment_intersects_segment(road.a,road.b,gate.point-gate.tangent*float(gate.width)*.5,gate.point+gate.tangent*float(gate.width)*.5)
    if hit==null:continue
    var direction: Vector2=(road.b-road.a).normalized()
    for along in range(-12,13):
     var p: Vector2=hit+direction*along
     var h: float=d.height_at(p)
     if not player_clear(p,h):road_blocked.append(str(p))
     var q:=PhysicsRayQueryParameters3D.create(Vector3(p.x,h+.5,p.y),Vector3(p.x,h-.7,p.y),1)
     var support: Dictionary=w.get_world_3d().direct_space_state.intersect_ray(q)
     if support.is_empty() or absf(float(support.position.y)-h)>.2:floor_missing.append(str(p))
     road_samples+=1
   if rid==14:
    var canvas:=CanvasLayer.new();root.add_child(canvas)
    var panel:=PanelContainer.new();panel.position=Vector2(24,22);canvas.add_child(panel)
    var text:=Label.new();text.add_theme_font_size_override("font_size",23);panel.add_child(text)
    text.text="EXO-MURIM • PASSAGEM FLUVIAL INTEGRADA\nGodot 4.6.2 / Compatibility • Seed 101 • Cidade 14\nMuralha nas margens • Rio sob o arco • Estrada sobre ponte"
    var style:=StyleBoxFlat.new();style.bg_color=Color(.025,.04,.055,.93);style.content_margin_left=18;style.content_margin_right=18;style.content_margin_top=12;style.content_margin_bottom=12;panel.add_theme_stylebox_override("panel",style)
    var target:=Vector3(crossing.x,float(gate.water_level)+3.0,crossing.y)
    w.camera.size=52;w.camera.position=target+Vector3(20,30,45);w.camera.look_at(target)
    await shot("01-passagem-fluvial-e-muralha")
    w.camera.size=140;w.camera.position=target+Vector3(75,85,90);w.camera.look_at(target)
    await shot("02-muralha-cidade-escala-ampla")
    canvas.free()
  check(wet_samples>0 and wet_blocked.is_empty(),"water_channel_clear_"+str(rid)+":"+str(wet_blocked))
  check(road_samples>0 and road_blocked.is_empty(),"roads_clear_"+str(rid)+":"+str(road_blocked))
  check(floor_missing.is_empty(),"road_bridge_support_"+str(rid)+":"+str(floor_missing))
  facts.cities.append({"region":rid,"wet_samples":wet_samples,"road_samples":road_samples,"blocked_water":wet_blocked,"blocked_roads":road_blocked,"missing_floor":floor_missing,"segments":status.segments,"river_gates":status.river_gates})
 check(w.save_progress(),"save_real_river_city")
 var expected: Dictionary={"region":w.current_region,"digest":w.active_region.data.digest(),"items":w.journey.data.items,"character":w.journey.data.character,"narrative":w.journey.data.narrative,"progress":w.journey_manager.state().progress,"npc_ids":w.residents.map(func(actor):return actor.identity.id)}
 FileAccess.open(OUT+"reload_expected.json",FileAccess.WRITE).store_string(JSON.stringify(expected))
 facts["engine"]=Engine.get_version_info().string
 await finish("fluvial_integration")
