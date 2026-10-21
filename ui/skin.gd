extends RefCounted
const INK=Color("101b24")
const GOLD=Color("d5ba80")
const TEXT=Color("e7e7dc")
static func make() -> Theme:
	var result:=Theme.new()
	result.default_font_size=16
	for type in ["PanelContainer","PopupMenu"]:
		var box:=StyleBoxFlat.new()
		box.bg_color=Color(.035,.065,.085,.95)
		box.border_color=Color("6f7464")
		box.set_border_width_all(1)
		box.set_content_margin_all(16)
		result.set_stylebox("panel",type,box)
	for state in ["normal","hover","pressed","focus","disabled"]:
		var box:=StyleBoxFlat.new()
		box.bg_color=Color("162b37") if state=="normal" else Color("284654")
		box.border_color=Color("48616b") if state=="normal" else GOLD
		if state=="disabled":box.bg_color=Color("111b22");box.border_color=Color("29363c")
		box.set_border_width_all(1)
		box.set_content_margin_all(9)
		for type in ["Button","OptionButton","LineEdit"]:result.set_stylebox(state,type,box)
	for type in ["Label","Button","OptionButton","LineEdit","PopupMenu"]:
		result.set_color("font_color",type,TEXT)
	result.set_color("font_disabled_color","Button",Color("73838b"))
	return result
static func backdrop(parent: Control,world: Node3D) -> void:
	var image:=TextureRect.new()
	parent.add_child(image)
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.texture=load("res://assets/central_"+["exo","anime","adventure","fantasy"][world.graphics.menu_style]+".png")
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.modulate=Color(.46,.5,.54)
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var shade:=ColorRect.new()
	parent.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color=Color(.025,.045,.065,.5)
	shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
