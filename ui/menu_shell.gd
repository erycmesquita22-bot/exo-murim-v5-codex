extends RefCounted
const Palette=preload("res://ui/skin.gd")
const GROUPS=["PERSONAGEM","MISSÕES","EQUIPAMENTOS","MUNDO","CONFIGURAÇÕES","AJUDA"]
const ROUTES=[[["Visão geral","ficha"],["Atributos","atributos"],["Técnicas","ativas"],["Passivas","passivas"],["Classes","classes"],["Títulos","titulos"],["Linhagem","linhagem"]],[["Crônicas e contratos","jornada"]],[["Inventário","inventario"],["Arma equipada","equipamento"]],[["Mapa","mapa"]],[["Vídeo e identidade","config"],["HUD","hud"],["Áudio","audio"],["Controles","controles"]],[["Primeiros passos","ajuda"],["Laboratório","testes"]]]
var menu: Control
var body: VBoxContainer
var tabs: HBoxContainer
var caption: Label
var coins: Label
var exit_button: Button
var background_root: Control
var nav_buttons: Array[Button]=[]
var frame: Control
var paper: Control
var built:=false
var group:=0
func _init(value: Control) -> void:menu=value
func build() -> void:
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.theme=Palette.make()
	menu.name="AdventureMenu"
	background_root=Control.new();menu.add_child(background_root)
	background_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Palette.backdrop(background_root,menu.world)
	var layout:=MarginContainer.new();menu.add_child(layout)
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:layout.add_theme_constant_override("margin_"+side,18)
	var row:=HBoxContainer.new();layout.add_child(row)
	row.add_theme_constant_override("separation",18)
	var navigation:=PanelContainer.new();row.add_child(navigation)
	navigation.custom_minimum_size.x=192
	var nav:=VBoxContainer.new();navigation.add_child(nav)
	nav.add_theme_constant_override("separation",12)
	menu.text(nav,"E X O",32).modulate=Palette.GOLD
	menu.text(nav,"CRÔNICAS DO MURIM",11)
	menu.button(nav,"INÍCIO",func():menu.open("central") if menu.world.flow.phase=="adventure" else menu.close_menu(),158)
	nav.add_child(HSeparator.new())
	for i in range(GROUPS.size()):
		var item: Button=menu.button(nav,GROUPS[i],func():menu.open(ROUTES[i][0][1]),158)
		item.custom_minimum_size.y=51
		item.disabled=menu.world.flow.phase!="adventure" and i!=4
		nav_buttons.append(item)
	var space:=Control.new();nav.add_child(space);space.size_flags_vertical=Control.SIZE_EXPAND_FILL
	menu.text(nav,"P / Esc • voltar ao mundo",11,158).modulate=Color("91a6ac")
	exit_button=menu.button(nav,"VOLTAR AO MUNDO" if menu.world.flow.phase=="adventure" else "VOLTAR AO PRÓLOGO",menu.close_menu,158)
	var right:=VBoxContainer.new();row.add_child(right)
	right.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation",12)
	var top:=HBoxContainer.new();right.add_child(top)
	caption=menu.text(top,"",24);caption.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	coins=menu.text(top,"",16);coins.modulate=Palette.GOLD
	tabs=HBoxContainer.new();right.add_child(tabs);tabs.add_theme_constant_override("separation",6)
	var panel:=PanelContainer.new();right.add_child(panel)
	panel.name="PageSurface"
	paper=preload("res://manuscript.gd").new();panel.add_child(paper)
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var scroll:=ScrollContainer.new();panel.add_child(scroll)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	body=VBoxContainer.new();scroll.add_child(body)
	body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",12)
	menu.note=menu.text(right,"",13)
	frame=preload("res://exo_frame.gd").new();menu.add_child(frame)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	built=true
func navigate(page: String) -> VBoxContainer:
	if not built:build()
	frame.visible=menu.world.graphics.ornaments;paper.visible=menu.world.graphics.paper
	menu.clear(body);menu.clear(tabs)
	menu.preview=null
	menu.world.ui.preview=null
	caption.text="CENTRAL DO AVENTUREIRO"
	coins.text="MOEDAS  %d"%menu.world.journey.data.coins
	group=-1
	for i in range(ROUTES.size()):
		for entry in ROUTES[i]:
			if entry[1]==page:group=i
	if page=="titulos":group=0
	for i in range(nav_buttons.size()):
		nav_buttons[i].modulate=Palette.GOLD if i==group else Color.WHITE
		nav_buttons[i].disabled=menu.world.flow.phase!="adventure" and i!=4
	exit_button.text="VOLTAR AO MUNDO" if menu.world.flow.phase=="adventure" else "VOLTAR AO PRÓLOGO"
	if group>=0:
		caption.text=GROUPS[group]
		for entry in ROUTES[group]:
			var item: Button=menu.button(tabs,entry[0],func():menu.open(entry[1]))
			item.modulate=Palette.GOLD if entry[1]==page else Color.WHITE
	menu.note.text=""
	return body
func update_background() -> void:
	menu.clear(background_root)
	Palette.backdrop(background_root,menu.world)
