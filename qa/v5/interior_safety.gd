extends SceneTree
const Catalog = preload("res://exo_settlement_forge/runtime/interior_catalog.gd")
const Builder = preload("res://exo_settlement_forge/runtime/interior_builder.gd")
var failures: Array = []
var edges: int = 0
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var scene := Node3D.new()
    root.add_child(scene)
    var tested: int = 0
    for entry in Catalog.get_catalog().templates:
        var prefab: Dictionary = Catalog.get_prefab(str(entry.id))
        var room: Node3D = Builder.build(prefab)
        scene.add_child(room)
        Builder.set_cutaway(room, true)
        await physics_frame
        var cells: Dictionary = {}
        for run in prefab.floor_runs:
            for x in range(int(run.start), int(run.end) + 1):
                cells[Vector2i(x, int(run.z))] = true
        for cell: Vector2i in cells:
            for direction: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
                if cells.has(cell + direction):continue
                var center := Vector3((float(cell.x) - float(prefab.width_tiles - 1) / 2.0) * Builder.TILE, 0.5,
                    (float(cell.y) - float(prefab.depth_tiles - 1) / 2.0) * Builder.TILE)
                var query := PhysicsRayQueryParameters3D.create(center, center + Vector3(direction.x, 0, direction.y) * Builder.TILE)
                if scene.get_world_3d().direct_space_state.intersect_ray(query).is_empty():
                    failures.append(str(entry.id) + ":unsealed_edge:" + str(cell) + str(direction))
                edges += 1
        # Real CharacterBody movement through the authored doorway, not just raycasts.
        var player := CharacterBody3D.new()
        var collision := CollisionShape3D.new()
        var capsule := CapsuleShape3D.new()
        capsule.radius = 0.3; capsule.height = 1.8
        collision.shape = capsule; collision.position.y = 0.9
        player.add_child(collision); scene.add_child(player)
        player.position = room.get_node("InteriorSpawn").position
        for frame in range(120):
            await physics_frame
            player.velocity = Vector3(0, player.velocity.y - 20.0 / 60.0, 4.0)
            player.move_and_slide()
        if player.position.y < -0.1 or not player.is_on_floor():
            failures.append(str(entry.id) + ":door_walk_fall:" + str(player.position))
        player.free(); room.free(); tested += 1
    print("V5_INTERIOR_SAFETY ", JSON.stringify({"templates":tested,"boundary_edges":edges,"failures":failures}))
    scene.free()
    quit(0 if failures.is_empty() else 1)
