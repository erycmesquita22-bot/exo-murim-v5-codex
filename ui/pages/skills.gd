extends RefCounted
const Slots=preload("res://data/slot_rules.gd")
const Catalog=preload("res://catalog.gd")
var menu: Control
var world: Node3D
func _init(owner_menu: Control) -> void:
	menu=owner_menu
	world=menu.world

func skills(parent: Node) -> void:
	menu.text(parent,"HABILIDADES ATIVAS • %d ESPAÇOS"%world.journey.data.loadout.size(),22).modulate=Color("d8bd81")
	var filters:=HBoxContainer.new()
	parent.add_child(filters)
	var field:=LineEdit.new()
	filters.add_child(field)
	field.placeholder_text="Buscar técnica do EXO..."
	field.text=menu.search
	field.custom_minimum_size=Vector2(355,34)
	var select:=OptionButton.new()
	filters.add_child(select)
	var categories: Array=["Todos"]
	for skill in Catalog.SKILLS:
		if world.cultivation.known(skill.id) and skill.kind not in categories:categories.append(skill.kind)
	for kind in categories:
		select.add_item(Catalog.kind_name(kind))
	if menu.category not in categories:menu.category="Todos"
	select.select(maxi(0,categories.find(menu.category)))
	var row:=HBoxContainer.new()
	parent.add_child(row)
	var list_scroll:=ScrollContainer.new()
	row.add_child(list_scroll)
	list_scroll.custom_minimum_size=Vector2(275,315)
	menu.list_box=VBoxContainer.new()
	list_scroll.add_child(menu.list_box)
	menu.detail_box=VBoxContainer.new()
	row.add_child(menu.detail_box)
	menu.detail_box.custom_minimum_size.x=390
	field.text_changed.connect(func(value: String): menu.search=value; populate_skills())
	select.item_selected.connect(func(index: int): menu.category=categories[index]; populate_skills())
	populate_skills()
	skill_detail()

func populate_skills() -> void:
	if not world.cultivation.visible(menu.selected_skill):menu.selected_skill=world.journey.data.loadout[0]
	menu.clear(menu.list_box)
	for item in Catalog.SKILLS:
		if not world.cultivation.visible(item.id):continue
		var is_known: bool=world.cultivation.known(item.id)
		if (menu.search.is_empty() or (is_known and item.name.to_lower().contains(menu.search.to_lower()))) and (menu.category=="Todos" or (is_known and menu.category==item.kind)):
			var item_button: Button=menu.button(menu.list_box,item.name if world.cultivation.known(item.id) else "???",func(): menu.selected_skill=item.id; populate_skills(); skill_detail(),255)
			item_button.clip_text=true
			if item.id==menu.selected_skill:item_button.modulate=Color("d8bd81")

func skill_detail() -> void:
	menu.clear(menu.detail_box)
	if not world.cultivation.visible(menu.selected_skill):
		menu.selected_skill=world.journey.data.loadout[0]
	var spec: Dictionary=world.cultivation.stats(Catalog.skill(menu.selected_skill))
	if not world.cultivation.known(spec.id):
		menu.text(menu.detail_box,"???",24)
		menu.text(menu.detail_box,"Ainda não descoberta.",17,385)
		if world.cultivation.BRANCHES.has(spec.id):menu.text(menu.detail_box,"Possível melhoria de "+(Catalog.skill(world.cultivation.BRANCHES[spec.id].parent).name if world.cultivation.known(world.cultivation.BRANCHES[spec.id].parent) else "???")+".",16,385)
		return
	menu.text(menu.detail_box,spec.name,20,385).modulate=Color("aeb9c4")
	menu.text(menu.detail_box,spec.description,16,385)
	menu.text(menu.detail_box,"Grau de domínio: %d"%world.cultivation.grade(spec.id),15,385)
	menu.text(menu.detail_box,"Família: %s\nEnergia: %d • Vigor: %d\nRecarga: %.1f s" % [Catalog.kind_name(spec.kind),spec.mana,spec.stamina,spec.cooldown],15,385)
	menu.text(menu.detail_box,"Maestria da técnica: %d"%int(world.journey.data.mastery.get(spec.id,0)),15,385)
	if not world.cultivation.learned(spec.id):
		if world.cultivation.BRANCHES.has(spec.id):
			var branch: Dictionary=world.cultivation.BRANCHES[spec.id]
			menu.text(menu.detail_box,"Requer %d de maestria em %s."%[branch.mastery,(Catalog.skill(branch.parent).name if world.cultivation.known(branch.parent) else "???")],16,385)
		var learn_button: Button=menu.button(menu.detail_box,"APRENDER",func(): menu.result(world.cultivation.learn(spec.id)),370)
		learn_button.disabled=not world.cultivation.eligible(spec.id)
		return
	for i in range(world.journey.data.loadout.size()):
		menu.button(menu.detail_box,"%d • %s  → equipar" % [i+1,Catalog.skill(world.journey.data.loadout[i]).name],func(): menu.result(world.equip_skill(spec.id,i)),380)
	menu.text(menu.detail_box,"Trocar de espaço não reinicia a recarga da técnica.",14,385)

func passives(parent: Node) -> void:
	menu.text(parent,"PASSIVAS • %d ESPAÇOS"%Slots.PASSIVE,22).modulate=Color("d8bd81")
	for item in Catalog.PASSIVES:
		if not world.cultivation.visible(item.id):continue
		if not world.cultivation.known(item.id):
			menu.text(parent,"??? • Ainda não descoberta.",19)
			continue
		menu.text(parent,item.name,19)
		menu.text(parent,item.description,16)
		if item.id!="percepcao_qi":menu.text(parent,"Maestria da passiva: %d"%int(world.journey.data.mastery.get(item.id,0)),14)
		if not world.cultivation.learned(item.id):
			var learn_button: Button=menu.button(parent,"APRENDER",func(): menu.result(world.cultivation.learn(item.id)))
			learn_button.disabled=not world.cultivation.eligible(item.id)
			continue
		menu.button(parent,"DESEQUIPAR" if item.id in world.journey.data.passives else "EQUIPAR",func(): menu.result(world.toggle_passive(item.id)))

