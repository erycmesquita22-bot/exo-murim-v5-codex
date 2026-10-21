extends Node3D
## Real Godot 4.6.2 gallery SCENE SOURCE. Not a pre-rendered screenshot.
## Install on dev copy with Core+Skin3D+Humanoides03 dependencies before opening.
const CoreRig = preload("res://rig.gd")
const BaseWardrobe = preload("res://wardrobe.gd")
const BaseCodec = preload("res://exo_skin3d/profile_codec.gd")
const VisualR2 = preload("res://exo_humanoids03_r2/scripts/actor_visual_adapter.gd")
var preview_rigs: Array = []
var time_s: float = 0.0
const EXHIBITS = [
    {"title":"PLAYER / CLASSIC", "role":"player","faction":"jade_martial_school","model":"classic","weapon":"sword"},
    {"title":"PLAYER / SLIM", "role":"player","faction":"black_moon_school","model":"slim","weapon":"sword"},
    {"title":"RESIDENTE", "role":"resident","faction":"neutral","model":"classic","weapon":"sword"},
    {"title":"DISCIPULO", "role":"disciple","faction":"jade_martial_school","model":"slim","weapon":"sword"},
    {"title":"MESTRE", "role":"master","faction":"black_moon_school","model":"classic","weapon":"sword"},
    {"title":"SENTINELA", "role":"sentinel","faction":"dungeon_wardens","model":"classic","weapon":"sword"},
    {"title":"BESTIARIO 02", "role":"rival_disciple","faction":"mountain_guardians","model":"slim","weapon":"sword"}
]

func _ready() -> void:
    var camera := Camera3D.new()
    add_child(camera)
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 15.0
    camera.position = Vector3(8,8,13)
    camera.look_at(Vector3(0,1,0),Vector3.UP)
    camera.current = true
    var light := DirectionalLight3D.new()
    add_child(light)
    light.rotation_degrees = Vector3(-47,-25,0)
    light.light_energy = 1.55
    var fill := WorldEnvironment.new()
    add_child(fill)
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("202c34")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("a5b7b3")
    env.ambient_light_energy = .7
    fill.environment = env
    for i in range(EXHIBITS.size()):
        var data: Dictionary = EXHIBITS[i]
        var anchor := Node3D.new()
        add_child(anchor)
        anchor.position = Vector3(float(i-3)*1.52,0,0)
        var rig: Node3D = CoreRig.new()
        anchor.add_child(rig)
        var c: Dictionary = BaseCodec.defaults()
        c["model"] = str(data.model)
        c["equipment"] = {} # R2 demonstration armor: do not double-layer pre-existing Skin3D armor
        c["accessories"] = {}
        var base: Dictionary = {"race":0,"robe":2,"outfit":2,"skin3d":c,"haircut":3,
            "weapon":str(data.weapon),"body":0,"style":1}
        BaseWardrobe.apply(rig,base)
        var event: Dictionary = {"uid":"gallery/"+str(i),"world_seed":"R2-QUALITY-REVIEW",
            "region_id":6,"role":str(data.role),"faction":str(data.faction),"prestige":3 if data.role == "master" else 1,
            "weapon_id":str(data.weapon),"weapon_state":"drawn","has_imported_skin_without_geo_hair":true}
        var choice: Dictionary = VisualR2.on_visual_created(rig,event)
        if choice.is_empty(): push_warning("R2 gallery role not applied: "+str(data.role))
        preview_rigs.append(rig)
        var text3d := Label3D.new()
        anchor.add_child(text3d)
        text3d.text = str(data.title)
        text3d.font_size = 40
        text3d.pixel_size = .0042
        text3d.position = Vector3(0,2.5,0)
        text3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        var base_floor := MeshInstance3D.new()
        anchor.add_child(base_floor)
        var plane := BoxMesh.new()
        plane.size = Vector3(1.3,.07,1.2)
        base_floor.mesh = plane
        base_floor.position.y = -.09
        var floor_material := StandardMaterial3D.new()
        floor_material.albedo_color = Color("46575a")
        base_floor.material_override = floor_material

func _process(delta: float) -> void:
    time_s += delta
    for i in range(preview_rigs.size()):
        var rig: Node3D = preview_rigs[i]
        if not is_instance_valid(rig): continue
        var walking: bool = i in [2,3,6]
        var attacking: float = fmod(time_s,3.0)/.8 if i == 6 and fmod(time_s,3.0) < .8 else -1.0
        # Preview only; combat/animation ownership stays with original Core Rig.
        rig.pose(time_s+float(i)*.12,walking,false,true,attacking)
