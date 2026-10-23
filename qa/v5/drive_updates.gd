extends SceneTree
const Game=preload("res://convergence/game.gd")
const Creator=preload("res://ui/character_creation.gd")
const Proxy=preload("res://exo_crowd_illusion/visuals/real_npc_visual.gd")
var failures: Array=[]
var checks: Array=[]
var w: Node3D
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
    checks.append({"name":label,"pass":ok})
    if not ok:failures.append(label)
    print("DRIVE_CHECK ",label," ",ok)
func frames(count: int) -> void:
    for i in range(count):await physics_frame
func button(label: String) -> Button:
    for node in w.ui.find_children("*","Button",true,false):
        if node.text==label:return node
    return null
func run() -> void:
    w=Game.new();w.load_on_start=false;w.world_seed_override=101
    w.save_path="user://drive-updates.json";w.settings_path="user://drive-updates.cfg"
    root.add_child(w);await process_frame
    var model_count: int=0
    var normal_failures: Array=[]
    var directory:=DirAccess.open("res://models/forja_v3")
    for name in directory.get_files():
        if not name.ends_with(".glb"):continue
        var scene: PackedScene=load("res://models/forja_v3/"+name)
        var instance: Node3D=scene.instantiate()
        if not instance.find_children("*","MeshInstance3D",true,false).is_empty():model_count+=1
        for mesh in instance.find_children("*","MeshInstance3D",true,false):
            for surface in range(mesh.mesh.get_surface_count()):
                var arrays: Array=mesh.mesh.surface_get_arrays(surface)
                var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL] if arrays[Mesh.ARRAY_NORMAL]!=null else PackedVector3Array()
                if normals.is_empty():normal_failures.append(name)
                for normal in normals:
                    if normal.length()<0.9:normal_failures.append(name);break
        instance.free()
    check(model_count==42,"42_regenerated_models_native_instantiate")
    check(normal_failures.is_empty(),"42_models_have_lighting_normals")
    var probe:=Node3D.new();root.add_child(probe)
    var wall: Node3D=preload("res://godot/modular_kit.gd").place(probe,"city_wall_stone_2m",Vector3.ZERO,0,"",false)
    var filter_ok: bool=true
    for mesh in wall.find_children("*","MeshInstance3D",true,false):
        for surface in range(mesh.mesh.get_surface_count()):
            var material: StandardMaterial3D=mesh.get_active_material(surface)
            if material.albedo_texture==null and material.texture_filter==BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC:filter_ok=false
    check(filter_ok,"untextured_forja_avoids_black_anisotropic_path")
    probe.free()
    var bank: Node=w.audio_fx
    check(bank.forge_events.size()==91,"sound_forge_91_events")
    var valid_audio: int=0
    for id in bank.forge_events:
        var stream: AudioStream=bank.cache.get(str(bank.forge_events[id].path))
        if stream!=null and stream.get_length()>0.1:valid_audio+=1
    check(valid_audio==91,"91_native_decoded_ogg")
    var played: int=bank.played
    bank.play_event("swing")
    check(bank.played==played+1 and bank.history.back()=="swing","mapped_attack_playback")
    var routed: bool=false
    for voice in bank.voices:
        if voice.stream==bank.cache[bank.forge_events["weapon.sword.swing_light"].path]:routed=true
    check(routed,"attack_uses_sound_forge_stream")
    bank.play_event("weapon.sword.draw")
    check(bank.history.back()=="weapon.sword.draw","direct_sound_event_playback")
    w.flow.phase="creator";w.ui.creation_tab=1;w.ui.appearance_tab=1;w.ui.show_creator()
    await process_frame
    check(button("Guarda")!=null,"creator_style_buttons_present")
    if button("Guarda")!=null:button("Guarda").pressed.emit()
    await process_frame
    check(w.ui.profile.skin3d.equipment.get("chest","")=="guard_cuirass","guard_preset_changes_real_profile")
    check(w.ui.preview.get_meta("skin3d_instances",[]).size()>0,"preset_real_preview_geometry")
    for id in ["Traços","Acessórios","Armaduras","Vestuário"]:
        var target: Button=button(id)
        check(target!=null,"creator_tab:"+id)
        if target!=null:target.pressed.emit()
        await process_frame
    if button("Caminhar")!=null:button("Caminhar").pressed.emit()
    await frames(10)
    check(w.ui.preview_root.preview_pose=="walk" and w.ui.preview_root.pose_time>0,"animated_creator_preview")
    var image: Image=preload("res://exo_identity.gd").paint(w.ui.profile)
    check(image.get_size()==Vector2i(256,256),"fighterart_256_profile_texture")
    var expected: Dictionary=w.ui.profile.duplicate(true)
    check(w.flow.create_character(expected,101),"create_customized_character")
    w.ui.resume()
    for i in range(350):
        if w.current_region>=0 and not w.changing_region:break
        await physics_frame
    check(w.current_region>=0,"customized_campaign_entry")
    check(w.journey.data.character.skin3d.equipment.get("chest","")=="guard_cuirass","customization_preserved_in_campaign")
    var terrain_connected: bool=false
    for node in get_nodes_in_group("exo_visual_terrain"):
        if not w.active_region.is_ancestor_of(node):continue
        var material: ShaderMaterial=node.material_override
        if material!=null and material.get_shader_parameter("forge_enabled")==true:
            var texture: Texture2D=material.get_shader_parameter("forge_grass_atlas")
            terrain_connected=texture!=null and texture.resource_path.begins_with("res://exo_terrain_forge/textures/")
            break
    check(terrain_connected,"restored_terrain_atlas_bound_to_actual_shader")
    var active_forge_models: int=0
    for node in w.active_region.find_children("*","Node3D",true,false):
        if node.get_meta("forja_house_template","")=="godot/modular_kit.gd:build_house/murim_blue/6/2" and node.get_node_or_null("ForjaCompleteVisual")!=null:active_forge_models+=1
    check(active_forge_models>0,"forja_models_mounted_in_settlement")
    var profile: Dictionary=w.residents[0].identity.duplicate(true)
    var proxy: Node3D=Proxy.new();root.add_child(proxy)
    check(proxy.configure(profile,"npc/r00/crowd/qa",str(w.atlas.seed)),"full_rig_ghost_configure")
    check(proxy.find_children("*","CollisionObject3D",true,false).is_empty(),"ghost_no_physics_or_interactions")
    var real_image: Image=w.residents[0].rig.skin.albedo_texture.get_image()
    var ghost_image: Image=proxy.rig.skin.albedo_texture.get_image()
    check(real_image.get_data()==ghost_image.get_data(),"ghost_and_real_npc_texture_identical")
    check(proxy.rig.get_script()==w.residents[0].rig.get_script(),"ghost_uses_same_rig_script")
    var canonical: Dictionary=w.residents[0].rig.get_meta("exo_humanoid_r2_selection",{})
    var ghost_selection: Dictionary=proxy.rig.get_meta("exo_humanoid_r2_selection",{})
    check(not canonical.is_empty() and canonical.get("preset_id")==ghost_selection.get("preset_id") and canonical.get("style")==ghost_selection.get("style"),"ghost_keeps_resolved_canonical_wardrobe")
    var original: Vector3=proxy.position
    proxy.display_step(0.1,Vector3(1,0,1),Vector3(0,0,1.5),"walk",0)
    check(proxy.position!=original,"ghost_actual_motion")
    proxy.free()
    print("DRIVE_GEOMETRY ",JSON.stringify(w.active_region.get_meta("v4_crowd_check",{}))," ATTACH ",JSON.stringify(w.active_region.get_meta("v4_crowd_attach",{})))
    var status: Dictionary=w.exo_core.services.invoke("crowd.illusion","status")
    print("DRIVE_CROWD_STATUS ",JSON.stringify(status))
    check(status.get("ghosts",0)>0,"hive_attached_real_authorized_lanes")
    # Move the actual game camera to a physically certified crowd route so
    # culling must instantiate visible rigs, not merely a population plan.
    for node in w.active_region.find_children("*","Node3D",true,false):
        if node.has_method("stats") and not node.agents.is_empty():
            w.player.global_position=node.to_global(node._actor_position(node.agents[0]))
            w.player.velocity=Vector3.ZERO
            w.update_camera()
            break
    await frames(40)
    var renderer_seen: bool=false
    var full_rigs_seen: int=0
    for node in w.active_region.find_children("*","Node3D",true,false):
        if node.has_method("stats"):
            var stat: Dictionary=node.stats()
            if stat.get("uses_real_npc_rig",false):
                renderer_seen=true
                full_rigs_seen+=stat.get("visible",0)
    check(renderer_seen,"hive_renderer_in_actual_region")
    check(full_rigs_seen>0,"hive_visible_full_rigs_in_game_camera")
    # Immutable source capture: replan should not modify actual NPC cosmetics.
    w.exo_core.services.invoke("crowd.illusion","set_density",[0.0])
    w.exo_core.services.invoke("crowd.illusion","set_density",[1.0])
    check(w.residents[0].identity==profile,"hive_replan_keeps_npc_identity")
    check(w.save_progress(),"save_customized_campaign")
    var fresh=preload("res://journey_save.gd").new(w.save_path,101)
    check(fresh.load_progress() and fresh.data.character.skin3d.equipment.get("chest","")=="guard_cuirass","customization_real_save_reload")
    w.free();await process_frame
    print("V5_DRIVE_UPDATES ",JSON.stringify({"checks":checks,"failures":failures,"visible_ghosts_sample":full_rigs_seen}))
    quit(0 if failures.is_empty() else 1)
