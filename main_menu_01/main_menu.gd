extends Control
## A light 2D menu sharing the game's settings files and real loading phases.
const GAME_SCENE: String = "res://convergence/game.tscn"
const SAVE_PATH: String = "user://journey.json"
const ART: Texture2D = preload("res://main_menu_01/art/voxel_murim_dawn.png")
const Spec = preload("res://exo_visual/spec.gd")
const CAPTIONS: Array[String] = ["Continuar jornada", "Nova jornada", "Carregar personagem", "Configurações", "Sair do jogo"]
const GRAPHICS_PATH: String = "user://graphics.cfg"
const AUDIO_PATH: String = "user://exo-audio.cfg"
var wallpaper: TextureRect
var title_label: Label
var subtitle_label: Label
var ambient: Control
var buttons: Array[TextureButton] = []
var modal: Control
var card: PanelContainer
var card_column: VBoxContainer
var current_panel: String = ""
var action_busy: bool = false
var pending_mode: String = ""
var full_screen_toggle: CheckButton
var volume_slider: HSlider
var graphics_preset: OptionButton
var settings_tab: String = "video"
var settings_scroll: ScrollContainer
var option_controls: Dictionary = {}
var audio_controls: Dictionary = {}
var hud_controls: Dictionary = {}
var loading_panel: PanelContainer
var loading_label: Label
var loading_bar: ProgressBar
var loading_status: Label
var loading_request_started := false
var load_stage := 0
var pending_visual: Dictionary = {}
var pending_audio: Dictionary = {}
var pending_hud: Dictionary = {}
var pending_interface: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	wallpaper = TextureRect.new()
	wallpaper.name = "WuxiaWallpaper"
	wallpaper.texture = ART
	wallpaper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wallpaper.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	wallpaper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wallpaper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wallpaper)
	ambient = preload("res://main_menu_01/ambient.gd").new()
	ambient.name = "SakuraAndWind"
	add_child(ambient)
	title_label = _make_label("EXO • MURIM", 52, Color("ffe0a3"))
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, .85))
	title_label.add_theme_constant_override("shadow_offset_x", 3)
	title_label.add_theme_constant_override("shadow_offset_y", 3)
	add_child(title_label)
	subtitle_label = _make_label("O caminho das artes marciais", 20, Color("ffdfaa"))
	subtitle_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, .85))
	add_child(subtitle_label)
	_build_buttons()
	_build_panel()
	_build_loading()
	_apply_saved_display()
	get_viewport().size_changed.connect(_layout)
	_layout()

func _build_buttons() -> void:
	for i in range(5):
		var btn := TextureButton.new()
		btn.name = "Action_%d" % i
		btn.tooltip_text = CAPTIONS[i]
		btn.texture_normal = load("res://main_menu_01/buttons/plaque_%d_normal.png" % i)
		btn.texture_hover = load("res://main_menu_01/buttons/plaque_%d_hover.png" % i)
		btn.texture_pressed = load("res://main_menu_01/buttons/plaque_%d_pressed.png" % i)
		btn.texture_focused = btn.texture_hover
		btn.texture_disabled = load("res://main_menu_01/buttons/plaque_%d_disabled.png" % i)
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_SCALE
		btn.focus_mode = Control.FOCUS_ALL
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.pressed.connect(_on_action.bind(i))
		add_child(btn)
		buttons.append(btn)
	_refresh_buttons()

func _refresh_buttons() -> void:
	if buttons.is_empty():
		return
	# Dialogs temporarily disable every plaque. When a dialog closes, restore
	# each menu action, not only the save-dependent ones.
	var available: bool = FileAccess.file_exists(SAVE_PATH)
	for i in range(buttons.size()):
		buttons[i].disabled = (i == 0 or i == 2) and not available

