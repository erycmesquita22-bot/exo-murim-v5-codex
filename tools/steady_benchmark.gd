extends SceneTree
var w: Node3D
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(960,600);DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 w=load("res://main.gd").new();w.load_on_start=false;w.save_path="user://steady092.json";w.settings_path="user://steady092.cfg";root.add_child(w);await process_frame
 w.flow.phase="creator";w.flow.create_character({"name":"Benchmark","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0,"weapon":"sword"});w.ui.resume();w.graphics.select(1)
 for a in w.enemies:a.enabled=false
 w.player.position=Vector3(0,.03,28);w.camera.size=15
 for i in range(120):await process_frame
 var samples:Array=[];var physics:Array=[];var process:Array=[]
 for i in range(120):
  var before=Time.get_ticks_usec();await process_frame;samples.append((Time.get_ticks_usec()-before)/1000.0)
  physics.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000);process.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
 samples.sort()
 print("STEADY_BENCHMARK ",JSON.stringify({"quality":1,"resolution":"960x600","renderer":RenderingServer.get_video_adapter_name(),"warmup_frames":120,"sample_frames":120,"frame_ms_mean":mean(samples),"frame_ms_median":samples[60],"frame_ms_p95":samples[114],"physics_ms_mean":mean(physics),"process_ms_mean":mean(process),"static_memory_mb":Performance.get_monitor(Performance.MEMORY_STATIC)/1048576,"video_memory_mb":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1048576,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"resources":Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)}))
 w.audio_fx.shutdown();w.queue_free();await process_frame;await process_frame;quit()
func mean(a:Array)->float:
 var sum_value=0.0
 for v in a:sum_value+=v
 return sum_value/maxi(1,a.size())
