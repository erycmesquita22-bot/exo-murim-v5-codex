extends SceneTree
const Game=preload("res://convergence/game.gd")
var w:Node3D
func _initialize()->void:call_deferred("run")
func frames(n:int)->void:
    for i in range(n):await process_frame
func shot(label:String)->void:
    await RenderingServer.frame_post_draw
    var code:int=root.get_texture().get_image().save_png("user://murim-"+label+".png")
    print("MURIM_CAPTURE ",label," ",code)
func run()->void:
    w=Game.new();w.load_on_start=false;w.world_seed_override=101
    w.save_path="user://murim-render.json";w.settings_path="user://murim-render.cfg"
    root.add_child(w);await frames(8)
    w.flow.phase="creator";w.flow.create_character({"name":"Murim Visual","race":0,"path":0,"robe":1,"skin":0,"hair":0,"style":0,"weapon":"sword"},101);w.ui.resume()
    for i in range(400):
        if w.current_region>=0 and not w.changing_region:break
        await physics_frame
    if not await w.change_region(14):quit(1);return
    await frames(15);w.simulation_enabled=false
    var center:=Vector3(0,w.active_region.data.center_h,0)
    var perimeter:Dictionary=w.active_region.get_meta("exo_architecture",{})
    print("RENDER_PERIMETER ",perimeter.get("status")," ",perimeter.get("reason",""))
    w.camera.far=1200
    w.camera.size=265;w.camera.position=center+Vector3(150,190,150);w.camera.look_at(center)
    for layer in w.find_children("*","CanvasLayer",true,false):layer.visible=false
    await frames(5);await shot("courtyard-enclosed-with-city-gates")
    for layer in w.find_children("*","CanvasLayer",true,false):layer.visible=true
    w.simulation_enabled=true;w.camera.size=18
    var wild:int=0
    for region in w.atlas.regions:
        if str(region.kind)=="wild" and str(region.biome) in ["temperate_forest","mixed_woodland"]:wild=int(region.id);break
    if not await w.change_region(wild):quit(1);return
    w.ecology_director.detach()
    var wolf:Dictionary=w.exo_core.services.invoke("bestiary.catalog","get_profile",["wolf"])
    var sites:Array=preload("res://regional_ecology/territories.gd").build_fauna(w.active_region.data,"101",[wolf],[])
    var point:=Vector3.ZERO
    for site in sites:
        point=Vector3(site.p.x,site.y,site.p.y)
        var anchor:Vector3=w.regional_spawn(w.active_region,point+Vector3(30,0,30))
        if not anchor.is_finite():continue
        w.player.position=anchor;w.player.velocity=Vector3.ZERO
        w.camera.position=anchor+Vector3(0,12,0);w.camera.look_at(anchor+Vector3(50,0,50))
        w.ecology_director.region_id=w.current_region;w.ecology_director.sites=[site];w.ecology_director.timer=0;w.ecology_director.tick(1)
        if w.ecology_director.active.size()>=3:break
    print("RENDER_WOLVES ",w.ecology_director.active.size())
    w.simulation_enabled=false
    w.camera.size=18;w.camera.position=point+Vector3(10,12,10);w.camera.look_at(point)
    await frames(8);await shot("wolf-pack-and-world-grid")
    w.free();await process_frame
    w=Game.new();w.load_on_start=false;w.world_seed_override=707
    w.save_path="user://murim-battle-render.json";w.settings_path="user://murim-battle-render.cfg"
    root.add_child(w);await frames(8)
    w.journey.data.hero=0;w.flow.start_prologue()
    for index in range(3):
        await frames(105)
        await shot("twelve-battle-"+str(index))
        w.simulation_enabled=false
        var focus:=Vector3(90,0,0)
        w.camera.size=34;w.camera.position=focus+Vector3(18,24,18);w.camera.look_at(focus)
        await frames(1);await shot("twelve-panorama-"+str(index))
        w.simulation_enabled=true;w.camera.size=20
    print("RENDER_BATTLE_SKILLS ",w.flow.actors.reduce(func(sum_value,actor):return sum_value+actor.skills_released,0))
    w.free();await process_frame;quit()
