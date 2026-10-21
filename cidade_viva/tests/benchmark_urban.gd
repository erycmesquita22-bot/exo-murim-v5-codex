extends "res://validation_r3/support.gd"
func _initialize():call_deferred("run_benchmark")
func run_benchmark():
 RenderingServer.render_loop_enabled=false
 await boot("user://cidade_viva_benchmark.json")
 check(await w.change_region(78),"benchmark_city")
 w.graphics.select(2);w.graphics.set_option("fps_limit",0);w.graphics.set_option("vsync",0)
 w.set_physics_process(false)
 w.encounters.set_physics_process(false)
 for canvas in w.find_children("*","CanvasLayer",true,false):canvas.hide()
 w.camera.size=55;w.camera.far=900
 var focus:=Vector3(0,w.active_region.data.center_h,0)
 w.camera.position=focus+Vector3(45,58,48);w.camera.look_at(focus)
 for actor in w.residents:
  actor.rig.visible=not actor.sheltered and w.resident_is_visible(actor);actor.caption.visible=false
 var rows: Array=[]
 var layer: Node3D=w.active_region.get_node("EXOCidadeViva01")
 for active in [false,true]:
  layer.visible=active;RenderingServer.render_loop_enabled=true
  for i in range(12):await process_frame
  var raw: Array=[];var previous: int=Time.get_ticks_usec()
  for i in range(60):
   await process_frame
   var now: int=Time.get_ticks_usec();raw.append(float(now-previous)/1000.0);previous=now
  var sorted: Array=raw.duplicate();sorted.sort()
  var total:=0.0
  for ms in raw:total+=float(ms)
  rows.append({"urban_visible":active,"mean_frame_ms":total/raw.size(),"mean_fps":1000.0/(total/raw.size()),"p95_frame_ms":sorted[56],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"nodes":get_node_count(),"raw_frame_ms":raw})
  RenderingServer.render_loop_enabled=false
 facts={"rows":rows,"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"resolution":str(root.size),"profile":"Medio","npcs":w.residents.size(),"urban":w.active_region.get_meta("cidade_viva"),"fixed_fps":false,"limits":"Frozen simulation isolates rendering cost; 60 samples per condition on CPU llvmpipe, not owner hardware or live gameplay FPS."}
 await finish("cidade_viva_benchmark")
