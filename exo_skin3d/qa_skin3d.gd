extends SceneTree
# Run inside Godot 4.6.2: godot --headless --path PROJECT --script res://exo_skin3d/qa_skin3d.gd
# For REAL screenshots use a Compatibility-capable display (e.g., xvfb-run).
const Rig=preload("res://rig.gd")
const Wardrobe=preload("res://wardrobe.gd")
const UV=preload("res://exo_skin3d/uv_layout.gd")
const Codec=preload("res://exo_skin3d/profile_codec.gd")
const Importer=preload("res://exo_skin3d/skin_importer.gd")
const NPC=preload("res://exo_skin3d/appearance_adapter.gd")
const Save=preload("res://journey_save.gd")
var log: Array[Dictionary]=[]
var failures: int=0
var output_path: String="user://exo_skin3d_qa/"

func _initialize() -> void:
    call_deferred("_run")

func check(condition: bool,name: String,notes: String="") -> void:
    log.append({"test":name,"passed":condition,"detail":notes})
    if not condition:
        failures+=1
        push_error("SKIN3D QA FAIL: "+name+" "+notes)

func body() -> Dictionary:
    return {"name":"Teste Skin 3D","race":0,"path":0,"robe":0,"hair":0,"skin":0,"style":0,"outfit":1,"haircut":3,"weapon":"sword"}

func _test_uv() -> void:
    for part in UV.PARTS:
        for slim in [false,true]:
            var d: Vector3i=UV.dimensions(part,slim)
            var r: Array[Rect2]=UV.face_rects(part,true,slim)
            check(r.size()==6,"uv_faces_%s_%s" % [part,slim])
            check(int(r[0].size.x)==d.x and int(r[0].size.y)==d.y,"uv_front_%s_%s"%[part,slim])
            for face in r:
                check(face.position.x>=0 and face.position.y>=0 and face.end.x<=64 and face.end.y<=64,"uv_in_bounds_%s_%s"%[part,slim])
            var upper: Array[Rect2]=UV.face_rects(part,true,slim,0)
            var lower: Array[Rect2]=UV.face_rects(part,true,slim,1)
            check(int(upper[0].end.y)==int(lower[0].position.y),"uv_joint_contiguous_%s_%s"%[part,slim])
    check(UV.dimensions("right_arm",true).x==3,"slim_exactly_3px")
    check(UV.dimensions("right_arm",false).x==4,"classic_exactly_4px")

func _run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_path))
    _test_uv()
    var fixture: String=ProjectSettings.globalize_path("res://exo_skin3d/fixtures/hybrid_test_64.png")
    var source_hash: String=FileAccess.get_md5(fixture)
    var skin_file: String=Importer.import_file(fixture)
    check(not skin_file.is_empty(),"import_png_64")
    check(FileAccess.get_md5(skin_file)==source_hash,"png_binary_unchanged")
    var stage:=Node3D.new()
    get_root().add_child(stage)
    var rig=Rig.new()
    stage.add_child(rig)
    var profile: Dictionary=body()
    profile.skin_file=skin_file
    profile.skin3d=Codec.defaults()
    Wardrobe.apply(rig,profile)
    var layers: Dictionary=rig.get_meta("skin3d_layers",{})
    check(layers.get("head",[]).size()==1,"head_overlay_present")
    check(layers.get("right_arm",[]).size()==2,"elbow_overlay_splits")
    check(layers.get("right_leg",[]).size()==2,"knee_overlay_splits")
    var head_mat: StandardMaterial3D=layers.head[0].material_override
    check(head_mat.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR,"transparent_scissor")
    var original_socket: Node3D=rig.sword
    var base_pos: Vector3=rig.arms[0].position
    var old_triangles: int=(rig.arms[0].get_child(0) as MeshInstance3D).mesh.get_faces().size()/3
    profile.skin3d.model="slim"
    Wardrobe.apply(rig,profile)
    check(rig.arms[0].position.x>base_pos.x,"slim_shoulder_inwards")
    check(rig.sword==original_socket,"weapon_socket_preserved")
    check((rig.arms[0].get_child(0) as MeshInstance3D).mesh.get_faces().size()/3==old_triangles,"slim_same_triangle_budget")
    var slim_layers: Dictionary=rig.get_meta("skin3d_layers",{})
    check(slim_layers.get("left_arm",[]).size()==2,"slim_sleeve_split")
    profile.skin3d.layers.head=false
    Wardrobe.apply(rig,profile)
    check(rig.get_meta("skin3d_layers",{}).head.is_empty(),"head_layer_switch")
    profile.skin3d.layers.head=true
    profile.skin3d.accessories={"hair":"topknot","waist":"jade_belt","sheath":"sword_sheath"}
    profile.skin3d.equipment={"chest":"guard_cuirass","head":"iron_helm"}
    Wardrobe.apply(rig,profile)
    check(rig.get_meta("skin3d_layers",{}).head[0].visible==false,"helmet_occludes_hat")
    check(rig.get_meta("skin3d_layers",{}).torso[0].visible==false,"armor_occludes_jacket")
    check(rig.get_meta("skin3d_instances",[]).size()>10,"modular_volume_installed")
    var pre_stress_count: int=rig.get_meta("skin3d_instances",[]).size()
    var start_us: int=Time.get_ticks_usec()
    for i in range(75):
        profile.skin3d.model="classic" if i%2==0 else "slim"
        Wardrobe.apply(rig,profile)
        rig.pose(float(i)*0.1,i%2==0,false,true,0.5 if i%3==0 else -1.0)
    check(rig.get_meta("skin3d_instances",[]).size()==pre_stress_count,"75_reapply_no_duplication")
    check(rig.sword==original_socket,"75_reapply_weapon_integrity")
    profile.skin3d.model="classic"
    Wardrobe.apply(rig,profile)
    check(rig.arms[0].position==base_pos,"classic_shoulders_restored")
    check(Codec.valid(profile.skin3d),"cosmetic_profile_valid")
    var old: Dictionary=body()
    check(Codec.valid(Codec.normalized(old)),"legacy_defaults")
    check(NPC.npc_cosmetics("resident/1","guard","patrol")==NPC.npc_cosmetics("resident/1","guard","patrol"),"npc_deterministic")
    check(NPC.npc_cosmetics("resident/1","master")!=NPC.npc_cosmetics("resident/1","guard"),"npc_profession_variation")
    var save=Save.new("user://skin3d_qa_journey.json",123)
    save.data.character=profile.duplicate(true)
    check(save.valid(save.data),"legacy_v4_with_optional_skin3d_valid")
    check(save.write(),"save_write")
    var loaded=Save.new("user://skin3d_qa_journey.json",123)
    check(loaded.load_progress(),"save_reload")
    check(loaded.data.get("character",{}).get("skin3d",{})==profile.skin3d,"save_cosmetics_exact")
    check(loaded.data.get("character",{}).get("skin_file","")==skin_file,"save_png_path_exact")
    check(FileAccess.get_md5(skin_file)==source_hash,"original_png_after_reload")
    var ms: float=float(Time.get_ticks_usec()-start_us)/1000.0
    log.append({"test":"75_reapply_wall_ms","passed":true,"detail":"%.2f"%ms})
    await _screenshots(stage,rig,profile)
    var report: Dictionary={"engine":Engine.get_version_info(),"renderer":RenderingServer.get_video_adapter_name(),"tests":log,"failures":failures,"elapsed_75_reapply_ms":ms}
    var file:=FileAccess.open(output_path+"result.json",FileAccess.WRITE)
    if file!=null:file.store_string(JSON.stringify(report,"  "));file.close()
    print("EXO SKIN3D QA ","PASS" if failures==0 else "FAIL"," errors=",failures," results=",log.size()," report=",ProjectSettings.globalize_path(output_path+"result.json"))
    quit(0 if failures==0 else 1)

