extends Control
## Entry flow: title > play > slots > creator > Haneul. Runs over the paused world.
const ART := preload("res://modules/title_flow/haneul_reference_clean.png")
const ATMOSPHERE := preload("res://modules/title_flow/atmosphere_overlay.png")
const INK_FONT := preload("res://modules/title_flow/fonts/PermanentMarker-Regular.ttf")
const BRUSH_FONT := preload("res://modules/title_flow/fonts/Kalam-Bold.ttf")
const SCRIPT_FONT := preload("res://modules/title_flow/fonts/KaushanScript-Regular.ttf")
const SWORD_ICON := preload("res://modules/title_flow/icons/sword.png")
const GEAR_ICON := preload("res://modules/title_flow/icons/gear.png")
const GATE_ICON := preload("res://modules/title_flow/icons/gate.png")
const WOOD_PANEL := preload("res://modules/title_flow/ui/wood_panel.png")
const PLAQUE_NORMAL := preload("res://modules/title_flow/ui/normal.png")
const PLAQUE_HOVER := preload("res://modules/title_flow/ui/hover.png")
const PLAQUE_PRESSED := preload("res://modules/title_flow/ui/pressed.png")
const PLAQUE_DISABLED := preload("res://modules/title_flow/ui/disabled.png")
const RIG := preload("res://modules/character_core_v3/assets/EXO_Character_Core01.glb")
const APPEARANCE := preload("res://modules/character_customization/appearance.gd")
const CONFIG := "user://exo_title_config_01.json"
var host: Node3D
var page := "title"
var mode := "new"
var selected_slot := 1
var profile: Dictionary = {}
var layout: VBoxContainer
var paper: NinePatchRect
var info: Label
var preview: Node3D
var name_input: LineEdit
var face_choice: OptionButton
var hair_choice: OptionButton
var cloth_choice: OptionButton
var body_choice: OptionButton
var status: Label
var volume := .8
func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter = Control.MOUSE_FILTER_STOP
 _load_config()
 var art := TextureRect.new()
 art.name = "HaneulReferenceVillage"
 art.texture = ART
 art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
 art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 art.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(art)
 var mood := TextureRect.new()
 mood.texture = ATMOSPHERE
 mood.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 mood.stretch_mode = TextureRect.STRETCH_SCALE
 mood.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mood.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(mood)
 paper = NinePatchRect.new()
 paper.texture = WOOD_PANEL
 paper.patch_margin_left = 53
 paper.patch_margin_top = 52
 paper.patch_margin_right = 53
 paper.patch_margin_bottom = 52
 paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(paper)
 layout = VBoxContainer.new()
 layout.add_theme_constant_override("separation",7)
 add_child(layout)
 _render()
func _process(_delta: float) -> void:
 if visible and host.heart_menu != null and host.heart_menu.has_session: visible = false
func _unhandled_input(event: InputEvent) -> void:
 if not visible: return
 if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
  if page == "title": return
  if page == "play": page = "title"
  elif page == "slots": page = "play"
  elif page == "creator" or page == "overwrite": page = "slots"
  else: page = "title"
  _render()
  get_viewport().set_input_as_handled()
func _floating(parent: Control, value: String, pos: Vector2, size: Vector2, font: Font, pts: int, fill: Color, outline := 5) -> Label:
 var label := Label.new()
 label.text = value
 label.position = pos
 label.size = size
 label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 label.add_theme_font_override("font",font)
 label.add_theme_font_size_override("font_size",pts)
 label.add_theme_color_override("font_color",fill)
 label.add_theme_color_override("font_outline_color",Color("180b0e"))
 label.add_theme_constant_override("outline_size",outline)
 label.add_theme_color_override("font_shadow_color",Color("190909aa"))
 label.add_theme_constant_override("shadow_offset_x",5)
 label.add_theme_constant_override("shadow_offset_y",6)
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(label)
 return label
