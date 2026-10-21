extends RefCounted
const Catalog=preload("res://catalog.gd")
var menu: Control
var world: Node3D
func _init(owner_menu: Control) -> void:
	menu=owner_menu
	world=menu.world

func journal(parent: Node) -> void:
	menu.text(parent,"CRÔNICAS • ECOS DA GUERRA",22).modulate=Color("d8bd81")
	menu.text(parent,world.flow.objective(),20,680)
	menu.text(parent,"Mundo %s • Seed %d • Geração v%d"%[world.journey.data.world.id,int(world.journey.data.world.seed),int(world.journey.data.world.generation_version)],13,680)
	menu.text(parent,"Exploração das ruínas: "+("Concluída" if world.journey.data.get("ruins_explored",false) else "Entre no círculo dourado ao norte após descansar")+"\nVigia dos Ecos: "+("Derrotado" if "ascendant" in world.journey.data.defeated else "Desafio opcional"),17,680)
	if world.journey.data.encounter.met:
		menu.text(parent,"Encontro do Acaso • "+("Um pergaminho foi entregue." if world.journey.data.encounter.done else "O desconhecido pediu três fragmentos de ferro das ruínas."),17,680)
	menu.text(parent,"Marcos visitados: %d / 3\nContrato entregue: %s\nAbrigo: %s\nDescanso: %s\nMeditação: %.0f s" % [world.journey.data.visits.size(),"Sim" if world.journey.data.claimed else "Não","Pousada da Guilda" if world.journey.data.lodging else "Sem residência","Concluído" if world.journey.data.rested else "Pendente",world.journey.data.meditation],17,680)
	menu.text(parent,"A Guerra do Panteão terminou, mas suas âncoras ainda prendem os reinos. As estradas e a Guilda são o começo da sua história.",16,680)
	preload("res://journey_dynamic/quest_ui_adapter.gd").render(menu,parent,world)

func laboratory(parent: Node) -> void:
	menu.text(parent,"LABORATÓRIO DA PRÉVIA",22).modulate=Color("d8bd81")
	menu.text(parent,"Área de testes sem recompensas. As bases disponíveis ainda não representam a distribuição de itens e técnicas da campanha final.",16,680)
	menu.button(parent,"VOLTAR DO PÁTIO" if world.flow.lab_mode else "ENTRAR NO PÁTIO COM ALVOS",func():
		menu.close_menu()
		if world.flow.lab_mode:
			world.flow.end_lab()
		else:
			world.flow.begin_lab())
	menu.button(parent,"REVER PRÓLOGO / ESCOLHER ENTRE OS 12 HERÓIS",func(): menu.close_menu(); world.flow.replay_prologue())
	menu.text(parent,"Rever o prólogo preserva seu personagem, missão e moedas. Ao terminar as Crônicas, você retorna à aventura.",14,680)
	if world.flow.lab_mode:
		menu.button(parent,"KIT TEMPORÁRIO: ARMAS, MANUAIS E MATERIAIS",func():
			world.inventory.test_kit()
			menu.open("inventario"))
		menu.button(parent,"CULTIVO TEMPORÁRIO: MAESTRIA E MEDITAÇÃO",func():
			for skill in Catalog.SKILLS:world.journey.data.mastery[skill.id]=250
			world.journey.data.meditation=120
			menu.open("ativas"))
		var races:=OptionButton.new()
		parent.add_child(races)
		for race in Catalog.RACES:races.add_item(race.name)
		races.select(int(world.journey.data.character.race))
		races.item_selected.connect(func(i: int): world.journey.data.character.race=i; world.journey.data.character.race_id=Catalog.RACES[i].id; world.flow.apply_character(); menu.open("testes"))
		for item in Catalog.WEAPONS:
			menu.button(parent,"TESTAR "+item.name,func(): world.equip_weapon(item.id); menu.open("testes"))
		for item in Catalog.SKILLS:
			menu.button(parent,"TESTAR TÉCNICA: "+item.name,func(): world.equip_skill(item.id,0); menu.open("testes"))
	if world.flow.lab_mode:
		menu.button(parent,"SIMULAR ENCONTRO DO ACASO NO PÁTIO",func():
			menu.close_menu()
			world.journey.data.encounter={"met":false,"done":false}
			world.encounters.appear()
			world.encounters.stranger.position=world.player.position+Vector3(2,0,0)
			world.inventory.add("material","iron",3))
	var duel: Button=menu.button(parent,"REPETIR DUELO COM O VIGIA",func(): menu.close_menu(); world.flow.end_lab() if world.flow.lab_mode else null; world.begin_trial())
	duel.disabled=not world.journey.data.claimed
	menu.button(parent,"VOLTAR AO MARCO DA ALDEIA",func(): menu.close_menu(); world.flow.end_lab() if world.flow.lab_mode else null; world.resume_checkpoint())
	var fresh: Button=menu.button(parent,"CONFIRMAR: APAGAR JORNADA E ESCOLHER HERÓI?" if menu.new_confirm else "NOVA JORNADA / 12 ARQUÉTIPOS",func():
		if menu.new_confirm:
			menu.hide()
			world.flow.end_lab() if world.flow.lab_mode else null
			world.new_journey()
		else:
			menu.new_confirm=true
			menu.open())
	fresh.modulate=Color("d8ad80")
	menu.text(parent,"Nova jornada limpa o personagem e os objetivos deste perfil, mantendo os gráficos. A confirmação acima evita reinício acidental.",14,680)

