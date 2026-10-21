extends CanvasLayer
# Editor-only authoring UI. Does NOT ship in production runtime.
var game: Variant
var glow_slider: HSlider
var speed_slider: HSlider
var selector: OptionButton
var quality: OptionButton
var status: Label
func setup(demo: Node3D) -> void:
    game = demo
func _ready() -> void:
    var panel: PanelContainer = PanelContainer.new()
    panel.offset_left=16.0
    panel.offset_top=116.0
    panel.offset_right=320.0
    panel.offset_bottom=390.0
    add_child(panel)
    var col: VBoxContainer = VBoxContainer.new()
    panel.add_child(col)
    var head: Label=Label.new()
    head.text="VFX AUTHORING — SANDBOX ONLY"
    col.add_child(head)
    selector=OptionButton.new()
    for i in range(game.get_entry_ids().size()):
        selector.add_item(str(game.get_entry_ids()[i]),i)
    selector.item_selected.connect(_select)
    col.add_child(selector)
    quality=OptionButton.new()
    for val in ["low","medium","high"]:
        quality.add_item(val)
    quality.select(1)
    quality.item_selected.connect(_quality)
    col.add_child(quality)
    var glow: Label=Label.new();glow.text="Time scale preview (0.1–2.0x)";col.add_child(glow)
    speed_slider=HSlider.new()
    speed_slider.min_value=0.1;speed_slider.max_value=2.0;speed_slider.step=0.1;speed_slider.value=1.0
    speed_slider.value_changed.connect(_speed)
    col.add_child(speed_slider)
    var bright: Label=Label.new();bright.text="Glow strength (preview instances)";col.add_child(bright)
    glow_slider=HSlider.new()
    glow_slider.min_value=0.1;glow_slider.max_value=2.0;glow_slider.step=0.1;glow_slider.value=1.0
    glow_slider.value_changed.connect(_glow)
    col.add_child(glow_slider)
    for label in ["PLAY", "CANCEL / INTERRUPT", "EXPORT PRESET JSON"]:
        var b: Button=Button.new()
        b.text=label
        col.add_child(b)
        if label=="PLAY":b.pressed.connect(_play)
        elif label.begins_with("CANCEL"):b.pressed.connect(_cancel)
        else:b.pressed.connect(_export)
    status=Label.new()
    col.add_child(status)
func _select(i: int) -> void:
    game.selection=i
    game._play_selection()
func _quality(i: int) -> void:
    game.selected_quality=["low","medium","high"][i]
    game._update_hud()
func _speed(v: float) -> void:
    if game.visual_service!=null:
        for n in game.visual_service.get_children():
            if n is Node3D:n.set_process(v>0.0)
    Engine.time_scale=v # Sandbox-only; NEVER call from visual production runtime.
func _glow(v: float) -> void:
    if game.visual_service==null:return
    for n in game.visual_service.get_children():
        if n.get("glow_mats") is Array:
            for mat in n.get("glow_mats"):
                mat.set_shader_parameter("glow_strength",v)
func _play() -> void:
    game._play_selection()
func _cancel() -> void:
    game.visual_service.clear_all()
func _export() -> void:
    var data: Dictionary={"schema":"exo.vfx.editor-preset/1","vfx_id":str(game.get_entry_ids()[game.selection]),"quality_profile":game.selected_quality,"preview_time_scale":speed_slider.value,"preview_glow":glow_slider.value,"SAMPLE_ONLY":true}
    var f: FileAccess=FileAccess.open("user://exo_vfx_editor_preset.json",FileAccess.WRITE)
    if f==null:
        status.text="Export blocked: cannot write user://"
        return
    f.store_string(JSON.stringify(data,"  "))
    f.close()
    status.text="Exported: user://exo_vfx_editor_preset.json"