func _draw_brand() -> void:
 var brand := Control.new()
 brand.set_meta("title_dynamic",true)
 brand.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(brand)
 if page == "creator":
  _floating(brand,"EXO  ·  LENDAS DE MURIM",Vector2(61,26),Vector2(660,67),INK_FONT,36,Color("fb9653"),5)
  return
 _floating(brand,"EXO",Vector2(175,36),Vector2(242,151),INK_FONT,118,Color("fa914d"),8)
 _floating(brand,"LENDAS DE MURIM",Vector2(458,58),Vector2(760,117),INK_FONT,70,Color("fa914d"),7)
 var byline := _floating(brand,"DAXZIN PRESENTS",Vector2(440,177),Vector2(400,52),BRUSH_FONT,30,Color("fff0ca"),4)
 byline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 byline.add_theme_color_override("font_color",Color("321919"))
 byline.add_theme_color_override("font_outline_color",Color("ffe4b4"))
 byline.add_theme_constant_override("outline_size",2)
func _label(value: String, size: int, color: Color = Color("f9e7c9")) -> Label:
 var label := Label.new()
 label.text = value
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.add_theme_font_override("font",BRUSH_FONT)
 label.add_theme_font_size_override("font_size",size)
 label.add_theme_color_override("font_color",color)
 label.add_theme_color_override("font_outline_color",Color("1b0b0e"))
 label.add_theme_constant_override("outline_size",3)
 label.add_theme_color_override("font_shadow_color",Color("14070a"))
 label.add_theme_constant_override("shadow_offset_x",3)
 label.add_theme_constant_override("shadow_offset_y",3)
 layout.add_child(label)
 return label
func _button(value: String, action: Callable, enabled := true) -> Button:
 var button := Button.new()
 button.name = value.replace(" ","_")
 button.disabled = not enabled
 button.custom_minimum_size = Vector2(495 if page=="title" else 465,68 if page == "title" else (43 if page == "creator" else 58))
 button.focus_mode = Control.FOCUS_ALL
 button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 if page == "title":
  var blank := StyleBoxEmpty.new()
  button.add_theme_stylebox_override("normal",blank)
  button.add_theme_stylebox_override("disabled",blank)
  var over := StyleBoxFlat.new()
  over.bg_color = Color("d9783340")
  over.border_color = Color("fbc07877")
  over.set_border_width_all(1)
  over.set_corner_radius_all(8)
  button.add_theme_stylebox_override("hover",over)
  button.add_theme_stylebox_override("pressed",over)
  button.add_theme_stylebox_override("focus",over)
 else:
  button.add_theme_stylebox_override("normal",_plaque(PLAQUE_NORMAL))
  button.add_theme_stylebox_override("hover",_plaque(PLAQUE_HOVER))
  button.add_theme_stylebox_override("pressed",_plaque(PLAQUE_PRESSED))
  button.add_theme_stylebox_override("disabled",_plaque(PLAQUE_DISABLED))
  button.add_theme_stylebox_override("focus",_plaque(PLAQUE_HOVER))
 button.pressed.connect(action)
 layout.add_child(button)
 var icon: Texture2D
 if page == "title":
  if value == "JOGAR": icon = SWORD_ICON
  elif value == "CONFIGURAÇÕES": icon = GEAR_ICON
  elif value == "SAIR": icon = GATE_ICON
 if icon != null:
  var mark := TextureRect.new()
  mark.texture = icon
  mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  mark.position = Vector2(3,4)
  mark.size = Vector2(66,58)
  mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
  button.add_child(mark)
 var ink := Label.new()
 ink.text = value
 ink.position = Vector2(79 if icon != null else (20 if page!="title" else 10),0)
 ink.size = Vector2(407 if icon != null else (475 if page=="title" else 440),button.custom_minimum_size.y)
 ink.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 ink.add_theme_font_override("font",BRUSH_FONT)
 ink.add_theme_font_size_override("font_size",46 if page=="title" else (23 if page=="creator" else 28))
 ink.add_theme_color_override("font_color",Color("fa874f") if page=="title" and enabled else (Color("ffc180") if enabled else Color("97867b")))
 ink.add_theme_color_override("font_outline_color",Color("16080c"))
 ink.add_theme_constant_override("outline_size",5 if page=="title" else 3)
 ink.add_theme_color_override("font_shadow_color",Color("180606aa"))
 ink.add_theme_constant_override("shadow_offset_x",3)
 ink.add_theme_constant_override("shadow_offset_y",4)
 ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
 button.add_child(ink)
 button.mouse_entered.connect(func(): if enabled: ink.add_theme_color_override("font_color",Color("ffe5a9")))
 button.button_down.connect(func(): ink.position.y = 2)
 button.button_up.connect(func(): ink.position.y = 0)
 button.mouse_exited.connect(func(): ink.add_theme_color_override("font_color",Color("fa874f") if page=="title" and enabled else (Color("ffc180") if enabled else Color("97867b"))))
 return button
