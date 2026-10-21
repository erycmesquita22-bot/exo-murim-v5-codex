extends "res://ui/runtime_ui.gd"

const Catalog=preload("res://catalog.gd")
const ExoMenu=preload("res://exo_menu.gd")
var creation_tab:=0
var creation_randomized:=false
var procedural_seed:=""
var exo: Control
var exo_hud: Control
var murim_hud: Control
var preview_clock:=0.0

const Wardrobe=preload("res://wardrobe.gd")
const MapView=preload("res://map_view.gd")
var flow_screen: Control
var screen_column: VBoxContainer
var cinema: PanelContainer
var cinema_text: Label
var preview: Node3D
var preview_root: Control
var preview_view: SubViewport
var profile: Dictionary={"name":"Andarilho","race":0,"path":0,"robe":0,"hair":0,"skin":0,"style":0,"body":0,"outfit":0,"haircut":0,"eyes":0,"eye_color":0,"muscles":0,"mark":0}
var race_description: Label
var path_description: Label
var creator_notice: Label
var name_field: LineEdit
var location_label: Label
var location_panel: PanelContainer
var story_clock:=0.0
var story_ready:=0.0
var trajectory: MeshInstance3D
var confirming:=false
var flow_kind:=""

func _ready() -> void:
	super._ready()
	get_child(0).theme=preload("res://ui/skin.gd").make()
	flow_screen=Control.new()
	get_child(0).add_child(flow_screen)
	flow_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flow_screen.hide()
	cinema=PanelContainer.new()
	get_child(0).add_child(cinema)
	cinema.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	cinema.offset_top=-190
	cinema.offset_left=120
	cinema.offset_right=-120
	cinema.offset_bottom=-80
	cinema_text=label(cinema,"",26)
	cinema_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	cinema_text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	cinema.hide()
	exo=ExoMenu.new()
	exo.world=world
	get_child(0).add_child(exo)
	exo.hide()
	exo_hud=preload("res://exo_hud.gd").new()
	exo_hud.world=world
	exo_hud.ui=self
	get_child(0).add_child(exo_hud)
	exo_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	murim_hud=preload("res://exo_ui/hud_murim.gd").new()
	murim_hud.world=world
	murim_hud.ui=self
	get_child(0).add_child(murim_hud)
	murim_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	location_panel=PanelContainer.new()
	get_child(0).add_child(location_panel)
	location_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	location_panel.offset_left=365
	location_panel.offset_right=-365
	location_panel.offset_top=24
	location_panel.offset_bottom=65
	location_label=label(location_panel,"",20)
	location_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	location_panel.modulate.a=0
	location_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	trajectory=MeshInstance3D.new()
	world.add_child(trajectory)
	var mesh:=BoxMesh.new()
	mesh.size=Vector3(.035,.025,1)
	trajectory.mesh=mesh
	var ink:=StandardMaterial3D.new()
	ink.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.albedo_color=Color("adada0")
	trajectory.material_override=ink
	trajectory.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	trajectory.hide()
	# Keep pause compact and put discovery tools beside graphics.

func boot() -> void:
	if world.flow.phase=="adventure":
		world.flow.apply_character()
		world.set_paused(true)
	else:
		show_hero()

func clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func begin_screen(kind: String) -> VBoxContainer:
	flow_kind=kind
	world.set_paused(true)
	menu.hide()
	modal.hide()
	flow_screen.show()
	clear_children(flow_screen)
	preview=null
	preview_root=null
	preload("res://ui/skin.gd").backdrop(flow_screen,world)
	var margin:=MarginContainer.new()
	flow_screen.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,28)
	var panel:=PanelContainer.new();margin.add_child(panel)
	var col:=VBoxContainer.new();panel.add_child(col)
	col.add_theme_constant_override("separation",14)
	screen_column=col
	return col

func paragraph(parent: Node,text: String,size_value: int=17,width: float=480) -> Label:
	var item:=label(parent,text,size_value)
	item.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	item.custom_minimum_size.x=width
	return item

func title(parent: Node,text: String,size_value: int=30) -> Label:
	var item:=label(parent,text,size_value)
	item.modulate=Color("d8bd81")
	return item