func _layout() -> void:
	var vp: Vector2 = get_viewport_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return
	var scale_factor: float = minf(vp.x / 1672.0, vp.y / 941.0)
	var portrait: bool = vp.x / vp.y < 1.32
	wallpaper.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	title_label.position = Vector2(25, maxf(18, vp.y * .065))
	title_label.add_theme_font_size_override("font_size", int(clampf(vp.x * .042, 27, 54)))
	title_label.size = Vector2(vp.x * .7, 72)
	subtitle_label.position = title_label.position + Vector2(2, clampf(vp.x * .05, 38, 62))
	subtitle_label.add_theme_font_size_override("font_size", int(clampf(vp.x * .018, 13, 20)))
	subtitle_label.size = Vector2(vp.x * .8, 36)
	if portrait:
		# Portrait/mobile UI: large touch plates, vertically arranged.
		var pw: float = minf(vp.x - 28.0, 485.0)
		var ph: float = clampf(vp.y * 0.075, 62.0, 94.0)
		var gap: float = maxf(9.0, ph * 0.12)
		var first_y: float = maxf(70.0, (vp.y - (ph * 5 + gap * 4)) * 0.72)
		for i in range(5):
			buttons[i].position = Vector2((vp.x - pw) * 0.5, first_y + i * (ph + gap))
			buttons[i].size = Vector2(pw, ph)
	else:
		var bw: float = 430.0 * scale_factor
		var bh: float = 91.0 * scale_factor
		var gap: float = 13.0 * scale_factor
		var right: float = 33.0 * scale_factor
		var top: float = (vp.y - 941.0 * scale_factor) * 0.5 + 352.0 * scale_factor
		for i in range(5):
			buttons[i].position = Vector2(vp.x - bw - right, top + i * (bh + gap))
			buttons[i].size = Vector2(bw, bh)
	if is_instance_valid(modal):
		modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		card.custom_minimum_size.x = minf(790.0 if current_panel == "settings" else 520.0, maxf(270.0, vp.x-24.0))
		card.custom_minimum_size.y = minf(590.0 if current_panel == "settings" else 390.0, maxf(250.0, vp.y-24.0))
		card_column.custom_minimum_size.x = minf(750.0 if current_panel == "settings" else 480.0, maxf(228.0, vp.x-65.0))
		if is_instance_valid(volume_slider):
			volume_slider.custom_minimum_size.x = minf(430.0, maxf(160.0, vp.x-110.0))
	if is_instance_valid(loading_panel):
		loading_panel.custom_minimum_size.x = minf(560.0, maxf(260.0, vp.x - 24.0))
		loading_bar.custom_minimum_size.x = minf(480.0, maxf(185.0, vp.x - 90.0))
		loading_panel.position = Vector2((vp.x-loading_panel.size.x)*.5, vp.y * .72)

func _make_style(bg: Color, edge: Color, border: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = edge
	style.set_border_width_all(border)
	style.set_corner_radius_all(5)
	style.shadow_color = Color(0, 0, 0, .48)
	style.shadow_size = 8
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _make_label(text_value: String, font_size: int = 19, color: Color = Color("ead3ac")) -> Label:
	var l := Label.new()
	l.text = text_value
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", font_size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _action_button(text_value: String, callback: Callable, primary: bool = false) -> Button:
	var b := Button.new()
	b.text = text_value
	b.custom_minimum_size = Vector2(140, 43)
	b.add_theme_font_size_override("font_size", 17)
	b.add_theme_color_override("font_color", Color("f4dcad"))
	b.add_theme_stylebox_override("normal", _make_style(Color("322820") if primary else Color("24201c"), Color("aa7842")))
	b.add_theme_stylebox_override("hover", _make_style(Color("70221e"), Color("e5a75a")))
	b.add_theme_stylebox_override("pressed", _make_style(Color("511c1a"), Color("e7b76b")))
	b.add_theme_stylebox_override("focus", _make_style(Color(0,0,0,0), Color("ffd88b"), 1))
	b.pressed.connect(callback)
	return b

func _build_panel() -> void:
	modal = Control.new()
	modal.name = "SingleMenuDialog"
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal)
	var shade := ColorRect.new()
	shade.name = "DimBackdrop"
	shade.color = Color(0.045, 0.027, 0.015, 0.66)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(center)
	card = PanelContainer.new()
	card.name = "MurimSettingsCard"
	card.custom_minimum_size = Vector2(520, 390)
	card.add_theme_stylebox_override("panel", _make_style(Color("231a13"), Color("d9a557"), 3))
	center.add_child(card)
	card_column = VBoxContainer.new()
	card_column.custom_minimum_size.x = 480
	card_column.add_theme_constant_override("separation", 13)
	card.add_child(card_column)
	modal.visible = false

