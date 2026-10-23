extends SceneTree
## Execute only in a dev Core copy, after exo_humanoids03 and this R2 are installed.
const Rig = preload("res://rig.gd")
const Wardrobe = preload("res://wardrobe.gd")
const Codec = preload("res://exo_skin3d/profile_codec.gd")
const Adapter = preload("res://exo_humanoids03_r2/scripts/actor_visual_adapter.gd")
const Selector = preload("res://exo_humanoids03_r2/scripts/preset_selector.gd")
const Voxel = preload("res://exo_humanoids03_r2/scripts/voxel_geometry.gd")
var fails: int = 0
var checks: int = 0

func check(ok: bool, name: String) -> void:
    checks += 1
    if not ok:
        fails += 1
        push_error("FAIL R2: "+name)

func _initialize() -> void:
    for model in ["classic","slim"]:
        var actor: Node3D = Rig.new()
        root.add_child(actor)
        var cosmetics: Dictionary = Codec.defaults()
        cosmetics["model"] = model
        var base: Dictionary = {"race":0,"outfit":2,"robe":0,"body":0,"skin3d":cosmetics,"weapon":"sword"}
        Wardrobe.apply(actor,base)
        var skin_before: Texture2D = actor.skin.albedo_texture
        var torso_before: Mesh = (actor.torso.get_child(0) as MeshInstance3D).mesh
        var uv_before: PackedVector2Array = torso_before.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
        var event: Dictionary = {"uid":"r2/test/"+model,"role":"sentinel","faction":"dungeon_wardens",
            "world_seed":"ABCD","region_id":7,"prestige":2,"weapon_id":"sword","weapon_state":"sheathed"}
        var a: Dictionary = Selector.choose(event)
        var b: Dictionary = Selector.choose(event)
        check(a == b,model+" deterministic")
        var saved: Dictionary = Adapter.on_visual_created(actor,event,a)
        check(not saved.is_empty(),model+" attachment created")
        check(actor.skin.albedo_texture == skin_before,model+" skin texture unchanged")
        check((actor.torso.get_child(0) as MeshInstance3D).mesh == torso_before,model+" torso original mesh unchanged")
        check((actor.torso.get_child(0) as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV] == uv_before,
            model+" UV unchanged")
        check(not Adapter.on_visual_created(actor,event,{"uid":"WRONG","preset_id":"garrison_guard"}).has("schema"),model+" foreign save blocked")
        var count: int = actor.get_meta("exo_humanoid_r2_roots",[]).size()
        check(count == 0,model+" old cosmetic roots retired")
        check(actor.get_meta("exo_character_refit_version",0)==1,model+" new refit geometry")
        Adapter.on_action_changed(actor,"roll",true)
        Adapter.on_action_changed(actor,"crouch",true)
        Adapter.on_action_changed(actor,"roll",false)
        Adapter.on_action_changed(actor,"crouch",false)
        Adapter.on_action_changed(actor,"two_handed",true)
        Adapter.on_action_changed(actor,"two_handed",false)
        var reapply: bool = Adapter.on_wardrobe_reapplied(actor,event,saved)
        check(reapply,model+" reapply after wardrobe")
        check(actor.get_meta("exo_humanoid_r2_roots",[]).size() == count,model+" no duplicate attachments")
        Adapter.on_visual_removed(actor)
        check(actor.get_meta("exo_humanoid_r2_roots",[]).is_empty(),model+" cleanup")
        actor.queue_free()
    print(JSON.stringify({"r2_checks":checks,"failed":fails,"mesh_cache":Voxel.cache_counts()}))
    quit(1 if fails > 0 else 0)
