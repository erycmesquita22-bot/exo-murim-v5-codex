extends "res://validation_r3/support.gd"
var rows: Array=[]
func _initialize() -> void:call_deferred("run_benchmark")
func run_benchmark() -> void:
 await boot("user://core_equivalent_benchmark.json")
 w.graphics.select(1);w.graphics.shake_enabled=false;DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 var tag: String=OS.get_cmdline_user_args()[0]
 for rid in [78,52,86]:
  var start: int=Time.get_ticks_usec();check(await w.change_region(rid),"benchmark_region_"+str(rid));var load_ms: float=(Time.get_ticks_usec()-start)/1000.0
  w.camera.size=40;w.update_camera()
  for i in range(20):await process_frame
  var raw: Array=[];var previous: int=Time.get_ticks_usec()
  for i in range(90):
   await process_frame
   var now: int=Time.get_ticks_usec();raw.append(float(now-previous)/1000.0);previous=now
  var sorted: Array=raw.duplicate();sorted.sort();var total:=0.0
  for ms in raw:total+=float(ms)
  var mean: float=total/raw.size()
  rows.append({"region":rid,"mean_fps":1000.0/mean,"mean_frame_ms":mean,"p95_frame_ms":sorted[int(ceil(sorted.size()*.95))-1],"memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"nodes":get_node_count(),"npcs":w.residents.size(),"enemies":w.ecology_director.active.size(),"buildings":w.active_region.props.size(),"load_ms":load_ms,"generation_ms":w.region_metrics.back().generation_ms,"raw_frame_ms":raw})
 facts["performance"]={"tag":tag,"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_video_adapter_name(),"resolution":[1152,720],"fixed_fps":false,"profile":"Equilibrado","rows":rows,"limits":"90 rendered frames per region; CPU software rendering, no prediction for owner PC; scene composition includes integrated assets."}
 await finish("exo_core_benchmark_"+tag)
