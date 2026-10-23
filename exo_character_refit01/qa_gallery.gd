extends SceneTree
const Rig=preload("res://rig.gd")
const Wardrobe=preload("res://wardrobe.gd")
const Catalog=preload("res://catalog.gd")
const Visual=preload("res://convergence/visual_actor_r10.gd")
var errors:Array[String]=[]
var models:Array=[]

func _initialize() -> void:
    call_deferred("run")

func expect(ok:bool,desc:String)->void:
    if not ok:
        errors.append(desc)
        push_error("EXO_REFIT_QA_FAIL "+desc)

func count_nodes(node:Node)->int:
    var total:int=1
    for child in node.get_children():total+=count_nodes(child)
    return total

func count_meshes(node:Node)->int:
    var total:int=1 if node is MeshInstance3D and node.mesh!=null else 0
    for child in node.get_children():total+=count_meshes(child)
    return total

func new_char(parent:Node3D,at:Vector3,profile:Dictionary)->Node3D:
    var rig:Node3D=Rig.new()
    parent.add_child(rig)
    rig.position=at
    Wardrobe.apply(rig,profile)
    models.append(rig)
    return rig

func run()->void:
    var world:=Node3D.new()
    root.add_child(world)
    var environment:=WorldEnvironment.new()
    environment.environment=Environment.new()
    environment.environment.background_mode=Environment.BG_COLOR
    environment.environment.background_color=Color("192d38")
    environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color=Color("e1eaf1")
    environment.environment.ambient_light_energy=.65
    world.add_child(environment)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-50,-25,0)
    sun.light_energy=1.35
    world.add_child(sun)
    var spots: Array[Dictionary]=[
        {"name":"Discipulo Jade", "profile":{"race":0,"robe":2,"skin":1,"hair":0,"outfit":0,"style":0,"haircut":0,"weapon":"sword"}},
        {"name":"Andarilha Carmesim", "profile":{"race":0,"robe":3,"skin":2,"hair":0,"outfit":3,"style":1,"haircut":2,"weapon":"spear"}},
        {"name":"Guardiao do Rio", "profile":{"race":0,"robe":1,"skin":3,"hair":3,"outfit":1,"style":0,"haircut":1,"weapon":"bow"}},
        {"name":"Artista do Qi", "profile":{"race":0,"robe":4,"skin":0,"hair":4,"outfit":3,"style":2,"haircut":0,"weapon":"arcane_staff"}}
    ]
    for i in range(spots.size()):
        var p:Dictionary=spots[i]
        var rig:Node3D=new_char(world,Vector3((float(i)-1.5)*1.9,0,0),p.profile)
        rig.rotation.y=.20 if i%2==0 else -.20
        expect(rig.get_meta("exo_character_refit_version",0)==1,"refit owner "+str(i))
        expect(rig.torso.get_child(0) is MeshInstance3D,"torso legacy mesh contract")
        expect(rig.torso.get_child(1) is Node3D,"head legacy node contract")
        expect(rig.arms.size()==2 and rig.forearms.size()==2,"limb contracts")
        expect(count_meshes(rig.sword)==0,"old sword visual removed")
        expect(rig.get_meta("weapon_root",null)!=null,"weapon instance equipped "+str(i))
        expect(count_meshes(rig)>8,"rendered character has parts "+str(i))
        var owned: Array=rig.get_meta("garments",[])
        expect(owned.size()>=6,"garment owner "+str(i))
        print("EXO_REFIT_MODEL ",p.name," nodes=",count_nodes(rig)," meshes=",count_meshes(rig)," garments=",owned.size())
    var first:Node3D=models[0]
    var before:int=count_nodes(first)
    for i in range(4):Wardrobe.apply(first,spots[0].profile)
    await process_frame
    await process_frame
    var after:int=count_nodes(first)
    expect(abs(after-before)<10,"reapplying same profile does not stack models %s %s"%[before,after])
    expect(not first.has_meta("exo_humanoid_r2_roots"),"no R2 geometry")
    # R2 selection stays serialized but extra meshes must not be generated.
    var r2_result:Dictionary=Visual.apply_resident(first,{"id":"npc/r01/char_refit_qa","role":"guard","appearance":spots[0].profile}, {}, "123")
    expect(not first.has_meta("exo_humanoid_r2_roots"),"R2 bridge respects exclusive refit ownership")
    # Validate all equipment categories against the same canonical rig.
    for wid in ["sword","dagger","greatsword","spear","halberd","scythe","quarterstaff","arcane_staff","bow","crossbow","gauntlets"]:
        var profile:Dictionary=spots[0].profile.duplicate(true)
        profile.weapon=wid
        Wardrobe.apply(first,profile)
        expect(str(first.get_meta("weapon_id",""))==wid,"weapon id "+wid)
        expect(first.get_meta("weapon_root",null)!=null,"weapon root "+wid)
    # Restore first character for gallery
    Wardrobe.apply(first,spots[0].profile)
    for i in range(models.size()):
        var stage:=MeshInstance3D.new()
        stage.mesh=BoxMesh.new()
        stage.mesh.size=Vector3(1.46,.18,1.35)
        var mat:=StandardMaterial3D.new()
        mat.albedo_color=Color("4b5153") if i%2==0 else Color("45464d")
        stage.material_override=mat
        world.add_child(stage)
        stage.position=Vector3((float(i)-1.5)*1.9,-.16,0)
    var camera:=Camera3D.new()
    world.add_child(camera)
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=5.8
    camera.position=Vector3(2.9,3.8,-10.8)
    camera.look_at(Vector3(0,1.1,0),Vector3.UP)
    camera.current=true
    root.size=Vector2i(1500,850)
    for frame in range(8):await process_frame
    var png:Image=root.get_texture().get_image()
    var path: String="res://exo_character_refit01/refit_gallery_real.png"
    var code:Error=png.save_png(ProjectSettings.globalize_path(path))
    expect(code==OK,"capture screenshot")
    print("EXO_REFIT_QA_TOTAL ",JSON.stringify({"failures":errors,"screenshot":path,"screenshot_size":[png.get_width(),png.get_height()],"render_method":RenderingServer.get_current_rendering_method(),"character_count":models.size(),"r2_selection_kept":not r2_result.is_empty()}))
    quit(0 if errors.is_empty() else 1)
