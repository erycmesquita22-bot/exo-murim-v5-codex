extends "res://godot/S06_Haneul_InteriorController.gd"
## Add ONE hand-authored outdoor route to the frozen Haneul S06 base.
## Keep V3 movements, combat and S06 doors intact. F near north road exit.
const S07_ROUTE_SCENE := preload("res://world_sprint07/S07_RouteScene.tscn")
const S07_ROUTE_ORIGIN := Vector3(1200.0,0.0,-1200.0)
const S07_HANEUL_GATE := Vector3(-13.0,0.0,-101.0)
var s07_route: Node3D
var s07_active: bool = false
var s07_reached_yunseong: bool = false
var s07_saved_position: Vector3
var s07_gateway: Node3D
var s07_events: Array[Dictionary] = []

func _ready() -> void:
    super._ready()
    s07_gateway = load("res://architecture_sprint02/kit/COURTYARD_GATE.glb").instantiate() as Node3D
    s07_gateway.name = "S07_Haneul_NorthRoadGate"
    s07_gateway.position = Vector3(-13.0,_terrain_height(-13.0,-101.0),-104.5)
    s07_gateway.scale = Vector3(.85,.85,.85)
    add_child(s07_gateway)
    # Quiet marker metadata, not fake map teleport boxes or a second city.
    s07_gateway.set_meta("destination","ROAD-02-01")
    print("S07_READY old_interiors=",entrances.size()," family=",active_family," ROAD_02_01_AVAILABLE")

func _on_haneul_road_gate() -> bool:
    if actor == null or active_room_id != "" or s07_active: return false
    return Vector2(actor.position.x-S07_HANEUL_GATE.x,actor.position.z-S07_HANEUL_GATE.z).length() < 5.0

func _on_route_return_gate() -> bool:
    if not s07_active or s07_route == null: return false
    var a: Vector3 = S07_ROUTE_ORIGIN + s07_route.local_start()
    return Vector2(actor.position.x-a.x,actor.position.z-a.z).length() < 6.5

func _on_city_gate() -> bool:
    if not s07_active or s07_route == null: return false
    var a: Vector3 = S07_ROUTE_ORIGIN + s07_route.local_arrival()
    return Vector2(actor.position.x-a.x,actor.position.z-a.z).length() < 9.0

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F:
        if s07_active:
            if _on_route_return_gate() and not is_transitioning:
                _s07_fade_to_region(false)
            elif _on_city_gate():
                s07_reached_yunseong = true
                s07_events.append({"event":"ARRIVAL_GATE","region":"HWA-01_OUTSKIRTS"})
                print("S07_YUNSEONG_OUTSKIRTS reached; HWA-01 city interior NOT IMPLEMENTED")
            return
        if _on_haneul_road_gate() and not is_transitioning:
            _s07_fade_to_region(true)
            return
    super._unhandled_input(event)

func _s07_fade_to_region(go_road: bool) -> void:
    if is_transitioning: return
    is_transitioning = true
    var panel := ColorRect.new()
    panel.color = Color(.04,.05,.06,0.0)
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    panel.z_index = 110
    hud.get_parent().add_child(panel)
    var tween := create_tween()
    tween.tween_property(panel,"color:a",1.0,.15)
    await tween.finished
    if go_road: _s07_commit_enter()
    else: _s07_commit_return()
    var fade := create_tween()
    fade.tween_property(panel,"color:a",0.0,.20)
    await fade.finished
    panel.queue_free()
    is_transitioning = false

func _s07_commit_enter() -> bool:
    if s07_active or active_room_id != "": return false
    var route: Node3D = S07_ROUTE_SCENE.instantiate() as Node3D
    route.position = S07_ROUTE_ORIGIN
    route.name = "S07_ActiveRoad02_01"
    add_child(route)
    s07_route = route
    s07_saved_position = actor.position
    s07_active = true
    for n in environment_nodes: n.visible = false
    for n in get_children():
        if n is Node3D and (n.name.begins_with("EXO_Haneul_Terrain_") or n.name.begins_with("EXO_Rio_Hwa_")):
            n.visible = false
    s07_gateway.visible = false
    target.visible = false
    locked = false
    actor.velocity = Vector3.ZERO
    actor.position = S07_ROUTE_ORIGIN + route.local_start() + Vector3(0,1.1,0)
    pivot.position = actor.position + Vector3(0,1.65,0)
    camera_distance = 5.0
    s07_events.append({"event":"ENTER_ROAD","id":"ROAD-02-01"})
    print("S07_ENTER_ROAD route_colliders=",route.generated_collisions," vegetation=",route.vegetation_instances)
    return true

func _s07_commit_return() -> bool:
    if not s07_active: return false
    actor.velocity = Vector3.ZERO
    actor.position = s07_saved_position + Vector3(0,.7,0)
    pivot.position = actor.position + Vector3(0,1.65,0)
    for n in environment_nodes: n.visible = true
    for n in get_children():
        if n is Node3D and (n.name.begins_with("EXO_Haneul_Terrain_") or n.name.begins_with("EXO_Rio_Hwa_")):
            n.visible = true
    wong_signs.visible = active_family == "WONG"
    wudong_signs.visible = active_family == "WUDONG"
    s07_gateway.visible = true
    target.visible = show_training_dummy
    s07_route.queue_free()
    s07_route = null
    s07_active = false
    camera_distance = 3.8
    s07_events.append({"event":"RETURN_HANEUL","id":"HWA-02"})
    print("S07_RETURN_HANEUL success")
    return true

func finish_frame(delta: float) -> void:
    super.finish_frame(delta)
    if s07_active:
        hud.text = "EXO-MURIM / ROAD-02-01 / CAMINHO DO VAU\nWASD mover | Shift correr | F nos portoes | E arma | Q esquiva"
        if _on_route_return_gate(): s06_prompt.text = "[F] Voltar para Vila Haneul"
        elif _on_city_gate():
            s06_prompt.text = "[F] Yunseong — arredores preparados; cidade em producao"
        elif s07_reached_yunseong: s06_prompt.text = "Yunseong avistada: o mapa urbano ainda nao foi construido"
        else: s06_prompt.text = "Estrada das familias | atravesse o vale ate o portao de Yunseong"
    elif active_room_id == "" and _on_haneul_road_gate():
        s06_prompt.text = "[F] Viajar pela Estrada do Vau ate Yunseong"
