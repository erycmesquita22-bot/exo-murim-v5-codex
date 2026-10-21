extends SceneTree
var w: Node3D
var passed:=0
var failed:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	passed+=int(ok);failed+=int(not ok);print(("OK " if ok else "FAIL ")+label)
func ticks(n: int) -> void:
	for i in range(n):await physics_frame
func tap(action: String) -> void:
	Input.action_press(action);await ticks(2);Input.action_release(action);await ticks(2)
func run() -> void:
	w=load("res://main.gd").new();w.load_on_start=false;w.save_path="user://martial091.json";w.settings_path="user://martial091.cfg";root.add_child(w);await process_frame
	w.flow.phase="creator";w.flow.create_character({"name":"Marcial QA","race":0,"path":0,"robe":0,"hair":0,"skin":0,"style":0});w.ui.resume()
	for actor in w.enemies:actor.enabled=false
	w.player.position=Vector3(0,.03,28);await ticks(18)
	check(w.martial.stowed() and w.model.get_meta("stow_weight",0)>.95,"Espada fica embainhada fora de combate")
	var sheath: Node3D=w.model.get_meta("carry_sheath")
	check(sheath.get_child(0).is_visible_in_tree(),"Bainha real permanece visível no personagem de referência")
	var initial: Node3D=w.Rig.new();w.add_child(initial)
	preload("res://wardrobe.gd").apply(initial,{"name":"Manoplas iniciais","race":0,"path":2,"robe":0,"hair":0,"skin":0,"style":0,"weapon":"gauntlets"})
	await ticks(2)
	var shells:=0
	for part in initial.find_children("*","MeshInstance3D",true,false):
		if part.get_meta("gauntlet_shell",false) and part.is_visible_in_tree():shells+=1
	check(shells==4,"Criar personagem com Manoplas preserva as duas luvas visíveis")
	initial.queue_free();await ticks(2)
	var equipped: String=w.journey.data.equipped;var count: int=w.journey.data.items.size()
	await tap("toggle_hands");await ticks(15)
	check(w.current_weapon().id=="unarmed" and w.martial.bare(),"R ativa mãos livres sem exigir outro item")
	check(w.journey.data.equipped==equipped and w.journey.data.items.size()==count,"Guardar não remove, duplica ou troca o equipamento")
	check(w.save_progress(),"Estado desarmado salva")
	var save=load("res://journey_save.gd").new(w.save_path)
	check(save.load_progress() and save.data.character.hands_free and save.data.equipped==equipped,"Recarga preserva mãos livres e arma carregada")
	w.journey.data.character.hands_free=false
	check(w.journey.load_progress(),"Save é relido pelo mundo em execução")
	w.resume_checkpoint();await ticks(4)
	for actor in w.enemies:actor.enabled=false
	check(w.current_weapon().id=="unarmed" and w.martial.bare(),"Retomada real aplica o estado desarmado salvo")
	Input.action_press("up");await ticks(10);var q1: Quaternion=w.model.arms[0].quaternion;await ticks(9);var q2: Quaternion=w.model.arms[0].quaternion
	check(q1.angle_to(q2)>.04,"Caminhada desarmada anima o braço Minecraft visível")
	Input.action_press("sprint");await ticks(15);q1=w.model.arms[0].quaternion;await ticks(9);q2=w.model.arms[0].quaternion
	check(q1.angle_to(q2)>.04,"Corrida articula braços Minecraft")
	var origin: Vector3=w.player.position;Input.action_press("right");await ticks(12)
	check(w.player.position.distance_to(origin)>.7 and w.player.get_real_velocity().length()<6.7,"Diagonal preserva velocidade normalizada e física")
	Input.action_release("up");Input.action_release("right");Input.action_release("sprint");await ticks(12)
	w.player.position=Vector3(0,.03,28);w.player.velocity=Vector3.ZERO;w.set_facing(Vector3.FORWARD);await ticks(3)
	var target: Node3D=load("res://training_target.gd").new();target.setup(w,"martial_target","blade",Vector3(0,.03,26.8));w.add_child(target);target.hp=10000;target.max_hp=10000;w.enemies.append(target);await ticks(3)
	var palm_open:=false
	var indices: Array=[];var total_before: int=target.damage_total
	check(w.start_attack(),"Combo desarmado inicia")
	for step in range(4):
		var queued:=false;var hit_before: int=target.damage_total
		for n in range(75):
			target.position=target.home;target.forced_velocity=Vector3.ZERO
			if step==2 and w.attack_time>=w.attack_hit*.9:
				palm_open=w.model.forearms[0].rotation.x!=0.0 or w.model.forearms[1].rotation.x!=0.0
			if w.attack_time>=.11 and step<3 and not queued:w.start_attack();queued=true
			if w.attack_time<0 or w.combo_index!=step:break
			await ticks(1)
		indices.append(step)
		check(target.damage_total>hit_before,"Golpe desarmado %d acerta com dano real"%(step+1))
	check(palm_open,"Golpe com palma utiliza articulação de antebraço")
	check(w.attack_time<0 and w.combo_index==3,"Combo termina após quatro golpes, sem repetir para sempre")
	check(target.damage_total-total_before>30,"Dano acumulado usa o sistema existente")
	check("punch" in w.audio_fx.history and "blade_hit" not in w.audio_fx.history,"Mãos livres acionam movimento/impacto apropriados, sem lâmina")
	w.combat_timer=0;w.combo_timeout=0;target.home=Vector3(12,.03,28);target.position=target.home;target.forced_velocity=Vector3.ZERO;var hits_before: int=w.hits
	w.start_attack();await ticks(35)
	check(w.hits==hits_before,"Golpe que erra não produz dano/contato")
	w.combat_timer=0;await tap("toggle_hands");await ticks(15)
	check(w.current_weapon().id=="sword","R retoma a mesma espada")
	check(w.start_attack(),"Ataque armado inicia e solicita saque")
	await ticks(10)
	check(w.model.get_meta("stow_weight")<.3 and w.model.get_meta("motion_state")=="attack","Saque e ataque têm prioridade sobre corrida")
	check(not w.martial.toggle(),"Não troca de modo no meio da janela de ataque")
	await ticks(30);w.combat_timer=0;w.combo_timeout=0
	# Fixture: grant an actual gauntlets item, equip through the existing inventory path.
	var uid: String=w.inventory.add("weapon","gauntlets");check(w.equip_weapon("gauntlets",uid),"Manoplas exigem e equipam seu próprio item")
	check(w.current_weapon().id=="gauntlets" and not w.martial.bare(),"Manoplas continuam uma categoria independente")
	Input.action_press("up");Input.action_press("sprint");await ticks(15);q1=w.model.arms[0].quaternion;await ticks(9);q2=w.model.arms[0].quaternion
	check(q1.angle_to(q2)>.08 and w.martial.ready_weight<.1,"Manoplas vestidas também liberam os braços na corrida fora de combate")
	Input.action_release("up");Input.action_release("sprint");await ticks(10)
	w.player.position=Vector3(0,.03,28);w.player.velocity=Vector3.ZERO;w.set_facing(Vector3.FORWARD);target.home=Vector3(0,.03,26.8);target.position=target.home;await ticks(3)
	total_before=target.damage_total;w.start_attack()
	for step in range(3):
		var queued:=false
		for n in range(60):
			target.position=target.home;target.forced_velocity=Vector3.ZERO
			if w.attack_time>=.11 and step<2 and not queued:w.start_attack();queued=true
			if w.attack_time<0 or w.combo_index!=step:break
			await ticks(1)
	check(w.combo_index==2 and w.attack_time<0 and target.damage_total>total_before,"Combo equipado de Manoplas mantém três golpes e dano")
	w.combat_timer=0;w.combo_timeout=0;await tap("toggle_hands");await ticks(14)
	check(w.current_weapon().id=="unarmed" and not w.model.get_meta("weapon_nodes")[1].visible,"Guardar Manoplas libera as mãos e oculta as luvas")
	check(w.start_dash(Vector3.RIGHT),"Esquiva desarmada inicia")
	await ticks(5);check(w.model.get_meta("motion_state")=="evade","Esquiva tem prioridade sobre a base de locomoção")
	await ticks(35);check(w.model.get_meta("motion_state")=="locomotion","Esquiva retorna à locomoção")
	check(w.techniques.cast(1),"Habilidade existente inicia no modo desarmado")
	await ticks(5);check(w.model.get_meta("motion_state")=="skill","Camada de habilidade não é sobrescrita pela guarda")
	await ticks(65);w.techniques.reset();w.combat_timer=0
	target.home=Vector3(22,.03,40);target.position=target.home;target.forced_velocity=Vector3.ZERO
	var staff_uid: String=w.inventory.add("weapon","quarterstaff");check(w.equip_weapon("quarterstaff",staff_uid),"Arma de duas mãos equipa pelo fluxo normal")
	await ticks(15);check(not w.martial.stowed() and w.model.get_meta("ready_weight")>.9,"Bastão de duas mãos continua empunhado na exploração")
	# The old x=25 boundary was deliberately removed in landscape V2. Probe an actual solid structure.
	var wall:=StaticBody3D.new();var shape:=CollisionShape3D.new();var box:=BoxShape3D.new()
	box.size=Vector3(.6,4,8);shape.shape=box;wall.add_child(shape);w.add_child(wall);wall.position=Vector3(25,2,28);wall.collision_layer=4
	w.player.position=Vector3(23,.1,28);w.player.velocity=Vector3.ZERO;await ticks(3)
	Input.action_press("right");await ticks(40);Input.action_release("right")
	check(w.player.position.x<24.6 and w.player.position.x>23.2,"Movimento para na colisão física real sem limite antigo")
	wall.queue_free()
	await ticks(4);w.combat_timer=0
	var dagger_uid: String=w.inventory.add("weapon","dagger")
	check(w.equip_weapon("dagger",dagger_uid),"Arma rápida equipa sem alterar Manoplas ou mãos livres")
	await ticks(18);w.start_attack();await ticks(8)
	check(w.model.get_meta("stow_weight")<.01,"Adaga termina o saque antes da sua janela de acerto curta")
	print("MARTIAL091 ",passed," passaram / ",failed," falharam")
	w.process_mode=Node.PROCESS_MODE_DISABLED;w.audio_fx.shutdown();OS.delay_msec(120);await create_timer(.2).timeout;w.queue_free();await process_frame;await process_frame;await create_timer(.35).timeout;w=null;quit(int(failed>0))
