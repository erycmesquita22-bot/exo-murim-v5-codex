extends RefCounted
const INK=Color("211b19")
const GOLD=Color("e7c18b")
const TEXT=Color("f3e5cf")
static func make() -> Theme:
	var result:=Theme.new()
	result.default_font_size=16
	for type in ["PanelContainer","PopupMenu"]:
		var box:=StyleBoxFlat.new()
		box.bg_color=Color(.105,.075,.065,.94)
		box.border_color=Color("a5835b")
		box.set_border_width_all(1)
		box.set_corner_radius_all(5)
		box.shadow_color=Color(0,0,0,.38)
		box.shadow_size=6
		box.set_content_margin_all(16)
		result.set_stylebox("panel",type,box)
	for state in ["normal","hover","pressed","focus","disabled"]:
		var box:=StyleBoxFlat.new()
		box.bg_color=Color("382a25") if state=="normal" else Color("654433")
		box.border_color=Color("98714c") if state=="normal" else GOLD
		if state=="disabled":box.bg_color=Color("211d1b");box.border_color=Color("514237")
		box.set_border_width_all(1)
		box.set_corner_radius_all(4)
		box.set_content_margin_all(9)
		for type in ["Button","OptionButton","LineEdit"]:result.set_stylebox(state,type,box)
	for type in ["Label","Button","OptionButton","LineEdit","PopupMenu"]:
		result.set_color("font_color",type,TEXT)
	result.set_color("font_disabled_color","Button",Color("978675"))
	return result
static func backdrop(parent: Control,world: Node3D) -> void:
	var image:=TextureRect.new()
	parent.add_child(image)
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.texture=load("res://main_menu_01/art/voxel_murim_dawn.png")
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.modulate=Color(.62,.54,.47)
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var shade:=ColorRect.new()
	parent.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color=Color(.075,.042,.032,.52)
	shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
