extends Control
const Catalog=preload("res://catalog.gd")
const Wardrobe=preload("res://wardrobe.gd")
const Shell=preload("res://ui/menu_shell.gd")
var world: Node3D
var shell: RefCounted
var pages: Dictionary={}
var page:="central"
var preview: Node3D
var note: Label
var selected_weapon:="sword"
var selected_skill:="corte_inicial"
var list_box: VBoxContainer
var detail_box: VBoxContainer
var search:=""
var category:="Todos"
var new_confirm:=false
var selected_item:=""
func clear(node: Node) -> void:
	for child in node.get_children():node.remove_child(child);child.queue_free()
func text(parent: Node,value: String,size_value: int=16,width: float=0) -> Label:
	var item:=Label.new();parent.add_child(item)
	item.text=value;item.add_theme_font_size_override("font_size",size_value)
	if width>0:item.custom_minimum_size.x=width;item.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return item
func button(parent: Node,value: String,action: Callable,width: float=0) -> Button:
	var item:=Button.new();parent.add_child(item)
	item.text=value;item.custom_minimum_size=Vector2(width,36)
	item.add_theme_font_size_override("font_size",14)
	item.pressed.connect(func():world.audio_fx.play_event("ui","ui",.4);action.call())
	return item
func open(value: String="") -> void:
	if value!="":page=value
	if page.begins_with("central_"):page=Shell.ROUTES[clampi(int(page.trim_prefix("central_")),0,5)][0][1]
	if world.flow.phase!="adventure" and page not in ["config","hud","audio","controles"]:close_menu();return
	if shell==null:
		shell=Shell.new(self)
		for id in ["character","inventory","skills","settings","journal"]:pages[id]=load("res://ui/pages/"+id+".gd").new(self)
	var content: VBoxContainer=shell.navigate(page)
	match page:
		"central":home(content)
		"ficha":pages.character.ficha(content)
		"atributos":pages.character.attributes(content)
		"classes":pages.character.classes(content)
		"titulos":pages.character.titles(content)
		"linhagem":pages.character.lineages(content)
		"inventario":pages.inventory.bag(content)
		"equipamento":pages.inventory.equipment(content)
		"ativas":pages.skills.skills(content)
		"passivas":pages.skills.passives(content)
		"jornada":pages.journal.journal(content)
		"testes":pages.journal.laboratory(content)
		"config":pages.settings.configuration(content)
		"hud":pages.settings.hud_options(content)
		"audio":pages.settings.audio_options(content)
		"controles":pages.settings.controls(content)
		"ajuda":pages.settings.help_page(content)
		"mapa":map_page(content)
	show()
func home(parent: Node) -> void:
	var row:=HBoxContainer.new();parent.add_child(row)
	var left:=VBoxContainer.new();row.add_child(left);left.custom_minimum_size.x=325
	var d: Dictionary=world.journey.data
	text(left,d.character.name,30).modulate=Color("d5ba80")
	text(left,"%s • %s"%[Catalog.RACES[int(d.character.race)].name,world.flow.PATHS[int(d.character.path)]],17,320)
	text(left,"SEU CAMINHO",13).modulate=Color("87b9bf")
	text(left,world.flow.objective(),20,320)
	text(left,"Vida %d / %d\nQi %.0f / 100\nEstamina %.0f / 100"%[world.health,world.max_health,world.techniques.mana,world.techniques.stamina],17)
	button(left,"CONTINUAR A JORNADA",close_menu,310)
	button(left,"TÉCNICAS CONHECIDAS",func():open("ativas"),310)
	button(left,"ABRIR INVENTÁRIO",func():open("inventario"),310)
	var right:=VBoxContainer.new();row.add_child(right);right.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	world.ui.make_preview(right,d.character,Vector2(490,470));preview=world.ui.preview
	text(right,"Arraste o personagem para girar • roda do mouse aproxima",12)
func refresh_portrait(profile: Dictionary={}) -> void:
	if is_instance_valid(preview):Wardrobe.apply(preview,world.journey.data.character if profile.is_empty() else profile)
func result(ok: bool) -> void:
	if ok:open()
	else:note.text="Ação indisponível. Confira os requisitos e encerre o combate."
func skill_detail() -> void:pages.skills.skill_detail()
func populate_skills() -> void:pages.skills.populate_skills()
func map_page(parent: Node) -> void:
	var birth: Dictionary=world.journey.data.world.get("birthplace",world.get_meta("landscape_plan",{}))
	text(parent,"MUNDO • Região %02d"%int(world.get("current_region")),22) if world.get("current_region")!=null and int(world.get("current_region"))>=0 else text(parent,"MUNDO • "+str(birth.get("title","Primeiro Eco")),22)
	text(parent,"Seed %s • Atlas de 88 regiões externas"%str(world.journey.data.world.seed),13) if world.get("current_region")!=null and int(world.get("current_region"))>=0 else text(parent,"Seed %s • Região conectada: vila, bambuzal, montanhas e ruínas"%str(world.journey.data.world.seed),13)
	var map:=preload("res://map_view.gd").new();map.world=world;parent.add_child(map)
	text(parent,"Ciano: você • Dourado: objetivo/marco por explorar • Vermelho: inimigos • Cinza: marco recolhido",13)
func close_menu() -> void:
	hide();world.ui.close_flow()
	if world.flow.phase=="hero":world.ui.show_hero()
	elif world.flow.phase=="creator":world.ui.show_creator()
	else:world.set_paused(false)
