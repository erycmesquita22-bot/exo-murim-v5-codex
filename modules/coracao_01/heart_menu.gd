extends Control
## Coração 01: navigation and persistent session services over the existing V11 scene.
const LEGACY_SAVE_PATH := "user://exo_coracao_01.json"
var save_path := LEGACY_SAVE_PATH
var active_slot := 0
const BACKDROP := preload("res://modules/coracao_01/concept_menu_reference.jpg")
var host: Node3D
var data: Dictionary = {}
var page := "home"
var has_session := false
var was_enemy_dead := false
var known_evades := 0
var menu_layer: Control
var hotspots: Control
var shade: ColorRect
var card: PanelContainer
var continue_button: Button
var continue_cover: ColorRect
var hp_bar: ProgressBar
var qi_bar: ProgressBar
var page_title: Label
var body: Label
var buttons: VBoxContainer
var footer: Label
var status: Label
var close_button: Button
var panel: PanelContainer
var ambience: TextureRect
var panel_style: StyleBoxFlat
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_load()
	_build()
	_render()
func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		resume_or_main()
		get_viewport().set_input_as_handled()
func set_slot(slot: int) -> void:
	active_slot = clampi(slot,1,3)
	save_path = "user://exo_character_slot_%d.json" % active_slot
	if active_slot == 1 and not FileAccess.file_exists(save_path) and FileAccess.file_exists(LEGACY_SAVE_PATH):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(LEGACY_SAVE_PATH),ProjectSettings.globalize_path(save_path))
	_load()
func _load() -> void:
	data = {"version":1,"wins":0,"evades":0,"coins":0,"visits":0,"arrival":false,"event_wins":0,"event_active":false,"sect_points":0,"started":false,"snapshot":{},"character":{}}
	if not FileAccess.file_exists(save_path): return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if parsed is Dictionary and parsed.get("version",0) == 1:
		for key in data.keys():
			if parsed.has(key): data[key] = parsed[key]
func _save() -> void:
	var file := FileAccess.open(save_path,FileAccess.WRITE)
	if file == null:
		push_error("HEART_SAVE_FAILED "+str(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(data,"\t"))
	file.close()
func _build() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	color_backdrop()
	var design := Control.new()
	design.name = "ReferenceComposition1280x720"
	design.position = Vector2(0,40)
	design.size = Vector2(1280,720)
	add_child(design)
	ambience = TextureRect.new()
	ambience.name = "UserApprovedMenuConcept"
	ambience.texture = BACKDROP
	ambience.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ambience.stretch_mode = TextureRect.STRETCH_SCALE
	ambience.size = Vector2(1280,720)
	ambience.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design.add_child(ambience)
	build_live_card(design)
	hotspots = Control.new()
	hotspots.name = "InteractiveReferenceButtons"
	hotspots.size = Vector2(1280,720)
	design.add_child(hotspots)
	_hotspot("COMEÇAR",Rect2(513,280,247,98),_new_game)
	continue_button = _hotspot("CONTINUAR",Rect2(557,377,170,51),_continue)
	_hotspot("MAPA DO MUNDO",Rect2(106,216,254,64),func():_go("map"))
	_hotspot("CONQUISTAS",Rect2(106,284,254,67),func():_go("achievements"))
	_hotspot("LOJA",Rect2(106,354,254,67),func():_go("shop"))
	_hotspot("SAIR",Rect2(106,423,254,68),func():get_tree().quit())
	_hotspot("GERENCIAR SEITA",Rect2(565,65,139,119),func():_go("sect"))
	_hotspot("MAPA DO MUNDO",Rect2(407,159,126,130),func():_go("map"))
	_hotspot("TREINAMENTO DE TÉCNICAS",Rect2(736,159,125,131),func():_go("training"))
	_hotspot("LOJA",Rect2(403,361,130,137),func():_go("shop"))
	_hotspot("CONQUISTAS & DESAFIOS",Rect2(738,360,126,138),func():_go("achievements"))
	_hotspot("OPÇÕES",Rect2(565,457,140,126),func():_go("options"))
	_hotspot("EVENTOS",Rect2(1047,541,212,63),func():_go("events"))
	_hotspot("SEITA",Rect2(1047,603,212,64),func():_go("sect"))
	continue_cover = ColorRect.new()
	continue_cover.color = Color("08131b99")
	continue_cover.position = Vector2(555,383)
	continue_cover.size = Vector2(176,45)
	continue_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design.add_child(continue_cover)
	shade = ColorRect.new()
	shade.color = Color("06111bdc")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	build_detail_panel()
func color_backdrop() -> void:
	var bars := ColorRect.new()
	bars.color = Color("100c0c")
	bars.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bars)
