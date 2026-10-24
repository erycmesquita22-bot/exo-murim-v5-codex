extends "res://modules/active_skills/catalog_ui.gd"
func configure(owner_controller):
	super.configure(owner_controller)
	panel.remove_child(listing)
	panel.custom_minimum_size = Vector2(480,540);panel.size = Vector2(480,540)
	var scroll := ScrollContainer.new();scroll.custom_minimum_size = Vector2(430,495);scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll);scroll.add_child(listing);listing.custom_minimum_size = Vector2(410,1);listing.add_theme_font_size_override("font_size",16)
func refresh():
	super.refresh()
	if not is_instance_valid(controller): return
	var text := "QI %d/100 · K catálogo · M maestria: %s · B ataque: %s\n" % [int(controller.qi),"iniciante" if controller.host.sword_mastery < .5 else "treinado","novo" if controller.host.footwork_mode else "legado"]
	for i in controller.catalog.size():
		var skill = controller.catalog[i];var cd: float = controller.cooldowns[skill.skill_id]
		text += "[%d] %s %s   " % [i+1,skill.display_name,"%.1fs"%cd if cd > 0 else ""]
		if i == 2: text += "\n"
	bar.text = text+"\n"+controller.feedback
