extends SceneTree
const Game=preload("res://convergence/game.gd")
var w:Node3D
func _initialize()->void:call_deferred("run")
func frames(n:int)->void:
    for i in range(n):await process_frame
func capture(label:String)->void:
    await RenderingServer.frame_post_draw
    var code:int=root.get_texture().get_image().save_png("user://terrain-water-"+label+".png")
    print("TERRAIN_WATER_CAPTURE ",label," ",code)
func run()->void:
    w=Game.new();w.load_on_start=false;w.world_seed_override=101
    w.save_path="user://terrain-water-render.json";w.settings_path="user://terrain-water-render.cfg"
    root.add_child(w);await frames(8)
    w.flow.phase="creator"
    w.flow.create_character({"name":"Relief QA","race":0,"path":0,"robe":1,"skin":0,"hair":0,"style":0,"weapon":"sword"},101)
    w.ui.resume()
    for i in range(400):
        if w.current_region>=0 and not w.changing_region:break
        await physics_frame
    var target:int=-1
    for region in w.atlas.regions:
        if str(region.kind)=="wild" and str(region.biome) in ["rocky_highlands","alpine"]:
            target=int(region.id);break
    if target<0 or not await w.change_region(target):quit(1);return
    w.simulation_enabled=false
    for layer in w.find_children("*","CanvasLayer",true,false):layer.visible=false
    w.camera.far=900;w.camera.size=75
    var best:=Vector2(120,80);var gradient:=0.0
    for z in range(-180,181,20):
        for x in range(-180,181,20):
            var p:=Vector2(x,z)
            var here:float=w.active_region.data.terrain_height_at(p)
            var slope:float=absf(here-w.active_region.data.terrain_height_at(p+Vector2(8,0)))
            if slope>gradient and w.active_region.data.river_distance(p)>20:
                gradient=slope;best=p
    var focus:=Vector3(best.x,w.active_region.data.terrain_height_at(best),best.y)
    w.camera.position=focus+Vector3(45,65,45);w.camera.look_at(focus)
    await frames(8);await capture("highland-terraces")
    print("TERRAIN_WATER_HIGHLAND ",target," slope8 ",gradient)
    var water_region:int=-1
    for edge in w.atlas.rivers_macro:
        if str(w.atlas.regions[int(edge.from)].kind)!="settlement":water_region=int(edge.from);break
        if str(w.atlas.regions[int(edge.to)].kind)!="settlement":water_region=int(edge.to);break
    if water_region<0 and not w.atlas.rivers_macro.is_empty():water_region=int(w.atlas.rivers_macro[0].from)
    if water_region<0 or not await w.change_region(water_region):quit(1);return
    w.simulation_enabled=false
    var river:Dictionary=w.active_region.data.rivers[0]
    var point:Vector2=w.active_region.data.river_hub.lerp(river.p,0.56)
    var clearance:float=0.0
    for branch in w.active_region.data.rivers:
        for sample in range(2,19):
            var candidate:Vector2=w.active_region.data.river_hub.lerp(branch.p,float(sample)/20.0)
            var safe:float=w.active_region.data.road_distance(candidate)
            if safe>clearance and candidate.length()<200.0:
                clearance=safe;point=candidate;river=branch
    focus=Vector3(point.x,w.active_region.data.river_level(river,point),point.y)
    w.camera.size=35;w.camera.position=focus+Vector3(21,32,21);w.camera.look_at(focus)
    await frames(8);await capture("river-channel")
    print("TERRAIN_WATER_RIVER ",water_region," width ",w.active_region.data.river_half_width(river)," road_clearance ",clearance)
    quit()
