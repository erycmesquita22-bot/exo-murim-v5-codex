extends SceneTree
# Reproducible engine-controlled play sequence. Fixtures are identified below; this is not a human playtest.
var w: Node3D
var passed:=0
var failed:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	passed+=int(ok);failed+=int(not ok);print(("OK " if ok else "FAIL ")+label)
func frames(n: int) -> void:
	for i in range(n):await process_frame
func shot(name_value: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://evidencias/"+name_value+".png")
func tap(action: String) -> void:
	Input.action_press(action);await frames(2);Input.action_release(action)
func run() -> void:
	root.size=Vector2i(960,600)
	w=load("res://main.gd").new();w.load_on_start=false;w.save_path="user://playable09.json";w.settings_path="user://playable09.cfg";root.add_child(w);await process_frame
	w.graphics.select(1);w.graphics.shake_enabled=false
	w.flow.phase="creator";w.flow.create_character({"name":"Validação 09","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0});w.ui.resume()
	for actor in w.enemies:actor.enabled=false
	w.player.position=Vector3(0,.03,28);w.camera.size=34;w.message("09 • vila com acessos orientados e sombras pintadas")
	await frames(15);await shot("vila-completa");w.camera.size=15
	var origin: Vector3=w.player.position
	Input.action_press("right");await frames(15);await shot("personagem-caminhada");await frames(10);Input.action_release("right");await frames(8)
	check(w.player.position.distance_to(origin)>.8,"Movimento por entrada real com física e animação")
	origin=w.player.position
	Input.action_press("left");Input.action_press("sprint");await frames(10);await shot("personagem-corrida");await frames(10);Input.action_release("left");Input.action_release("sprint");await frames(8)
	check(w.player.position.distance_to(origin)>1,"Corrida por entrada real")
	await tap("jump");await frames(8);await shot("personagem-salto")
	check(w.player.position.y>.3,"Salto se afasta do solo")
	await frames(40);await tap("dash");await frames(6);await shot("personagem-esquiva");await frames(26)
	check(w.dodges>0 and "evade" in w.audio_fx.history,"Esquiva executada com seu próprio áudio")
	# Fixture: stationary training dummy at the attacker's front, with high HP to check the combo.
	w.player.position=Vector3(0,.03,28);w.player.velocity=Vector3.ZERO;w.set_facing(Vector3.FORWARD)
	var target: Node3D=load("res://training_target.gd").new();target.setup(w,"validation_target","blade",Vector3(0,.03,26.65));w.add_child(target);target.max_hp=1000;target.hp=1000;w.enemies.append(target)
	await frames(5)
	for i in range(3):
		await tap("attack");await frames(10);await shot("personagem-espada");await frames(30)
	check(target.damage_total>20,"Ataques atingem alvo na cena, com dano e animação")
	check("swing" in w.audio_fx.history and "blade_hit" in w.audio_fx.history,"Som de espada e contato com alvo acolchoado acionados pelo combate")
	await tap("skill_2");await frames(48)
	check("gelo" in w.audio_fx.history and "skill_windup" in w.audio_fx.history,"Conjuração e gelo acionados pela habilidade equipada")
	# Fixture: load one existing arcane skill to exercise its real cast controller and audio route.
	w.techniques.reset();w.techniques.configure(["dardo_arcano"])
	await tap("skill_1");await frames(45)
	check("qi" in w.audio_fx.history,"Técnica arcana usa ressonância de Qi, separada da esquiva")
	await shot("combate-personagem09")
	w.combat_timer=0;w.techniques.reset();w.attack_time=-1;w.roll_time=-1
	# Fixture: a valid existing stage-5 save, at the approach to the already repaired ruins quest.
	var d: Dictionary=w.journey.data
	d.stage=5;d.claimed=true;d.coins=100;d.lodging=true;d.rested=true;d.visits=[0,1,2];d.defeated=["road_blade","road_mage"]
	check(w.journey.valid(d),"Pré-condições do save de ruínas são válidas")
	w.player.position=Vector3(0,.03,-26.5);w.player.velocity=Vector3.ZERO;w.camera.size=15
	await frames(4);await shot("ruinas-antes")
	Input.action_press("up");Input.action_press("right");await frames(40);Input.action_release("up");Input.action_release("right");await frames(5)
	check(d.ruins_explored,"Exploração conclui durante caminhada física, sem chamar update_quest manualmente")
	check(not w.flow.ruin_marker.visible,"Marcador desaparece após conclusão")
	await shot("ruinas-concluidas")
	check(w.save_progress(),"Estado concluído salvo")
	var save=load("res://journey_save.gd").new(w.save_path)
	check(save.load_progress() and save.data.ruins_explored and save.data.items.size()==d.items.size(),"Recarga preserva missão e inventário")
	w.ui.show_extra(false);w.ui.exo.open("inventario");await frames(5);await shot("inventario");w.ui.exo.open("config");await frames(5);await shot("configuracoes")
	check(w.ui.exo.find_children("PageSurface","PanelContainer",true,false).size()==1 and not w.ui.menu.visible,"Menu mantém uma única superfície durante a navegação")
	w.ui.exo.close_menu();await frames(8)

	w.player.position=w.flow.MAT+Vector3(.8,0,0);w.player.velocity=Vector3.ZERO;w.combat_timer=0;w.attack_time=-1;w.roll_time=-1;w.techniques.reset()
	await frames(8);await tap("interact");await frames(100)
	check(w.flow.meditating and w.activity.blend>.99,"Meditação acionada por E chega ao assento")
	w.simulation_enabled=false;w.camera.size=5.8;w.camera.position=w.player.position+Vector3(16,12,-21);w.camera.look_at(w.player.position+Vector3.UP*.7)
	await frames(3);await shot("meditacao09-final")
	w.simulation_enabled=true;await tap("interact");await frames(25)
	check(not w.flow.meditating and w.activity.blend<.01,"E levanta suavemente")
	w.simulation_enabled=false;w.camera.position=w.player.position+Vector3(16,12,-21);w.camera.look_at(w.player.position+Vector3.UP)
	await frames(3);await shot("personagem09-final");w.simulation_enabled=true
	print("PLAYABLE09_JSON ",JSON.stringify({"passed":passed,"failed":failed,"dummy_damage":target.damage_total,"ruins_explored":d.ruins_explored,"audio_events":w.audio_fx.history,"method":"Godot rendered sequence with input injection; fixture stage5 and stationary dummy; no human playtest"}))
	w.audio_fx.shutdown();w.queue_free();await frames(3);quit(int(failed>0))
