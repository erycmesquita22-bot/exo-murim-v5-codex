extends "res://modules/character_core_v3/V3_Controller.gd"
## EXO Haneul HWA-02 V09 / Sprint05 — Character Core V3 Motion as the sole active player controller.
## The imported GLB and its animation clips are unchanged; V3 logic is inherited.
## The map remains physically fixed; seed selects family signage only.

@export var world_seed: int = 101
@export_enum("AUTO", "WONG", "WUDONG") var family_override: String = "AUTO"
@export var enable_environment_collisions: bool = true
@export var show_training_dummy: bool = true

var haneul_scene: Node3D
var sprint02_architecture: Node3D
var sprint03_props: Node3D
var sprint05_infrastructure: Node3D
var entrance_anchors: Node3D
var sprint05_collider_groups: int = 0
var prop_colliders_created := 0
var wong_signs: Node3D
var wudong_signs: Node3D
var active_family: String = "WONG"
var colliders_created := 0
const SPAWN_X := -12.0
const SPAWN_Z := -65.0

func _ready() -> void:
    # Build world and V3 actor/animations/camera using tested V3 parent logic.
    super._ready()
    actor.position = Vector3(SPAWN_X, 3.0, SPAWN_Z)
    actor.velocity = Vector3.ZERO
    yaw = PI
    # Match the facing direction to the third-person camera before first input.
    visual.rotation.y = 0.0
    pivot.position = actor.position + Vector3(0, 1.65, 0)
    if target:
        target.position = actor.position + Vector3(0, -actor.position.y, 6.0)
        target_origin = target_visual.position
        target.visible = show_training_dummy
    # Keep map-specific QA separate from V3's original isolated training-lab replay.
    hud.text = "EXO-MURIM  /  HANEUL / CHARACTER V3"
    print("EXO_HANEUL_V04_READY family=", active_family, " colliders=", colliders_created, " rig=", skeleton.get_bone_count(), " animations=", player.get_animation_list())

func build_environment() -> void:
    var packed: PackedScene = load("res://model/HWA02_Nature_And_TerrainCollision_S02.glb")
    haneul_scene = packed.instantiate() as Node3D
    haneul_scene.name = "HaneulEnvironment"
    add_child(haneul_scene)
    # Terrain Sprint 01 ONLY: preserve Haneul physics mesh as invisible collision source.
    # Hide old checkered terrain and raised road ribbons; new surface matches same XYZ vertices.
    for n in haneul_scene.find_children("*", "MeshInstance3D", true, false):
        if n.name in ["Terrain", "River"]:
            n.visible = false
    var ink_terrain: Node3D = load("res://infrastructure_sprint05/HWA02_Terrain_S05.glb").instantiate()
    ink_terrain.name = "EXO_Haneul_Terrain_Sprint05_Approaches"
    add_child(ink_terrain)
    # Sprint 05: replace the inherited per-triangle river texture with
    # seam-continuous world-space UVs. Original river stays hidden, never double-rendered.
    var river_s05: Node3D = load("res://infrastructure_sprint05/HWA02_River_S05.glb").instantiate()
    river_s05.name = "EXO_Rio_Hwa_Sprint05_SeamlessWater"
    add_child(river_s05)
    # Sprint 02: completely replace old building groups. No overlays/legacy active geometry.
    sprint02_architecture = load("res://architecture_sprint02/HWA02_Architecture_Sprint02.glb").instantiate() as Node3D
    sprint02_architecture.name = "EXO_Sprint02_Murim_Architecture"
    add_child(sprint02_architecture)
    # Sprint 03: independent original environment dressing, no replacement of older modules.
    sprint03_props = load("res://props_sprint03/HWA02_Props_Vegetation_S03.glb").instantiate() as Node3D
    sprint03_props.name = "EXO_Sprint03_Props_Vegetation"
    add_child(sprint03_props)
    # Sprint05 single active infrastructure. Standalone GLB; no patched legacy props.
    sprint05_infrastructure = load("res://infrastructure_sprint05/HWA02_Infraestrutura_S05.glb").instantiate() as Node3D
    sprint05_infrastructure.name = "EXO_Sprint05_PhysicalInfrastructure"
    add_child(sprint05_infrastructure)
    _make_interior_reservations()
    wong_signs = load("res://model/HWA02_Family_Wong.glb").instantiate()
    wudong_signs = load("res://model/HWA02_Family_Wudong.glb").instantiate()
    wong_signs.name = "FamilyWong"
    wudong_signs.name = "FamilyWudong"
    add_child(wong_signs)
    add_child(wudong_signs)
    active_family = _get_family()
    wong_signs.visible = active_family == "WONG"
    wudong_signs.visible = active_family == "WUDONG"
    if enable_environment_collisions:
        _add_environment_collisions(haneul_scene)
        _add_architecture_collisions(sprint02_architecture)
        _add_prop_collisions(sprint03_props)
        _add_sprint05_collisions(sprint05_infrastructure)
    var env := WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color("b8d1d1")
    env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_color = Color("f1eee4")
    env.environment.ambient_light_energy = .68
    add_child(env)
    light = DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-52,-28,0)
    light.light_energy = .78
    light.shadow_enabled = true
    light.directional_shadow_max_distance = 60
    add_child(light)
    # Training target uses geometry from V3's original lab, at the spawn street.
    target = StaticBody3D.new()
    target.name = "TrainingDummy"
    add_child(target)
    var shape := CollisionShape3D.new()
    var cylinder := CylinderShape3D.new()
    cylinder.radius = .42
    cylinder.height = 1.9
    shape.shape = cylinder
    shape.position.y = .95
    target.add_child(shape)
    target_visual = Node3D.new()
    target.add_child(target_visual)
    var post := CylinderMesh.new()
    post.top_radius = .23
    post.bottom_radius = .32
    post.height = 1.8
    post.radial_segments = 8
    target_material = material("51483d")
    mesh_node(post, target_material, Vector3(0,.9,0), target_visual)
    add_contact_shadow(target)
    target_origin = target_visual.position

