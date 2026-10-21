extends RefCounted
const Loot=preload("res://procedural/loot_generator.gd")
const Catalog=preload("res://catalog.gd")
var menu: Control
var world: Node3D
func _init(owner_menu: Control) -> void:
	menu=owner_menu
	world=menu.world

func equipment(parent: Node) -> void:
	menu.text(parent,"EQUIPAMENTO DO VIAJANTE",22)
	menu.button(parent,"RETOMAR ARMA [R]" if world.martial.bare() else "GUARDAR ARMA / MÃOS LIVRES [R]",func():menu.result(world.martial.toggle()))
	menu.text(parent,"Mãos livres não exigem equipamento. Armas de uma mão são embainhadas fora de combate; atacar saca automaticamente.",15,680)
	var any_weapon:=false
	for item in world.journey.data.items:
		if item.kind!="weapon":continue
		any_weapon=true
		var spec:=Loot.weapon(item)
		var equipped: bool=item.uid==world.journey.data.equipped
		menu.button(parent,world.inventory.title(item)+(" • EQUIPADA" if equipped else " • EQUIPAR"),func(): menu.result(world.inventory.use(item.uid)))
		menu.text(parent,"Dano %d • Alcance %.1f m • Ciclo %.2f s"%[spec.damage,spec.reach,spec.duration],15,680)
	if not any_weapon:menu.text(parent,"Você ainda não possui uma arma.",16)
	menu.text(parent,"Outros equipamentos podem ser encontrados na jornada.",15,680)

func bag(parent: Node) -> void:
	menu.text(parent,"INVENTÁRIO • %d / 24"%world.journey.data.items.size(),23)
	var columns:=HBoxContainer.new()
	parent.add_child(columns)
	columns.add_theme_constant_override("separation",18)
	var grid:=GridContainer.new()
	columns.add_child(grid)
	grid.columns=4
	var items: Array=world.journey.data.items
	for i in range(24):
		if i<items.size():
			var item: Dictionary=items[i]
			var name_value: String=world.inventory.title(item)
			var tile: Button=menu.button(grid,name_value+(" ×%d"%int(item.qty) if item.qty>1 else "")+(" • E" if item.uid==world.journey.data.equipped else ""),func(): menu.selected_item=item.uid; menu.open("inventario"),92)
			tile.custom_minimum_size.y=68
			tile.add_theme_font_size_override("font_size",10)
			tile.alignment=HORIZONTAL_ALIGNMENT_CENTER
			var icon:=preload("res://item_icon.gd").new()
			icon.kind=item.kind
			icon.ref=item.ref
			tile.add_child(icon)
			icon.position=Vector2(46,22)
			tile.text="\n\n\n"+tile.text
			tile.clip_text=true
			tile.tooltip_text=name_value+"\n"+Loot.describe(item) if item.kind=="weapon" else name_value
		else:
			var empty: Button=menu.button(grid,"·",func(): pass,92)
			empty.custom_minimum_size.y=68
			empty.disabled=true
	var detail:=VBoxContainer.new()
	columns.add_child(detail)
	detail.custom_minimum_size.x=270
	var item: Dictionary=world.inventory.find_item(menu.selected_item)
	if item.is_empty() and not items.is_empty():item=items[0]
	if item.is_empty():return
	menu.text(detail,world.inventory.title(item),21,270)
	menu.text(detail,"%s • Quantidade %d"%[item.get("rarity","Comum"),int(item.qty)],15,270)
	if item.kind=="weapon":
		var spec:=Loot.weapon(item)
		var current: Dictionary=world.current_weapon()
		menu.text(detail,Loot.describe(item),14,270)
		menu.text(detail,spec.description,16,270)
		menu.text(detail,"Dano %d (%+d)\nAlcance %.1f (%+.1f)\nCiclo %.2f s (%+.2f)\n%d mão(s)"%[spec.damage,spec.damage-current.damage,spec.reach,spec.reach-current.reach,spec.duration,spec.duration-current.duration,spec.hands],16,270)
		menu.button(detail,"EQUIPAR",func(): menu.result(world.inventory.use(item.uid)),260)
		var preview_profile: Dictionary=world.journey.data.character.duplicate(true)
		preview_profile.weapon=item.ref
		world.ui.make_preview(detail,preview_profile,Vector2(270,200))
		menu.preview=world.ui.preview
	elif item.kind=="manual":
		menu.text(detail,"Leia para revelar este conhecimento. Cultivo e aprendizado são feitos em Habilidades.",16,270)
		menu.button(detail,"LER MANUAL",func(): menu.result(world.inventory.use(item.uid)),260)
	elif item.kind=="consumable":
		menu.text(detail,world.inventory.SPECIAL[item.ref].description,16,270)
		menu.button(detail,"CONSUMIR",func(): menu.result(world.inventory.use(item.uid)),260)
	else:menu.text(detail,world.inventory.SPECIAL[item.ref].description,16,270)

