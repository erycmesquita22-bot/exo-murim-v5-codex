extends SceneTree
const World=preload("res://main.gd")
const Catalog=preload("res://catalog.gd")
const Save=preload("res://journey_save.gd")
var w: Node3D
var passed:=0
var failed:=0
var lines: Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok: bool,name_value: String) -> void:
	passed+=int(ok)
	failed+=int(not ok)
	var line: String=("OK " if ok else "FAIL ")+name_value
	lines.append(line)
	print(line)
func visible_text(node: Node) -> String:
	var result:=""
	if node is Label or node is Button:result+=node.text+"\n"
	for child in node.get_children():result+=visible_text(child)
	return result
func run() -> void:
	w=World.new()
	w.load_on_start=false
	w.save_path="user://discovery04.json"
	w.settings_path="user://discovery04.cfg"
	root.add_child(w)
	await process_frame
	w.simulation_enabled=false
	w.flow.start_prologue()
	w.flow.begin_omen()
	w.flow.tick(8.1)
	check(w.ui.flow_kind=="story","Crônicas abrem em tela própria")
	check(not visible_text(w.ui.flow_screen).contains("PRÓXIMA CRÔNICA"),"Crônicas não exigem botão")
	var page: int=w.flow.story_page
	w.ui.story_ready=0
	var click:=InputEventMouseButton.new()
	click.button_index=MOUSE_BUTTON_LEFT
	click.pressed=true
	w.ui._input(click)
	check(w.flow.story_page==page+1,"Clique avança Crônica")
	w.ui._input(click)
	check(w.flow.story_page==page+1,"Debounce impede salto duplo")
	w.ui.story_ready=0
	var key:=InputEventKey.new()
	key.physical_keycode=KEY_F
	key.pressed=true
	w.ui._input(key)
	check(w.flow.story_page==page+2,"Tecla de ação também avança Crônica")
	for i in range(2):w.flow.advance_story()
	w.ui.profile.weapon="spear"
	check(w.flow.create_character(w.ui.profile),"Criação permite escolher uma arma inicial")
	w.ui.resume()
	w.simulation_enabled=false
	check(w.current_weapon().id=="spear" and w.journey.data.items.size()==2,"Uma arma e consumíveis iniciais")
	check(w.journey.valid(w.journey.data),"Perfil novo valida inventário e conhecimento")
	check(not w.equip_weapon("crossbow"),"Arma não obtida bloqueada")
	check(not w.equip_skill("nova_glacial",0),"Técnica não aprendida bloqueada")
	check(not w.toggle_passive("percepcao_qi") and not w.cultivation.trajectory(),"Trajetória oculta antes de aprender percepção")
	w.ui.show_extra(false)
	w.ui.exo.open("ativas")
	check(not visible_text(w.ui.exo).contains("Nova Glacial"),"Catálogo não revela técnica desconhecida")
	w.cultivation.rumor("golpe_circular")
	w.ui.exo.open("ativas")
	w.ui.exo.selected_skill="golpe_circular"
	w.ui.exo.skill_detail()
	var words:=visible_text(w.ui.exo)
	check(words.contains("???") and words.contains("Ainda não descoberta") and not words.contains("Golpe Circular"),"Rumor mostra ??? e melhoria sem revelar nome")
	w.ui.exo.hide()
	w.set_paused(false)
	var uid: String=w.inventory.add("manual","golpe_circular")
	check(not w.inventory.title(w.inventory.find_item(uid)).contains("Golpe"),"Manual fechado não revela nome da técnica")
	check(w.inventory.use(uid) and w.cultivation.known("golpe_circular") and not w.cultivation.learned("golpe_circular"),"Ler revela conhecimento sem aprender automaticamente")
	check(not w.cultivation.BRANCHES.has("golpe_circular"),"EXO não inventa requisito de Corte Inicial para Golpe Circular")
	w.journey.data.mastery.corte_inicial=250
	check(w.cultivation.learn("golpe_circular") and w.equip_skill("golpe_circular",0),"Conhecimento permite aprender e equipar técnica sem requisito de maestria no EXO")
	uid=w.inventory.add("manual","percepcao_qi")
	w.inventory.use(uid)
	check(not w.cultivation.learn("percepcao_qi"),"Percepção exige cultivo de meditação")
	w.journey.data.meditation=120
	check(w.cultivation.learn("percepcao_qi") and w.toggle_passive("percepcao_qi") and w.cultivation.trajectory(),"Percepção aprendida habilita trajetória")
	uid=w.inventory.add("weapon","bow")
	check(w.inventory.use(uid) and w.journey.data.equipped==uid and w.current_weapon().id=="bow","Instância do inventário equipa arma")
	var hp: int=w.health
	w.health=20
	var potion: String=w.journey.data.items[1].uid
	var before_qty: int=w.journey.data.items[1].qty
	var consumed: bool=w.inventory.use(potion)
	check(consumed and w.health==mini(w.max_health,60) and w.journey.data.items[1].qty==before_qty-1,"Consumível recupera vida e reduz pilha")
	w.health=hp
	check(w.save_progress(),"Inventário e cultivo gravam")
	var restored:=Save.new(w.save_path)
	check(restored.load_progress() and restored.data.equipped==uid and restored.data.mastery.corte_inicial==250,"Inventário e maestria persistem ao carregar")
	var bad: Dictionary=restored.data.duplicate(true)
	bad.items.append(bad.items[0].duplicate(true))
	check(not restored.valid(bad),"Identificadores de itens duplicados são rejeitados")
	bad=restored.data.duplicate(true)
	bad.character.race=1
	bad.character.race_id=Catalog.RACES[1].id
	check(not restored.valid(bad),"Ancestralidade permanece vinculada ao save")
	var before: Dictionary=w.journey.data.duplicate(true)
	check(w.flow.begin_lab(),"Laboratório abre separado da progressão")
	w.inventory.test_kit()
	w.equip_weapon("crossbow")
	w.flow.end_lab()
	check(w.journey.data==before,"Laboratório restaura inventário, arma e cultivo")
	var enemy: Node3D=w.enemies[0]
	enemy.position=Vector3(0,.03,-4)
	w.enemy_defeated(enemy)
	w.enemy_defeated(enemy)
	check(w.journey.data.pending_loot.size()==1 and w.journey.data.defeated.count(enemy.uid)==1,"Derrota registra saque uma vez")
	w.player.position=enemy.position
	check(w.inventory.collect(enemy.uid) and w.journey.data.pending_loot.is_empty(),"Saque pode ser recolhido no mundo")
	check(not w.inventory.collect(enemy.uid),"Saque recolhido não duplica")
	w.player.position=Vector3(1,.03,30)
	w.combat_timer=0
	w.encounters.appear()
	check(w.journey.data.encounter.met and "percepcao_qi" in w.journey.data.known,"Encontro registra descoberta anterior sem removê-la")
	w.player.position=w.encounters.stranger.position
	w.inventory.add("material","iron",3)
	check(w.encounters.interact() and w.journey.data.encounter.done,"Encontro troca materiais por manual")
	w.ui.resume()
	w.combat_timer=0
	# Cursor rays at eight sectors converge from the actual arrow muzzle.
	var precise:=true
	for i in range(8):
		var angle:=TAU*i/8
		w.aim_offset=Vector2(cos(angle),sin(angle))*160
		w.refresh_aim_target()
		w.techniques.weapon_shot(Catalog.weapon("bow"),w.facing,10)
		var shot: Dictionary=w.techniques.projectiles.back()
		var to_target: Vector3=(w.aim_point-shot.node.global_position).normalized()
		precise=precise and shot.direction.dot(to_target)>.9999
		w.techniques.reset()
	check(precise,"Disparo converge no cursor nos oito setores")
	var original: Dictionary=w.journey.data.duplicate(true)
	while w.journey.data.items.size()<24:w.inventory.add("weapon","sword")
	check(w.inventory.add("manual","golpe_circular").is_empty() and w.journey.data.items.size()==24,"Capacidade de 24 espaços é respeitada")
	var pending: Node3D=w.enemies[1]
	pending.position=Vector3(0,.03,-7)
	w.enemy_defeated(pending)
	w.player.position=pending.position
	var pending_count: int=w.journey.data.pending_loot.size()
	check(not w.inventory.collect(pending.uid) and w.journey.data.pending_loot.size()==pending_count,"Inventário cheio preserva o saque no mundo")
	var pending_save:=Save.new(w.save_path)
	check(pending_save.load_progress() and pending_save.data.pending_loot.size()==pending_count,"Saque pendente sobrevive ao recarregamento")
	w.journey.data=original.duplicate(true)
	w.inventory.rebuild_drops()
	w.player.position=Vector3(0,.03,30)
	w.journey.data.encounter={"met":false,"done":false}
	w.encounters.clock=125
	w.encounters.check_clock=19.9
	w.encounters.attempts=2
	w.simulation_enabled=true
	w.encounters._physics_process(.2)
	w.simulation_enabled=false
	check(w.encounters.raining and w.journey.data.encounter.met,"Chuva habilita encontro natural com limite de azar")
	w.journey.data.encounter={"met":false,"done":false}
	w.encounters.clock=0
	w.encounters.check_clock=19.9
	w.encounters.attempts=2
	w.health=10
	w.simulation_enabled=true
	w.encounters._physics_process(.2)
	w.simulation_enabled=false
	check(not w.encounters.raining and w.journey.data.encounter.met,"Ferimentos graves também habilitam encontro")
	w.journey.data=original.duplicate(true)
	var report: String="\n".join(lines)+"\nDISCOVERY04: %d passaram / %d falharam"%[passed,failed]
	FileAccess.open("res://discovery-result.txt",FileAccess.WRITE).store_string(report)
	print(report.split("\n")[-1])
	w.ui.exo.hide()
	w.techniques.reset()
	await create_timer(.1,true,false,true).timeout
	w.audio_fx.shutdown()
	OS.delay_msec(100) # Give the independent audio mixer time to release OGG playback before headless exit.
	await create_timer(.15,true,false,true).timeout
	w.queue_free()
	await process_frame
	await process_frame
	quit(0 if failed==0 else 1)
