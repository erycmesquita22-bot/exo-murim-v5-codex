extends "res://modules/murim_footwork/catalog_ui.gd"
func refresh():
	super.refresh()
	if not is_instance_valid(controller): return
	var lines := bar.text.split("\n")
	lines[0] = "QI %d/100 · Segure ataque: combo · K catálogo · B comparar legado"%int(controller.qi)
	bar.text = "\n".join(lines)
