extends SceneTree
const Game=preload("res://convergence/game.gd")
var w: Node3D
func _initialize()->void:call_deferred("run")
func frames(n:int)->void:
    for i in range(n):await process_frame
func shot(label:String)->void:
    await RenderingServer.frame_post_draw
    var result:int=root.get_texture().get_image().save_png("user://city-"+label+".png")
    print("CITY_CAPTURE ",label," ",result)
func run()->void:
    w=Game.new();w.load_on_start=false;w.world_seed_override=101
    w.save_path="user://city-visual.json";w.settings_path="user://city-visual.cfg"
    root.add_child(w);await frames(8)
    w.flow.phase="creator";w.flow.create_character({"name":"Urban QA","race":0,"path":0,"robe":1,"skin":0,"hair":0,"style":0,"weapon":"sword"},101);w.ui.resume()
    for i in range(400):
        if w.current_region>=0 and not w.changing_region:break
        await physics_frame
    for scale_name in ["village","town","city"]:
        for spec in w.atlas.regions:
            if str(spec.kind)!="settlement" or str(spec.settlement_scale)!=scale_name:continue
            if not await w.change_region(int(spec.id)):quit(1);return
            await frames(25)
            var row:Dictionary=w.active_region.data.lots[0]
            w.player.position=Vector3(row.door.x,w.active_region.data.height_at(row.door)+.1,row.door.y)+Vector3(1.5,0,1.5)
            w.player.velocity=Vector3.ZERO;w.update_camera();await frames(15)
            await shot(scale_name+"-street")
            w.simulation_enabled=false
            var center:=Vector3.ZERO
            var extent:float=20.0
            for lot in w.active_region.data.lots:center+=Vector3(lot.p.x,0,lot.p.y)
            center/=float(w.active_region.data.lots.size());center.y=w.active_region.data.center_h
            for lot in w.active_region.data.lots:extent=maxf(extent,Vector2(lot.p.x-center.x,lot.p.y-center.z).length()+10.0)
            w.camera.size=extent*1.7
            w.camera.global_position=center+Vector3(100,140,100)
            w.camera.look_at(center,Vector3.UP)
            for layer in w.find_children("*","CanvasLayer",true,false):layer.visible=false
            await frames(8);await shot(scale_name+"-panorama")
            for layer in w.find_children("*","CanvasLayer",true,false):layer.visible=true
            w.camera.size=18.0;w.simulation_enabled=true
            break
    w.free();await process_frame;quit()
