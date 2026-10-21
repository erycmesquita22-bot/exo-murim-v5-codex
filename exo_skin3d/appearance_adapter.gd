extends RefCounted
const Codec=preload("res://exo_skin3d/profile_codec.gd")
const UV=preload("res://exo_skin3d/uv_layout.gd")
const Overlays=preload("res://exo_skin3d/overlay_builder.gd")
const Gear=preload("res://exo_skin3d/equipment_visuals.gd")

static func _arms_baseline(rig: Node3D) -> void:
    if rig.has_meta("skin3d_arm_baseline"):return
    var baseline: Dictionary={"positions":[],"upper":[],"lower":[]}
    for i in range(2):
        baseline.positions.append(rig.arms[i].position)
        baseline.upper.append((rig.arms[i].get_child(0) as MeshInstance3D).mesh)
        baseline.lower.append((rig.forearms[i].get_child(0) as MeshInstance3D).mesh)
    rig.set_meta("skin3d_arm_baseline",baseline)

static func _set_arms(rig: Node3D,slim: bool) -> void:
    _arms_baseline(rig)
    var baseline: Dictionary=rig.get_meta("skin3d_arm_baseline")
    for i in range(2):
        var part: String="right_arm" if i==0 else "left_arm"
        var upper: MeshInstance3D=rig.arms[i].get_child(0)
        var lower: MeshInstance3D=rig.forearms[i].get_child(0)
        rig.arms[i].position=baseline.positions[i]
        upper.mesh=baseline.upper[i]
        lower.mesh=baseline.lower[i]
        if slim:
            rig.arms[i].position.x+=.03125 if i==0 else -.03125
            upper.mesh=UV.build_box(Vector3(.1875,.375,.25),part,false,true,0)
            lower.mesh=UV.build_box(Vector3(.1875,.375,.25),part,false,true,1)

static func _remove_previous(rig: Node3D) -> void:
    for item in rig.get_meta("skin3d_instances",[]):
        if is_instance_valid(item):
            item.get_parent().remove_child(item)
            item.queue_free()
    rig.set_meta("skin3d_instances",[])
    rig.set_meta("skin3d_layers",{})

static func apply(rig: Node3D,profile: Dictionary) -> void:
    if rig==null or not is_instance_valid(rig) or rig.skin==null:return
    _remove_previous(rig)
    var skin3d: Dictionary=Codec.normalized(profile)
    var slim: bool=skin3d.model=="slim"
    _set_arms(rig,slim)
    var layers: Dictionary=Overlays.build(rig,skin3d)
    var owned: Array=[]
    for part in layers:owned.append_array(layers[part])
    owned.append_array(Gear.apply(rig,skin3d,layers))
    rig.set_meta("skin3d_instances",owned)
    rig.set_meta("skin3d_layers",layers)
    rig.set_meta("skin3d_cosmetics",skin3d)

static func npc_cosmetics(stable_id: String,occupation: String,faction: String="",seed_text: String="") -> Dictionary:
    # Local deterministic stream; no randomize(), no frame-time, no global RNG state.
    var c: Dictionary=Codec.defaults()
    var hash_value: int=abs((stable_id+"|"+occupation+"|"+faction+"|"+seed_text).hash())
    c.model="slim" if hash_value%5==0 else "classic"
    match occupation:
        "guard","soldier":
            c.equipment={"chest":"guard_cuirass","shoulders":"iron_pauldron"}
            if hash_value%2==0:c.equipment.head="iron_helm"
        "master","elder":
            c.accessories={"hair":"topknot","collar":"jade_collar","waist":"jade_belt","back":"short_cape"}
        "disciple","monk":
            c.accessories={"head":"headband","wrists":"wrist_wraps","waist":"jade_belt"}
        "outlaw","bandit","enemy":
            c.accessories={"head":"face_mask","wrists":"wrist_wraps","sheath":"sword_sheath"}
        "boss":
            c.equipment={"chest":"guard_cuirass","head":"iron_helm","boots":"iron_boots"}
            c.accessories={"back":"short_cape","sheath":"sword_sheath"}
        _:
            if hash_value%3==0:c.accessories={"waist":"jade_belt"}
            elif hash_value%3==1:c.accessories={"collar":"jade_collar"}
    return c