func _get_family() -> String:
    if family_override != "AUTO": return family_override
    return "WONG" if posmod(world_seed,2) == 1 else "WUDONG"

func _add_environment_collisions(node: Node) -> void:
    if node is MeshInstance3D:
        var mesh_node := node as MeshInstance3D
        if mesh_node.name in ["Terrain", "Wood_Structures"] and mesh_node.mesh:
            var body := StaticBody3D.new()
            body.name = "StaticHWA02_" + mesh_node.name
            var collider := CollisionShape3D.new()
            var trimesh: ConcavePolygonShape3D = mesh_node.mesh.create_trimesh_shape()
            # HWA-02 terrain's source mesh has downward-facing triangles.
            # Without backface collision, players fall through the visible terrain.
            trimesh.backface_collision = true
            collider.shape = trimesh
            body.add_child(collider)
            mesh_node.add_child(body)
            colliders_created += 1
    for child in node.get_children():
        if not child.name.begins_with("StaticHWA02_"):
            _add_environment_collisions(child)

func _add_architecture_collisions(node: Node) -> void:
    # Each authored house is a separate static collision volume.
    # No collisions from hidden legacy buildings are created.
    if node is MeshInstance3D and node.mesh:
        var mesh_node := node as MeshInstance3D
        if mesh_node.name.begins_with("ARCH_"):
            var body := StaticBody3D.new()
            body.name = "S02_" + mesh_node.name
            var collider := CollisionShape3D.new()
            var shape: ConcavePolygonShape3D = mesh_node.mesh.create_trimesh_shape()
            shape.backface_collision = true
            collider.shape = shape
            body.add_child(collider)
            mesh_node.add_child(body)
            colliders_created += 1
    for child in node.get_children():
        if not child.name.begins_with("S02_"):
            _add_architecture_collisions(child)

