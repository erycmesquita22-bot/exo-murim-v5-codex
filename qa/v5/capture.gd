extends SceneTree
const Game=preload("res://convergence/game.gd")
var w: Node3D
func _initialize() -> void:call_deferred("run")
func frames(n: int) -> void:
    for i in range(n):await process_frame
func shot(name_value: String) -> void:
    await RenderingServer.frame_post_draw
    var img: Image=root.get_texture().get_image()
    var code: int=img.save_png("user://"+name_value+".png")
    print("CAPTURE ",name_value," ",code," ",img.get_size())
func run() -> void:
    root.size=Vector2i(1280,720)
    w=Game.new();w.load_on_start=false;w.world_seed_override=101;w.save_path="user://visual.json";w.settings_path="user://visual.cfg"
    root.add_child(w);await frames(8)
    await shot("v5-menu")
    w.flow.phase="creator";w.ui.show_creator();await frames(8)
    await shot("v5-creator")
    w.flow.create_character({"name":"Visual V5","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0,"weapon":"sword"},101)
    w.ui.resume()
    for i in range(600):
        if w.current_region>=0 and not w.changing_region:break
        await physics_frame
    await frames(12)
    await shot("v5-settlement")
    w.graphics.set_option("fps_limit",0)
    var samples: Array=[]
    var last: int=Time.get_ticks_usec()
    for i in range(60):
        await process_frame
        var now: int=Time.get_ticks_usec();samples.append((now-last)/1000.0);last=now
    samples.sort()
    print("SOFTWARE_RENDER_MEASUREMENT ",JSON.stringify({"renderer":RenderingServer.get_video_adapter_name(),"samples":samples.size(),"median_ms":samples[30],"p95_ms":samples[57],"memory_bytes":OS.get_static_memory_usage(),"platform":"Linux virtual Xorg software OpenGL; not target PC/Android benchmark"}))
    var plan: Dictionary=w.wg5_visit.service.active_plan()
    var door: Array=plan.buildings[0].exterior_door
    w.player.global_position=Vector3(door[0],door[1],door[2]);w.player.velocity=Vector3.ZERO
    w.simulation_enabled=false
    if w.wg5_visit.try_interact():
        w.simulation_enabled=true
        for i in range(60):await physics_frame
        await shot("v5-interior")
    w.free();await process_frame;quit()
