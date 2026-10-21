extends Node3D
## Render-focused native lab: 4 / 8 / 16 assets, NO AI, NO gameplay or simulated metrics.
## Run as main scene in project copied with res://exo_creature_harmonizacao02/ folder.
const Catalog = preload("res://exo_creature_harmonizacao02/integration/visual_catalog.gd")
var actors: Array[Node3D] = []
var samples: Array[String] = ["wolf", "boar", "tiger", "deer", "snake", "stone_guardian", "mountain_goat", "desert_scorpion", "fox", "rabbit", "bear", "spirit_deer", "leopard", "corrupted_wolf", "demon_boar", "desert_monitor"]
func _ready() -> void:
    spawn_count(4)
    print("EXO HARMONIZACAO LAB - only FPS from actual native runtime; no AI/damage/spawns")
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_1: spawn_count(4)
            KEY_2: spawn_count(8)
            KEY_3: spawn_count(16)
            KEY_SPACE: play_clip("walk")
            KEY_T: play_clip("attack")
func spawn_count(count: int) -> void:
    for actor in actors:
        if is_instance_valid(actor):
            actor.queue_free()
    actors.clear()
    for idx in range(count):
        var species_id: String = samples[idx % samples.size()]
        var data := Catalog.get_visual(species_id)
        if data.is_empty():
            continue
        var visual_scene := load(data["scene"]) as PackedScene
        if visual_scene == null:
            continue
        var actor := visual_scene.instantiate() as Node3D
        if actor == null:
            continue
        actor.position = Vector3(float(idx % 4) * 5.0 - 7.5, 0, float(idx / 4) * 5.0 - 7.5)
        add_child(actor)
        actors.append(actor)
    print("LAB spawned visuals=", actors.size(), " fps_native=", Engine.get_frames_per_second())
func play_clip(clip_name: String) -> void:
    for actor in actors:
        var player := actor.find_child("AnimationPlayer", true, false) as AnimationPlayer
        if player == null:
            continue
        for anim_name in player.get_animation_list():
            if anim_name == clip_name or anim_name.ends_with("/" + clip_name):
                player.play(anim_name)
                break