func _plaque(texture: Texture2D) -> StyleBoxTexture:
 var style := StyleBoxTexture.new()
 style.texture = texture
 style.texture_margin_left = 30
 style.texture_margin_right = 30
 style.texture_margin_top = 26
 style.texture_margin_bottom = 26
 return style
func _field(control: Control) -> void:
 var normal := StyleBoxFlat.new()
 normal.bg_color = Color("1d1115f2")
 normal.border_color = Color("b97848")
 normal.border_width_left = 2
 normal.border_width_right = 3
 normal.border_width_top = 2
 normal.border_width_bottom = 4
 normal.corner_radius_top_left = 5
 normal.corner_radius_top_right = 5
 normal.corner_radius_bottom_left = 5
 normal.corner_radius_bottom_right = 5
 normal.content_margin_left = 14
 normal.content_margin_right = 9
 normal.content_margin_top = 2
 normal.content_margin_bottom = 2
 normal.shadow_color = Color("050304a9")
 normal.shadow_size = 5
 var focus := normal.duplicate()
 focus.border_color = Color("ffe1a0")
 focus.bg_color = Color("422322")
 for state in ["normal","hover","pressed","read_only"]:
  control.add_theme_stylebox_override(state,normal)
 control.add_theme_stylebox_override("focus",focus)
 control.add_theme_font_override("font",BRUSH_FONT)
 control.add_theme_font_size_override("font_size",21)
 control.add_theme_color_override("font_color",Color("ffe9c5"))
 control.add_theme_color_override("font_hover_color",Color("fff5da"))
func _clear() -> void:
 for child in get_children():
  if child.has_meta("creator_preview") or child.has_meta("title_dynamic"):
   remove_child(child)
   child.queue_free()
 for child in layout.get_children():
  layout.remove_child(child)
  child.queue_free()
 preview = null
func _render() -> void:
 _clear()
 paper.visible = page != "title"
 if page == "creator":
  paper.position = Vector2(42,76);paper.size = Vector2(586,700)
  layout.position = Vector2(90,126);layout.size = Vector2(490,630)
 elif page == "title":
  layout.position = Vector2(100,345);layout.size = Vector2(510,320)
 else:
  paper.position = Vector2(65,280)
  paper.size = Vector2(575,405 if page=="slots" else (350 if page=="overwrite" else 335))
  layout.position = Vector2(119,323);layout.size = Vector2(475,375)
 _draw_brand()
 match page:
  "title":
   _button("JOGAR",func(): page="play";_render())
   _button("CONFIGURAÇÕES",func(): page="settings";_render())
   _button("SAIR",func(): get_tree().quit())
  "play":
   _label("ESCOLHA SEU CAMINHO",27,Color("ffd4a0"))
   _button("INICIAR NOVO JOGO",func():mode="new";page="slots";_render())
   _button("CARREGAR JOGO",func():mode="load";page="slots";_render())
   _button("VOLTAR",func():page="title";_render())
  "slots":
   _label("SLOTS DE PERSONAGEM",27,Color("ffd4a0"))
   for i in range(1,4):
    var record := _slot_record(i)
    var filled: bool = bool(record.get("started",false))
    var character: Dictionary = record.get("character",{})
    var title := "SLOT %d  ·  %s" % [i,str(character.get("name","Viajante de Haneul")) if filled else "VAZIO"]
    _button(title,func():_slot_pressed(i,filled),mode=="new" or filled)
   _button("VOLTAR",func():page="play";_render())
  "overwrite":
   _label("SLOT %d JÁ POSSUI UMA JORNADA" % selected_slot,26,Color("ffcf9c"))
   _label("Criar outro personagem neste slot substituirá o progresso dele.",20)
   _button("CRIAR NESTE SLOT",func():_open_creator())
   _button("CANCELAR",func():page="slots";_render())
  "creator": _build_creator()
  "settings":
   _label("CONFIGURAÇÕES",27,Color("ffd4a0"))
   _button("TELA CHEIA: %s" % ("SIM" if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else "NÃO"),func():_toggle_fullscreen())
   _button("VOLUME: %d%%" % int(volume*100),func():_cycle_volume())
   _button("VOLTAR",func():page="title";_render())