func show_hero() -> void:preload("res://ui/prologue_picker.gd").new(self).show_hero()

func make_preview(parent: Node,value: Dictionary,dimensions: Vector2=Vector2(360,350)) -> void:
	var stage:=preload("res://ui/portrait_stage.gd").new(world,value,dimensions)
	parent.add_child(stage)
	preview_root=stage
	preview_view=stage.viewport
	preview=stage.rig

func show_story() -> void:
	begin_screen("story")
	clear_children(flow_screen)
	story_clock=0
	story_ready=.25
	var ink:=preload("res://manuscript.gd").new()
	ink.dark=true
	flow_screen.add_child(ink)
	ink.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center:=CenterContainer.new()
	flow_screen.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column:=VBoxContainer.new()
	center.add_child(column)
	column.custom_minimum_size=Vector2(860,330)
	column.add_theme_constant_override("separation",34)
	var page: int=world.flow.story_page
	var heading:=paragraph(column,world.flow.STORY[page][0],46,860)
	heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font",ThemeDB.fallback_font)
	heading.modulate=Color.WHITE
	var body:=paragraph(column,world.flow.STORY[page][1],34,860)
	body.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_override("font",ThemeDB.fallback_font)
	body.modulate=Color.WHITE
	column.modulate.a=0
	var fade:=create_tween()
	fade.tween_property(column,"modulate:a",1.0,.65)
	var instruction:=label(flow_screen,"Clique na tela ou pressione qualquer tecla para continuar",16)
	instruction.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	instruction.position=Vector2(590,670)
	instruction.size=Vector2(530,30)
	instruction.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	instruction.modulate=Color("b7b7bd")


func selector(parent: Node,text: String,items: Array,selected: int,callback: Callable) -> OptionButton:
	var row:=HBoxContainer.new()
	parent.add_child(row)
	var caption:=label(row,text,16)
	caption.custom_minimum_size.x=115
	var option:=OptionButton.new()
	row.add_child(option)
	option.custom_minimum_size=Vector2(290,34)
	option.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for item in items:
		option.add_item(item)
	option.select(selected)
	option.item_selected.connect(callback)
	return option

func show_creator() -> void:
	if not creation_randomized:
		creation_randomized=true
		var rng:=RandomNumberGenerator.new();rng.randomize()
		for key in ["robe", "hair", "skin", "style", "body", "outfit", "haircut", "eyes", "eye_color", "muscles", "mark"]:
			profile[key] = rng.randi_range(0, {"robe":5, "hair":5, "skin":5, "style":2, "body":6, "outfit":3, "haircut":3, "eyes":3, "eye_color":5, "muscles":2, "mark":2}[key])
	preload("res://ui/character_creation.gd").new(self).show_creator()
func update_profile() -> void:preload("res://ui/character_creation.gd").new(self).update_profile()
func confirm_character() -> void:preload("res://ui/character_creation.gd").new(self).confirm_character()
func show_start_settings() -> void:
	close_flow();menu.hide();exo.open("config")

func close_flow() -> void:
	flow_screen.hide()
	flow_kind=""
	if is_instance_valid(preview_view):
		preview_view.render_target_update_mode=SubViewport.UPDATE_DISABLED

func cinematic(text: String,value: bool) -> void:
	cinema.visible=value
	cinema_text.text=text
	for child in get_child(0).get_children():
		if child not in [cinema,flow_screen,menu,modal,exo] and child is CanvasItem:
			child.visible=not value
	reticle.visible=not value and not get_tree().paused

func show_menu(value: bool) -> void:
	super.show_menu(value)
	if (is_instance_valid(flow_screen) and flow_screen.visible) or (is_instance_valid(exo) and exo.visible):
		menu.hide()
	if value and world.flow!=null:
		heading.text="EXO • MURIM / PAUSA"
		if world.flow.phase=="hero":
			play.text="ESCOLHER HERÓI DO PRÓLOGO"
		save_status.text=world.journey.status

func resume() -> void:
	if world.flow!=null:
		if world.flow.phase=="hero":
			show_hero()
			return
		if world.flow.phase in ["story","creator"]:
			return
	super.resume()

func restart() -> void:
	if world.flow!=null and world.flow.phase!="adventure":
		world.flow.start_prologue()
		return
	super.restart()

