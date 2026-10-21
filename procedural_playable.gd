extends SceneTree
# Engine input replay, not human playtesting. Enemy health/AI and target are controlled fixtures.
const Seed=preload("res://procedural/world_state.gd")
const Loot=preload("res://procedural/loot_generator.gd")
var w: Node3D
var passed:=0
var failed:=0
var reload_mode:=false
func _initialize() -> void:call_deferred("run")
func frames(n: int) -> void:
	for i in range(n):await process_frame
func check(ok: bool,label: String) -> void:
	passed+=int(ok);failed+=int(not ok);print(("OK " if ok else "FAIL ")+label)
func tap(action: String) -> void:
	Input.action_press(action);await frames(2);Input.action_release(action)
func shot(label_value: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://evidencias/092-"+label_value+".png")
func button(node: Node,text_value: String) -> Button:
	if node is Button and node.text==text_value:return node
	for child in node.get_children():
		var found:=button(child,text_value)
		if found:return found
	return null
func words(node: Node) -> String:
	var result:=""
	if node is Label or node is Button:result+=node.text+"\n"
	for child in node.get_children():result+=words(child)
	return result
func run() -> void:
	root.size=Vector2i(1152,720);reload_mode="reload" in OS.get_cmdline_user_args()
	w=load("res://main.gd").new();w.load_on_start=reload_mode;w.save_path="user://demo092-restart.json";w.settings_path="user://demo092-restart.cfg"
	root.add_child(w);await process_frame
	w.graphics.select(1);w.graphics.shake_enabled=false
	for actor in w.enemies:actor.enabled=false
	if reload_mode:
		var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://demo092-expected.json"))
		check(w.flow.phase=="adventure","Novo processo abriu a aventura salva")
		check(w.journey.data.world.id==expected.world.id and w.journey.data.world.seed==expected.world.seed,"Novo processo preserva seed e identidade")
		var actual: Dictionary=w.inventory.find_item(expected.item.uid)
		check(actual==expected.item and w.journey.data.equipped==actual.uid,"Novo processo preserva item completo e equipado")
		check(w.journey.data.pending_loot.is_empty() and not w.inventory.collect("road_blade"),"Saque recolhido não reaparece após encerrar a engine")
		w.ui.resume();w.player.position=Vector3(0,.03,28);await frames(12)
		w.ui.show_extra(false);w.ui.exo.selected_item=actual.uid;w.ui.exo.open("inventario");await frames(12);await shot("reaberto")
		await frames(25);w.ui.exo.close_menu();await frames(5)
		w.techniques.reset();w.player.position=Vector3(0,.03,-5);w.player.velocity=Vector3.ZERO;w.set_facing(Vector3.FORWARD);await frames(8)
		w.audio_fx.history.clear();w.message("Salto Impetuoso • assinatura original EXO Visual");await tap("skill_3");await frames(12);await shot("salto-voo");await frames(40);await shot("salto-pouso")
		check(w.techniques.landings==1 and "exo_salto_cast" in w.audio_fx.history and "exo_salto_impact" in w.audio_fx.history,"Salto renderizado reproduz saída e pouso originais")
	else:
		# Find and display an explicit seed for a reproducible two-affix sword drop.
		var chosen:=0
		for candidate in range(10000):
			var sample:=Loot.generate(Seed.create(candidate,"world_demo"),"loot/road_blade","blade",1,"item_3")
			if sample.ref=="sword" and sample.affixes.size()==2:chosen=candidate;break
		w.flow.phase="creator";w.ui.creation_tab=2;w.ui.profile.name="Legado Procedural";w.ui.procedural_seed=str(chosen);w.ui.show_creator();await frames(30);await shot("seed")
		button(w.ui.flow_screen,"DESPERTAR NA ALDEIA").pressed.emit();await frames(5);w.ui.resume()
		check(w.flow.phase=="adventure" and w.journey.data.world.seed==chosen,"Seed definida pela criação existente inicia o mundo")
		var enemy: Node3D=w.enemies[0];enemy.hp=1;enemy.position=Vector3(0,.03,-6.3);enemy.home=enemy.position
		w.player.position=Vector3(0,.03,-5);w.player.velocity=Vector3.ZERO;w.set_facing(Vector3.FORWARD);await frames(12)
		w.message("09.2 • ataque real; alvo controlado com 1 PV");await tap("attack");await frames(22)
		check(enemy.hp==0 and w.journey.data.pending_loot.size()==1,"Ataque por entrada real derrota e cria saque")
		await shot("saque");await frames(15);w.player.position=Vector3(0,.03,-6.1);await frames(8);await tap("interact");await frames(8)
		var generated: Dictionary={}
		for item in w.journey.data.items:
			if item.has("generation"):generated=item
		check(not generated.is_empty() and w.journey.data.pending_loot.is_empty(),"E recolhe o equipamento procedural materializado")
		w.player.position=Vector3(0,.03,28);w.player.velocity=Vector3.ZERO;w.combat_timer=0;await frames(8)
		w.ui.show_extra(false);w.ui.exo.selected_item=generated.uid;w.ui.exo.open("inventario");await frames(65);await shot("inventario-antes")
		check(words(w.ui.exo).contains(Loot.title(generated)) and words(w.ui.exo).contains("dano da arma"),"Interface existente exibe nome, raridade e atributos funcionais")
		var equip:=button(w.ui.exo,"EQUIPAR");check(equip!=null,"Inventário oferece ação real de equipar")
		if equip:equip.pressed.emit()
		await frames(30);await shot("equipado");w.ui.exo.close_menu();await frames(5)
		check(w.journey.data.equipped==generated.uid and w.current_weapon().damage>w.Catalog.weapon(generated.ref).damage,"Botão equipa o item com dano alterado")
		# Existing reusable dummy: compare actual hit result to the same weapon's base in the combat formula.
		w.set_facing(Vector3.FORWARD)
		var target: Node3D=load("res://training_target.gd").new();target.setup(w,"qa092_dummy","blade",Vector3(0,.03,26.5));w.add_child(target);w.enemies.append(target);target.hp=1000;target.max_hp=1000
		await frames(5);await tap("attack");await frames(25)
		var plain_damage:=roundi(float(w.Catalog.weapon(generated.ref).damage)*w.basic_multiplier())
		check(target.damage_total>plain_damage,"Acerto do item gerado supera dano do mesmo equipamento-base")
		w.message("Dano no alvo: %d • base equivalente: %d"%[target.damage_total,plain_damage]);await shot("dano");await frames(10)
		check(w.save_progress(),"Partida grava antes de encerrar o processo")
		FileAccess.open("user://demo092-expected.json",FileAccess.WRITE).store_string(JSON.stringify({"world":w.journey.data.world,"item":generated}))
	print("PLAYABLE092 ",JSON.stringify({"mode":"reload" if reload_mode else "write","passed":passed,"failed":failed,"method":"Godot rendered input replay; stationary 1HP enemy and training dummy; no human playtest"}))
	w.audio_fx.shutdown();await frames(3);w.queue_free();await frames(4);w=null;quit(int(failed>0))
