extends SceneTree
var w: Node3D
var passed:=0
var failed:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	passed+=int(ok);failed+=int(not ok);print(("OK " if ok else "FAIL ")+label)
func ticks(n: int) -> void:
	for i in range(n):await physics_frame
func run() -> void:
	w=load("res://main.gd").new();w.load_on_start=false;w.save_path="user://quality09.json";w.settings_path="user://quality09.cfg";root.add_child(w);await process_frame
	w.flow.phase="creator";w.flow.create_character({"name":"QA09","race":0,"path":0,"robe":0,"hair":0,"skin":0,"style":0});w.ui.resume()
	for a in w.enemies:a.enabled=false
	check(w.model.forearms.size()==2 and w.model.calves.size()==2,"Corpo Minecraft articulado integrado")
	check(not w.model.has_meta("reference_visual"),"Nenhum modelo externo sobreposto")
	var bank: Dictionary=w.audio_fx.BANK
	for event in bank:
		if event!="chronicle_koto":check(not str(bank[event]).contains("chronicle_koto"),"Narrativa não é amostra de "+event)
	for event in ["qi","magia","skill_windup","summon","boss_entry","boss_phase","quest_complete"]:
		check(str(bank[event]).contains("audio09/"),"Fonte própria para "+event)
	check(w.audio_fx.event_group("chronicle_koto","combat")=="narrative","Crônicas têm canal narrativo independente do chamador")
	w.audio_fx.groups.master=1;w.audio_fx.groups.narrative=.5;w.audio_fx.recent.clear();w.audio_fx.play_event("chronicle_koto","combat")
	check(w.audio_fx.voices[19].get_meta("group")=="narrative","Narração usa voz reservada")
	w.audio_fx.play_event("boss_entry");check(w.audio_fx.voices[19].get_meta("group")=="narrative","Chefe não ocupa a voz das Crônicas")
	w.player.position=w.flow.MAT+Vector3(-.8,.05,0);w.player.velocity=Vector3.ZERO;await ticks(8)
	w.techniques.mana=10;w.techniques.stamina=10;var before: float=w.journey.data.meditation
	w.flow.interact();await ticks(55)
	check(w.flow.meditating and w.activity.blend>.99,"Interação inicia, aproxima e completa pose sentada")
	var point: Vector3=w.player.position;await ticks(35)
	check(Vector2(w.player.position.x-point.x,w.player.position.z-point.z).length()<.01,"Sem deslizamento horizontal enquanto medita")
	check(w.journey.data.meditation>before+.5 and w.techniques.mana>20 and w.techniques.stamina>20,"Tempo e recuperação preservados")
	check(w.player.get_child(0).shape.height<1.3,"Colisão acompanha o corpo sentado")
	check(w.save_progress(),"Salva durante meditação")
	var saved=load("res://journey_save.gd").new(w.save_path);check(saved.load_progress() and saved.data.meditation>before+.5,"Tempo de meditação persiste após recarga")
	w.flow.interact();await ticks(23)
	check(not w.flow.meditating and not w.activity.locked() and is_equal_approx(w.player.get_child(0).shape.height,1.95),"E levanta e restaura a colisão")
	w.flow.interact();await ticks(22);Input.action_press("right");await ticks(22);Input.action_release("right")
	check(not w.flow.meditating and not w.activity.locked(),"Movimento interrompe a meditação")
	w.player.position=w.flow.MAT;w.player.velocity=Vector3.ZERO;await ticks(5);w.activity.start();await ticks(22)
	Input.action_press("attack");await ticks(1);Input.action_release("attack");await ticks(22)
	check(not w.flow.meditating and (w.attack_time>=0 or "swing" in w.audio_fx.history),"Ataque interrompe e é executado depois de levantar")
	var boss: Node3D=w.enemies[5];w.attack_time=-1;w.techniques.reset();w.player.position=Vector3(0,.03,-28);boss.position=boss.home;boss.enabled=true;w.journey.data.stage=1;boss.hp=boss.max_hp;boss.encounter_started=false;w.audio_fx.recent.clear();await ticks(8)
	check("boss_entry" in w.audio_fx.history,"Entrada do chefe acionada no encontro real")
	boss.intro_timer=0;boss.begin_attack(Vector3.BACK,2);boss.attack_kind="shock";boss.execute_attack()
	check("boss_prepare" in w.audio_fx.history and "boss_release" in w.audio_fx.history and "boss_impact" in w.audio_fx.history,"Chefe emite preparação, liberação e impacto")
	boss.hp=boss.max_hp/2;await ticks(3)
	check("boss_phase" in w.audio_fx.history,"Metade de vida aciona a transformação sonora")
	w.simulation_enabled=false;w.audio_fx.shutdown();OS.delay_msec(120);await create_timer(.2,true,false,true).timeout;w.queue_free();await process_frame;await process_frame
	w=null;await create_timer(.35,true,false,true).timeout
	print("QUALITY09: %d passaram / %d falharam"%[passed,failed]);quit(int(failed>0))
