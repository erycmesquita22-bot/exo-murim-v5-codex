extends SceneTree
const World=preload("res://main.gd")
const Save=preload("res://journey_save.gd")
const Wardrobe=preload("res://wardrobe.gd")
var w: Node3D
var passed:=0
var failed:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	passed+=int(ok);failed+=int(not ok);print(("OK " if ok else "FAIL ")+label)
func run() -> void:
	w=World.new();w.load_on_start=false;w.save_path="user://qa07-ruins.json";w.settings_path="user://qa07-graphics.cfg"
	root.add_child(w);await process_frame
	w.simulation_enabled=false
	w.flow.start_prologue();w.flow.begin_omen();w.flow.tick(8.1)
	check("chronicle_koto" in w.audio_fx.history,"Koto é acionado na transição do decreto para as Crônicas")
	for i in range(4):w.flow.advance_story()
	w.flow.create_character(w.ui.profile);w.ui.resume();w.simulation_enabled=false
	var d: Dictionary=w.journey.data
	w.player.position=w.flow.RUIN_SURVEY;w.flow.update_quest(.01)
	check(not d.ruins_explored,"Ruínas não avançam antes da jornada da Guilda")
	d.stage=5;d.claimed=true;d.coins=100;d.lodging=true;d.rested=true;d.visits=[0,1,2];d.defeated=["road_blade","road_mage"]
	check(w.journey.valid(d),"Perfil 06 com primeira jornada concluída continua válido")
	var old: Dictionary=d.duplicate(true);old.erase("ruins_explored")
	var upgraded: Variant=w.journey.upgrade(old)
	check(upgraded.get("ruins_explored")==false and w.journey.valid(upgraded),"Save 06 recebe exploração pendente sem perder identidade ou inventário")
	w.player.position=w.flow.RUIN_SURVEY+Vector3(0,5,0);w.flow.update_quest(.01)
	check(not d.ruins_explored,"Passagem cinco metros acima do chão não conclui exploração")
	w.player.position=w.flow.RUIN_SURVEY+Vector3(4,0,0);w.flow.update_quest(.01)
	check(not d.ruins_explored,"Fora do círculo não conclui o objetivo")
	w.player.position=w.flow.RUIN_SURVEY+Vector3(2.9,0,0);w.flow.update_quest(.01)
	check(d.ruins_explored,"Caminhar no chão dentro do círculo conclui a exploração")
	check("ascendant" not in d.defeated and w.flow.objective().contains("opcional"),"Exploração independe de matar o Vigia e o próximo texto é explícito")
	check(not w.flow.has_destination() and not w.flow.ruin_marker.visible,"Bolinha e círculo não mantêm objetivo já concluído")
	check(d.coins==100 and d.items.size()==upgraded.items.size(),"Exploração não duplica recompensa nem objetos")
	check(w.save_progress(),"Conclusão grava progresso válido")
	var reloaded:=Save.new(w.save_path)
	check(reloaded.load_progress() and reloaded.data.ruins_explored,"Conclusão persiste ao recarregar")
	w.flow.update_quest(.1);check(d.coins==100,"Reentrar nas ruínas não repete recompensa")
	d.defeated.append("ascendant");check(w.flow.objective().contains("exploração livre"),"Vigia já derrotado produz encerramento coerente")
	# Regression for material precedence, critical/final hit, airborne miss, and family dispatch.
	var audio: Node=w.audio_fx
	for spec in [["wood",{"family":"fists","critical":true},"wood_hit"],["metal",{"fatal":true},"metal_hit"],["ground",{},"landing"],["body",{"family":"fists"},"fist_hit"],["body",{"heavy":true},"strong_hit"],["body",{"critical":true},"critical_hit"],["body",{"critical":true,"fatal":true},"fatal_hit"],["body",{"family":"blade"},"blade_hit"],["body",{"family":"draw"},"blade_hit"],["body",{"magic":true},"qi_hit"]]:
		check(audio.impact_event(spec[0],spec[1])==spec[2],"Roteamento de contato: "+spec[2])
	for skill in w.Catalog.SKILLS:
		check(audio.skill_event(skill) in ["swing","punch","gelo","fogo","vento","qi","terra","summon","exo_salto_cast"],"Técnica sem oscilador genérico: "+skill.id)
	for event in audio.BANK:
		for asset in audio.BANK[event]:check(audio.cache.has(asset),"Amostra carregada: "+asset)
	check(not str(audio.BANK).contains("bookFlip") or audio.BANK.ui==["foley/bookFlip1"],"Livro permanece apenas na interface")
	for bank in ["swing","punch","fist_hit","body_hit","gelo","fogo","magia"]:
		check((str(audio.BANK[bank]).contains("martial_audio/") or str(audio.BANK[bank]).contains("audio09/")) and not str(audio.BANK[bank]).contains("exo_audio/"),"Referências substituem áudio antigo: "+bank)
	check(audio.technique_context(w.Catalog.SKILLS[0]).family=="blade","Corte marcial tem contato de lâmina")
	check(not audio.technique_context(w.Catalog.SKILLS[6]).magic,"Investida física não produz magia eletrônica")
	check(audio.impact_event("body",{"magic":true,"element":6})=="gelo","Gelo mantém sua identidade no contato")
	check(audio.impact_event("body",{"magic":true,"element":5})=="fogo","Fogo mantém sua identidade no contato")
	# Pose-driven whoosh on a miss must never emit impact/fatal/critical.
	for actor in w.enemies:actor.position=Vector3(100,0,100)
	w.combat_timer=0;w.attack_time=-1;w.roll_time=-1;w.techniques.reset();w.flow.begin_lab();w.equip_weapon("gauntlets")
	audio.recent.clear();audio.history.clear();w.start_attack();w.update_attack(w.attack_hit+.01)
	check("punch" in audio.history and "fist_hit" not in audio.history and "fatal_hit" not in audio.history,"Soco no ar só desloca ar")
	Wardrobe.apply(w.model,{"race":0,"robe":1,"hair":0,"skin":1,"style":1,"voice":1})
	audio.recent.clear();audio.history.clear();audio.actor_voice(w.model)
	check("hurt_female" in audio.history,"Voz feminina acompanha perfil selecionado")
	audio.actor_voice(w.model);check(audio.history.size()==1,"Vozes do mesmo ator respeitam intervalo")
	for style in range(3):
		var profile: Dictionary=w.ui.profile.duplicate(true);profile.style=style;profile.outfit=0;profile.erase("skin_file")
		Wardrobe.apply(w.model,profile)
		check(w.model.get_meta("cloth_motion").size()>=4,"Estilo %d tem saia dividida e articulações próprias"%style)
		var count: int=w.model.get_meta("garments").size()
		Wardrobe.apply(w.model,profile)
		check(w.model.get_meta("garments").size()==count,"Trocar prévia não acumula vestimentas: "+str(style))
	w.flow.end_lab();w.audio_fx.shutdown();await create_timer(.2,true,false,true).timeout
	w.queue_free();await process_frame;await process_frame
	w=null
	await create_timer(.35,true,false,true).timeout
	OS.delay_msec(100)
	print("RUINS_MARTIAL07: %d passaram / %d falharam"%[passed,failed]);quit(int(failed>0))
