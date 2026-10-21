extends "res://validation_r3/support.gd"
## Headed/real renderer only. No fixed FPS samples; execute presets sequentially.
func _initialize() -> void:call_deferred("run_visual_bench")
func run_visual_bench() -> void:
 if DisplayServer.get_name()=="headless":
  print("VISUAL_BENCHMARK_NOT_RUN: headed renderer required")
  quit(2);return
 await boot("user://exo_visual_benchmark_save.json")
 var profiles: Array=[]
 for scene in [{"name":"cidade","region":78},{"name":"vila","region":86}]:
  if not await w.change_region(int(scene.region)):
   failures.append("region_unavailable:"+scene.name)
   continue
  for quality in [0,2,3,4]:
   w.graphics.select(quality)
   await frames(60)
   var samples: Array=[]
   for i in range(120):
    var t: int=Time.get_ticks_usec()
    await process_frame
    samples.append((Time.get_ticks_usec()-t)/1000.0)
   samples.sort()
   profiles.append({"scene":scene.name,"region":scene.region,"profile":quality,"engine":Engine.get_version_info().string,"rendering_method":RenderingServer.get_current_rendering_method(),"gpu":RenderingServer.get_video_adapter_name(),"median_frame_ms":samples[60],"p95_frame_ms":samples[113],"diagnostics":w.graphics.diagnostics(),"frames":120,"warmup_frames":60})
 var report: Dictionary={"results":profiles,"failures":failures,"fixed_fps":false,"real_capture":true}
 var out:=FileAccess.open("user://exo_visual_benchmark_01.json",FileAccess.WRITE)
 if out!=null:out.store_string(JSON.stringify(report,"  "))
 print("EXO_VISUAL_BENCHMARK ",JSON.stringify(report))
 w.audio_fx.shutdown();w.free();quit(int(not failures.is_empty()))
