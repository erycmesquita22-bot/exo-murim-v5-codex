extends SceneTree
## Lightweight native compile/construct smoke test for the HUD UI layer.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var hud_script: Script = load("res://exo_ui/hud_murim.gd")
	if hud_script == null or not hud_script.can_instantiate():
		push_error("HUD 01 não compila ou não instancia")
		quit(1)
		return
	var hud: Control = hud_script.new()
	root.add_child(hud)
	await process_frame
	if hud.font == null or hud.display_font == null:
		push_error("Fontes HUD 01 indisponíveis")
		quit(1)
		return
	hud.free()
	print("HUD_01_NATIVE_SMOKE_OK")
	quit(0)
