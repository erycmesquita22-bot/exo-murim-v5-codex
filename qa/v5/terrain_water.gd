extends SceneTree
const Game=preload("res://convergence/game.gd")
var w:Node3D
var checks:Array=[]
var failures:Array=[]
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
    checks.append({"name":label,"pass":ok})
    if not ok:failures.append(label)
    print("TERRAIN_WATER_CHECK ",label," ",ok)
func run()->void:
    w=Game.new();w.load_on_start=false;w.world_seed_override=101
    w.save_path="user://terrain-water-qa.json";w.settings_path="user://terrain-water-qa.cfg"
    root.add_child(w);await process_frame
    w.flow.phase="creator"
    w.flow.create_character({"name":"Water QA","race":0,"path":0,"robe":1,"skin":0,"hair":0,"style":0,"weapon":"sword"},101)
    w.ui.resume()
    for i in range(400):
        if w.current_region>=0 and not w.changing_region:break
        await physics_frame
    var water_region:int=-1
    for edge in w.atlas.rivers_macro:
        if str(w.atlas.regions[int(edge.from)].kind)!="settlement":water_region=int(edge.from);break
        if str(w.atlas.regions[int(edge.to)].kind)!="settlement":water_region=int(edge.to);break
    check(water_region>=0 and await w.change_region(water_region),"river_region_loaded")
    var d:RefCounted=w.active_region.data
    var point:=Vector2.ZERO;var branch:Dictionary={};var clearance:float=0.0
    for river in d.rivers:
        for sample in range(2,19):
            var candidate:Vector2=d.river_hub.lerp(river.p,float(sample)/20.0)
            var room:float=d.road_distance(candidate)
            if room>clearance and candidate.length()<200.0:
                clearance=room;point=candidate;branch=river
    check(not branch.is_empty() and clearance>10.0,"river_channel_clear_of_roads")
    w.simulation_enabled=false
    w.player.position=Vector3(point.x,d.terrain_height_at(point),point.y)
    check(w.wading_factor()<1.0,"player_slows_in_visible_water")
    check(w.audio_fx.movement_surface()=="water","river_uses_existing_water_footsteps")
    w.simulation_enabled=true
    Input.action_press("up")
    for i in range(18):await physics_frame
    Input.action_release("up")
    check(str(w.audio_fx.voices[17].get_meta("movement_event",""))=="foot.water.shallow","real_wading_starts_existing_water_audio")
    w.simulation_enabled=false
    var water_nodes:Array=get_nodes_in_group("exo_visual_water")
    var uv_ok:bool=false;var level_ok:bool=false
    for node in water_nodes:
        if not w.active_region.is_ancestor_of(node):continue
        var arrays:Array=node.mesh.surface_get_arrays(0)
        var uv:PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
        var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
        if uv.size()>=6 and uv[0].x==0.0 and uv[1].x==1.0 and uv[2].y>uv[0].y:uv_ok=true
        for vertex in vertices:
            if absf(vertex.x-point.x)<2.0 and absf(vertex.z-point.y)<2.0 and absf(vertex.y-d.river_level(branch,point))<0.2:level_ok=true
    check(uv_ok,"water_uv_follows_channel_and_bank")
    check(level_ok,"water_mesh_follows_river_level")
    w.player.position=Vector3(0,d.terrain_height_at(Vector2.ZERO),0)
    check(w.wading_factor()==1.0,"dry_ground_keeps_normal_movement")
    print("V5_TERRAIN_WATER ",JSON.stringify({"checks":checks,"failures":failures,"river_region":water_region,"road_clearance":clearance}))
    quit(0 if failures.is_empty() else 1)
