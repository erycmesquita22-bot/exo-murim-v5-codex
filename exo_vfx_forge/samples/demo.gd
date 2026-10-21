extends Node3D
# FAKE-EVENT HARNESS. No real damage, sound, core bindings, or locomotion.
const EDITOR_UI = preload("res://exo_vfx_forge/editor/authoring_panel.gd")
const SVC = preload("res://exo_vfx_forge/runtime/vfx_service.gd")
const ENTRIES = [
    ["vfx.slash.qi.blue.v1","launch","corte_inicial"],
    ["vfx.impact.martial.amber.v1","impact","golpe_circular"],
    ["vfx.dash.afterimage.jade.v1","launch","investida_brutal"],
    ["vfx.teleport.short.violet.v1","launch","salto_impetuoso"],
    ["vfx.ice.spikes.cold.v1","impact","nova_glacial"],
    ["vfx.thunder.lance.v1","launch","rajada_de_vento"],
    ["vfx.meteor.ember.v1","launch","rajada_de_fogo"],
    ["vfx.beam.qi.v1","launch","dardo_arcano"],
    ["vfx.snare.jade.v1","prepare","barreira_arcana"],
    ["vfx.crown.frost.v1","launch","guardiao_ancestral"]
]
var visual_service: Variant = null
var selection: int = 0
var counter: int = 0
var selected_quality: String = "medium"
var ui_text: Label
var demo_time: float = 0.0
var paused_effects: bool = false

func _ready() -> void:
    _make_stage()
    visual_service = SVC.new()
    visual_service.name = "VFX_Passive_Consumer"
    add_child(visual_service)
    for e in ENTRIES:
        visual_service.approve_binding(str(e[2]),[str(e[0])])
    _make_ui()
    var editing_panel: CanvasLayer = EDITOR_UI.new()
    editing_panel.call("setup",self)
    add_child(editing_panel)
    _play_selection()

func _make_stage() -> void:
    var ground: MeshInstance3D = MeshInstance3D.new()
    var floor_mesh: PlaneMesh = PlaneMesh.new()
    floor_mesh.size = Vector2(25,25)
    ground.mesh = floor_mesh
    var mat: StandardMaterial3D = StandardMaterial3D.new()
    mat.albedo_color = Color("4a5d51")
    ground.material_override = mat
    add_child(ground)
    var body: MeshInstance3D = MeshInstance3D.new()
    var box: BoxMesh = BoxMesh.new()
    box.size = Vector3(.75,1.5,.44)
    body.mesh = box
    body.position = Vector3(0,.75,1.8)
    var bmat: StandardMaterial3D = StandardMaterial3D.new()
    bmat.albedo_color = Color("303946")
    body.material_override = bmat
    add_child(body)
    var head: MeshInstance3D = MeshInstance3D.new()
    var hb: BoxMesh = BoxMesh.new()
    hb.size = Vector3(.55,.55,.55)
    head.mesh = hb
    head.position = Vector3(0,1.72,1.8)
    var hmat: StandardMaterial3D = StandardMaterial3D.new()
    hmat.albedo_color = Color("d6a079")
    head.material_override = hmat
    add_child(head)
    var camera: Camera3D = Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 15
    camera.position = Vector3(8,9,15)
    add_child(camera)
    camera.look_at(Vector3(0,.3,0),Vector3.UP)
    camera.current = true
    var light: DirectionalLight3D = DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-48,-30,0)
    add_child(light)
    var env: WorldEnvironment = WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color("1a2634")
    add_child(env)

func _make_ui() -> void:
    var hud: CanvasLayer = CanvasLayer.new()
    add_child(hud)
    var label: Label = Label.new()
    label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    label.position = Vector2(16,12)
    label.add_theme_font_size_override("font_size",18)
    hud.add_child(label)
    ui_text = label
    _update_hud()

func _update_hud() -> void:
    if ui_text == null: return
    ui_text.text = "EXO VFX FORGE 03 | FAKE EVENT SANDBOX | %s | quality: %s\n1-0: effect, SPACE: fire, Q: cycle quality, P: pause, N: single frame, X: interrupt\nAudio NOT PLAYED. No damage or movement. %s" % [ENTRIES[selection][0],selected_quality,str(visual_service.stats() if is_instance_valid(visual_service) else {})]

func _unhandled_key_input(e: InputEvent) -> void:
    if not e is InputEventKey or not e.pressed or e.echo: return
    if e.keycode >= KEY_1 and e.keycode <= KEY_9:
        selection = int(e.keycode - KEY_1)
        _play_selection()
    elif e.keycode == KEY_0:
        selection = 9
        _play_selection()
    elif e.keycode == KEY_SPACE:
        _play_selection()
    elif e.keycode == KEY_Q:
        selected_quality = "medium" if selected_quality == "low" else "high" if selected_quality == "medium" else "low"
    elif e.keycode == KEY_X:
        visual_service.clear_all()
    elif e.keycode == KEY_P:
        paused_effects = not paused_effects
        visual_service.process_mode = Node.PROCESS_MODE_DISABLED if paused_effects else Node.PROCESS_MODE_INHERIT
    elif e.keycode == KEY_N and paused_effects:
        for n in visual_service.get_children():
            if bool(n.get("active")):
                n.call("_process",1.0/30.0)
    _update_hud()

func _play_selection() -> void:
    if not is_instance_valid(visual_service): return
    var row: Array = ENTRIES[selection]
    counter += 1
    var castid: String = "SANDBOX-C" + str(counter)
    # Provenance: this harness is explicitly synthetic. Impact gets prior launch authorization.
    if str(row[1]) == "impact":
        visual_service.approve_binding(str(row[2]),[str(row[0]),"vfx.slash.qi.blue.v1"])
        var prime: Dictionary = _event(castid,row,"launch", "vfx.slash.qi.blue.v1",0)
        visual_service.consume_av_event(prime)
    var actual: Dictionary = _event(castid,row,str(row[1]),str(row[0]),1)
    visual_service.consume_av_event(actual)
    _update_hud()

func _event(cid: String, row: Array, phase: String, vfx: String, seq: int) -> Dictionary:
    return {"contract_version":"exo.vfx.events/1","cast_instance_id":cid,"skill_id":str(row[2]),"caster_entity_id":"SANDBOX_MANNEQUIN","cue_id":"sandbox."+str(row[2])+"."+phase,"vfx_id":vfx,"phase":phase,"visual_seed":157+counter,"quality_profile":selected_quality,"origin_xyz":[0.0,0.05,0.0],"direction_xyz":[0.0,0.0,-1.0],"event_sequence":seq}

func get_entry_ids() -> Array[String]:
    var names: Array[String] = []
    for row in ENTRIES:
        names.append(str(row[0]))
    return names
