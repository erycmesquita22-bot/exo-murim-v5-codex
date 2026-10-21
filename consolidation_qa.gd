extends SceneTree
const World=preload("res://main.gd")
const Catalog=preload("res://catalog.gd")
const Rules=preload("res://world/event_rules.gd")
var w: Node3D
var passed:=0
var failed:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,title: String) -> void:
	passed+=int(ok);failed+=int(not ok);print(("OK " if ok else "FAIL ")+title)
func words(node: Node) -> String:
	var result:=""
	if node is Label or node is Button:result+=node.text+"\n"
	for child in node.get_children():result+=words(child)
	return result
func run() -> void:
	w=World.new();w.load_on_start=false;w.save_path="user://consolidation06.json";w.settings_path="user://consolidation06.cfg"
	root.add_child(w);await process_frame
	w.simulation_enabled=false
	w.ui.show_start_settings();await process_frame
	check(w.ui.exo.visible and w.ui.exo.page=="config","Configuração inicial abre sem exigir personagem criado")
	check(w.ui.exo.shell.nav_buttons[0].disabled and not w.ui.exo.shell.nav_buttons[4].disabled,"Antes da criação só as configurações são navegáveis")
	w.ui.exo.close_menu()
	check(w.ui.flow_kind=="hero" and paused,"Voltar da configuração retorna à seleção")
	w.flow.start_prologue();w.flow.begin_omen();w.flow.tick(8.1)
	for i in range(4):w.flow.advance_story()
	for step in range(3):
		w.ui.creation_tab=step;w.ui.show_creator();await process_frame
		check(w.ui.flow_kind=="creator" and is_instance_valid(w.ui.preview_root),"Criação etapa %d possui prévia atual"%step)
	w.flow.create_character(w.ui.profile);w.ui.resume();w.simulation_enabled=false
	w.ui.show_extra(false);await process_frame
	var shell_id: int=w.ui.exo.shell.get_instance_id()
	var surface: Node=w.ui.exo.shell.body.get_parent().get_parent()
	for page in ["ficha","ativas","passivas","inventario","equipamento","atributos","linhagem","classes","titulos","jornada","mapa","config","audio","hud","controles","ajuda","testes","central"]:
		w.ui.exo.open(page);await process_frame
		check(w.ui.exo.shell.get_instance_id()==shell_id and w.ui.exo.shell.body.get_parent().get_parent()==surface and w.ui.exo.find_children("PageSurface","PanelContainer",true,false).size()==1,"Uma única estrutura de menu: "+page)
	check(not w.ui.exo.shell.nav_buttons[0].disabled,"Categorias habilitadas após a criação")
	var tab:=InputEventKey.new();tab.physical_keycode=KEY_TAB;tab.pressed=true
	w.ui._input(tab)
	check(w.ui.exo.page=="mapa" and w.ui.exo.shell.get_instance_id()==shell_id,"Tab utiliza a mesma estrutura de navegação")
	w.ui._input(tab)
	check(not w.ui.exo.visible and not paused,"Tab no mapa retorna à jornada")
	w.ui.show_extra(false)
	check(not words(w.ui.exo).contains("PERSONAGEM / PRIMEIRO ECO"),"Cabeçalho duplicado do menu antigo removido")
	check(not FileAccess.file_exists("res://legacy_ui.gd") and not FileAccess.file_exists("res://central_menu.gd"),"Implementações sobrepostas antigas retiradas")
	w.graphics.select(0);w.ui.exo.open("central");await process_frame
	var stage: Control=w.ui.preview_root
	stage.update_resolution();var low: Vector2i=stage.viewport.size
	w.graphics.select(3);stage.update_resolution();var high: Vector2i=stage.viewport.size
	check(high.x==low.x*2 and high.y==low.y*2,"Alto renderiza quatro vezes os pixels da prévia Mínimo")
	check(stage.viewport.msaa_3d==Viewport.MSAA_4X and w.get_viewport().msaa_3d==Viewport.MSAA_4X,"Alto aplica AA no mundo e nas prévias")
	var before: float=stage.rig.rotation.y
	var press:=InputEventMouseButton.new();press.button_index=MOUSE_BUTTON_LEFT;press.pressed=true;stage._gui_input(press)
	var move:=InputEventMouseMotion.new();move.relative=Vector2(20,0);stage._gui_input(move)
	check(not is_equal_approx(stage.rig.rotation.y,before),"Arraste gira o modelo renderizado")
	var mesh: MeshInstance3D=w.model.torso.get_child(0)
	var normals: PackedVector3Array=mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	check(normals[0].dot(Vector3.FORWARD)>.9999 and normals[6].dot(Vector3.BACK)>.9999 and normals[24].dot(Vector3.UP)>.9999,"Normais explícitas eliminam interpolação diagonal nos cubos")
	check(Catalog.SKILLS.size()==16 and Catalog.WEAPONS.size()==16 and Catalog.RACES.size()==12,"Catálogos externos preservam todos os representantes")
	var event: Dictionary=w.encounters.event
	check(Rules.eligible(event,{"safe":true,"already_met":false,"weather":"rain","health_ratio":1.0}),"Regra de encontro aceita chuva por dados")
	check(Rules.eligible(event,{"safe":true,"already_met":false,"weather":"dry","health_ratio":.19}),"Regra de encontro aceita ferimento por dados")
	check(not Rules.eligible(event,{"safe":false,"already_met":false,"weather":"rain","health_ratio":.1}),"Regra de encontro exige aldeia segura")
	check(not Rules.eligible(event,{"safe":true,"already_met":true,"weather":"rain","health_ratio":.1}),"Encontro já conhecido não é sorteado de novo")
	w.ui.exo.close_menu();w.combat_timer=0;w.attack_time=-1;w.roll_time=-1;w.techniques.reset()
	for actor in w.enemies:actor.position=Vector3(100,0,100)
	w.audio_fx.recent.clear();w.audio_fx.history.clear()
	w.start_attack();w.update_attack(.01)
	check(w.audio_fx.history.is_empty(),"Clique não emite impacto nem antecipação fora da janela")
	w.update_attack(w.attack_hit+.01)
	check("swing" in w.audio_fx.history and "body_hit" not in w.audio_fx.history,"Golpe no vazio produz só deslocamento no ar")
	w.attack_time=-1;w.combat_timer=0
	w.audio_fx.recent.clear();w.audio_fx.impact("body",{"family":"fists"})
	check(w.audio_fx.history.back()=="fist_hit","Soco contra corpo usa gravação de impacto físico")
	w.audio_fx.recent.clear();w.audio_fx.impact("wood",{"family":"fists"})
	check(w.audio_fx.history.back()=="wood_hit","Alvo de madeira usa material próprio")
	w.audio_fx.recent.clear();w.audio_fx.impact("metal",{})
	check(w.audio_fx.history.back()=="metal_hit","Contato metálico usa material próprio")
	check(w.audio_fx.BANK.swing[0].begins_with("martial_audio/") and w.audio_fx.BANK.gelo[0].begins_with("martial_audio/"),"Golpes e técnicas usam referências de áudio registradas")
	w.attack_time=-1;w.techniques.reset();w.combat_timer=0
	w.flow.begin_lab();w.audio_fx.recent.clear()
	w.enemies[0].hurt(10,Vector3.ZERO,0,{"family":"fists"})
	check(w.audio_fx.history.back()=="fist_hit","Poste acolchoado usa som de soco sem estalo de madeira")
	check(not w.enemies[0].rig.visible,"Alvo de treino tem representação acolchoada própria")
	w.flow.end_lab();w.combat_timer=0
	var saved: Dictionary=w.journey.data.duplicate(true)
	w.journey.data.known.append("dardo_arcano");w.journey.data.learned.append("dardo_arcano");w.journey.data.loadout.append("dardo_arcano")
	w.techniques.configure(w.journey.data.loadout);w.techniques.reset()
	check(w.techniques.DATA.size()==4 and w.techniques.cooldowns.size()==4,"Executor e reset aceitam quarto espaço sem constante espalhada")
	check(w.journey.valid(w.journey.data),"Validação do save aceita capacidade ampliada prevista")
	check(w.techniques.cast(3),"Quarto espaço executa técnica no mesmo sistema")
	w.techniques.tick(.1);w.techniques.reset();w.journey.data=saved;w.techniques.configure(saved.loadout)
	w.audio_fx.shutdown();OS.delay_msec(100)
	w.queue_free();await process_frame;await process_frame
	print("CONSOLIDATION06: %d passaram / %d falharam"%[passed,failed])
	quit(int(failed>0))
