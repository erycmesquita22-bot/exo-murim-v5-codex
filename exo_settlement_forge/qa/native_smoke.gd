extends SceneTree
## Execute with Godot 4.6.2: --headless --path <root> --script res://exo_settlement_forge/qa/native_smoke.gd
## Not executed by author; there is no Godot binary in current environment.
const Gen = preload("res://exo_settlement_forge/runtime/urban_generator.gd")
const Service = preload("res://exo_settlement_forge/runtime/settlement_service.gd")
const Portal = preload("res://exo_settlement_forge/runtime/portal_controller.gd")
var failures: Array[String] = []
var tested_cycles: int = 0

func _initialize() -> void:
    call_deferred("_run")

func _assert(label: String, value: bool) -> void:
    if not value:
        failures.append(label)

func _run() -> void:
    var scales: Array[String] = ["hamlet","village","medium_city","large_city"]
    for scale in scales:
        var seed_builds: Array = []
        for seed in [22, 87, 120]:
            var plan: Dictionary = Gen.generate(seed,"r78","c78",scale,"martial","rectangular")
            _assert("plan generated "+scale,plan.get("ok",false))
            _assert("all roads defined "+scale,plan.get("roads",[]).size()>0)
            var ids: Array = []
            for b in plan.get("buildings",[]):
                ids.append(str(b["building_id"]))
            seed_builds.append(ids)
            _assert("deterministic repeated id "+scale,ids == _ids(Gen.generate(seed,"r78","c78",scale,"martial","rectangular")))
        _assert("seeds vary "+scale,seed_builds[0] != seed_builds[1])
    var exterior := Node3D.new()
    root.add_child(exterior)
    var staging := Node3D.new()
    root.add_child(staging)
    var controller: Node = Service.new()
    root.add_child(controller)
    var portal: Node = Portal.new()
    root.add_child(portal)
    var plan: Dictionary = Gen.generate(22,"r78","c78","village","commercial","rectangular")
    _assert("host loads scene",controller.load_plan(plan,exterior))
    await physics_frame
    _assert("6 category records",_categories(controller).size()==6)
    var player := CharacterBody3D.new()
    player.collision_layer = 2
    player.collision_mask = 1
    root.add_child(player)
    var collision := CollisionShape3D.new()
    var cap := CapsuleShape3D.new()
    cap.height = 1.8
    cap.radius = 0.31
    collision.shape = cap
    player.add_child(collision)
    var camera := Camera3D.new()
    root.add_child(camera)
    camera.size = 17.0
    var originals: Array[Dictionary] = controller.list_by_function("")
    for index in range(10):
        var record: Dictionary = originals[index % originals.size()]
        var door: Array = record["exterior_door"]
        player.global_position = Vector3(float(door[0]),float(door[1])+1.05,float(door[2]))
        var before_id: int = player.get_instance_id()
        var entered: bool = portal.enter(player,exterior,staging,camera,record,true)
        _assert("enter %d"%index,entered)
        if entered:
            _assert("same player inside %d"%index,before_id == player.get_instance_id())
            var room: Node3D = staging.get_child(staging.get_child_count()-1) as Node3D
            var exit_anchor: Node3D = room.get_node_or_null("InteriorExit") as Node3D
            _assert("interior exit marker %d"%index,exit_anchor != null)
            if exit_anchor != null:
                player.global_position = exit_anchor.global_position + Vector3(0,0.14,0)
            var left: bool = portal.leave()
            _assert("leave %d"%index,left)
            _assert("same player outside %d"%index,before_id == player.get_instance_id())
            _assert("camera restored %d"%index,is_equal_approx(camera.size,17.0))
            if left:
                tested_cycles+=1
    print("SETTLEMENT_01_NATIVE ",JSON.stringify({"candidate_only":true,"cycles":tested_cycles,
        "errors":failures,"godot_runtime_test":true,"not_tested":"E-input, navigation, host-save, NPC04, FPS, Android"}))
    quit(0 if failures.is_empty() and tested_cycles==10 else 1)

func _ids(plan: Dictionary) -> Array:
    var values: Array = []
    for b in plan.get("buildings",[]):
        values.append(str(b["building_id"]))
    return values

func _categories(service: Node) -> Dictionary:
    var found: Dictionary = {}
    for b in service.list_by_function(""):
        found[str(b["function"])] = true
    return found
