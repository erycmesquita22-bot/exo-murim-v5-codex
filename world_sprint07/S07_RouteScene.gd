extends Node3D
## Authored HWA02 -> HWA01 roadside corridor. Standalone runtime sector.
## World atlas ID ROAD-02-01 is fixed. No random generation of route geometry.
const MANIFEST := "res://world_sprint07/data/manifest_sprint07.json"
var generated_collisions: int = 0
var vegetation_instances: int = 0
var locations: Dictionary = {}
var markers: Node3D
var terrain: Node3D
var landmarks: Node3D

func route_x(z: float) -> float:
    return 8.0 * sin((z + 22.0) / 91.0) + 5.0 * sin((z - 12.0) / 42.0)

func road_height(z: float) -> float:
    return 1.0 + 2.8 * (0.5 - 0.5 * cos(PI * (360.0-z) / 720.0)) + 0.45 * sin((z+25.0)/105.0)

func height_at(x: float, z: float) -> float:
    var d: float = absf(x - route_x(z))
    var shoulder: float = maxf(0.0, d - 6.0)
    var rolling: float = 0.10 * sin(x * .071 + z * .011) + .12 * cos(z*.066-x*.026)
    var ridge: float = pow(shoulder/55.0,1.65)*(8.5+1.6*sin(z/58.0+x/23.0))
    var eastern: float = pow(maxf(0.0,(x-route_x(z)-27.0)/40.0),1.8)*2.1
    return road_height(z) + rolling*minf(shoulder/8.0,1.0) + ridge + eastern

func _ready() -> void:
    name = "ROAD_02_01_Haneul_Yunseong"
    var meta: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
    if meta is Dictionary:
        for waypoint in meta.get("route_waypoints",[]):
            locations[str(waypoint["id"])] = waypoint
    terrain = load("res://world_sprint07/models/S07_Rota_Haneul_Yunseong_Terrain.glb").instantiate() as Node3D
    terrain.name = "S07_PaintedTerrain"
    add_child(terrain)
    landmarks = load("res://world_sprint07/models/S07_Roadside_Landmarks.glb").instantiate() as Node3D
    landmarks.name = "S07_MurimLandmarks"
    add_child(landmarks)
    _add_mesh_collisions(terrain, true)
    _add_mesh_collisions(landmarks, false)
    _place_authored_vegetation()
    _place_murim_architecture()
    _make_waymark_nodes()
    print("S07_ROUTE_READY colliders=", generated_collisions, " foliage=", vegetation_instances, " landmarks=",locations.size())

func _add_mesh_collisions(root_node: Node, terrain_mode: bool) -> void:
    if root_node is MeshInstance3D and root_node.mesh:
        var instance: MeshInstance3D = root_node as MeshInstance3D
        # Eliminate confirmed self-shadow acne / contour rings on dense terrain.
        # Props still cast shadows; authored hills remain visible in the terrain silhouette.
        if terrain_mode: instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        var collide: bool = (instance.name.begins_with("GROUND_WALK_") if terrain_mode else instance.name.begins_with("LANDMARK_COLLIDE_"))
        if collide:
            var b: StaticBody3D = StaticBody3D.new()
            b.name = "S07_STATIC_" + instance.name
            b.collision_layer = 1
            b.collision_mask = 1
            var cs: CollisionShape3D = CollisionShape3D.new()
            var shape: ConcavePolygonShape3D = instance.mesh.create_trimesh_shape()
            shape.backface_collision = true
            cs.shape = shape
            b.add_child(cs)
            instance.add_child(b)
            generated_collisions += 1
    for ch in root_node.get_children():
        if not ch.name.begins_with("S07_STATIC_"):
            _add_mesh_collisions(ch, terrain_mode)