func _add_prop_collisions(node: Node) -> void:
    # Collision budget is restricted to solid props (the GLB names are the contract).
    # No grass/flowers/bamboo leaves collision shapes; do not block authored routes.
    if node is MeshInstance3D and node.mesh and node.name.begins_with("PROP_COLLIDE_"):
        var m := node as MeshInstance3D
        var body := StaticBody3D.new()
        body.name = "S03_" + m.name
        var c := CollisionShape3D.new()
        var shape: ConcavePolygonShape3D = m.mesh.create_trimesh_shape()
        shape.backface_collision = true
        c.shape = shape
        body.add_child(c)
        m.add_child(body)
        prop_colliders_created += 1
        colliders_created += 1
    for child in node.get_children():
        if not child.name.begins_with("S03_"):
            _add_prop_collisions(child)


func _make_interior_reservations() -> void:
    # Architectural doors are still CLOSED physical facades; these are metadata
    # trigger volumes in front of the entrance, not implemented interior warps.
    entrance_anchors = Node3D.new()
    entrance_anchors.name = "S05_ReservedInteriorAnchors"
    add_child(entrance_anchors)
    var file := FileAccess.open("res://infrastructure_sprint05/data/manifest_sprint05.json", FileAccess.READ)
    if file == null:
        push_error("Sprint05: missing entrance manifest")
        return
    var parsed: Dictionary = JSON.parse_string(file.get_as_text())
    for record in parsed.get("entrance_anchors", []):
        var coords: Array = record["door_center"]
        var outward: Array = record["outward_normal"]
        var area := Area3D.new()
        area.name = "RESERVED_INTERIOR_" + record["id"]
        area.position = Vector3(float(coords[0]) + float(outward[0]) * 0.75, float(coords[1]) + 0.9, float(coords[2]) + float(outward[2]) * 0.75)
        area.collision_layer = 0
        area.collision_mask = 1
        area.monitoring = true
        area.add_to_group("haneul_interior_reservations")
        area.set_meta("location_id", record["id"])
        area.set_meta("sprint05_interior_status", "NOT_IMPLEMENTED")
        var shape := CollisionShape3D.new()
        var capsule := SphereShape3D.new()
        capsule.radius = 1.35
        shape.shape = capsule
        area.add_child(shape)
        entrance_anchors.add_child(area)

func _add_sprint05_collisions(root_node: Node) -> void:
    if root_node is MeshInstance3D and root_node.mesh and (root_node.name.begins_with("INFRA_WALK_") or root_node.name.begins_with("INFRA_COLLIDE_")):
        var mesh_inst := root_node as MeshInstance3D
        var static_body := StaticBody3D.new()
        static_body.name = "S05_STATIC_" + mesh_inst.name
        static_body.collision_layer = 1
        static_body.collision_mask = 1
        var cs := CollisionShape3D.new()
        var shape := mesh_inst.mesh.create_trimesh_shape()
        shape.backface_collision = true  # needed for double-sided paper-thin stone thresholds
        cs.shape = shape
        static_body.add_child(cs)
        mesh_inst.add_child(static_body)
        sprint05_collider_groups += 1
        colliders_created += 1
    for child in root_node.get_children():
        if not child.name.begins_with("S05_STATIC_"):
            _add_sprint05_collisions(child)

func _terrain_height(x: float, z: float) -> float:
    var center := 66.0 + 8.0 * sin((z + 20.0) / 41.0) + z * 0.045
    var base := 0.2 + 0.17 * sin(x * 0.072 + z * 0.013) + 0.17 * cos(z * 0.093 - x * 0.024)
    var west := pow(maxf(0.0, (-x - 57.0) / 55.0), 1.8) * 11.5
    var nw := maxf(0.0, (-z - 65.0) / 45.0) * maxf(0.0, (-x - 55.0) / 65.0) * 6.0
    var waterline := -2.25 * pow(maxf(0.0, 1.0 - absf(x - center) / 12.0), 1.35)
    return base + west + nw + waterline

func finish_frame(delta: float) -> void:
    # The V3 locomotion and action mechanisms still run; overlay is Haneul-specific.
    super.finish_frame(delta)
    hud.text = "EXO-MURIM / HANEUL HWA-02 / SPRINT05 INFRAESTRUTURA / %s\nWASD mover · Shift correr · Mouse camera · E arma\nClique/Espaço golpe · Q esquiva · Tab foco · Esc cursor" % active_family