func _build_loading() -> void:
	loading_panel = PanelContainer.new()
	loading_panel.name = "JourneyLoading"
	loading_panel.custom_minimum_size = Vector2(560, 120)
	loading_panel.add_theme_stylebox_override("panel", _make_style(Color("231a13"), Color("d9a557"), 2))
	add_child(loading_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	loading_panel.add_child(column)
	loading_label = _make_label("PREPARANDO A JORNADA", 20, Color("f6cd81"))
	column.add_child(loading_label)
	loading_bar = ProgressBar.new()
	loading_bar.name = "RealLoadingProgress"
	loading_bar.show_percentage = true
	loading_bar.max_value = 100
	loading_bar.custom_minimum_size = Vector2(480, 22)
	column.add_child(loading_bar)
	loading_status = _make_label("Lendo os recursos do mundo...", 14)
	column.add_child(loading_status)
	loading_panel.visible = false

func _apply_saved_display() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(GRAPHICS_PATH) != OK:
		Engine.max_fps = 60
		return
	Engine.max_fps = [0, 30, 60, 90, 120, 144][Spec.normalize("fps_limit", cfg.get_value("exo_visual", "fps_limit", 2))]
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if int(cfg.get_value("exo_visual", "vsync", 1)) > 0 else DisplayServer.VSYNC_DISABLED)
	var mode: int = Spec.normalize("window_mode", cfg.get_value("exo_visual", "window_mode", 0))
	if mode == 1:
		get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	elif mode == 2:
		get_window().mode = Window.MODE_MAXIMIZED
	else:
		get_window().mode = Window.MODE_WINDOWED
		get_window().size = Spec.DISPLAY_RESOLUTIONS[Spec.normalize("resolution", cfg.get_value("exo_visual", "resolution", 0))]

func _clear_panel() -> void:
	for child in card_column.get_children():
		card_column.remove_child(child)
		child.queue_free()
	modal.visible = true
	for btn in buttons:
		btn.disabled = true

func _show_panel(title_value: String, description: String) -> void:
	_clear_panel()
	card_column.add_child(_make_label(title_value, 30, Color("f1bd70")))
	card_column.add_child(HSeparator.new())
	card_column.add_child(_make_label(description, 16, Color("c4b39f")))

func _close_panel() -> void:
	modal.visible = false
	current_panel = ""
	_refresh_buttons()

func _footer_with_cancel(action: Callable, confirmation_text: String = "Confirmar") -> void:
	var stretch := Control.new()
	stretch.custom_minimum_size.y = 16
	card_column.add_child(stretch)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_END
	card_column.add_child(row)
	var back := _action_button("Voltar", _close_panel)
	var confirm := _action_button(confirmation_text, action, true)
	if get_viewport_rect().size.x < 440:
		back.custom_minimum_size.x = 100
		confirm.custom_minimum_size.x = 120
	row.add_child(back)
	row.add_child(confirm)

func _on_action(index: int) -> void:
	if action_busy or modal.visible:
		return
	match index:
		0:
			_begin_game("continue")
		1:
			_confirm_new()
		2:
			_show_load()
		3:
			_show_settings()
		4:
			get_tree().quit()

func _confirm_new() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_begin_game("new")
		return
	current_panel = "confirm"
	_show_panel("NOVA JORNADA", "Uma nova jornada substituirá o progresso do slot atual ao salvar. Deseja continuar?")
	_footer_with_cancel(func(): _begin_game("new"), "Iniciar jornada")

