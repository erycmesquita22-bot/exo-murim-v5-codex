extends SceneTree
# Godot 4.6.2 Compatibility — teste nativo da integracao R5.
# Execute apos --headless --editor --import. A presenca deste teste NAO e execucao.
const Catalog = preload("res://exo_creature_harmonizacao02/integration/visual_catalog.gd")
const Binder = preload("res://exo_creature_harmonizacao02/integration/runtime_visual_binding.gd")
const Species = preload("res://exo_bestiary/catalog/species_catalog.gd")
const Fauna = preload("res://exo_bestiary/integration/regional_fauna_actor.gd")
const COVERED: Array[String] = ["bear", "boar", "corrupted_wolf", "deer", "fox", "leopard", "mountain_goat", "rabbit", "snake", "spirit_deer", "stone_guardian", "tiger", "wolf"]
const WITHOUT_MODEL: Array[String] = ["wild_ox", "wild_buffalo", "qi_serpent"]
var passed: int = 0
var failed: int = 0
func check(ok: bool, label: String) -> void:
    if ok:
        passed += 1
    else:
        failed += 1
        push_error("C03_R5_NATIVE_FAIL " + label)
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var catalog = Species.new()
    check(catalog.load_data(), "bestiary_catalog")
    for species_id in COVERED:
        var descriptor: Dictionary = Catalog.get_visual(species_id)
        check(str(descriptor.get("species_id", "")) == species_id, "id_" + species_id)
        var holder := Node3D.new()
        holder.name = "R5TestHolder"
        get_root().add_child(holder)
        var voxel := MeshInstance3D.new()
        voxel.name = "VoxelFallback"
        holder.add_child(voxel)
        holder.scale = Vector3(1.15, 1.15, 1.15)
        var binding: Dictionary = Binder.attach_visual(holder, descriptor)
        check(not binding.is_empty(), "model_import_" + species_id)
        if not binding.is_empty():
            check(not voxel.visible and holder.scale == Vector3.ONE, "one_visual_no_double_scale_" + species_id)
            var player: AnimationPlayer = binding.get("player", null)
            check(player != null, "anim_player_" + species_id)
            if player != null:
                check(not Binder.clip_for(player, "idle").is_empty(), "idle_clip_" + species_id)
                check(not Binder.clip_for(player, "walk").is_empty(), "walk_clip_" + species_id)
                check(not Binder.clip_for(player, "attack").is_empty(), "attack_clip_" + species_id)
                check(Binder.play_action(binding, "walk"), "walk_play_" + species_id)
            Binder.detach_visual(holder, binding)
            check(voxel.visible and holder.scale == Vector3(1.15, 1.15, 1.15), "fallback_restore_" + species_id)
        holder.queue_free()
    for species_id in WITHOUT_MODEL:
        check(Catalog.get_visual(species_id).is_empty(), "missing_species_fallback_" + species_id)
    var fallback_holder := Node3D.new()
    get_root().add_child(fallback_holder)
    check(Binder.attach_visual(fallback_holder, {"scene": "res://another_module/unknown.tscn"}).is_empty(), "foreign_resource_rejected")
    check(Binder.attach_visual(fallback_holder, {"scene": "res://exo_creature_harmonizacao02/scenes/missing.tscn"}).is_empty(), "missing_scene_rejected")
    fallback_holder.queue_free()
    var actor = Fauna.new()
    check(actor.has_method("_install_harmonized_visual") and actor.has_method("_r5_visual_tick"), "existing_regional_actor_extended")
    actor.queue_free()
    print("C03_R5_NATIVE_VISUALS ", JSON.stringify({"passed": passed, "failed": failed}))
    quit(0 if failed == 0 else 1)
