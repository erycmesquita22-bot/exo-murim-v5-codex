extends Control
var controller
var bar: Label
var panel: PanelContainer
var listing: Label
func configure(owner_controller):
	controller = owner_controller
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar = Label.new();bar.position = Vector2(22,690);bar.add_theme_font_size_override("font_size",18)
	bar.add_theme_color_override("font_shadow_color",Color.BLACK);bar.add_theme_constant_override("shadow_offset_x",2);bar.add_theme_constant_override("shadow_offset_y",2)
	add_child(bar)
	panel = PanelContainer.new();panel.position = Vector2(760,115);panel.size = Vector2(480,500)
	var style := StyleBoxFlat.new();style.bg_color = Color(.035,.055,.065,.96);style.border_color = Color(.4,.7,.74);style.set_border_width_all(2);style.content_margin_left = 20;style.content_margin_right = 20;style.content_margin_top = 16;style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel",style)
	add_child(panel);panel.visible = false
	listing = Label.new();listing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;listing.custom_minimum_size = Vector2(430,450);listing.add_theme_font_size_override("font_size",18)
	panel.add_child(listing)
func refresh():
	if not is_instance_valid(controller): return
	var lines := "QI  %d / %d     K  Catálogo\n" % [int(controller.qi),int(controller.maximum_qi)]
	var catalog := "ARTES ATIVAS — CATÁLOGO\n\n"
	for i in controller.catalog.size():
		var skill = controller.catalog[i]
		var cooldown: float = controller.cooldowns.get(skill.skill_id,0.0)
		var status := "%.1fs" % cooldown if cooldown > 0 else ("QI insuficiente" if controller.qi < skill.qi_cost else "pronta")
		lines += "[%d] %s · %s%s" % [i+1,skill.display_name,status,"     " if i<2 else ""]
		catalog += "%d  %s · %s\nQi %d  |  Recarga %.1fs  |  Dano %d\n%s\n\n" % [i+1,skill.display_name,skill.school,int(skill.qi_cost),skill.cooldown,skill.damage,skill.description]
	bar.text = lines+"\n"+controller.feedback
	listing.text = catalog
