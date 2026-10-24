extends "res://modules/integration_v11/integrated_v11.gd"
const HeartMenu = preload("res://modules/coracao_01/heart_menu.gd")
var heart_menu: Control
func _ready() -> void:
	super._ready()
	heart_menu = HeartMenu.new()
	heart_menu.host = self
	var layer := CanvasLayer.new()
	layer.layer = 30
	layer.name = "HeartMenuLayer"
	add_child(layer)
	layer.add_child(heart_menu)
	heart_menu.open_main()
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		if heart_menu.visible: heart_menu.resume_or_main()
		else: heart_menu.open_pause()
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if heart_menu != null: heart_menu.observe()
