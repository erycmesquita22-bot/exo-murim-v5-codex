extends SceneTree
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    root.size=Vector2i(1440,780)
    var stage:=Node3D.new();root.add_child(stage)
    var e:=WorldEnvironment.new();stage.add_child(e)
    e.environment=Environment.new();e.environment.background_mode=Environment.BG_COLOR
    e.environment.background_color=Color("1a2229")
    e.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    e.environment.ambient_light_color=Color.WHITE
    e.environment.ambient_light_energy=0.55
    var sun:=DirectionalLight3D.new();stage.add_child(sun)
    sun.rotation_degrees=Vector3(-53,-22,0);sun.light_energy=1.2
    var camera:=Camera3D.new();stage.add_child(camera)
    camera.current=true;camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=10.8;camera.position=Vector3(4,3.7,-13);camera.look_at(Vector3(0,1.1,0))
    var ids: Array=["spear","greatsword","bow","crossbow","quarterstaff"]
    for i in range(ids.size()):
        var rig:=preload("res://rig.gd").new();stage.add_child(rig)
        rig.position=Vector3((i-2)*2.4,0,0)
        preload("res://arsenal.gd").equip(rig,ids[i])
        rig.pose(0.0,false,false,true)
        preload("res://arsenal.gd").animate(rig,preload("res://catalog.gd").weapon(ids[i]),0,-1)
        var tag:=Label3D.new();stage.add_child(tag);tag.text=ids[i];tag.font_size=36;tag.pixel_size=.014;tag.position=rig.position+Vector3(0,2.65,0)
    for i in range(10):await process_frame
    await RenderingServer.frame_post_draw
    var image:Image=root.get_texture().get_image()
    var status:int=image.save_png("/mnt/data/EXO-ROUND2-ARMA-VISUAL-QA.png")
    print("EXO_GRIP_VISUAL ",status," ",image.get_size())
    stage.free();quit(0)