func _screenshots(stage: Node3D,rig: Node3D,profile: Dictionary) -> void:
    # The image is a genuine engine viewport render, never a mockup.
    var viewport:=SubViewport.new()
    viewport.size=Vector2i(640,640)
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    viewport.transparent_bg=false
    get_root().add_child(viewport)
    stage.get_parent().remove_child(stage)
    viewport.add_child(stage)
    var camera:=Camera3D.new()
    viewport.add_child(camera)
    camera.current=true
    camera.fov=42
    var ambient:=WorldEnvironment.new()
    ambient.environment=Environment.new()
    ambient.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    ambient.environment.ambient_light_color=Color.WHITE
    ambient.environment.ambient_light_energy=.65
    viewport.add_child(ambient)
    var light:=DirectionalLight3D.new()
    viewport.add_child(light);light.rotation=Vector3(-.9,.65,.0)
    var clean_profile: Dictionary=profile.skin3d.duplicate(true)
    var cases=[
        {"id":"00_baseline_sem_overlay","baseline":true,"slim":false,"yaw":0.0,"pose":"idle"},
        {"id":"01_classic_front","slim":false,"yaw":0.0,"pose":"idle"},
        {"id":"02_classic_side","slim":false,"yaw":1.2,"pose":"walk"},
        {"id":"03_classic_back","slim":false,"yaw":3.1,"pose":"attack"},
        {"id":"04_slim_front","slim":true,"yaw":0.0,"pose":"idle"},
        {"id":"05_slim_side","slim":true,"yaw":1.2,"pose":"walk"},
        {"id":"06_slim_attack","slim":true,"yaw":2.2,"pose":"attack"}
    ]
    var baseline_png: PackedByteArray=PackedByteArray()
    for test_case in cases:
        profile.skin3d=clean_profile.duplicate(true)
        profile.skin3d.model="slim" if test_case.slim else "classic"
        if test_case.get("baseline",false):
            for part in Codec.LAYERS:profile.skin3d.layers[part]=false
            profile.skin3d.accessories={}
            profile.skin3d.equipment={}
        Wardrobe.apply(rig,profile)
        rig.pose(0.4,test_case.pose=="walk",false,true,0.47 if test_case.pose=="attack" else -1.0)
        camera.position=Vector3(sin(test_case.yaw)*3.4,2.0,cos(test_case.yaw)*3.4)
        camera.look_at(Vector3(0,1.05,0))
        await process_frame
        await process_frame
        await RenderingServer.frame_post_draw
        var screenshot: Image=viewport.get_texture().get_image()
        var dest: String=output_path+test_case.id+".png"
        var ok: bool=screenshot!=null and screenshot.get_width()==640 and screenshot.save_png(dest)==OK
        var colors: Dictionary={}
        if ok:
            for sy in range(4,640,4):
                for sx in range(4,640,4):
                    var color: Color=screenshot.get_pixel(sx,sy)
                    colors[color.to_html(false)]=true
        check(ok and colors.size()>8,"capture_"+test_case.id,"must be an actual nonblank viewport render")
        if ok:
            var png_bytes: PackedByteArray=FileAccess.get_file_as_bytes(dest)
            if test_case.get("baseline",false):baseline_png=png_bytes
            elif test_case.id=="01_classic_front":
                check(png_bytes!=baseline_png,"new_visual_differs_from_baseline")
    viewport.remove_child(stage)
    viewport.queue_free()
    stage.queue_free()
