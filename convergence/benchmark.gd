extends SceneTree
var w: Node3D
func _initialize():call_deferred("run")
func run():
 var args:=OS.get_cmdline_user_args();var mode: String=args[0] if not args.is_empty() else "home"
 root.size=Vector2i(1152,720);DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 w=load("res://main.gd" if mode=="base" else "res://convergence/game.gd").new();w.load_on_start=false;w.world_seed_override=101;w.save_path="user://convergence_bench.json";root.add_child(w);await process_frame
 w.graphics.select(1);w.flow.phase="creator";w.flow.create_character({"name":"Bench","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0});w.ui.resume()
 if mode in ["village","city"]:await w.change_region(86 if mode=="village" else 78)
 for actor in w.enemies:actor.enabled=false
 w.camera.size=36
 for i in range(30):await process_frame
 var samples: Array=[];var process_samples: Array=[];var physics_samples: Array=[]
 for i in range(120):
  var t:=Time.get_ticks_usec();await process_frame;samples.append((Time.get_ticks_usec()-t)/1000.0)
  process_samples.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
  physics_samples.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000)
 var raw_samples: Array=samples.duplicate()
 samples.sort()
 var report={"mode":mode,"renderer":RenderingServer.get_video_adapter_name(),"resolution":"1152x720","quality":1,"warmup":30,"frames":120,"fixed_fps":false,"frame_ms_mean":mean(samples),"frame_ms_p50":samples[60],"frame_ms_p95":samples[int(ceil(samples.size()*.95))-1],"physics_ms_mean":mean(physics_samples),"process_ms_mean":mean(process_samples),"static_memory_mb":Performance.get_monitor(Performance.MEMORY_STATIC)/1048576,"video_memory_mb":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1048576,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT)}
 report["frame_ms_samples"]=raw_samples
 report["engine"]=Engine.get_version_info().string
 report["project"]=ProjectSettings.get_setting("application/config/name")
 report["npc_count"]=w.residents.size() if mode!="base" else 0
 report["building_count"]=w.active_region.props.size() if mode!="base" and is_instance_valid(w.active_region) else 0
 var proc: String=FileAccess.get_file_as_string("/proc/self/status") if FileAccess.file_exists("/proc/self/status") else ""
 for line in proc.split("\n"):
  if line.begins_with("VmRSS:"):report["rss_kib"]=int(line.trim_prefix("VmRSS:").strip_edges().split(" ",false)[0])
 if mode!="base":report["generation"]=w.region_metrics
 FileAccess.open("res://convergence/benchmark_"+mode+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
 print("CONVERGENCE_BENCHMARK ",JSON.stringify(report));w.set_paused(false);w.audio_fx.shutdown();w.free();quit()
func mean(values: Array) -> float:
 var total:=0.0
 for v in values:total+=v
 return total/maxi(1,values.size())
