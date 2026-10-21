extends RefCounted
const Codec=preload("res://exo_skin3d/profile_codec.gd")
const Wardrobe=preload("res://wardrobe.gd")

# Uses the same EXO rig as the real actor (not a replacement preview avatar).
static func update(rig: Node3D,profile: Dictionary) -> void:
    if is_instance_valid(rig):Wardrobe.apply(rig,profile)

static func set_model(profile: Dictionary,model: String) -> Dictionary:
    return Codec.with_model(profile,model=="slim")

static func set_layer(profile: Dictionary,part: String,enabled: bool) -> Dictionary:
    var copy: Dictionary=profile.duplicate(true)
    var cosmetic: Dictionary=Codec.normalized(copy)
    if part in Codec.LAYERS:cosmetic.layers[part]=enabled
    copy.skin3d=cosmetic
    return copy

static func demonstrate_pose(rig: Node3D,pose_name: String,time: float=0.0) -> void:
    if not is_instance_valid(rig):return
    match pose_name:
        "walk":rig.pose(time,true,false,true)
        "attack":rig.pose(time,false,false,true,0.45)
        "roll":rig.pose(time,false,false,true,-1,0.45)
        "jump":rig.pose(time,false,false,false)
        _:rig.pose(time,false,false,true)

    # Rig.pose resets both arms each frame. Apply the same weapon-specific
    # grip as gameplay afterwards, especially for torso-mounted bows/crossbows.
    var spec: Dictionary=preload("res://catalog.gd").weapon(str(rig.get_meta("weapon_id","sword")))
    preload("res://arsenal.gd").animate(rig,spec,0,fmod(time,1.0) if pose_name=="attack" else -1.0)
