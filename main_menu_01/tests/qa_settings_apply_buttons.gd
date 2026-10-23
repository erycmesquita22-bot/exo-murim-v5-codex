extends SceneTree
## Regression: all five main-menu plaques must recover after Apply/Back.
## Run with isolated XDG_DATA_HOME to avoid accessing player saves.

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var issues: Array[String] = []
	var save_file: String = "user://journey.json"
	if FileAccess.file_exists(save_file):
		issues.append("test_user_dir_not_isolated")
		print("EXO_MENU_APPLY_QA ", JSON.stringify({"issues": issues}))
		quit(1)
		return
	var menu: Control = load("res://main_menu_01/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	if Engine.max_fps != 60: issues.append("menu_default_fps_not_capped")
	_check_buttons(menu, [true, false, true, false, false], "initial_no_save", issues)
	menu._show_settings()
	_check_buttons(menu, [true, true, true, true, true], "dialog_blocks_background", issues)
	menu._switch_settings_tab("audio")
	menu.volume_slider.value = 0.65
	menu.audio_controls["combat"].value = 0.25
	menu._switch_settings_tab("interface")
	menu.hud_controls["style"].select(1)
	menu.hud_controls["camera_shake"].button_pressed = false
	menu._switch_settings_tab("video")
	menu.graphics_preset.select(2)
	menu.option_controls["fps_limit"].select(1)
	menu._custom_option_changed(1, "fps_limit")
	menu._apply_settings()
	await process_frame
	if menu.modal.visible: issues.append("settings_still_open_after_apply")
	_check_buttons(menu, [true, false, true, false, false], "after_apply_no_save", issues)
	var audio_cfg := ConfigFile.new()
	if audio_cfg.load("user://exo-audio.cfg") != OK or absf(float(audio_cfg.get_value("volume", "master", 0.0)) - .65) > .001:
		issues.append("master_audio_not_saved")
	if absf(float(audio_cfg.get_value("volume", "combat", 0.0)) - .25) > .001:
		issues.append("combat_audio_not_saved")
	var gfx_cfg := ConfigFile.new()
	if gfx_cfg.load("user://graphics.cfg") != OK:
		issues.append("graphics_not_saved")
	else:
		if int(gfx_cfg.get_value("exo_visual", "fps_limit", -1)) != 1: issues.append("fps_not_shared")
		if int(gfx_cfg.get_value("hud", "style", -1)) != 1: issues.append("hud_not_shared")
		if bool(gfx_cfg.get_value("display", "camera_shake", true)): issues.append("camera_shake_not_shared")
	menu._show_settings()
	menu._close_panel()
	_check_buttons(menu, [true, false, true, false, false], "after_back_no_save", issues)
	var f: FileAccess = FileAccess.open(save_file, FileAccess.WRITE)
	if f == null:
		issues.append("cannot_create_test_save")
	else:
		f.store_string("{}")
		f.close()
		menu._show_settings()
		menu._apply_settings()
		await process_frame
		_check_buttons(menu, [false, false, false, false, false], "after_apply_with_save", issues)
		menu._show_settings()
		menu._close_panel()
		_check_buttons(menu, [false, false, false, false, false], "after_back_with_save", issues)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_file))
	print("EXO_MENU_APPLY_QA ", JSON.stringify({"issues": issues, "options": menu.buttons.size(), "dialog_closed": not menu.modal.visible}))
	quit(0 if issues.is_empty() else 1)

func _check_buttons(menu: Control, expected: Array, phase: String, issues: Array[String]) -> void:
	if menu.buttons.size() != expected.size():
		issues.append(phase + "_button_count")
		return
	for i in range(expected.size()):
		if menu.buttons[i].disabled != expected[i]:
			issues.append("%s_option_%d_expected_disabled_%s" % [phase, i, str(expected[i])])
