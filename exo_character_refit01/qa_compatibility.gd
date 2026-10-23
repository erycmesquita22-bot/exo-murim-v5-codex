extends SceneTree
const Rig=preload("res://rig.gd")
const Wardrobe=preload("res://wardrobe.gd")
const Codec=preload("res://exo_skin3d/profile_codec.gd")
var failures:Array[String]=[]
func check(value:bool,label:String)->void:
    if not value:
        failures.append(label)
        push_error("EXO_REFIT_COMPAT_FAIL "+label)
func _initialize()->void:
    call_deferred("_test")
func _test()->void:
    var rig:=Rig.new()
    root.add_child(rig)
    var p:Dictionary={"race":0,"robe":2,"hair":0,"skin":2,"outfit":3,"weapon":"sword","skin3d":Codec.defaults()}
    Wardrobe.apply(rig,p)
    check(rig.get_meta("exo_character_refit_version",0)==1,"authoritative rig")
    var material:Material=rig.skin
    check(rig.skin.albedo_texture.get_image().get_width() == 256,"native image 256 px")
    var initial_scale:Vector3=rig.scale
    Wardrobe.apply(rig,p)
    check(rig.scale.is_equal_approx(initial_scale),"scale doesn't accumulate")
    p.skin3d.model="slim"
    Wardrobe.apply(rig,p)
    check(is_equal_approx(rig.arms[0].get_child(0).mesh.get_aabb().size.x, .1875),"slim arm 3 px")
    var path:String="user://exo_skins/refit_qa_64.png"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://exo_skins"))
    var custom:=Image.create(64,64,false,Image.FORMAT_RGBA8)
    custom.fill(Color.TRANSPARENT)
    for block in [Rect2i(0,0,32,16),Rect2i(0,16,56,16),Rect2i(0,32,64,32)]:
        custom.fill_rect(block,Color("b68d68"))
    check(custom.save_png(path)==OK,"64 custom PNG created")
    p.skin_file=path
    Wardrobe.apply(rig,p)
    check(rig.skin.albedo_texture.get_image().get_width()==64,"literal 64x64 texture")
    check(rig.get_meta("garments",[]).is_empty(),"custom skins not covered by robes")
    p.erase("skin_file")
    Wardrobe.apply(rig,p)
    check(not rig.get_meta("garments",[]).is_empty(),"refit clothes restored")
    check(not rig.has_meta("exo_humanoid_r2_roots"),"old visual roots never coexist")
    print("EXO_REFIT_COMPAT ",JSON.stringify({"failures":failures,"native_uv":64,"original_skin_supported":true,"rig_contract":2}))
    quit(0 if failures.is_empty() else 1)
