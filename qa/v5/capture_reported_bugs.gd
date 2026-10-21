extends SceneTree
const Game=preload("res://convergence/game.gd")
var w: Node3D
func _initialize() -> void:call_deferred("run")
func frames(n: int) -> void:
    for i in range(n):await process_frame
func shot(label: String) -> void:
    await RenderingServer.frame_post_draw
    var code: int=root.get_texture().get_image().save_png("user://bugfix-"+label+".png")
    print("BUG_CAPTURE ",label," ",code)
func run() -> void:
    w=Game.new();w.load_on_start=false;w.world_seed_override=101
    w.save_path="user://visual-bugs.json";w.settings_path="user://visual-bugs.cfg"
    root.add_child(w);await frames(8)
    w.flow.phase="creator";w.ui.creation_tab=1;w.ui.appearance_tab=1
    w.ui.profile.weapon="crossbow";w.ui.show_creator();await frames(12)
    await shot("crossbow-forward-elbows")
    w.flow.create_character({"name":"Visual QA","race":0,"path":0,"robe":1,"skin":0,"hair":0,"style":0,"weapon":"sword"},101);w.ui.resume()
    for i in range(400):
        if w.current_region>=0 and not w.changing_region:break
        await physics_frame
    await frames(20)
    await shot("terrain-and-inhabitants")
    var renderer: Node3D
    for node in w.active_region.find_children("*","Node3D",true,false):
        if node.has_method("stats") and not node.agents.is_empty():renderer=node;break
    if renderer!=null:
        w.player.global_position=renderer.to_global(renderer._actor_position(renderer.agents[0]))
        w.update_camera();await frames(20)
        await shot("continuous-crowd")
    var gate: Dictionary=w.active_region.gate_nodes[0]
    w.player.position=gate.point+Vector3(0,0.1,0);w.player.velocity=Vector3.ZERO
    await frames(30);w.update_camera();await frames(8)
    await shot("active-portal")
    var wild: int=-1
    for spec in w.atlas.regions:
        if str(spec.kind)=="wild" and str(spec.biome) in ["rocky_highlands","alpine"]:wild=int(spec.id);break
    if wild<0:wild=0
    if await w.change_region(wild):
        for tree in w.active_region.get_children():
            if tree.has_meta("vegetation_ground_anchor"):
                w.player.position=tree.position+Vector3(3,0.3,0)
                w.player.position.y=w.active_region.surface_height_at(Vector2(w.player.position.x,w.player.position.z))+.1
                w.player.velocity=Vector3.ZERO;break
        await frames(25);w.update_camera();await frames(8)
        await shot("mountain-tree-grounding")
        for mode in range(3):
            w.graphics.set_option("texture_filter",mode);await frames(8)
            await shot("mountain-filter-"+str(mode))
        if not w.enemies.is_empty():
            var actor: Node3D=w.enemies[0]
            w.player.position=actor.position+Vector3(2,0,2);w.player.position.y=w.active_region.surface_height_at(Vector2(w.player.position.x,w.player.position.z))+.1
            w.update_camera();await frames(8)
            await shot("textured-echo-enemy")
    for spec in w.atlas.regions:
        if str(spec.kind) not in ["wild","ruins"]:continue
        if not await w.change_region(int(spec.id)):continue
        if w.enemies.is_empty():continue
        var actor: Node3D=w.enemies[0]
        w.player.position=actor.position+Vector3(2,0,2)
        w.player.position.y=w.active_region.surface_height_at(Vector2(w.player.position.x,w.player.position.z))+.1
        w.player.velocity=Vector3.ZERO;w.update_camera();await frames(10)
        await shot("textured-echo-enemy")
        break
    w.free();await process_frame;quit()
