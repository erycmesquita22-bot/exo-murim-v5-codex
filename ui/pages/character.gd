extends RefCounted
const Slots=preload("res://data/slot_rules.gd")
const Catalog=preload("res://catalog.gd")
var menu: Control
var world: Node3D
func _init(owner_menu: Control) -> void:
	menu=owner_menu
	world=menu.world

func ficha(parent: Node) -> void:
	var data: Dictionary=world.journey.data
	var race: Dictionary=Catalog.RACES[int(data.character.race)]
	menu.text(parent,"FICHA DO VIAJANTE",23).modulate=Color("d8bd81")
	menu.text(parent,"%s  •  %s  •  Afinidade: %s" % [race.name,world.flow.PATHS[int(data.character.path)],Catalog.ELEMENTS[int(data.character.get("element",6))]],18,680)
	menu.text(parent,race.description,16,680)
	menu.text(parent,"TÉCNICAS EQUIPADAS",18)
	for i in range(world.journey.data.loadout.size()):
		menu.text(parent,"%d  %s" % [i+1,Catalog.skill(data.loadout[i]).name],16)
	menu.text(parent,"PASSIVAS • %d / %d" % [data.passives.size(),Slots.PASSIVE],18)
	for id in data.passives:
		for item in Catalog.PASSIVES:
			if item.id==id:
				menu.text(parent,item.name+" • "+item.description,16,680)
	menu.text(parent,"Seu personagem permanece com a ancestralidade escolhida. Equipamento, técnicas e classe base podem ser preparados fora de combate.",15,680)

func attributes(parent: Node) -> void:
	var total:=0
	for value in world.journey.data.attributes.values():
		total+=int(value)
	menu.text(parent,"ATRIBUTOS • %d PONTOS LIVRES" % (6-total),22).modulate=Color("d8bd81")
	var effects: Array=["+1% dano básico por ponto","+2% velocidade de ataque e -0,01 s na rolada","+2 vida máxima por ponto","+2% dano de técnicas e +0,4 energia/s","Barreira +5% e cura +2 por ponto","+2% chance de crítico básico (dano ×1,5)"]
	for i in range(6):
		var key: String=world.journey.ATTRIBUTES[i]
		var row:=HBoxContainer.new()
		parent.add_child(row)
		menu.text(row,"%s   %d" % [key.to_upper(),world.attribute(key)],17,180)
		menu.text(row,effects[i],14,420)
		menu.button(row,"+1",func(): menu.result(world.assign_attribute(key)),55)
	if world.get("journey_manager")!=null:
		var p: Dictionary=world.journey_manager.state().progress
		menu.text(parent,"Nível %d • Pontos adicionais disponíveis: %d"%[int(p.level),int(p.unspent)],16,680)
		for key in world.journey.ATTRIBUTES:
			var attribute: String=str(key)
			var extra=menu.button(parent,"USAR PONTO DE NÍVEL • "+attribute.to_upper(),func():menu.result(world.journey_manager.allocate(attribute)))
			extra.disabled=int(p.unspent)<=0
	else:
		menu.text(parent,"Seis pontos iniciais para testar a distribuição.",14,680)

func classes(parent: Node) -> void:
	menu.text(parent,"CLASSES",22).modulate=Color("d8bd81")
	var current: int=int(world.journey.data.character.path)
	menu.text(parent,world.flow.PATHS[current]+" • Caminho inicial",20)
	menu.text(parent,"Outros caminhos ainda precisam ser descobertos.",16,680)
	if not world.journey.data.claimed:return
	if world.journey.data.boon!="":
		menu.text(parent,"Bônus legado da prévia: "+str({"blade":"Lâmina","frost":"Geada","vitality":"Vigor"}.get(world.journey.data.boon,"")),16,680)
		menu.text(parent,"Benefício antigo preservado no seu personagem. A maestria das técnicas é desenvolvida por prática efetiva.",15,680)

func titles(parent: Node) -> void:
	menu.text(parent,"TÍTULOS OBTIDOS",22).modulate=Color("d8bd81")
	for value in ["Viajante","Vigia das Estradas"]:
		if value=="Vigia das Estradas" and not world.journey.data.claimed:continue
		var b: Button=menu.button(parent,value+(" • ATUAL" if world.journey.data.title==value else ""),func():
			var previous: String=world.journey.data.title
			world.journey.data.title=value
			if not world.save_progress():
				world.journey.data.title=previous
			menu.open())
		b.disabled=value=="Vigia das Estradas" and not world.journey.data.claimed
	menu.text(parent,"Títulos registram os feitos que você já realizou.",16,680)

func lineages(parent: Node) -> void:
	var race: Dictionary=Catalog.RACES[int(world.journey.data.character.race)]
	menu.text(parent,"SUA ANCESTRALIDADE",22)
	menu.text(parent,race.name,20)
	menu.text(parent,race.description,17,680)
	menu.text(parent,race.source_lore,16,680)
	menu.text(parent,"Vínculo permanente desta jornada. Os caminhos futuros ainda precisam ser descobertos.",15,680)


