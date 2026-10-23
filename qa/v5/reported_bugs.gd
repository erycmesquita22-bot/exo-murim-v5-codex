extends SceneTree
const Game=preload("res://convergence/game.gd")
const Wardrobe=preload("res://wardrobe.gd")
const Preview=preload("res://exo_skin3d/skin_preview.gd")
var failures: Array=[]
var checks: Array=[]
var w: Node3D
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
    print("BUG_CHECK ",label," ",ok);checks.append({"name":label,"pass":ok})
    if not ok:failures.append(label)
func frames(count: int) -> void:
    for i in range(count):await physics_frame
func run() -> void:
    w=Game.new();w.load_on_start=false;w.world_seed_override=101
    w.save_path="user://reported-bugs.json";w.settings_path="user://reported-bugs.cfg"
    root.add_child(w);await process_frame
    var textured_enemies: int=0
    for actor in w.enemies:
        if actor.rig.skin.albedo_texture.get_width()==256 and actor.rig.has_meta("skin3d_cosmetics"):textured_enemies+=1
    check(textured_enemies==w.enemies.size() and textured_enemies>0,"echo_enemies_share_full_textured_appearance")
    # Real preview geometry/IK after the same profile callbacks as the creator.
    var spare: Node3D=w.Rig.new();root.add_child(spare)
    for weapon in ["bow","crossbow"]:
        Wardrobe.apply(spare,{"race":0,"weapon":weapon})
        Preview.demonstrate_pose(spare,"idle",1.0)
        check(spare.forearms[0].rotation.x>=0,"forward_elbow:"+weapon)
        var wrist: Vector3=spare.forearms[0].to_global(Vector3(0,-0.375,0))
        var grip: Vector3=spare.get_meta("weapon_root").global_position
        check(wrist.distance_to(grip)<0.05,"preview_grip_attached:"+weapon)
    spare.pose(1,true,false,true)
    check(spare.forearms[0].rotation.x>=0 and spare.forearms[1].rotation.x>=0,"forward_elbows_walking")
    spare.free()
    var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://exo_terrain_forge/worldgen/terrain_texture_manifest.json"))
    var atlas_ok: bool=true
    for row in manifest.runtime_atlases.values():
        var texture: Texture2D=load(row.path)
        print("ATLAS_NATIVE ",row.path," ",texture.get_size()," expected ",row.resolution)
        if texture.get_width()!=int(row.resolution[0]) or texture.get_height()!=int(row.resolution[1]):atlas_ok=false
    check(atlas_ok,"atlas_dimensions_match_r3_contract")
    w.flow.phase="creator";w.flow.create_character({"name":"Bug QA","race":0,"path":0,"robe":1,"skin":0,"hair":0,"style":0,"weapon":"sword"},101);w.ui.resume()
    for i in range(400):
        if w.current_region>=0 and not w.changing_region:break
        await physics_frame
    check(w.current_region>=0,"campaign_loaded")
    if w.current_region<0:
        w.free();quit(1);return
    var region: Node3D=w.active_region
    var filter_bindings: bool=true
    for mode in range(3):
        w.graphics.set_option("texture_filter",mode)
        for node in get_nodes_in_group("exo_visual_terrain"):
            if not region.is_ancestor_of(node):continue
            var mat: ShaderMaterial=node.material_override
            if not mat.get_shader_parameter("natural_rock_tex") is Texture2D:filter_bindings=false
            if not mat.get_shader_parameter("forge_r3_indices") is Vector3:filter_bindings=false
            for transition in ["grass_dirt","dirt_stone","stone_grass"]:
                if not mat.get_shader_parameter("forge_"+transition+"_mask") is Texture2D:filter_bindings=false
            if str(region.data.spec.kind)=="settlement" and not is_equal_approx(float(mat.get_shader_parameter("forge_stone_road")),1.0):filter_bindings=false
            break
    check(filter_bindings,"all_three_video_filters_preserve_current_terrain_bindings")
    var headings: Dictionary={}
    for actor in w.residents:headings[roundi(actor.rig.rotation.y*10)]=true
    check(headings.size()>1,"npcs_not_all_default_northeast")
    var renderer: Node3D
    for node in region.find_children("*","Node3D",true,false):
        if node.has_method("stats") and node.agents.size()>0:renderer=node;break
    check(renderer!=null,"continuous_crowd_mounted")
    w.simulation_enabled=false
    if renderer!=null:
        var agent: Dictionary=renderer.agents[0]
        check(bool(agent.get("loop",false)) and agent.route[0].distance_to(agent.route[-1])<0.01,"crowd_closed_circuit_no_teleport")
        print("CONTINUOUS_ROUTE_METERS ",agent.route_length)
        var start: Vector3=renderer._actor_position(agent)
        # More than triple the previous 7-second one-shot route lifetime.
        await frames(1440)
        var position_before: Vector3=renderer._actor_position(agent)
        await frames(12)
        var after: Vector3=renderer._actor_position(agent)
        check(after.distance_to(position_before)>0.05,"crowd_still_walking_after_24_seconds")
        check(after.distance_to(position_before)<0.6,"crowd_no_position_jump")
        var separated: bool=true
        for i in range(renderer.agents.size()):
            for j in range(i):
                if renderer._actor_position(renderer.agents[i]).distance_to(renderer._actor_position(renderer.agents[j]))<0.75:separated=false
        check(separated,"crowd_not_stacked_at_endpoints")
        check(renderer.agents.size()<2 or renderer._actor_position(renderer.agents[0]).distance_to(renderer._actor_position(renderer.agents[1]))>1.0,"crowd_distributed_along_road")
    w.simulation_enabled=true
    if renderer!=null:
        w.player.global_position=renderer.to_global(renderer.agents[0].route[5])+Vector3.UP*0.1
        w.player.velocity=Vector3.ZERO
        await frames(35)
        Input.action_press("up")
        await frames(12)
        check(w.audio_fx.voices[17].playing,"footsteps_during_real_player_input")
        Input.action_release("up")
        await frames(6)
        check(not w.audio_fx.voices[17].playing,"footsteps_stop_after_input_release")
    var original: Vector3=w.player.position
    w.audio_fx.last_step=original-Vector3(0.1,0,0)
    w.audio_fx.steps(original,true,true)
    check(w.audio_fx.voices[17].playing and str(w.audio_fx.voices[17].get_meta("movement_event","")).begins_with("foot."),"real_footstep_stream_started")
    w.audio_fx.steps(original,true,false)
    await frames(12) # Movement audio fades out over at most 70ms instead of cutting.
    check(not w.audio_fx.voices[17].playing,"footsteps_stop_when_stationary")
    # The actual portal carries a visual membrane and E performs real travel.
    var gate: Dictionary=region.gate_nodes[0]
    check(gate.open and gate.node.get_node_or_null("ActiveTransitPortal")!=null,"open_gate_has_visible_portal")
    var expected: int=int(gate.contract.neighbor)
    w.player.position=gate.point+Vector3.UP*0.1;w.player.velocity=Vector3.ZERO
    await frames(60)
    w.interaction_cooldown=0;w.gate_cooldown=0
    print("PORTAL_BEFORE ",w.player.position," floor ",w.player.is_on_floor()," phase ",w.flow.phase," expected ",expected)
    w.interact()
    for i in range(400):
        if w.current_region==expected and not w.changing_region:break
        await physics_frame
    print("PORTAL_AFTER region ",w.current_region," expected ",expected," feedback ",w.feedback," failure ",w.generation_failure)
    check(w.current_region==expected,"portal_real_interaction_travels")
    # Validate anchors against real ground collision in a non-settlement region.
    var wild: int=-1
    for spec in w.atlas.regions:
        if str(spec.kind)=="wild":wild=int(spec.id);break
    check(await w.change_region(wild),"wild_region_loaded_for_trees")
    await frames(3)
    var anchored: int=0;var buried: int=0;var colored: bool=false
    for node in w.active_region.get_children():
        if not node.has_meta("vegetation_ground_anchor"):continue
        anchored+=1
        var pos: Vector3=node.global_position
        var query:=PhysicsRayQueryParameters3D.create(pos+Vector3.UP*12,pos-Vector3.UP*12,1)
        var hit: Dictionary=w.get_world_3d().direct_space_state.intersect_ray(query)
        if hit.is_empty() or absf(float(hit.position.y)-(pos.y+0.08))>0.03:buried+=1
        var visual: MeshInstance3D=node.get_child(0)
        var colors: PackedColorArray=visual.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
        for color in colors:
            if color.g>color.r*1.1 and color.g>color.b*1.1:colored=true;break
    check(anchored>0 and buried==0,"trees_grounded_on_actual_mesh:"+str(anchored))
    check(colored,"tree_material_colors_survive_mesh_merge")
    check(not w.npc_activity_label("viagem").contains("cf/r"),"dialogue_human_activity_label")
    w.free();await process_frame
    print("V5_REPORTED_BUGS ",JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
