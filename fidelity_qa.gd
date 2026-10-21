extends SceneTree
const World=preload("res://main.gd")
const Catalog=preload("res://catalog.gd")
const Save=preload("res://journey_save.gd")
const Graphics=preload("res://graphics.gd")
var w: Node3D
var passed:=0
var failed:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	passed+=int(ok);failed+=int(not ok)
	print(("OK " if ok else "FAIL ")+label)
func words(node: Node) -> String:
	var result:=""
	if node is Label or node is Button:result+=node.text+"\n"
	for child in node.get_children():result+=words(child)
	return result
func find_button(node: Node,value: String) -> Button:
	if node is Button and node.text==value:return node
	for child in node.get_children():
		var found:=find_button(child,value)
		if found:return found
	return null
func run() -> void:
	w=World.new();w.load_on_start=false
	w.save_path="user://fidelity05-test.json";w.settings_path="user://fidelity05-test.cfg"
	root.add_child(w)
	await process_frame
	w.flow.start_prologue();w.flow.begin_omen();w.flow.tick(8.1)
	for i in range(4):w.flow.advance_story()
	w.flow.create_character(w.ui.profile);w.ui.resume();w.simulation_enabled=false
	w.ui.show_extra(false)
	check(w.ui.exo.page=="central" and words(w.ui.exo).contains("CENTRAL DO AVENTUREIRO"),"P entra na Central atual")
	for section in range(6):
		w.ui.exo.open("central_%d"%section)
		check(w.ui.exo.shell.group==section,"Categoria %d constrói navegação e cartões"%section)
	w.ui.exo.open("ativas")
	var button:=find_button(w.ui.exo.list_box,"Bola de Gelo")
	button.pressed.emit()
	check(w.ui.exo.selected_skill=="bola_de_gelo" and words(w.ui.exo.detail_box).begins_with("Bola de Gelo"),"Seleção e detalhe permanecem sincronizados")
	check(find_button(w.ui.exo.list_box,"Bola de Gelo").modulate==Color("d8bd81"),"Seleção tem destaque explícito")
	w.ui.exo.open("classes")
	check(not words(w.ui.exo).contains("MAESTRIA DA PRIMEIRA JORNADA"),"Bônus provisório removido da escolha de maestria")
	w.ui.exo.close_menu();w.ui.resume()
	var d: Dictionary=w.journey.data
	w.health=w.max_health
	for actor in w.enemies:actor.position=Vector3(100,0,100)
	d.mastery.corte_inicial=55
	check(w.cultivation.grade("corte_inicial")==0,"Domínio respeita passo original antes do limite")
	d.mastery.corte_inicial=56
	check(w.cultivation.grade("corte_inicial")==1,"Domínio usa passo 56 do Corte Inicial no EXO")
	var base: Dictionary=Catalog.skill("corte_inicial")
	var effective: Dictionary=w.cultivation.stats(base)
	check(is_equal_approx(effective.damage,base.damage*1.06) and is_equal_approx(effective.cooldown,base.cooldown*.988),"Grau modifica dano e recarga pelas curvas do EXO")
	check(effective.stamina==ceilf(base.stamina*.992),"Redução de custo respeita arredondamento")
	d.mastery.corte_inicial=100000
	check(w.cultivation.grade("corte_inicial")==int(w.cultivation.rules.actives.corte_inicial.maxMasteryRank),"Domínio respeita limite por técnica")
	d.mastery.corte_inicial=0
	w.cultivation.practice("corte_inicial")
	check(d.mastery.corte_inicial==0,"Liberação vazia não dá maestria")
	w.techniques.reset();w.techniques.configure(["corte_inicial","bola_de_gelo","salto_impetuoso"])
	w.techniques.cast(0);w.techniques.tick(1)
	check(int(d.mastery.corte_inicial)==0,"Execução real sem inimigo não dá maestria")
	w.techniques.reset()
	var data: Dictionary=base.duplicate(true);data._cast=1001
	w.cultivation.credit(data);w.cultivation.credit(data)
	check(d.mastery.corte_inicial==1,"Múltiplos impactos do mesmo lançamento creditam uma vez")
	data._cast=1002;w.cultivation.credit(data)
	check(d.mastery.corte_inicial==2,"Novo lançamento válido permite novo crédito")
	data._cast=0;w.cultivation.credit(data)
	check(d.mastery.corte_inicial==2,"Ataque sem identidade de técnica não credita")
	w.health=int(w.max_health*.2)
	data._cast=1003;w.cultivation.credit(data)
	check(d.mastery_fraction.corte_inicial==250,"Bônus de dificuldade conserva fração de prática")
	check(w.save_progress(),"Maestria e frações salvam")
	var restored:=Save.new(w.save_path)
	check(restored.load_progress() and restored.data.mastery_fraction.corte_inicial==250,"Frações persistem ao recarregar")
	var invalid: Dictionary=d.duplicate(true);invalid.mastery_fraction.corte_inicial=1000
	check(not restored.valid(invalid),"Save rejeita fração fora do intervalo")
	check(not w.cultivation.BRANCHES.has("golpe_circular"),"Sem requisito inventado de Corte para Golpe Circular")
	check(w.cultivation.BRANCHES.nova_glacial.parent=="lanca_de_gelo" and w.cultivation.BRANCHES.nova_glacial.mastery==120,"Nova Glacial usa origem e requisito reais")
	w.health=w.max_health
	w.cultivation.reveal("cura");w.cultivation.learn("cura")
	w.techniques.reset();w.techniques.configure(["cura","bola_de_gelo","salto_impetuoso"])
	var old: int=int(d.mastery.get("cura",0))
	w.techniques.cast(0);w.techniques.tick(2)
	check(int(d.mastery.get("cura",0))==old,"Cura sem vida faltando não dá prática")
	w.techniques.reset();w.health=w.max_health-20
	w.techniques.cast(0);w.techniques.tick(2)
	check(int(d.mastery.get("cura",0))==old+1,"Cura efetiva concede prática")
	w.techniques.reset();w.health=w.max_health;w.combat_timer=0
	var before: Dictionary=d.duplicate(true)
	w.flow.begin_lab();data._cast=2000;w.cultivation.credit(data)
	check(w.journey.data.mastery==before.mastery,"Laboratório não concede maestria da campanha")
	w.Arsenal.equip(w.model,"gauntlets")
	var elbows: Array=w.model.get_meta("fist_forearms")
	check(elbows.size()==2 and elbows[0].get_parent()==w.model.arms[0],"Manoplas possuem cotovelos articulados ligados ao braço")
	w.model.pose(0,false,false,true);w.Arsenal.fist_pose(w.model,0,-1)
	var guard: Vector3=elbows[0].to_global(Vector3(0,-.4,0))
	w.Arsenal.fist_pose(w.model,0,.43)
	var extended: Vector3=elbows[0].to_global(Vector3(0,-.4,0))
	check(w.model.to_local(extended).z<w.model.to_local(guard).z-.15 and elbows[0].rotation.x<.01,"Jab estende cotovelo na direção do golpe")
	check(w.model.legs[0].rotation==Vector3.ZERO and absf(w.model.torso.rotation.y)<=.25,"Soco mantém base estável sem giro de dança")
	w.Arsenal.fist_pose(w.model,1,.43)
	check(elbows[1].rotation.x<.01 and elbows[0].rotation.x>1,"Direto alterna mão e mantém outra em guarda")
	w.Arsenal.equip(w.model,"sword")
	check(w.model.arms[0].get_child(0).visible and w.model.get_meta("fist_forearms").is_empty(),"Troca de arma restaura braços originais")
	w.flow.end_lab()
	var complete:=true
	for event in w.audio_fx.BANK:
		for filename in w.audio_fx.BANK[event]:complete=complete and w.audio_fx.cache.has(filename)
	check(complete,"Todos os eventos sonoros resolvem os arquivos declarados")
	check(w.audio_fx.voices.size()==20,"Pool de vozes é limitado")
	var volumes: Dictionary=w.audio_fx.groups.duplicate()
	w.audio_fx.groups={"master":1.0,"combat":1.0,"magic":1.0,"ui":1.0}
	w.audio_fx.recent.clear()
	w.audio_fx.play_event("hit");w.audio_fx.play_event("fogo","magic")
	var simultaneous:=0
	for voice in w.audio_fx.voices:simultaneous+=int(voice.playing)
	check(simultaneous>=2,"Impacto e técnica podem soar simultaneamente")
	w.audio_fx.select_volume("combat",.2)
	var adjusted:=false
	for voice in w.audio_fx.voices:
		if voice.playing and voice.get_meta("group","")=="combat":adjusted=voice.volume_db<-13
	check(adjusted,"Volume ajusta camadas já em reprodução")
	check(AudioServer.get_bus_effect_count(AudioServer.get_bus_index("EXO"))==1,"Barramento sonoro limita picos")
	for key in volumes:w.audio_fx.select_volume(key,volumes[key])
	w.graphics.menu_style=3;w.graphics.hud.style=9;w.graphics.hud.scale=1.25
	w.graphics.save_settings()
	var graphics=Graphics.new(w,w.settings_path)
	check(graphics.menu_style==3 and graphics.hud.style==9 and graphics.hud.scale==1.25,"Menu e preferências do HUD persistem")
	check(w.ui.exo_hud.STYLES.size()==10 and w.ui.exo_hud.THEMES.size()==7 and w.ui.exo_hud.ANCHORS.size()==9,"Catálogo de apresentação acompanha HUD atual do EXO")
	print("FIDELITY05: %d passaram / %d falharam"%[passed,failed])
	w.techniques.reset()
	w.audio_fx.shutdown()
	OS.delay_msec(100) # Give the independent audio mixer time to release OGG playback before headless exit.
	await create_timer(.15,true,false,true).timeout
	w.queue_free()
	await process_frame
	await process_frame
	quit(int(failed>0))