func _slot_record(index: int) -> Dictionary:
 var path := "user://exo_character_slot_%d.json" % index
 if index == 1 and not FileAccess.file_exists(path): path = "user://exo_coracao_01.json"
 if not FileAccess.file_exists(path): return {}
 var loaded: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
 return loaded if loaded is Dictionary else {}
func _slot_pressed(index: int, filled: bool) -> void:
 selected_slot = index
 if mode == "load":
  if filled: _load_game()
  return
 if filled:
  page = "overwrite";_render()
 else: _open_creator()
func _open_creator() -> void:
 profile = {"name":"Viajante","face":"original","hair":{"style":"low_tail","color":"#423a3a"},"apparel":{"outer":"#748b94","tunic":"#b6bec0","sash":"#b58c63","trousers":"#485663"},"body_style":{"width":1.0,"height":1.0,"depth":1.0},"hide_embedded_sword":false}
 page="creator"
 _render()
func _choice(label: String, options: Array[String], current: int, changed: Callable) -> OptionButton:
 _label(label,17,Color("ffe1b5"))
 var choice := OptionButton.new()
 for item in options: choice.add_item(item)
 choice.selected = current
 choice.custom_minimum_size = Vector2(460,37)
 _field(choice)
 var popup := choice.get_popup()
 popup.add_theme_stylebox_override("panel",_plaque(PLAQUE_NORMAL))
 popup.add_theme_stylebox_override("hover",_plaque(PLAQUE_HOVER))
 popup.add_theme_font_override("font",BRUSH_FONT)
 popup.add_theme_font_size_override("font_size",19)
 popup.add_theme_color_override("font_color",Color("ffe9c5"))
 choice.item_selected.connect(changed)
 layout.add_child(choice)
 return choice
func _build_creator() -> void:
 _label("CRIAR PERSONAGEM  ·  SLOT %d" % selected_slot,23,Color("ffd4a0"))
 name_input = LineEdit.new()
 name_input.placeholder_text = "Nome do personagem"
 name_input.text = str(profile.name)
 name_input.max_length = 22
 name_input.custom_minimum_size.y = 38
 _field(name_input)
 layout.add_child(name_input)
 face_choice = _choice("ROSTO",["V4 original","Vigília do rio","Trabalhador do vau","Guardião do cais","Morador da praça","Casa de chá"],0,func(i):profile.face=["original","river_watch","river_worker","jetty_keeper","market_local","tea_attendant"][i];_refresh_preview())
 hair_choice = _choice("CABELO",["Preso baixo","Curto","Solto curto","Preso compacto","Preso alto"],0,func(i):profile.hair.style=["low_tail","cropped","loose_short","compact_tail","high_tail"][i];_refresh_preview())
 cloth_choice = _choice("ROUPA",["Azul do Vau","Areia do rio","Verde do cais","Terracota","Casa de chá"],0,func(i):_choose_cloth(i))
 body_choice = _choice("CORPO",["Equilibrado","Alto","Robusto","Esbelto"],0,func(i):_choose_body(i))
 var create := _button("COMEÇAR JORNADA",func():_commit_creation())
 create.custom_minimum_size.y = 42
 var back := _button("VOLTAR",func():page="slots";_render())
 back.custom_minimum_size.y = 38
 _build_preview()
