extends CanvasLayer
# Runtime overlays only: pause, dialogue, objective and cursor. No hidden legacy menu.
var world: Node3D
var menu: Control
var play: Button
var heading: Label
var reticle: Label
var quest: Label
var prompt: Label
var save_status: Label
var modal: Control
var modal_title: Label
var modal_body: Label
var modal_actions: VBoxContainer
var first_play:=true
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	var root:=Control.new();add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	root.theme=preload("res://ui/skin.gd").make()
	var journal:=PanelContainer.new();root.add_child(journal)
	journal.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	journal.offset_left=-330;journal.offset_top=18;journal.offset_right=-18
	var col:=VBoxContainer.new();journal.add_child(col)
	label(col,"CRÔNICA ATUAL",13).modulate=Color("d5ba80")
	quest=label(col,"",15);quest.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;quest.custom_minimum_size.x=275
	save_status=label(col,"",11)
	prompt=label(root,"",19);prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	prompt.offset_left=-260;prompt.offset_right=260;prompt.offset_top=180;prompt.offset_bottom=220
	reticle=label(root,"+",26);reticle.mouse_filter=Control.MOUSE_FILTER_IGNORE
	menu=overlay(root)
	var pause_col:=menu_column(menu,420)
	heading=label(pause_col,"PAUSA",26)
	play=button(pause_col,"CONTINUAR",resume)
	button(pause_col,"CONFIGURAÇÕES",func():settings_from_pause())
	button(pause_col,"SALVAR",func():world.save_progress();save_status.text=world.journey.status)
	button(pause_col,"SALVAR E SAIR",func():if world.save_progress():get_tree().quit())
	modal=overlay(root)
	var dialogue_col:=menu_column(modal,520)
	modal_title=label(dialogue_col,"",23)
	modal_body=label(dialogue_col,"",17);modal_body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;modal_body.custom_minimum_size.x=500
	modal_actions=VBoxContainer.new();dialogue_col.add_child(modal_actions)
	button(dialogue_col,"CONTINUAR",resume)
	modal.hide()
func settings_from_pause() -> void:
	if world.flow.phase=="adventure":world.ui.show_extra(false);world.ui.exo.open("config")
	else:world.ui.show_start_settings()
func overlay(parent: Node) -> Control:
	var result:=Control.new();parent.add_child(result)
	result.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade:=ColorRect.new();result.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.color=Color(.02,.03,.045,.85)
	return result
func menu_column(parent: Control,width: float) -> VBoxContainer:
	var center:=CenterContainer.new();parent.add_child(center);center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel:=PanelContainer.new();center.add_child(panel)
	var col:=VBoxContainer.new();panel.add_child(col);col.custom_minimum_size.x=width;col.add_theme_constant_override("separation",14)
	return col
func label(parent: Node,value: String,size_value: int) -> Label:
	var item:=Label.new();parent.add_child(item);item.text=value;item.add_theme_font_size_override("font_size",size_value);return item
func button(parent: Node,value: String,action: Callable) -> Button:
	var item:=Button.new();parent.add_child(item);item.text=value;item.custom_minimum_size=Vector2(0,39)
	item.pressed.connect(func():world.audio_fx.play_event("ui","ui",.3);action.call());return item
func resume() -> void:
	if world.health<=0:world.resume_checkpoint()
	first_play=false;modal.hide();world.set_paused(false)
func restart() -> void:world.resume_checkpoint();resume()
func dialogue(title_value: String,body: String) -> void:
	for child in modal_actions.get_children():modal_actions.remove_child(child);child.queue_free()
	world.set_paused(true);menu.hide();modal.show();modal_title.text=title_value;modal_body.text=body
func show_menu(value: bool) -> void:
	menu.visible=value;modal.hide();reticle.visible=not value
	if value:
		heading.text="EXO • PAUSA"
		play.text="RETOMAR DO MARCO" if world.health<=0 else "CONTINUAR"
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_ESCAPE:
		if modal.visible:resume()
		else:world.set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()
func refresh() -> void:
	quest.text=world.objective()
	save_status.text=world.journey.status
	prompt.text=world.interaction_hint()
	var point: Vector2=world.camera.unproject_position(world.player.position+Vector3(0,1.1,0))+world.aim_offset
	reticle.position=point.clamp(Vector2(15,15),get_viewport().get_visible_rect().size-Vector2(30,30))-Vector2(8,15)

func dialogue_actions(title_value: String, body: String, actions: Array) -> void:
	dialogue(title_value, body)
	for action in actions:
		button(modal_actions, str(action.label), action.action)
