extends SceneTree
const World=preload("res://main.gd")
const Catalog=preload("res://catalog.gd")
const Save=preload("res://journey_save.gd")
var w: Node3D
var passes:=0
var errors: Array[String]=[]
var lines: Array[String]=[]
func _initialize() -> void:
	call_deferred("run")
func check(value: bool,name: String) -> void:
	var line:=("OK • " if value else "FALHOU • ")+name
	print(line)
	lines.append(line)
	if value:
		passes+=1
	else:
		errors.append(name)
func find_button(node: Node,value: String) -> Button:
	if node is Button and node.text==value:
		return node
	for child in node.get_children():
		var found:=find_button(child,value)
		if found!=null:
			return found
	return null

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame
func clean_action() -> void:
	w.attack_time=-1
	w.combo_timeout=0
	w.roll_time=-1
	w.roll_cooldown=0
	w.techniques.reset()
	w.combat_timer=0
func run() -> void:
	w=World.new()
	w.load_on_start=false
	w.save_path="user://test-foundations.json"
	w.settings_path="user://test-foundations-graphics.cfg"
	root.add_child(w)
	await process_frame
	check(paused and w.ui.flow_kind=="hero","Inicializa na seleção dos 12 arquétipos")
	check(Catalog.HEROES.size()==12 and Catalog.WEAPONS.size()==16 and Catalog.RACES.size()==12 and Catalog.SKILLS.size()==16,"Catálogos completos da etapa")
	check(w.journey.valid(w.journey.data),"Novo perfil da etapa é válido")
	for i in range(12):
		var hero_button:=find_button(w.ui.flow_screen,Catalog.ELEMENTS[i])
		hero_button.pressed.emit()
		check(w.journey.data.hero==i and w.ui.preview.get_meta("weapon_id")==Catalog.HEROES[i].weapon,"Seleção pela interface do arquétipo %d"%i)
		w.flow.start_prologue()
		check(w.model.get_meta("weapon_id")==Catalog.HEROES[i].weapon,"Arquétipo %d aplica arma" % i)
		check(w.model.get_meta("race_index")==Catalog.HEROES[i].race,"Arquétipo %d aplica ancestralidade" % i)
		check(w.techniques.DATA[0].id==Catalog.HEROES[i].skills[0],"Arquétipo %d aplica técnicas" % i)
		var excludes: bool=w.enemies.size()==11
		for actor in w.enemies:
			excludes=excludes and actor.faction!=i
		check(excludes,"Arquétipo %d exclui seu elemento dos adversários" % i)
	await frames(150)
	var npc_targets:=0
	for actor in w.enemies:
		if is_instance_valid(actor.victim) and actor.victim!=w.player:
			npc_targets+=1
	check(npc_targets>0,"Facções do prólogo se enfrentam entre si")
	w.flow.begin_omen()
	w.flow.tick(8.1)
	check(paused and w.flow.phase=="story","Intervenção leva às Crônicas")
	for i in range(4):
		w.flow.advance_story()
	var profile: Dictionary=w.ui.profile.duplicate(true)
	profile.name="Fundamentos"
	profile.race=3
	profile.path=0
	profile.weapon="sword"
	profile.element=5
	check(w.flow.create_character(profile),"Criação aceita base bestial e perfil completo")
	w.ui.resume()
	await frames(12)
	check(w.model.get_meta("race_index")==3 and w.model.get_meta("anatomy_nodes").size()>0,"Anatomia bestial aplicada no mundo")
	check(w.is_safe(w.player.position),"Despertar ocorre na área protegida")
	var hp: int=w.health
	w.invulnerability=0
	check(not w.damage_player(50) and w.health==hp,"Vila bloqueia dano hostil")
	var actor: Node3D=w.enemies[0]
	actor.position=Vector3(0,.03,10)
	for i in range(90):
		actor.step(1.0/60)
	check(actor.position.z<=9.5 and actor.attack_time<0,"Inimigo não atravessa o limite da vila e interrompe ataque")
	check(actor.leashing or actor.position.distance_to(actor.home)<8,"Inimigo retorna ao território")
	actor.restore(false)
	var far:=true
	for foe in w.enemies:
		far=far and foe.home.z<0
	check(far,"Encontros começam afastados da porta")
	check(not w.ui.menu.find_children("*","Button",true,false).any(func(item):return "MAESTRIA" in item.text or "PÁTIO" in item.text),"Esc não exibe progressão ou laboratório")
	check(w.flow.begin_lab(),"Pátio de testes abre sem alterar a missão")
	await frames(8)
	w.simulation_enabled=false
	var target: Node3D=w.enemies[0]
	for weapon in Catalog.WEAPONS:
		clean_action()
		w.player.position=Vector3(90,.03,1.5)
		target.position=Vector3(90,.03,0)
		w.enemies[1].position=Vector3(100,.03,-10)
		w.enemies[2].position=Vector3(80,.03,-10)
		target.forced_velocity=Vector3.ZERO
		await frames(2)
		check(w.equip_weapon(weapon.id) and w.current_weapon().id==weapon.id and w.model.get_meta("weapon_id")==weapon.id,"Equipa "+weapon.name)
		var before: int=target.damage_total
		w.set_facing(Vector3.FORWARD)
		var started: bool=w.start_attack()
		w.model.pose(0,false,false,true)
		w.Arsenal.animate(w.model,weapon,0,.5)
		w.update_attack(w.attack_hit+.01)
		for tick in range(12):
			w.techniques.tick(1.0/60)
		check(started and target.damage_total>before,"Acerto funcional de "+weapon.name)
		check(w.model.get_meta("weapon_nodes").size()>0,"Modelo e empunhadura de "+weapon.name)
	clean_action()
	for i in range(12):
		var preview_profile: Dictionary=profile.duplicate(true)
		preview_profile.race=i
		w.flow.Wardrobe.apply(w.model,preview_profile)
		w.Anatomy.animate(w.model,1.0,4,true)
		check(w.model.get_meta("race_index")==i,"Aplica base anatômica "+Catalog.RACES[i].name)
	w.flow.apply_character()
	for skill in Catalog.SKILLS:
		clean_action()
		w.health=40
		w.player.position=Vector3(90,.03,3)
		for i in range(3):
			w.enemies[i].position=Vector3(90+(i-1)*1.2,.03,1)
			w.enemies[i].root_timer=0
			w.enemies[i].forced_velocity=Vector3.ZERO
		w.set_facing(Vector3.FORWARD)
		var ids: Array=[skill.id]
		for candidate in Catalog.SKILLS:
			if candidate.id!=skill.id and ids.size()<3:
				ids.append(candidate.id)
		w.techniques.configure(ids)
		await frames(2)
		var total_before:=0
		for foe in w.enemies:
			total_before+=foe.damage_total
		var casted: bool=w.techniques.cast(0)
		check(casted,"Conjura "+skill.name)
		if skill.kind=="leap":
			w.enemies[0].position=Vector3(91.5,.03,-1)
			w.enemies[1].position=Vector3(88.5,.03,-1)
			w.enemies[2].position=Vector3(91.5,.03,-3)
			w.simulation_enabled=true
			await frames(100)
			w.simulation_enabled=false
		else:
			for tick in range(150):
				w.techniques.tick(1.0/60)
		var total_after:=0
		for foe in w.enemies:
			total_after+=foe.damage_total
		match str(skill.kind):
			"shield":
				check(w.techniques.shield>0,"Barreira cria absorção")
				var before_hp: int=w.health
				w.invulnerability=0
				w.damage_player(9)
				check(w.health==before_hp and w.techniques.shield<35,"Barreira absorve dano recebido")
			"heal": check(w.health>40,"Cura recupera vida")
			"summon": check(w.techniques.summons.size()==1,"Invocação cria guardião temporário")
			"pull": check(total_after>total_before and w.enemies[0].forced_velocity.length()>0,"Atração causa dano e aplica força")
			"root": check(total_after>total_before and w.enemies[0].root_timer>0,"Nova imobiliza e causa dano")
			"trap": check(w.techniques.fields.size()==1 and total_after>total_before,"Campo persistente pulsa e causa dano")
			"leap": check(w.techniques.landings==1,"Salto registra pouso real")
			_: check(total_after>total_before,"Efeito de combate de "+skill.name)
	clean_action()
	w.techniques.configure(["jato_de_fogo","corte_inicial","bola_de_gelo"])
	w.set_paused(false)
	await frames(2)
	check(w.techniques.cast(0),"Canalização pode começar")
	w.techniques.tick(.4)
	w.start_dash(Vector3.RIGHT)
	check(not w.techniques.busy(),"F interrompe canalização")
	clean_action()
	w.techniques.configure(["bola_de_gelo","corte_inicial","cura"])
	w.techniques.cast(0)
	w.techniques.finish()
	w.techniques.configure(["cura","corte_inicial","bola_de_gelo"])
	check(w.techniques.cooldowns[2]>0,"Troca de espaço conserva recarga por ID")
	clean_action()
	check(w.toggle_passive("corpo_1") and w.max_health>=115,"Passiva de corpo altera vida")
	check(w.toggle_passive("concentracao_1") and not w.toggle_passive("folego_1"),"Limite de duas passivas")
	for i in range(6):
		check(w.assign_attribute("vitalidade"),"Distribui ponto de atributo %d"%i)
	check(not w.assign_attribute("forca"),"Atributos respeitam seis pontos iniciais")
	check(w.choose_path(1) and w.techniques.scaled_damage(10)==11,"Arcanista fortalece o dano das técnicas")
	w.choose_path(0)
	w.combat_timer=3
	var previous: String=w.current_weapon().id
	check(not w.equip_weapon("bow") and w.current_weapon().id==previous,"Troca de arma bloqueada em combate")
	w.combat_timer=0
	for page in ["ficha","equipamento","ativas","passivas","atributos","classes","titulos","linhagem","jornada","testes"]:
		w.ui.show_extra(false)
		w.ui.exo.open(page)
		check(w.ui.exo.visible and paused,"Menu P abre "+page)
	w.ui.exo.open("testes")
	find_button(w.ui.exo,"TESTAR Manoplas").pressed.emit()
	check(w.current_weapon().id=="gauntlets","Botão do laboratório equipa arma temporária")
	find_button(w.ui.exo,"TESTAR TÉCNICA: Cripta de Espinhos").pressed.emit()
	check(w.journey.data.loadout[0]=="cripta_espinhos_1" and w.techniques.DATA[0].id=="cripta_espinhos_1","Botão do laboratório equipa técnica temporária")
	w.ui.exo.hide()
	w.set_paused(false)
	w.flow.end_lab()
	check(w.enemies.size()==6 and w.player.position.x<30,"Pátio devolve à região e restaura inimigos")
	w.simulation_enabled=true
	w.player.position=w.npc.position+Vector3(1,0,0)
	await frames(3)
	w.flow.interact()
	check(w.journey.data.stage==1,"Contrato continua disponível")
	w.ui.resume()
	w.simulation_enabled=false
	for point in w.flow.PATROL:
		w.player.position=point
		w.flow.update_quest(0)
	for foe in w.enemies:
		if foe.uid in ["road_blade","road_mage"]:
			foe.hurt(10000,Vector3.ZERO)
	w.flow.update_quest(0)
	check(w.journey.data.stage==4,"Patrulha e combate liberam entrega")
	w.player.position=w.npc.position
	w.flow.interact()
	check(w.journey.data.coins==100 and w.journey.data.claimed,"Recompensa concedida uma vez")
	w.ui.resume()
	w.flow.interact()
	check(w.journey.data.coins==100,"Repetir conversa não duplica moedas")
	w.ui.resume()
	w.player.position=w.flow.BED
	w.flow.interact()
	check(w.journey.data.rested,"Descanso conclui primeira jornada")
	check(w.select_boon("blade") and not w.select_boon("frost"),"Bônus legado mantém compatibilidade sem nova escolha na interface")
	check(w.save_progress(),"Salva todos os fundamentos")
	var loaded:=Save.new(w.save_path)
	check(loaded.load_progress() and loaded.data.version==4,"Carrega versão atual")
	check(loaded.data.character.race_id==Catalog.RACES[3].id,"Ancestralidade conserva ID de origem do EXO")
	check(loaded.data.attributes.vitalidade==0 and loaded.data.passives.is_empty() and loaded.data.character.race==3,"Identidade persiste; alterações temporárias do laboratório são restauradas")
	var old: Dictionary=w.journey.data.duplicate(true)
	old.version=2
	old.character.race=1
	old.character.erase("race_id")
	for key in ["hero","loadout","passives","attributes","title"]+preload("res://inventory.gd").defaults().keys():
		old.erase(key)
	var upgraded: Variant=loaded.upgrade(old)
	check(loaded.valid(upgraded) and upgraded.loadout.size()==3 and upgraded.character.name==profile.name,"Migração mantém personagem da prévia 01")
	var old_path:="user://migration-foundations.json"
	FileAccess.open(old_path,FileAccess.WRITE).store_string(JSON.stringify(old))
	var migrated:=Save.new(old_path)
	check(migrated.load_progress() and FileAccess.file_exists(old_path+".pre04.json"),"Migração grava cópia do perfil anterior")
	var recovery:=Save.new("user://recovery-foundations.json")
	recovery.data=w.journey.data.duplicate(true)
	check(recovery.write() and recovery.write(),"Grava versões sucessivas válidas")
	FileAccess.open(recovery.path,FileAccess.WRITE).store_string("interrompido")
	var repaired:=Save.new(recovery.path)
	check(repaired.load_progress() and repaired.data.claimed,"Recupera cópia válida após corrupção do principal")
	for suffix in ["",".bak",".tmp",".pre04.json"]:
		DirAccess.remove_absolute(old_path+suffix)
		DirAccess.remove_absolute(recovery.path+suffix)
	var bad: Dictionary=loaded.data.duplicate(true)
	bad.character.race=12
	check(not loaded.valid(bad),"Rejeita ancestralidade fora do catálogo")
	bad=loaded.data.duplicate(true)
	bad.loadout[0]="habilidade_inexistente"
	check(not loaded.valid(bad),"Rejeita técnica desconhecida")
	for quality in range(3):
		check(w.graphics.select(quality),"Aplica perfil gráfico %d"%quality)
	var report:="EXO-MURIM 04 • REGRESSÃO\n"+"\n".join(lines)+"\n\n%d passaram / %d falharam\n" % [passes,errors.size()]
	FileAccess.open("res://test-result.txt",FileAccess.WRITE).store_string(report)
	print("RESULTADO: ",passes," passaram / ",errors.size()," falharam")
	await create_timer(.3,true,false,true).timeout
	w.audio_fx.shutdown()
	OS.delay_msec(100) # Give the independent audio mixer time to release OGG playback before headless exit.
	await create_timer(.15,true,false,true).timeout
	w.queue_free()
	await process_frame
	quit(0 if errors.is_empty() else 1)