func _place_authored_vegetation() -> void:
    var vegetation: Node3D = Node3D.new()
    vegetation.name = "S07_RoadsideFoliage"
    add_child(vegetation)
    # Deterministic authored layout (not world seed): meadow, pine ridges,
    # bamboo near the traveler rest. No dynamic collision in foliage.
    var pine: PackedScene = load("res://props_sprint03/kit/PINE_YOUNG.glb")
    var shrub: PackedScene = load("res://props_sprint03/kit/SHRUB.glb")
    var bamboo: PackedScene = load("res://props_sprint03/kit/BAMBOO_CLUSTER.glb")
    var rock: PackedScene = load("res://props_sprint03/kit/ROCK_CLUSTER.glb")
    var flower: PackedScene = load("res://props_sprint03/kit/WILDFLOWERS.glb")
    var sources: Array = [pine,shrub,bamboo,rock,flower]
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = 20271023
    for i in 420:
        var z: float = rng.randf_range(-309.0,312.0)
        var sign_side: float = -1.0 if i % 2 == 0 else 1.0
        var d: float = rng.randf_range(14,60)
        var x: float = route_x(z) + sign_side*d
        # Keep main POIs visually readable, never cover approach to little shrine.
        if z > 40 and z < 95 and x < route_x(z)-22 and x > route_x(z)-39:
            continue
        var which: int = 0 if i % 5 < 2 else (1 if i % 5==2 else (2 if i%5==3 else 3))
        if i % 13 == 0: which = 4
        var prefab: PackedScene = sources[which]
        if prefab == null: continue
        var inst: Node3D = prefab.instantiate() as Node3D
        inst.name = "S07_Flora_%03d" % i
        inst.position = Vector3(x, height_at(x,z)-.12,z)
        inst.rotation.y = rng.randf_range(-PI,PI)
        var sc: float = rng.randf_range(1.02,1.68)
        inst.scale = Vector3.ONE * sc
        vegetation.add_child(inst)
        vegetation_instances += 1

func _place_murim_architecture() -> void:
    # Reuse the already-authored Murim architectural kit; no outside assets.
    # Positions are stable and do not depend on family seed.
    var structures: Node3D = Node3D.new()
    structures.name = "S07_Architectural_POIs"
    add_child(structures)
    var records: Array = [
        {"file":"COURTYARD_GATE","x":route_x(-337.0),"z":-337.0,"scale":1.22,"label":"Pavilhao do Portao de Yunseong"},
        {"file":"TEAHOUSE","x":route_x(-290.0)-24.0,"z":-291.0,"scale":.90,"label":"Casa de Cha dos Viajantes"},
        {"file":"SHRINE","x":route_x(65.0)-29.0,"z":65.0,"scale":.91,"label":"Santuario dos Pinheiros"},
        {"file":"STOREHOUSE","x":route_x(-278.0)+25.0,"z":-271.0,"scale":.82,"label":"Armazem da Rota"}
    ]
    for rec in records:
        var path: String = "res://architecture_sprint02/kit/%s.glb" % rec["file"]
        var packed: PackedScene = load(path)
        if packed == null:
            push_error("S07 Missing authored architecture " + path)
            continue
        var inst: Node3D = packed.instantiate() as Node3D
        var x:float = float(rec["x"])
        var z:float = float(rec["z"])
        var scale_value: float = float(rec["scale"])
        inst.position = Vector3(x,height_at(x,z)+.10,z)
        inst.scale = Vector3.ONE * scale_value
        inst.name = str(rec["file"]) + "_S07"
        inst.set_meta("world_poi",rec["label"])
        structures.add_child(inst)
        # Static architectural set dressing only; keep route path unblocked.

func _make_waymark_nodes() -> void:
    markers = Node3D.new()
    markers.name = "S07_StableWorldMarkers"
    add_child(markers)
    for id in locations:
        var record: Dictionary = locations[id]
        var p: Array = record["local"]
        var marker: Marker3D = Marker3D.new()
        marker.name = str(id)
        marker.position = Vector3(float(p[0]),float(p[1]),float(p[2]))
        marker.set_meta("poitype",record["kind"])
        markers.add_child(marker)

func local_start() -> Vector3:
    return Vector3(route_x(328.0),height_at(route_x(328.0),328.0)+.35,328.0)
func local_arrival() -> Vector3:
    return Vector3(route_x(-328.0),height_at(route_x(-328.0),-328.0)+.35,-328.0)