func _show_load() -> void:
	current_panel = "load"
	_show_panel("CARREGAR PERSONAGEM", "Selecione uma jornada registrada para continuar.")
	if FileAccess.file_exists(SAVE_PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
		var title_value: String = "Slot 01  •  Jornada salva"
		if parsed is Dictionary:
			var profile: Variant = parsed.get("character", {})
			if profile is Dictionary:
				title_value = "Slot 01  •  %s" % str(profile.get("name", "Andarilho"))
		card_column.add_child(_action_button(title_value, func(): _begin_game("load"), true))
	else:
		card_column.add_child(_make_label("Nenhuma jornada salva encontrada.", 16))
	card_column.add_child(_action_button("Voltar", _close_panel))

func _load_audio() -> float:
	var cfg := ConfigFile.new()
	if cfg.load(AUDIO_PATH) == OK:
		return clampf(float(cfg.get_value("volume", "master", .75)), 0.0, 1.0)
	return .75

func _show_settings() -> void:
	current_panel = "settings"
	settings_tab = "video"
	var gfx := ConfigFile.new()
	gfx.load(GRAPHICS_PATH)
	pending_visual = Spec.defaults()
	pending_visual.merge(Spec.PRESETS[2], true)
	for key in Spec.OPTIONS:
		pending_visual[key] = Spec.normalize(str(key), gfx.get_value("exo_visual", key, pending_visual[key]))
	pending_visual["preset"] = clampi(int(gfx.get_value("exo_visual", "preset", 2)), 0, 5)
	pending_hud.clear()
	for key in ["style", "theme", "anchor", "scale", "opacity", "values", "portrait", "compact", "target", "notices"]:
		var fallback: Variant = {"style":0,"theme":0,"anchor":0,"scale":1.0,"opacity":.85,"values":true,"portrait":true,"compact":false,"target":true,"notices":true}[key]
		pending_hud[key] = gfx.get_value("hud", key, fallback)
	pending_interface = {"menu_style":gfx.get_value("interface", "menu_style", 0),"ornaments":gfx.get_value("interface", "ornaments", true),"paper":gfx.get_value("interface", "paper", true),"preview_motion":gfx.get_value("interface", "preview_motion", true),"camera_shake":gfx.get_value("display", "camera_shake", true)}
	var audio_cfg := ConfigFile.new()
	audio_cfg.load(AUDIO_PATH)
	pending_audio.clear()
	for key in ["master", "combat", "magic", "ui", "ambience", "voice", "narrative", "music"]:
		pending_audio[key] = clampf(float(audio_cfg.get_value("volume", key, preload("res://exo_audio.gd").DEFAULT_GROUPS[key])), 0.0, 1.0)
	_show_panel("CONFIGURAÇÕES", "As mesmas opções de vídeo, áudio e interface usadas durante a jornada.")
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	card_column.add_child(tabs)
	for tab in [{"id":"video","name":"VÍDEO"},{"id":"audio","name":"SOM"},{"id":"interface","name":"INTERFACE"},{"id":"controls","name":"CONTROLES"}]:
		var b := _action_button(str(tab.name), _switch_settings_tab.bind(str(tab.id)), str(tab.id) == settings_tab)
		b.custom_minimum_size.x = 0
		if get_viewport_rect().size.x < 700: b.add_theme_font_size_override("font_size", 13)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(b)
	settings_scroll = ScrollContainer.new()
	settings_scroll.custom_minimum_size.y = minf(320.0, maxf(80.0, get_viewport_rect().size.y - 250.0))
	settings_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_column.add_child(settings_scroll)
	_render_settings_tab()
	_footer_with_cancel(_apply_settings, "Aplicar")
	_layout()

func _switch_settings_tab(tab: String) -> void:
	_capture_visible_settings()
	settings_tab = tab
	_render_settings_tab()

func _option_widget(parent: VBoxContainer, label_text: String, choices: Array, selected: int) -> OptionButton:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var label := _make_label(label_text, 16)
	label.custom_minimum_size.x = minf(285.0, maxf(100.0, get_viewport_rect().size.x * .31))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var option := OptionButton.new()
	option.custom_minimum_size = Vector2(minf(220.0, maxf(125.0, get_viewport_rect().size.x * .29)), 37)
	for choice in choices:
		option.add_item(str(choice))
	option.select(clampi(selected, 0, choices.size() - 1))
	option.add_theme_stylebox_override("normal", _make_style(Color("30231a"), Color("a7763e")))
	option.add_theme_color_override("font_color", Color("f5dca9"))
	row.add_child(option)
	return option

func _render_settings_tab() -> void:
	for child in settings_scroll.get_children():
		settings_scroll.remove_child(child)
		child.queue_free()
	option_controls.clear()
	audio_controls.clear()
	hud_controls.clear()
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 9)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_scroll.add_child(content)
	match settings_tab:
		"video":
			graphics_preset = _option_widget(content, "Perfil visual", Spec.PRESET_NAMES, int(pending_visual.preset))
			graphics_preset.item_selected.connect(_select_preset)
			full_screen_toggle = CheckButton.new()
			full_screen_toggle.text = "Tela cheia exclusiva"
			full_screen_toggle.button_pressed = int(pending_visual.window_mode) == 1
			full_screen_toggle.toggled.connect(func(value: bool): pending_visual.window_mode = 1 if value else 0; if option_controls.has("window_mode"): option_controls.window_mode.select(int(pending_visual.window_mode)))
			content.add_child(full_screen_toggle)
			for section in ["Tela", "Iluminação", "Ambiente", "Efeitos", "Texturas"]:
				content.add_child(_make_label(section.to_upper(), 19, Color("efbe77")))
				for key in Spec.OPTIONS:
					var definition: Dictionary = Spec.OPTIONS[key]
					if str(definition.section) != section:
						continue
					var option := _option_widget(content, str(definition.label), definition.choices, int(pending_visual[key]))
					option.disabled = not Spec.available(str(key))
					if option.disabled:
						option.tooltip_text = "Esta opção requer Forward+. O jogo usa Compatibility."
					option_controls[key] = option
					option.item_selected.connect(_custom_option_changed.bind(str(key)))
			content.add_child(_make_label("Opções indisponíveis neste renderizador ficam desativadas.", 13))
		"audio":
			for key in ["master", "combat", "magic", "ui", "ambience", "voice", "narrative", "music"]:
				content.add_child(_make_label({"master":"Volume geral","combat":"Golpes e impactos","magic":"Técnicas e qi","ui":"Interface","ambience":"Ambiente e passos","voice":"Vozes","narrative":"Narrativa","music":"Música"}[key], 16))
				var slider := HSlider.new()
				slider.custom_minimum_size = Vector2(minf(430.0, maxf(175.0, get_viewport_rect().size.x - 110.0)), 26)
				slider.min_value = 0
				slider.max_value = 1
				slider.step = .05
				slider.value = float(pending_audio[key])
				content.add_child(slider)
				audio_controls[key] = slider
				if key == "master": volume_slider = slider
		"interface":
			for key in ["style", "theme", "anchor"]:
				var choices: Array = {"style":preload("res://exo_hud.gd").STYLES,"theme":preload("res://exo_hud.gd").THEMES,"anchor":preload("res://exo_hud.gd").ANCHORS}[key]
				hud_controls[key] = _option_widget(content, {"style":"Estilo HUD","theme":"Paleta HUD","anchor":"Posição HUD"}[key], choices, int(pending_hud[key]))
			for key in ["scale", "opacity"]:
				content.add_child(_make_label("Escala do HUD" if key == "scale" else "Opacidade do HUD", 16))
				var slider := HSlider.new()
				slider.min_value = .6 if key == "scale" else .2
				slider.max_value = 1.5 if key == "scale" else 1.0
				slider.step = .05
				slider.value = float(pending_hud[key])
				content.add_child(slider)
				hud_controls[key] = slider
			for key in ["portrait", "values", "compact", "target", "notices"]:
				var check := CheckButton.new()
				check.text = {"portrait":"Retrato","values":"Valores numéricos","compact":"HUD compacto","target":"Alvo","notices":"Avisos"}[key]
				check.button_pressed = bool(pending_hud[key])
				content.add_child(check)
				hud_controls[key] = check
			for key in ["ornaments", "paper", "preview_motion", "camera_shake"]:
				var check := CheckButton.new()
				check.text = {"ornaments":"Ornamentos","paper":"Pergaminho","preview_motion":"Movimento na prévia","camera_shake":"Tremor de câmera"}[key]
				check.button_pressed = bool(pending_interface[key])
				content.add_child(check)
				hud_controls[key] = check
		"controls":
			content.add_child(_make_label("WASD mover • Mouse orientar • Clique atacar • F esquivar • E interagir • 1/2/3 técnicas • P central • I inventário • Tab mapa • Esc pausa", 18))

