extends "res://validation_r3/support.gd"
## Real Godot viewport evidence. Never fabricate a river region if none is valid.
const OUT="res://exo_core/evidence/river_gate_02/"
func _initialize() -> void:call_deferred("run_capture")
func shot(label: String) -> void:
 RenderingServer.render_loop_enabled=true
 for i in range(8):await process_frame
 await RenderingServer.frame_post_draw
 var img: Image=root.get_texture().get_image()
 check(img!=null and img.save_png(OUT+label+".png")==OK,"capture_"+label)
 RenderingServer.render_loop_enabled=false
func focus(p: Vector2,size: float,offset: Vector3) -> void:
 var h: float=w.active_region.data.height_at(p)
 w.camera.size=size;w.camera.position=Vector3(p.x,h,p.y)+offset
 w.camera.look_at(Vector3(p.x,h+3.5,p.y))
func run_capture() -> void:
 RenderingServer.render_loop_enabled=false
 DirAccess.make_dir_recursive_absolute(OUT)
 await boot("user://exo_river_capture_02.json")
 w.set_physics_process(false);w.ui.hide()
 check(await w.change_region(78),"unchanged_city_78")
 var original: Dictionary=w.exo_core.architecture_status()
 check(original.status=="ready","city_78_preserved")
 # Use ONLY real World Genesis regions of the running seed; no extra rivers.
 var candidate: Dictionary={}
 var original_id:=78
 for spec in w.atlas.regions:
  if spec.kind!="settlement" or spec.settlement_scale!="city":continue
  var d=preload("res://genesis/region_data.gd").new(w.atlas,int(spec.id))
  if d.rivers.is_empty():continue
  var plan: Dictionary=preload("res://fortifications/planner.gd").plan_region(d)
  if plan.status=="ready" and not plan.get("river_gates",[]).is_empty():
   candidate={"region":int(spec.id),"plan":plan};break
 if candidate.is_empty():
  check(false,"NOT_RUN_no_valid_real_river_city");await finish("exo_river_gate_captures");return
 check(await w.change_region(candidate.region),"actual_river_city_visited")
 var status: Dictionary=w.exo_core.architecture_status()
 check(status.status=="ready" and status.get("rendered",false),"real_city_ring_built")
 if status.status!="ready":await finish("exo_river_gate_captures");return
 var bridges: Array=status.plan.river_gates
 var first: Dictionary=bridges[0]
 focus(first.point,160,Vector3(105,135,110));await shot("01-rio-e-muralhas")
 focus(first.point,280,Vector3(160,220,185));await shot("05-panorama-da-cidade")
 focus(first.point,38,Vector3(22,25,25));await shot("06-detalhe-arco-margem")
 for label in ["small","medium","monumental"]:
  var gate: Dictionary={}
  for b in bridges:
   if b.variant==label:gate=b;break
  if gate.is_empty():continue # NOT_RUN recorded in final QA if no real sample.
  focus(gate.point,45,Vector3(25,32,25))
  await shot("0%d-%s"%[2 if label=="small" else 3 if label=="medium" else 4,label])
 facts["captured_variants"]=bridges.map(func(x):return x.variant)
 facts["seed"]=101;facts["region"]=candidate.region;facts["unchanged_city"]=original_id
 await finish("exo_river_gate_captures")
