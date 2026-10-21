extends RefCounted
const UV=preload("res://exo_skin3d/uv_layout.gd")
const BODYPARTS=["head","torso","right_arm","left_arm","right_leg","left_leg"]

static func layer_material(texture: Texture2D) -> StandardMaterial3D:
    var mat:=StandardMaterial3D.new()
    mat.albedo_texture=texture
    mat.albedo_color=Color.WHITE
    mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
    # Alpha scissor avoids coplanar blending and sort artifacts in Compatibility.
    mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
    mat.alpha_scissor_threshold=0.5
    mat.cull_mode=BaseMaterial3D.CULL_DISABLED
    mat.roughness=0.88
    return mat

static func create(parent: Node3D,center: Vector3,base_size: Vector3,part: String,segment: int,slim: bool,mat: Material) -> MeshInstance3D:
    var inflation: float=0.03125 if part=="head" else 0.015625
    var instance:=MeshInstance3D.new()
    instance.name="Skin3D_"+part+("_lower" if segment==1 else "_upper" if segment==0 else "")
    instance.mesh=UV.build_box(base_size+Vector3.ONE*(inflation*2.0),part,true,slim,segment)
    instance.material_override=mat
    parent.add_child(instance)
    instance.position=center
    instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    return instance

static func build(rig: Node3D,profile: Dictionary) -> Dictionary:
    var result: Dictionary={}
    var texture: Texture2D=rig.skin.albedo_texture
    if texture==null:return result
    var image: Image=texture.get_image()
    var slim: bool=str(profile.get("model","classic"))=="slim"
    var mat: Material=layer_material(texture)
    var head: Node3D=rig.torso.get_child(1)
    for part in BODYPARTS:
        result[part]=[]
        if not bool(profile.layers.get(part,true)) or not UV.has_alpha_content(image,part,slim):continue
        if part=="head":
            result[part].append(create(head,Vector3(0,.25,0),Vector3(.5,.5,.5),part,-1,slim,mat))
        elif part=="torso":
            result[part].append(create(rig.torso,Vector3(0,.375,0),Vector3(.5,.75,.25),part,-1,slim,mat))
        else:
            var i: int=0 if part.begins_with("right_") else 1
            var upper: Node3D=rig.arms[i] if part.ends_with("arm") else rig.legs[i]
            var lower: Node3D=rig.forearms[i] if part.ends_with("arm") else rig.calves[i]
            var width: float=.1875 if slim and part.ends_with("arm") else .25
            var size: Vector3=Vector3(width,.375,.25)
            result[part].append(create(upper,Vector3(0,-.1875,0),size,part,0,slim,mat))
            result[part].append(create(lower,Vector3(0,-.1875,0),size,part,1,slim,mat))
    return result
