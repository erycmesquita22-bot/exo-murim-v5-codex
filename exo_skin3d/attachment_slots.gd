extends RefCounted
# Purely visual voxel modules. Never manipulates collision, attributes, animations or weapon sockets.
const SLOT_NAMES=["hair","head","collar","chest","shoulders","wrists","waist","front_skirt","back_skirt","boots","back","sheath"]
const COLORS={"cloth":Color("40596a"),"cloth_light":Color("647f89"),"steel":Color("778993"),"iron":Color("4e626c"),"gold":Color("c8aa72"),"leather":Color("49382e"),"jade":Color("63a596")}

static func block(parent: Node3D,pos: Vector3,size: Vector3,tint: Color) -> MeshInstance3D:
    var m:=MeshInstance3D.new()
    var cube:=BoxMesh.new();cube.size=size;m.mesh=cube
    var material:=StandardMaterial3D.new()
    material.albedo_color=tint;material.roughness=.86
    m.material_override=material
    parent.add_child(m);m.position=pos
    m.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    return m

static func pivot(rig: Node3D,slot: String) -> Node3D:
    if slot in ["hair","head"]:return rig.torso.get_child(1)
    return rig.torso

static func add(rig: Node3D,slot: String,id: String,armor: bool=false) -> Array[Node]:
    var nodes: Array[Node]=[]
    if slot not in SLOT_NAMES:return nodes
    var steel: Color=COLORS.steel if armor else COLORS.cloth
    var dark: Color=COLORS.iron if armor else COLORS.leather
    var gold: Color=COLORS.gold
    var p: Node3D=pivot(rig,slot)
    if id=="topknot" and slot=="hair":
        nodes.append(block(p,Vector3(0,.57,.01),Vector3(.23,.20,.23),dark))
        nodes.append(block(p,Vector3(0,.68,.01),Vector3(.27,.05,.27),gold))
    elif id=="headband" and slot=="head":
        nodes.append(block(p,Vector3(0,.40,-.264),Vector3(.53,.08,.035),dark))
        nodes.append(block(p,Vector3(0,.40,-.288),Vector3(.12,.06,.013),gold))
    elif id=="horns" and slot=="head":
        for side in [-1,1]:nodes.append(block(p,Vector3(side*.22,.61,0),Vector3(.10,.27,.12),dark))
    elif id=="face_mask" and slot=="head":
        nodes.append(block(p,Vector3(0,.12,-.279),Vector3(.42,.18,.035),dark))
        nodes.append(block(p,Vector3(0,.12,-.305),Vector3(.10,.10,.023),gold))
    elif id=="iron_helm" and slot=="head":
        nodes.append(block(p,Vector3(0,.515,0),Vector3(.57,.15,.57),steel))
        nodes.append(block(p,Vector3(0,.405,-.286),Vector3(.54,.09,.035),dark))
        for side in [-1,1]:nodes.append(block(p,Vector3(side*.285,.30,0),Vector3(.055,.22,.42),steel))
    elif id=="jade_collar" and slot=="collar":
        nodes.append(block(p,Vector3(0,.737,0),Vector3(.53,.09,.3),COLORS.jade))
        nodes.append(block(p,Vector3(0,.75,-.17),Vector3(.13,.08,.04),gold))
    elif id in ["martial_vest","guard_cuirass"] and slot=="chest":
        nodes.append(block(p,Vector3(0,.40,-.155),Vector3(.51,.56,.095),steel))
        nodes.append(block(p,Vector3(0,.21,-.216),Vector3(.52,.10,.045),dark))
        if armor:nodes.append(block(p,Vector3(0,.39,-.208),Vector3(.18,.26,.035),gold))
    elif id in ["shoulder_cloth","iron_pauldron"] and slot=="shoulders":
        for i in range(2):
            nodes.append(block(rig.arms[i],Vector3(0,-.075,0),Vector3(.29,.17,.31),steel))
            if armor:nodes.append(block(rig.arms[i],Vector3(0,-.015,-.17),Vector3(.23,.065,.035),gold))
    elif id in ["wrist_wraps","iron_bracers"] and slot=="wrists":
        for i in range(2):
            nodes.append(block(rig.forearms[i],Vector3(0,-.18,0),Vector3(.26,.21,.27),dark))
            nodes.append(block(rig.forearms[i],Vector3(0,-.25,-.145),Vector3(.22,.05,.018),gold if armor else COLORS.cloth_light))
    elif id=="jade_belt" and slot=="waist":
        nodes.append(block(p,Vector3(0,.115,0),Vector3(.54,.12,.34),dark))
        nodes.append(block(p,Vector3(0,.115,-.19),Vector3(.12,.13,.05),COLORS.jade))
    elif id in ["front_robe","back_robe"] and slot in ["front_skirt","back_skirt"]:
        var z: float=-.19 if slot=="front_skirt" else .19
        for side in [-1,1]:nodes.append(block(p,Vector3(side*.135,-.245,z),Vector3(.245,.63,.075),steel))
    elif id in ["travel_boots","iron_boots"] and slot=="boots":
        for i in range(2):
            nodes.append(block(rig.calves[i],Vector3(0,-.175,0),Vector3(.29,.30,.29),dark))
            nodes.append(block(rig.calves[i],Vector3(0,-.28,-.06),Vector3(.30,.10,.36),steel))
    elif id=="short_cape" and slot=="back":
        nodes.append(block(p,Vector3(0,.33,.225),Vector3(.53,.75,.085),steel))
        nodes.append(block(p,Vector3(0,.69,.20),Vector3(.57,.10,.11),gold))
    elif id=="sword_sheath" and slot=="sheath":
        var sheath:=Node3D.new()
        p.add_child(sheath);sheath.position=Vector3(.34,.07,.08)
        sheath.rotation.z=.23
        nodes.append(sheath)
        block(sheath,Vector3(0,-.28,0),Vector3(.09,.62,.11),dark)
        block(sheath,Vector3(0,-.025,0),Vector3(.12,.07,.12),gold)
    return nodes