func show_extra(map_mode: bool) -> void:
	if world.flow==null or world.flow.phase!="adventure":return
	world.set_paused(true);menu.hide();modal.hide()
	exo.open("mapa" if map_mode else "central")

func _process(delta: float) -> void:
	preview_clock+=delta
	story_clock+=delta
	story_ready=maxf(0,story_ready-delta)
	if is_instance_valid(location_panel):
		var target:=1.0 if not location_label.text.is_empty() and not get_tree().paused and world.flow.phase=="adventure" else 0.0
		location_panel.modulate.a=move_toward(location_panel.modulate.a,target,delta*3)
	if is_instance_valid(trajectory) and world.cultivation!=null and world.flow!=null:
		trajectory.visible=not get_tree().paused and world.flow.phase=="adventure" and world.cultivation.trajectory()
		if trajectory.visible:
			var reach: float=world.current_weapon().reach
			trajectory.position=world.player.position+Vector3.UP*.12+world.facing*reach*.5
			trajectory.rotation.y=atan2(-world.facing.x,-world.facing.z)
			trajectory.scale.z=reach
	if cinema.visible and world.flow!=null and world.flow.phase=="omen" and world.flow.god.visible:
		var point: Vector2=world.camera.unproject_position(world.flow.god.to_global(Vector3(0,2.3,0)))
		cinema.set_anchors_preset(Control.PRESET_TOP_LEFT)
		cinema.position=Vector2(clampf(point.x-220,20,700),clampf(point.y-80,20,520))
		cinema.size=Vector2(440,80)
	if is_instance_valid(preview) and is_instance_valid(preview_view) and preview_view.render_target_update_mode==SubViewport.UPDATE_ALWAYS:
		preview.pose(preview_clock if world.graphics.preview_motion else 0.0,false,false,true)
		world.Arsenal.animate(preview,Catalog.weapon(str(preview.get_meta("weapon_id","sword"))),0,-1)
		world.Anatomy.animate(preview,preview_clock,0,true)

func _input(event: InputEvent) -> void:
	if world.flow!=null and world.flow.phase=="story":
		var advance: bool=(event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed) or (event is InputEventJoypadButton and event.pressed)
		if advance:
			get_viewport().set_input_as_handled()
			if story_ready<=0:world.flow.advance_story()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var focused:=get_viewport().gui_get_focus_owner()
		if focused is LineEdit and event.physical_keycode!=KEY_ESCAPE:return
		if exo.visible:
			if event.physical_keycode==KEY_I and world.flow.phase=="adventure":
				if exo.page=="inventario":exo.close_menu()
				else:exo.open("inventario")
				get_viewport().set_input_as_handled()
			elif event.physical_keycode in [KEY_P,KEY_ESCAPE]:exo.close_menu();get_viewport().set_input_as_handled()
			elif event.physical_keycode==KEY_TAB and world.flow.phase=="adventure":
				if exo.page=="mapa":exo.close_menu()
				else:exo.open("mapa")
				get_viewport().set_input_as_handled()
			return
		if flow_screen.visible:
			if event.physical_keycode==KEY_ESCAPE:get_viewport().set_input_as_handled()
			return
		if world.flow.phase=="adventure" and event.physical_keycode in [KEY_P,KEY_TAB,KEY_I]:
			if event.physical_keycode==KEY_I:
				world.set_paused(true);menu.hide();modal.hide();exo.open("inventario")
			else:show_extra(event.physical_keycode==KEY_TAB)
			get_viewport().set_input_as_handled();return
		if world.flow.phase=="omen":return
	super._input(event)

func refresh() -> void:
	super.refresh()
	if world.flow!=null:
		# Native EXO-Murim HUD owns the objective tracker during exploration.
		if is_instance_valid(quest) and is_instance_valid(quest.get_parent().get_parent()):
			quest.get_parent().get_parent().visible = not (world.flow.phase in ["adventure","prologue"] and int(world.graphics.hud.style)==0)
		if world.flow.phase!="adventure":
			quest.text=world.objective()
		if world.flow.phase=="omen":
			reticle.hide()

func set_location(value: String) -> void:
	if is_instance_valid(location_label):location_label.text=value