func _hotspot(title: String, rect: Rect2, callback: Callable) -> Button:
	var button := Button.new()
	button.text = ""
	button.tooltip_text = title
	button.name = title.replace(" ","_").replace("&", "E")
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
	var lit := StyleBoxFlat.new()
	lit.bg_color = Color("55c8e03c")
	lit.border_color = Color("f6d9a5")
	lit.set_border_width_all(3)
	lit.set_corner_radius_all(15)
	button.add_theme_stylebox_override("hover",lit)
	button.add_theme_stylebox_override("pressed",lit)
	button.add_theme_stylebox_override("focus",lit)
	button.pressed.connect(callback)
	hotspots.add_child(button)
	return button
func build_live_card(parent: Control) -> void:
	card = PanelContainer.new()
	card.name = "RealPlayerStatus"
	card.position = Vector2(66,518)
	card.size = Vector2(407,163)
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color("e0c89f")
	paper.border_color = Color("80572f")
	paper.set_border_width_all(4)
	paper.set_corner_radius_all(7)
	paper.set_content_margin_all(16)
	card.add_theme_stylebox_override("panel",paper)
	parent.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",4)
	card.add_child(column)
	var title := _label("VIAJANTE DE HANEUL",20,Color("39271e"))
	title.add_theme_constant_override("shadow_offset_x",0)
	title.add_theme_constant_override("shadow_offset_y",0)
	column.add_child(title)
	status = _label("",16,Color("382c25"))
	status.add_theme_constant_override("shadow_offset_x",0)
	status.add_theme_constant_override("shadow_offset_y",0)
	column.add_child(status)
	hp_bar = _meter(Color("9e302c"))
	qi_bar = _meter(Color("207793"))
	column.add_child(hp_bar)
	column.add_child(qi_bar)
func _meter(fill_color: Color) -> ProgressBar:
	var meter := ProgressBar.new()
	meter.show_percentage = false
	meter.custom_minimum_size.y = 12
	var under := StyleBoxFlat.new()
	under.bg_color = Color("6b5846")
	under.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(3)
	meter.add_theme_stylebox_override("background",under)
	meter.add_theme_stylebox_override("fill",fill)
	return meter
