extends SceneTree
const Game=preload("res://convergence/game.gd")
func _initialize():call_deferred("run")
func run():
 Engine.max_fps=0
 var w:Node3D=Game.new();w.load_on_start=false;w.save_path="user://v4_benchmark.json";w.settings_path="user://v4_benchmark.cfg";root.add_child(w);await process_frame
 w.flow.phase="creator"
 w.flow.create_character({"name":"Benchmark QA","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0,"weapon":"sword","outfit":0},101)
 for i in range(1600):
  await physics_frame
  if w.current_region>=0 and not w.changing_region:break
 await w.change_region(78);w.ui.resume();w.graphics.set_option("vsync",0);w.camera.size=15
 for i in range(30):await process_frame
 var durations:Array=[];var calls:Array=[];var rss:Array=[];var cpu:Array=[]
 var started:int=Time.get_ticks_usec();var last:int=started
 var at:Vector3=w.player.position
 var previous_position:Vector3=at
 var traveled_m:float=0.0
 Input.action_press("right")
 for i in range(240):
  if i==120:Input.action_release("right");Input.action_press("left")
  await process_frame
  traveled_m+=w.player.position.distance_to(previous_position);previous_position=w.player.position
  var now:int=Time.get_ticks_usec();durations.append(float(now-last)/1000.0);last=now
  calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
  rss.append(OS.get_static_memory_usage());cpu.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000.0)
 Input.action_release("left")
 var wall:float=float(Time.get_ticks_usec()-started)/1000000.0
 durations.sort();calls.sort();rss.sort();cpu.sort()
 var tail:float=0.0
 for i in range(237,240):tail+=float(durations[i])
 var result:Dictionary={"status":"PASS_MEASUREMENT_ONLY","engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"resolution":str(root.size),"seed":101,"region":78,"camera_size":w.camera.size,"samples":240,"wall_seconds":wall,"average_fps":240.0/wall,"one_percent_low_fps":1000.0/(tail/3.0),"p95_frame_ms":durations[227],"p99_frame_ms":durations[237],"max_frame_ms":durations[-1],"process_monitor_p95_ms":cpu[227],"draw_calls_p95":calls[227],"godot_static_memory_peak_bytes":rss[-1],"real_npcs":w.residents.size(),"crowd":w.exo_core.services.invoke("crowd.illusion","status"),"controller_displacement_m":w.player.position.distance_to(at),"controller_traveled_m":traveled_m,"limits":"llvmpipe CPU; one candidate run; no Vega8/Android claim; 240 frames with automated input; OS static memory is not whole-process RSS"}
 FileAccess.open("res://V4_CHECKPOINT/evidence/benchmark-v4.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
 print("BENCHMARK_V4 ",JSON.stringify(result))
 w.queue_free();await process_frame;await process_frame;quit()