func _select_preset(index: int) -> void:
	pending_visual.preset = index
	if index < 5:
		pending_visual.merge(Spec.PRESETS[index], true)
		for key in option_controls:
			option_controls[key].select(int(pending_visual[key]))

func _custom_option_changed(index: int, key: String) -> void:
	pending_visual[key] = index
	pending_visual.preset = 5
	graphics_preset.select(5)
	if key == "window_mode": full_screen_toggle.set_pressed_no_signal(index == 1)

func _capture_visible_settings() -> void:
	if settings_tab == "video":
		if is_instance_valid(graphics_preset): pending_visual.preset = graphics_preset.selected
		for key in option_controls: pending_visual[key] = option_controls[key].selected
		if is_instance_valid(full_screen_toggle) and full_screen_toggle.button_pressed: pending_visual.window_mode = 1
	elif settings_tab == "audio":
		for key in audio_controls: pending_audio[key] = audio_controls[key].value
	elif settings_tab == "interface":
		for key in hud_controls:
			var control: Control = hud_controls[key]
			var value: Variant = control.selected if control is OptionButton else control.value if control is HSlider else control.button_pressed
			if pending_hud.has(key): pending_hud[key] = value
			else: pending_interface[key] = value

func _apply_settings() -> void:
	_capture_visible_settings()
	var audio_cfg := ConfigFile.new()
	audio_cfg.load(AUDIO_PATH)
	for key in pending_audio: audio_cfg.set_value("volume", key, pending_audio[key])
	if audio_cfg.save(AUDIO_PATH) != OK:
		_show_panel("ERRO AO SALVAR", "Não foi possível salvar o áudio.")
		card_column.add_child(_action_button("Voltar", _close_panel))
		return
	var gfx_cfg := ConfigFile.new()
	gfx_cfg.load(GRAPHICS_PATH)
	gfx_cfg.set_value("exo_visual", "schema", Spec.VERSION)
	gfx_cfg.set_value("exo_visual", "preset", pending_visual.preset)
	for key in Spec.OPTIONS: gfx_cfg.set_value("exo_visual", key, pending_visual[key])
	for key in pending_hud: gfx_cfg.set_value("hud", key, pending_hud[key])
	for key in pending_interface:
		gfx_cfg.set_value("display" if key == "camera_shake" else "interface", key, pending_interface[key])
	if gfx_cfg.save(GRAPHICS_PATH) != OK:
		_show_panel("ERRO AO SALVAR", "Não foi possível salvar as configurações gráficas.")
		card_column.add_child(_action_button("Voltar", _close_panel))
		return
	_apply_saved_display()
	_close_panel()