func build_detail_panel() -> void:
	panel = PanelContainer.new()
	panel.position = Vector2(180,46)
	panel.size = Vector2(920,708)
	panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color("0c1e2bf8")
	panel_style.border_color = Color("caa66e")
	panel_style.set_border_width_all(4)
	panel_style.set_corner_radius_all(19)
	panel_style.set_content_margin_all(25)
	panel.add_theme_stylebox_override("panel",panel_style)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",13)
	panel.add_child(column)
	var crest := _label("✦   EXO  ·  LENDAS DO MURIM   ✦",18,Color("e5bd7a"))
	crest.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(crest)
	var back := _button("←  VOLTAR AO MENU")
	back.custom_minimum_size.y = 34
	back.pressed.connect(func():_go("home"))
	column.add_child(back)
	page_title = _label("",36,Color("f8e4b1"))
	column.add_child(page_title)
	var rule := ColorRect.new()
	rule.color = Color("977b55")
	rule.custom_minimum_size.y = 2
	column.add_child(rule)
	body = _label("",20,Color("f0e6d7"))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	buttons = VBoxContainer.new()
	buttons.add_theme_constant_override("separation",8)
	column.add_child(buttons)
	footer = _label("",14,Color("a7c3ce"))
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(footer)
func _label(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	label.add_theme_color_override("font_shadow_color",Color("02070a"))
	label.add_theme_constant_override("shadow_offset_x",2)
	label.add_theme_constant_override("shadow_offset_y",2)
	return label
func _button(value: String) -> Button:
	var button := Button.new()
	button.text = value
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size.y = 47
	button.add_theme_font_size_override("font_size",19)
	button.add_theme_color_override("font_color",Color("f4e4bc"))
	button.add_theme_color_override("font_hover_color",Color("ffffff"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("123144f3")
	normal.border_color = Color("b8965d")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(9)
	normal.set_content_margin_all(8)
	var hover := normal.duplicate()
	hover.bg_color = Color("1c6c8e")
	hover.border_color = Color("f5d18d")
	button.add_theme_stylebox_override("normal",normal)
	button.add_theme_stylebox_override("hover",hover)
	button.add_theme_stylebox_override("pressed",hover)
	return button
func _action(title: String, callback: Callable) -> void:
	var button := _button(title)
	button.pressed.connect(callback)
	buttons.add_child(button)
func _go(target: String) -> void:
	page = target
	_render()
func _render() -> void:
	if not is_instance_valid(buttons): return
	for child in buttons.get_children(): child.queue_free()
	status.text = "VIDA %d/%d  ·  QI %d/%d  ·  SELOS %d" % [host.health.hp,host.health.maximum,int(host.skills.qi),int(host.skills.maximum_qi),int(data.coins)]
	hp_bar.max_value = host.health.maximum
	hp_bar.value = host.health.hp
	qi_bar.max_value = host.skills.maximum_qi
	qi_bar.value = host.skills.qi
	var home := page == "home"
	panel.visible = not home
	shade.visible = not home
	hotspots.visible = home
	card.visible = home
	continue_button.disabled = not bool(data.started)
	continue_cover.visible = not bool(data.started) and home
	match page:
		"home":
			page_title.text = "O CAMINHO COMEÇA AQUI"
			body.text = "Haneul é o seu ponto de partida. Atravesse a vila, treine com o rival e siga pela Estrada do Vau. O seu caminho fica salvo neste dispositivo."
			_action("COMEÇAR NOVA JORNADA",_new_game)
			if bool(data.started): _action("CONTINUAR",_continue)
			if has_session: _action("VOLTAR AO JOGO",_resume)
			_action("SAIR",func():get_tree().quit())
			footer.text = "ESC abre e fecha o menu durante a jornada."
		"map":
			page_title.text = "MAPA DO MUNDO"
			var region := "Estrada do Vau" if host.s07_active else ("Interior de Haneul" if host.active_room_id != "" else "Vila de Haneul")
			body.text = "VOCÊ ESTÁ EM: %s\n\nHANEUL  →  ESTRADA DO VAU  →  ARREDORES DE YUNSEONG\n\nA Estrada do Vau está aberta pelo portão norte. Yunseong tem somente o marco de chegada nesta versão. Visitas à estrada: %d." % [region,int(data.visits)]
			_action("RETOMAR E EXPLORAR",_continue)
			footer.text = "No portão norte da vila, pressione F. Use V para viagem e F no fim da estrada."
		"training":
			page_title.text = "TREINAMENTO DE TÉCNICAS"
			var lines := "O catálogo ativo tem %d artes. Escolha a escola e pratique contra o rival da vila.\n\n" % host.skills.catalog.size()
			for i in host.skills.catalog.size():
				var art: Resource = host.skills.catalog[i]
				lines += "%d  %s  ·  %s  ·  %d Qi\n" % [i+1,art.display_name,art.school,int(art.qi_cost)]
			body.text = lines
			_action("TREINAR NA VILA",_practice)
			footer.text = "Durante o jogo: K abre o catálogo; teclas 1–6 executam as artes. M compara as variantes de maestria disponíveis."
		"sect":
			page_title.text = "GERENCIAR SEITA"
			var rank := "Discípulo iniciante" if int(data.sect_points) < 3 else ("Discípulo dedicado" if int(data.sect_points) < 10 else "Discípulo veterano")
			body.text = "FAMÍLIA  ·  %s\nREPUTAÇÃO LOCAL  ·  %d\nPATENTE  ·  %s\n\nEscolha a família representada nos portões de Haneul. Contribua 10 selos para registrar um ponto de reputação. Os interiores usarão a variante familiar escolhida na próxima entrada." % [host.active_family,int(data.sect_points),rank]
			_action("AFILIAR-SE À FAMÍLIA WONG",func():_choose_family("WONG"))
			_action("AFILIAR-SE À FAMÍLIA WUDONG",func():_choose_family("WUDONG"))
			_action("CONTRIBUIR 10 SELOS",_donate)
			footer.text = "Afiliação e reputação são locais. Membros e política da seita aguardam módulo próprio."
		"achievements":
			page_title.text = "CONQUISTAS & DESAFIOS"
			body.text = "PRIMEIRO DUELO  %s\nTRÊS VITÓRIAS  %s\nPASSO FANTASMA  %s\nROTA DO VAU  %s\nLIMIAR DE YUNSEONG  %s" % [_mark(int(data.wins)>=1),_mark(int(data.wins)>=3),_mark(int(data.evades)>=1),_mark(int(data.visits)>=1),_mark(bool(data.arrival))]
			_action("VOLTAR AOS DESAFIOS",func():_go("events"))
			footer.text = "Evasões %d  ·  Vitórias %d. Progresso salvo localmente." % [int(data.evades),int(data.wins)]
		"shop":
			page_title.text = "LOJA DA VILA"
			body.text = "SELOS DISPONÍVEIS  ·  %d\n\nUnguento de batalha  ·  20 selos  ·  recupera até 45 de vida.\nMeditação guiada  ·  15 selos  ·  recupera até 35 de Qi.\n\nCada vitória sobre o rival concede 25 selos. Itens são aplicados ao comprar; inventário persistente virá em outro módulo." % int(data.coins)
			_action("COMPRAR UNGUENTO  ·  20",func():_purchase("hp"))
			_action("COMPRAR MEDITAÇÃO  ·  15",func():_purchase("qi"))
			footer.text = "Loja de testes integrada aos atributos reais do personagem."
		"events":
			page_title.text = "EVENTOS"
			body.text = "DESAFIO DE ESPADAS DE HANEUL\n\nVença o rival numa batalha de treino. Ao ativar o evento, o duelo é reiniciado na vila. A vitória concede os 25 selos normais e 15 selos extras do evento.\n\nEventos concluídos: %d" % int(data.event_wins)
			_action("INICIAR DESAFIO",_start_event)
			footer.text = "O evento usa a IA e as áreas de ataque já implementadas."
		"options":
			page_title.text = "OPÇÕES"
			body.text = "CLIMA ATUAL  ·  %s\nRIVAL DE TREINO  ·  %s\nCONTROLES  ·  WASD mover, Shift correr, V viajar, Espaço pular, clique atacar, E sacar, Q esquivar, F interagir/defender, Tab focar, K técnicas.\n\nESC abre este menu." % [host.climate.weather_name,"ativo" if host.enable_training_rival else "inativo"]
			_action("ALTERAR CLIMA",_change_weather)
			_action("ATIVAR/DESATIVAR RIVAL",_toggle_rival)
			_action("SALVAR AGORA",_snapshot)
			footer.text = "F7 e F9 também funcionam durante o jogo."
func _mark(value: bool) -> String: return "CONCLUÍDO" if value else "EM ABERTO"
func _set_open(value: bool) -> void:
	visible = value
	host.hud.get_parent().visible = not value
	get_tree().paused = value
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED
	if value: _render()
func open_main() -> void:
	page = "home"
	_set_open(true)
func open_pause() -> void:
	_snapshot()
	page = "home"
	_set_open(true)
func resume_or_main() -> void:
	if has_session: _resume()
	else: _go("home")
func _resume() -> void:
	has_session = true
	_set_open(false)
func _new_game() -> void:
	if host.s07_active: host._s07_commit_return()
	if host.active_room_id != "": host._commit_exit_room()
	host.reset_duel()
	if host.has_method("reset_village_npcs"): host.reset_village_npcs()
	if host.has_method("reset_cultivation"): host.reset_cultivation()
	host.actor.position = Vector3(-12.0,3.0,-65.0)
	host.pivot.position = host.actor.position+Vector3(0,1.65,0)
	host.skills.qi = host.skills.maximum_qi
	for key in ["wins","evades","coins","visits","event_wins","sect_points"]: data[key] = 0
	for key in ["arrival","event_active"]: data[key] = false
	data.started = true
	host.s07_reached_yunseong = false
	host.enable_training_rival = true
	host._sync_regions(true)
	was_enemy_dead = false;known_evades = host.health.evade_count
	has_session = true
	_snapshot()
	_resume()
func _continue() -> void:
	if not bool(data.started):
		_new_game()
		return
	if not has_session:
		_restore_snapshot()
		has_session = true
	_resume()
func _snapshot() -> void:
	if not bool(data.started): return
	var region := "road" if host.s07_active else ("room" if host.active_room_id != "" else "village")
	data.snapshot = {"region":region,"room":host.active_room_id,"pos":[host.actor.position.x,host.actor.position.y,host.actor.position.z],"hp":host.health.hp,"qi":host.skills.qi,"weather":host.climate.weather_name,"rival":host.enable_training_rival,"family":host.active_family,"arrival":host.s07_reached_yunseong}
	_save()
func _restore_snapshot() -> void:
	var state: Dictionary = data.get("snapshot",{})
	if state.is_empty(): return
	var region: String = str(state.get("region","village"))
	_set_family(str(state.get("family",host.active_family)))
	if region == "road": host._s07_commit_enter()
	elif region == "room": host._commit_enter_room(str(state.get("room","")))
	var pos: Array = state.get("pos",[])
	if pos.size() == 3:
		var point := Vector3(float(pos[0]),float(pos[1]),float(pos[2]))
		if _valid_position(region,point):
			host.actor.position = point+Vector3(0,.35,0)
			host.pivot.position = host.actor.position+Vector3(0,1.65,0)
	host.health.hp = clampi(int(state.get("hp",host.health.maximum)),1,host.health.maximum)
	host.skills.qi = clampf(float(state.get("qi",100)),0,host.skills.maximum_qi)
	host.s07_reached_yunseong = bool(state.get("arrival",false))
	host.enable_training_rival = bool(state.get("rival",true))
	var weather: String = str(state.get("weather","clear"))
	if weather in host.presets: host.climate.set_weather(weather)
	host._sync_regions(true)
func _valid_position(region: String, point: Vector3) -> bool:
	if not point.is_finite(): return false
	if region == "road": return host.s07_active and point.distance_to(host.S07_ROUTE_ORIGIN) < 1000
	if region == "room": return host.active_room_id != "" and point.distance_to(host.ISOLATED_ORIGIN) < 100
	return point.distance_to(Vector3(-12,0,-65)) < 500
func _set_family(which: String) -> void:
	if which not in ["WONG","WUDONG"]: return
	host.active_family = which
	host.wong_signs.visible = which == "WONG" and not host.s07_active and host.active_room_id == ""
	host.wudong_signs.visible = which == "WUDONG" and not host.s07_active and host.active_room_id == ""
func _choose_family(which: String) -> void:
	if host.s07_active or host.active_room_id != "":
		footer.text = "Escolha sua família quando estiver na vila."
		return
	_set_family(which)
	_snapshot();_render()
func _donate() -> void:
	if int(data.coins) < 10:
		footer.text = "Você precisa de 10 selos para contribuir."
		return
	data.coins = int(data.coins)-10
	data.sect_points = int(data.sect_points)+1
	_snapshot();_render()
func _practice() -> void:
	if not bool(data.started): _new_game()
	else:
		if host.s07_active: host._s07_commit_return()
		if host.active_room_id != "": host._commit_exit_room()
		host.enable_training_rival = true
		host._sync_regions(true)
		_resume()
func _start_event() -> void:
	if not bool(data.started): _new_game()
	if host.s07_active: host._s07_commit_return()
	if host.active_room_id != "": host._commit_exit_room()
	host.reset_duel()
	host.enable_training_rival = true
	host._sync_regions(true)
	data.event_active = true
	_snapshot()
	_resume()
func _purchase(which: String) -> void:
	var cost := 20 if which == "hp" else 15
	if int(data.coins) < cost:
		footer.text = "Selos insuficientes. Vença um duelo para receber 25."
		return
	if which == "hp":
		if host.health.hp >= host.health.maximum:
			footer.text = "Sua vida já está completa."
			return
		host.health.hp = mini(host.health.maximum,host.health.hp+45)
	else:
		if host.skills.qi >= host.skills.maximum_qi:
			footer.text = "Seu Qi já está completo."
			return
		host.skills.qi = minf(host.skills.maximum_qi,host.skills.qi+35)
	data.coins = int(data.coins)-cost
	_snapshot()
	_render()
func _change_weather() -> void:
	host.preset_index = (host.preset_index+1)%host.presets.size()
	host.climate.set_weather(host.presets[host.preset_index])
	_snapshot();_render()
func _toggle_rival() -> void:
	host.enable_training_rival = not host.enable_training_rival
	host._sync_regions(true)
	_snapshot();_render()
func observe() -> void:
	if not bool(data.started): return
	var dead: bool = host.enemy.vitals.dead
	if dead and not was_enemy_dead and host.enable_training_rival and not host._remote():
		data.wins = int(data.wins)+1
		data.coins = int(data.coins)+25
		if bool(data.event_active):
			data.coins = int(data.coins)+15
			data.event_wins = int(data.event_wins)+1
			data.event_active = false
		_snapshot()
	was_enemy_dead = dead
	var evades: int = host.health.evade_count
	if evades > known_evades:
		data.evades = int(data.evades)+(evades-known_evades)
		known_evades = evades
		_snapshot()
	if host.s07_events.size() > 0:
		for event in host.s07_events:
			if not event.has("heart_recorded"):
				if event.get("event","") == "ENTER_ROAD": data.visits = int(data.visits)+1
				if event.get("event","") == "ARRIVAL_GATE": data.arrival = true
				event.heart_recorded = true
				_snapshot()
