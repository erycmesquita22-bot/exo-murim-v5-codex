extends Node3D
# Demonstração isolada com malhas originais. Ataques emitem intenção,
# sem dano/sistema XP paralelo e sem alegar integração real ao EXO Core.
const Catalog=preload("res://exo_bestiary/catalog/species_catalog.gd")
const Actor=preload("res://exo_bestiary/creatures/creature_actor.gd")
var catalog
var count_attacks: int=0
func _ready() -> void:
    catalog=Catalog.new()
    if not catalog.load_data():push_error("BES02: catalog not available");return
    _environment()
    var deer: Node3D=_spawn("deer",Vector3(1,0,1),1)
    var wolf: Node3D=_spawn("wolf",Vector3(-7,0,1),0)
    var boar: Node3D=_spawn("boar",Vector3(3,0,-7),1)
    var dummy: Node3D=_spawn("wild_ox",Vector3(8,0,-7),0)
    deer.set("external_target",wolf)
    wolf.set("external_target",deer)
    boar.set("external_target",dummy)
    dummy.set("external_target",null)
    _spawn("rabbit",Vector3(-4,0,-9),2)
    _spawn("tiger",Vector3(-12,0,-13),0)
    _spawn("snake",Vector3(11,0,11),2)
    print("EXO_BESTIARY_02_LAB: ready 7 voxel wildlife actors")
func _spawn(id: String,p: Vector3,palette: int) -> Node3D:
    var actor=Actor.new();actor.name=id;actor.position=p;add_child(actor)
    actor.configure(catalog.get_profile(id),palette)
    actor.attack_requested.connect(_on_attack)
    return actor
func _on_attack(source: Node3D,target: Node3D,attack_id: String) -> void:
    count_attacks+=1
    print("EXO_BESTIARY_ATTACK_INTENT: ",source.name," -> ",target.name," attack:",attack_id," | physical damage BLOCKED until EXO combat bound")
func _environment() -> void:
    var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-53,-35,-10);sun.light_energy=1.5;add_child(sun)
    var world_env:=WorldEnvironment.new();add_child(world_env)
    var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("8eaec0");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("dee0d0");world_env.environment=env
    var floor:=StaticBody3D.new();floor.name="TrainingSoil";add_child(floor)
    var box:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(55,.5,55);box.shape=shape;box.position.y=-.3;floor.add_child(box)
    var mesh:=MeshInstance3D.new();var geo:=BoxMesh.new();geo.size=Vector3(55,.5,55);mesh.mesh=geo;mesh.position.y=-.3;floor.add_child(mesh)
    var mat:=StandardMaterial3D.new();mat.albedo_color=Color("5d8552");mat.roughness=1.0;mesh.material_override=mat
    for i in range(20):
        var stump:=MeshInstance3D.new();var trunk:=CylinderMesh.new();trunk.top_radius=.15;trunk.bottom_radius=.23;trunk.height=1.7;stump.mesh=trunk
        stump.position=Vector3(-22.0+float(i%5)*10.6,.8,-22.0+float(i/5)*14.0);add_child(stump)
        var tmat:=StandardMaterial3D.new();tmat.albedo_color=Color("725139");stump.material_override=tmat
    var camera:=Camera3D.new();camera.position=Vector3(20,28,25);camera.rotation_degrees=Vector3(-45,35,0);camera.fov=50;camera.current=true;add_child(camera)