func _begin_game(mode: String) -> void:
	if action_busy:
		return
	action_busy = true
	pending_mode = mode
	modal.visible = false
	for button in buttons: button.visible = false
	loading_panel.visible = true
	loading_bar.value = 0
	loading_status.text = "Lendo a cena do mundo..."
	_layout()
	var err: Error = ResourceLoader.load_threaded_request(GAME_SCENE)
	if err != OK:
		_loading_failed("Não foi possível ler a cena. Código Godot: %d" % err)
	else:
		loading_request_started = true
		set_process(true)

func _process(_delta: float) -> void:
	if not loading_request_started:
		return
	var progress: Array = []
	var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(GAME_SCENE, progress)
	if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		_loading_failed("Falha na leitura dos recursos do mundo.")
		return
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		loading_bar.value = clampf(float(progress[0]) * 35.0, 0.0, 35.0) if not progress.is_empty() else 0.0
		return
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		loading_request_started = false
		loading_bar.value = 35
		loading_status.text = "Cena pronta. Iniciando serviços e região..."
		call_deferred("_enter_loaded_game")

func _enter_loaded_game() -> void:
	var scene: PackedScene = ResourceLoader.load_threaded_get(GAME_SCENE) as PackedScene
	if scene == null:
		_loading_failed("A cena carregada não é válida.")
		return
	MenuBoot.choose(pending_mode)
	# The destination owns the remaining milestones, including region restoration.
	var err: Error = get_tree().change_scene_to_packed(scene)
	if err != OK:
		MenuBoot.choose("continue")
		_loading_failed("Não foi possível abrir o jogo. Código Godot: %d" % err)

func _loading_failed(reason: String) -> void:
	loading_request_started = false
	action_busy = false
	loading_panel.visible = false
	for button in buttons: button.visible = true
	current_panel = "error"
	_show_panel("ERRO AO INICIAR", reason)
	card_column.add_child(_action_button("Voltar", _close_panel))