func _build_preview() -> void:
 var frame := NinePatchRect.new()
 frame.position = Vector2(743,169)
 frame.size = Vector2(422,555)
 frame.texture = WOOD_PANEL
 frame.patch_margin_left = 53
 frame.patch_margin_right = 53
 frame.patch_margin_top = 52
 frame.patch_margin_bottom = 52
 frame.set_meta("creator_preview",true)
 add_child(frame)
 var box := SubViewportContainer.new()
 box.position = Vector2(31,32)
 box.size = Vector2(360,489)
 box.stretch = true
 frame.add_child(box)
 var viewport := SubViewport.new()
 viewport.size = Vector2i(360,489)
 viewport.own_world_3d = true
 viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 box.add_child(viewport)
 var world := Node3D.new();viewport.add_child(world)
 preview = RIG.instantiate();world.add_child(preview)
 preview.rotation.y = 0
 preview.position.y = -.1
 var camera := Camera3D.new();camera.position = Vector3(0,1.55,2.85);world.add_child(camera);camera.look_at(Vector3(0,1.3,0));camera.current = true
 var light := DirectionalLight3D.new();light.rotation_degrees = Vector3(-35,-25,0);light.light_energy = 1.8;world.add_child(light)
 var environment := WorldEnvironment.new();environment.environment = Environment.new();environment.environment.background_mode = Environment.BG_COLOR;environment.environment.background_color = Color("302527");environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color = Color("d5c6b5");environment.environment.ambient_light_energy = .8;world.add_child(environment)
 _refresh_preview()
func _refresh_preview() -> void:
 if preview != null: APPEARANCE.apply_to_visual(preview,profile)
func _choose_cloth(i: int) -> void:
 var roster: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://modules/village_npcs/roster.json"))
 profile.apparel = roster.npcs[i].apparel.duplicate(true)
 _refresh_preview()
func _choose_body(i: int) -> void:
 var choices := [Vector3.ONE,Vector3(.98,1.05,.98),Vector3(1.07,1.01,1.05),Vector3(.94,1.02,.95)]
 var v: Vector3 = choices[i]
 profile.body_style = {"width":v.x,"height":v.y,"depth":v.z}
 _refresh_preview()
func _commit_creation() -> void:
 var chosen := name_input.text.strip_edges()
 if chosen.is_empty(): chosen = "Viajante"
 profile.name = chosen
 host.heart_menu.set_slot(selected_slot)
 host.village_npcs.use_slot(selected_slot)
 host.cultivation_path.use_slot(selected_slot)
 host.wildlife.use_slot(selected_slot)
 host.heart_menu.data.character = profile.duplicate(true)
 host.heart_menu._new_game()
 _apply_player_profile()
 visible = false
func _load_game() -> void:
 host.heart_menu.set_slot(selected_slot)
 host.village_npcs.use_slot(selected_slot)
 host.cultivation_path.use_slot(selected_slot)
 host.wildlife.use_slot(selected_slot)
 host.heart_menu._continue()
 profile = host.heart_menu.data.get("character",{})
 if not profile.is_empty(): _apply_player_profile()
 visible = false
func _apply_player_profile() -> void:
 profile["hide_embedded_sword"] = false
 APPEARANCE.apply_to_visual(host.visual,profile)
 var size: Vector3 = APPEARANCE.proportions(profile)
 host.visual.position.y = -.125*size.y
 for child in host.actor.get_children():
  if child is CollisionShape3D and child.shape is CapsuleShape3D:
   child.shape.radius = .34*maxf(size.x,size.z)
   child.shape.height = 2.65*size.y
   child.position.y = 1.325*size.y
func _load_config() -> void:
 if not FileAccess.file_exists(CONFIG): return
 var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
 if saved is Dictionary: volume = clampf(float(saved.get("volume",.8)),0,1)
 AudioServer.set_bus_volume_db(0,linear_to_db(maxf(.001,volume)))
func _save_config() -> void:
 var file := FileAccess.open(CONFIG,FileAccess.WRITE)
 if file != null: file.store_string(JSON.stringify({"volume":volume}));file.close()
func _toggle_fullscreen() -> void:
 DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
 _render()
func _cycle_volume() -> void:
 volume = 0.0 if volume >= 1.0 else minf(1.0,volume+.25)
 AudioServer.set_bus_volume_db(0,linear_to_db(maxf(.001,volume)))
 _save_config();_render()
