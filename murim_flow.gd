extends RefCounted
const Catalog=preload("res://catalog.gd")

const Wardrobe=preload("res://wardrobe.gd")
const Actor=preload("res://prologue_actor.gd")
const RACES=["Humano", "Luminar", "Umbrio", "Kitsune de Uma Cauda", "Lobo de Orelhas Prateadas", "Felino de Garras", "Ursino Robusto", "Escamado de Pele Firme", "Falcão de Penachos", "Corvo das Plumas", "Núcleo Latente", "Centelha Arcana"]
const PATHS=["Combatente","Arcanista","Guardião"]
const PATROL=[Vector3(0,0.03,14),Vector3(0,0.03,-3),Vector3(-5,0.03,-15)]
const RUIN_SURVEY=Vector3(0,0.03,-31)
const RUIN_RADIUS:=3.4
var ruin_marker: Node3D
const LEGACY_BED=Vector3(7.5,0.03,29)
const LEGACY_MAT=Vector3(6,0.03,23)
var BED: Vector3=LEGACY_BED
var MAT: Vector3=LEGACY_MAT
const STORY=[
	["I • A GUERRA DO PANTEÃO","Povos e domínios se enfrentaram. Entre técnicas, linhagens e ambições, a guerra alcançou aqueles que acreditavam estar acima dos mortais."],
	["II • O DECRETO","O Deus Supremo interrompeu o conflito. Sua ordem encerrou aquela batalha — mas as âncoras sobreviveram. Os reinos permaneceram presos aos ecos da guerra."],
	["III • AS ESTRADAS","Nas vilas, a Guilda reuniu quem podia abrir um novo caminho. Escolas marciais guardaram suas técnicas. Outros buscaram poder entre as ruínas."],
	["IV • SEU CAMINHO","Esta era não decide quem você será. Herói ou vilão, discípulo ou andarilho: o próximo nome desta história pertence a você."]]
var world: Node3D
var field_enemies: Array[Node3D]=[]
var actors: Array[Node3D]=[]
var markers: Array[Node3D]=[]
var clock:=0.0
var story_page:=0
var omen_time:=0.0
var meditating:=false
var practice_clock:=0.0
var god: Node3D
var heal_clock:=0.0
const WAR_DURATION:=90.0
const WAR_CENTER:=Vector3(90,.03,0)
var reinforcements:=0
var renewal_clock:=0.0
var god_arrived:=false
var replay_state: Dictionary={}
var replaying:=false
var phase: String:
	get:
		return world.journey.data.phase
	set(value):
		world.journey.data.phase=value

func _init(owner_world: Node3D) -> void:
	world=owner_world
	sync_village_sites()
	field_enemies=world.enemies.duplicate()
	for i in range(field_enemies.size()):
		var actor: Node3D=field_enemies[i]
		if actor.kind!="boss":
			var hostile_skin: Dictionary={"race":i%3,"robe":2 if actor.kind=="blade" else 4,"hair":i%4,"skin":i%4,"style":i%3,"weapon":"arcane_staff" if actor.kind=="mage" else "spear" if i%2==0 else "sword"}
			hostile_skin.skin3d=preload("res://exo_skin3d/appearance_adapter.gd").npc_cosmetics("field/%d" % i,"enemy",str(actor.kind))
			Wardrobe.apply(actor.rig,hostile_skin)
			preload("res://convergence/visual_actor_r10.gd").apply_enemy(actor.rig,str(actor.uid),"hostile_wanderer",str(world.journey.data.world.seed))
	# Patrol positions are intentionally invisible: the mission uses PATROL distances.
	ruin_marker=Node3D.new()
	world.add_child(ruin_marker)
	ruin_marker.position=RUIN_SURVEY
	# Invisible survey area. Tracking remains available from quest and map UI.
	ruin_marker.hide()
	Wardrobe.apply(world.npc,{"robe":0,"hair":0,"skin":1,"style":1,"voice":1})
	world.npc.set_meta("role","Representante da Guilda")
	world.fragment.hide()
	world.camera.size=17
	god=world.Rig.new()
	world.add_child(god)
	god.position=WAR_CENTER
	god.scale=Vector3.ONE*3.4
	Wardrobe.apply(god,{"race":1,"robe":3,"hair":2,"skin":3,"style":1})
	god.rotation.y=PI
	for side in [-1,1]:
		Wardrobe.piece(god.torso,Vector3(side*0.38,0.68,0),Vector3(0.3,0.18,0.4),Color("d2b576"))
		Wardrobe.piece(god.torso,Vector3(side*0.28,0.25,0.2),Vector3(0.12,1.0,0.1),Color("76bcbc"))
	var head: Node3D=god.torso.get_child(1)
	for x in [-0.2,0,0.2]:
		Wardrobe.piece(head,Vector3(x,0.7,0),Vector3(0.09,0.3 if x==0 else 0.2,0.11),Color("dabd7f"))
	god.sword.hide()
	for attachment in god.get_meta("weapon_nodes",[]):
		attachment.hide()
	god.hide()
	if phase=="adventure":
		apply_character()
	else:
		phase="hero"
		world.player.position=Vector3(90,0.03,7)
		Wardrobe.apply(world.model,Catalog.hero_profile(int(world.journey.data.hero)))
		for actor in field_enemies:
			actor.enabled=false
	world.update_camera()

# All village services use region layout anchors; old saves still use the old coordinates.
func sync_village_sites() -> void:
	var sites: Dictionary=world.get_meta("village_services",{})
	BED=sites.get("bed",LEGACY_BED)
	MAT=sites.get("mat",LEGACY_MAT)

var prologue_serial:int=0

func start_prologue() -> void:
	if world.has_method("legacy_active") and int(world.get("current_region"))<0:world.legacy_active(true)
	clear_actors()
	phase="prologue"
	prologue_serial+=1
	clock=0
	renewal_clock=0
	reinforcements=0
	god_arrived=false
	world.camera.size=20
	world.hits=0
	world.player.position=Vector3(90,0.03,7)
	world.player.velocity=Vector3.ZERO
	world.apply_boon()
	world.health=world.max_health
	world.techniques.reset()
	world.techniques.configure(Catalog.HEROES[int(world.journey.data.hero)].skills)
	world.attack_time=-1
	world.roll_time=-1
	world.target=null
	world.enemies.clear()
	god.hide()
	Wardrobe.apply(world.model,Catalog.hero_profile(int(world.journey.data.hero)))
	var selected: int=int(world.journey.data.hero)
	for i in range(11):
		var faction: int=i if i<selected else i+1
		var archetype: Dictionary=Catalog.HEROES[faction]
		var actor:=Actor.new()
		actor.faction=faction
		actor.color=Color(Catalog.COLORS[faction])
		var angle:=TAU*i/11.0
		actor.setup(world,"prologue_%d/run%d"%[i,prologue_serial],"blade",Vector3(90+cos(angle)*8,0.03,sin(angle)*8-3))
		world.add_child(actor)
		actor.technique_clock=.6+float(faction%6)*.27
		actor.max_hp=320
		actor.hp=320
		actor.display_name=Catalog.ELEMENTS[faction]+" • "+RACES[int(archetype.race)]
		for child in actor.get_children():
			if child is Label3D:
				child.text=actor.display_name
				child.modulate=actor.color
		Wardrobe.apply(actor.rig,Catalog.hero_profile(faction))
		actors.append(actor)
		world.enemies.append(actor)
	world.beacon.hide()
	world.fragment.hide()
	world.badge.hide()
	world.ui.close_flow()
	world.set_paused(false)
	world.message("Prólogo • poderes no auge. Ondas contínuas até a intervenção divina. E antecipa após 10 s.")
	world.save_progress()

func clear_actors() -> void:
	for actor in actors:
		if is_instance_valid(actor):
			actor.queue_free()
	actors.clear()
	world.enemies.clear()
	for actor in field_enemies:
		world.enemies.append(actor)

func begin_omen() -> void:
	if phase!="prologue":
		return
	phase="omen"
	omen_time=0
	god_arrived=false
	god.position=WAR_CENTER+Vector3(0,7,0)
	for actor in actors:
		actor.velocity=Vector3.ZERO
		actor.attack_time=-1
		actor.forced_velocity=Vector3.ZERO
	world.player.velocity=Vector3.ZERO
	world.attack_time=-1
	world.roll_time=-1
	world.techniques.reset()
	world.clear_hostile_shots()
	world.ui.reticle.hide()
	world.ui.cinematic("O chão se parte sob os pés...",true)
	world.play_sound("boss_entry")
	world.save_progress()

func tick(delta: float) -> bool:
	if phase=="prologue":
		clock+=delta
		renewal_clock+=delta
		world.techniques.mana=minf(100,world.techniques.mana+28*delta)
		world.techniques.stamina=minf(100,world.techniques.stamina+32*delta)
		world.health=mini(world.max_health,world.health+int(heal_clock+delta*10))
		heal_clock=fmod(heal_clock+delta*10,1.0)
		if renewal_clock>=1.0:
			renewal_clock=0
			for i in range(actors.size()):
				var actor: Node3D=actors[i]
				if actor.hp<=0:
					var angle:=TAU*(i+reinforcements*.618)/11.0
					actor.restore(false)
					actor.position=WAR_CENTER+Vector3(cos(angle)*16,0,sin(angle)*16)
					actor.technique_windup=-1
					actor.victim=null
					actor.technique_clock=2.0
					reinforcements+=1
					world.techniques.ring(actor.position,1.1,actor.color,.35)
		if clock>=WAR_DURATION:
			begin_omen()
	elif phase=="omen":
		omen_time+=delta
		world.elapsed+=delta
		world.update_effects(delta)
		world.model.pose(world.elapsed,false,false,true)
		world.camera.size=27
		var focus:=Vector3(90,1,0)
		world.camera.position=focus+Vector3(15,18,15)
		world.camera.look_at(focus)
		if world.graphics.shake_enabled:
			world.camera.position+=Vector3(sin(omen_time*62),cos(omen_time*57),0)*0.11
		for actor in actors:
			actor.rig.pose(world.elapsed,false,false,true)
			actor.rig.torso.rotation.x=0.65
			actor.velocity=Vector3.ZERO
		if omen_time>1.5:
			god.show()
			god.position.y=lerpf(7.0,.03,smoothstep(1.5,3.5,omen_time))
			god.pose(world.elapsed,false,false,true)
			world.ui.cinematic("DEUS SUPREMO\n"+("Basta." if omen_time<4.5 else "Esta guerra termina aqui."),true)
		if omen_time>=3.5 and not god_arrived:
			god_arrived=true
			world.techniques.ring(WAR_CENTER,9,Color("e8d6a2"),1.4)
			# Divine arrival is not a player footstep. EXO-owned layered power and
			# stone-energy impact replace the generic ground landing sound.
			world.audio_fx.play_event("god_descent_low", "magic", 0.90)
			world.audio_fx.play_event("god_descent_impact", "magic", 0.80)
			world.audio_fx.play_event("god_descent_echo", "magic", 0.42)
			for actor in actors:
				if actor.position.distance_to(WAR_CENTER)<3:
					var away: Vector3=(actor.position-WAR_CENTER).normalized()
					actor.position=WAR_CENTER+(away if away.length()>.1 else Vector3.RIGHT)*3.5
			if world.player.position.distance_to(WAR_CENTER)<3:
				world.player.position=WAR_CENTER+Vector3(0,0,4)
		if omen_time>8.0:
			phase="story"
			story_page=0
			world.ui.cinematic("",false)
			world.save_progress()
			world.audio_fx.play_event("chronicle_koto","ambience",.8)
			world.ui.show_story()
			world.camera.size=17
		return false
	elif phase!="adventure":
		return false
	if phase=="adventure":
		if world.activity!=null:world.activity.tick(delta)
		var race: Dictionary=Catalog.RACES[int(world.journey.data.character.get("race",0))]
		world.techniques.mana=minf(100,world.techniques.mana+float(race.mana)*delta)
		world.techniques.stamina=minf(100,world.techniques.stamina+float(race.stamina)*delta)
	return true

func advance_story() -> void:
	if phase!="story":
		return
	story_page+=1
	if story_page>=STORY.size():
		if replaying:
			finish_replay()
			return
		phase="creator"
		world.save_progress()
		world.ui.show_creator()
	else:
		world.ui.show_story()

func create_character(profile: Dictionary,world_seed: int=-1) -> bool:
	if phase!="creator" or not world.journey.valid_character(profile):
		return false
	var previous: Dictionary=world.journey.data.duplicate(true)
	if world_seed>=0:
		if world_seed>=2147483647:return false
		world.journey.data.world=preload("res://procedural/world_state.gd").create(world_seed,world.journey.data.world.id)
	if world.has_method("_begin_new_procedural_campaign"):
		var state:Dictionary=world.extension()
		state.atlas_seed=str(world.journey.data.world.seed)
		state.erase("atlas")
	if world.has_method("_begin_new_procedural_campaign") and world.exo_core!=null:
		var martial_owner:Variant=world.exo_core.instances.get("exo_martial")
		if martial_owner!=null and not martial_owner.prepare_new_campaign_seed(str(world.journey.data.world.seed)):
			world.journey.data=previous
			return false
	if world.has_method("_begin_new_procedural_campaign") and world.exo_core!=null:
		var economy_owner:Variant=world.exo_core.instances.get("exo_economy")
		if economy_owner!=null and not economy_owner.prepare_new_campaign_seed(str(world.journey.data.world.seed)):
			world.journey.data=previous
			return false
	if world.has_method("_prepare_worldgen_campaign") and not world._prepare_worldgen_campaign():
		world.journey.data=previous;return false
	world.journey.data.world.landscape_version=2
	var birthplace: Dictionary=preload("res://world/biome_plan.gd").create(world.journey.data.world)
	world.journey.data.world.birthplace={"version":2,"kind":birthplace.kind,"title":birthplace.title,"roll":birthplace.roll}
	world.journey.data.character=profile.duplicate(true)
	world.journey.data.character.race_id=Catalog.RACES[int(profile.race)].id
	world.journey.data.character.merge({"weapon":["sword","arcane_staff","gauntlets"][int(profile.path)],"element":6},false)
	world.journey.data.loadout=[["corte_inicial","bola_de_gelo","salto_impetuoso"],["dardo_arcano","barreira_arcana","cura"],["golpe_circular","investida_brutal","barreira_arcana"]][int(profile.path)].duplicate()
	phase="adventure"
	world.journey.data.merge(preload("res://inventory.gd").defaults(),true)
	world.inventory.seed_profile()
	# Birth conditions are small, real starter-resource differences; class and story remain viable.
	if str(birthplace.kind)=="empobrecida":
		for item in world.journey.data.items:
			if item.kind=="consumable" and item.ref=="potion":item.qty=2
	elif str(birthplace.kind)=="prospera":
		world.inventory.add("consumable","potion",1)
	elif str(birthplace.kind)=="especial":
		world.inventory.add("material","iron",2)
	if not world.save_progress():
		world.journey.data=previous
		return false
	clear_actors()
	god.hide()
	# For Convergence 03 a new campaign NEVER rebuilds or respawns in the retired
	# village before the seed-based atlas is ready. The old prologue remains a
	# separate historical/test flow until its other dependencies are detached.
	if world.has_method("_begin_new_procedural_campaign"):
		apply_character()
		world.player.velocity=Vector3.ZERO
		world.ui.close_flow()
		world.set_paused(false)
		world.call_deferred("_begin_new_procedural_campaign")
		world.message("Nascimento: "+str(birthplace.title)+" • preparando região procedural.")
		return true
	# Compatibility only for non-Convergence test scenes with no atlas host.
	world.rebuild_region()
	sync_village_sites()
	for actor in field_enemies:
		actor.enabled=true
	world.resume_checkpoint()
	apply_character()
	world.prepare_player_spawn(world.village_anchor("camp",Vector3(1.5,0.03,30)))
	world.update_camera()
	world.ui.close_flow()
	world.message("Nascimento: "+str(birthplace.title)+" • procure a representante da Guilda.")
	world.ui.dialogue("Um novo destino • "+str(birthplace.title),"Uma moradora lhe oferece água e indica a praça. Você não tem casa nem vínculo com uma escola.\n\nA representante da Guilda espera junto ao quadro de contratos. Aproxime-se e pressione E.\n\nP • ficha e crônicas   |   Tab • mapa   |   Esc • pausa e gráficos")
	return true

func apply_character() -> void:
	Wardrobe.apply(world.model,world.journey.data.character)
	preload("res://convergence/visual_actor_r10.gd").apply_player(world)
	world.apply_boon()
	world.health=world.max_health
	world.techniques.configure(world.journey.data.loadout)

func update_quest(delta: float) -> void:
	if lab_mode:
		return
	if phase!="adventure":
		return
	var data: Dictionary=world.journey.data
	if data.stage==1:
		for i in range(PATROL.size()):
			if i not in data.visits and world.player.position.distance_to(PATROL[i])<2.4:
				data.visits.append(i)
				world.message("Patrulha • %d/3" % data.visits.size())
				world.save_progress()
		if data.visits.size()==3 and "road_blade" in data.defeated and "road_mage" in data.defeated:
			data.stage=4
			world.save_progress()
			world.message("Estrada inspecionada. Volte à Guilda para receber seu pagamento.")
	# Survey the ground region, not the floating visual marker. No jump or boss kill required.
	var surveying: bool=data.stage==5 and data.rested and not data.get("ruins_explored",false)
	ruin_marker.visible=surveying
	if surveying:
		var offset: Vector3=world.player.position-RUIN_SURVEY
		if Vector2(offset.x,offset.z).length()<=RUIN_RADIUS and absf(offset.y)<=2.0:
			data.ruins_explored=true
			ruin_marker.hide()
			world.message("Exploração concluída • Ruínas do Panteão registradas nas Crônicas. O Vigia é um desafio opcional.")
			world.audio_fx.play_event("quest_complete","ui",.55)
			world.save_progress()
	world.autosave_time+=delta
	if world.autosave_time>=20:
		world.autosave_time=0
		world.save_progress()

func interact() -> void:
	if meditating and world.activity!=null:
		world.activity.stop();return
	if phase=="adventure" and not lab_mode:
		var drop: String=world.inventory.nearby_drop()
		if not drop.is_empty():
			world.inventory.collect(drop)
			return
		if world.encounters.interact():return
		if world.explore_nearby():return
	if lab_mode:
		if world.encounters.interact():return
		end_lab()
		return
	if phase=="prologue":
		if clock>=10:
			begin_omen()
		else:
			world.message("Experimente os controles. E avança após 10 segundos.")
		return
	if phase!="adventure":
		return
	var data: Dictionary=world.journey.data
	if world.player.position.distance_to(world.npc.position)<3.5:
		if data.stage==0:
			data.stage=1
			world.save_progress()
			world.ui.dialogue("Contrato • O chamado das estradas","As caravanas deixaram de chegar. Inspecione os três marcos ao norte da aldeia e afaste os dois salteadores da estrada.\n\nOs pontos da patrulha são registrados no mapa (Tab); aproxime-se dos locais para inspecioná-los.\n\nPagamento: 100 moedas, título Vigia das Estradas e abrigo na pousada. A Guilda aceita viajantes de qualquer origem.")
		elif data.stage==4:
			if world.journey.claim_reward():
				world.ui.dialogue("Um nome na Guilda","A estrada está segura. Você recebe 100 moedas e o título Vigia das Estradas.\n\nA Guilda custeará seu primeiro abrigo. Procure o colchão em frente à pousada e pressione E para descansar.\n\nVocê pode consultar suas técnicas em P > Personagem > Técnicas e explorar as ruínas. O Vigia dos Ecos ainda guarda aquele lugar.")
		else:
			world.ui.dialogue("Guilda dos Aventureiros","Conclua a patrulha antes de receber o pagamento." if not data.claimed else "Seu contrato está registrado. O abrigo está disponível na pousada. As ruínas ao norte guardam um desafio opcional; outros contratos chegarão nas próximas prévias.")
	elif world.player.position.distance_to(BED)<2.8:
		if not data.lodging:
			world.ui.dialogue("Abrigo da Guilda","A pousada oferece um lugar aos viajantes que ajudam a aldeia. Conclua o primeiro contrato para obter abrigo.")
		else:
			world.rest("camp")
			data.rested=true
			world.save_progress()
			world.ui.dialogue("Um lugar para recomeçar","Você descansa sob a proteção da aldeia. Vida, energia e vigor foram recuperados.\n\nPrimeira jornada concluída! Seu personagem, contrato, título e abrigo estão salvos.\n\nVocê pode continuar explorando, meditar no pátio ou desafiar o Vigia nas ruínas.")
	elif world.player.position.distance_to(MAT)<2.5:
		world.activity.start()
	else:
		world.message("Procure a Guilda, o abrigo ou o pátio de meditação. Tab abre o mapa.")

func objective() -> String:
	if lab_mode:
		return "Pátio de testes • P prepara as bases; E retorna. Sem recompensas."
	if phase=="hero":
		return "Escolha seu primeiro olhar sobre a guerra."
	if phase=="prologue":
		return "PRÓLOGO • "+Catalog.HEROES[int(world.journey.data.hero)].name+"\nPODERES NO AUGE • Reforços: %d\nE antecipa após 10 s • Intervenção em %d s" % [reinforcements,maxi(0,int(WAR_DURATION-clock))]
	if phase in ["omen","story","creator"]:
		return "O fim de uma era. O início do seu caminho."
	var data: Dictionary=world.journey.data
	match int(data.stage):
		0: return "Fale com a representante da Guilda [E]."
		1: return "Patrulhe os marcos: %d/3\nSalteadores afastados: %d/2" % [data.visits.size(),int("road_blade" in data.defeated)+int("road_mage" in data.defeated)]
		4: return "Volte à Guilda e receba o pagamento [E]."
		_:
			if not data.rested:return "Seu abrigo espera. Descanse na pousada [E]."
			if not data.get("ruins_explored",false):return "Explore as ruínas • entre no círculo dourado ao norte.\nBasta caminhar; o Vigia é opcional."
			return "Ruínas exploradas • Desafio opcional: vença o Vigia dos Ecos." if "ascendant" not in data.defeated else "Ruínas exploradas • Vigia derrotado.\nJornada disponível concluída • exploração livre."

func destination() -> Vector3:
	if lab_mode:
		return Vector3(90,0,0)
	if phase!="adventure":
		return Vector3(90,0,-5)
	var data: Dictionary=world.journey.data
	if data.stage==1:
		for i in range(PATROL.size()):
			if i not in data.visits:
				return PATROL[i]
		for actor in field_enemies:
			if actor.uid in ["road_blade","road_mage"] and actor.hp>0:
				return actor.position
	if data.stage==5:
		return RUIN_SURVEY if data.rested else BED
	return world.npc.position

func hint() -> String:
	if phase=="adventure" and not lab_mode:
		if not world.inventory.nearby_drop().is_empty():return "E • Recolher objetos"
		if world.encounters.nearby():return "E • Conversar com o desconhecido"
		if not world.nearby_exploration().is_empty():return "E • Examinar marco de exploração"
	if lab_mode:
		return "E • Voltar do pátio"
	if phase!="adventure":
		return ""
	if world.player.position.distance_to(world.npc.position)<3.5:
		return "E • Guilda / Quadro de contratos"
	if world.player.position.distance_to(BED)<2.8:
		return "E • Descansar no abrigo" if world.journey.data.lodging else "E • Consultar hospedagem"
	if world.player.position.distance_to(MAT)<2.5:
		return "E • Encerrar meditação" if meditating else "E • Meditar"
	return ""

var lab_mode:=false
var lab_targets: Array[Node3D]=[]
var lab_state: Dictionary={}

func begin_lab() -> bool:
	if world.get("current_region")!=null and int(world.get("current_region"))>=0:
		world.message("Retorne ao recinto inicial para usar este pátio.");return false
	if lab_mode or phase!="adventure" or not world.can_configure():
		world.message("O pátio fica disponível fora de combate.")
		return false
	lab_state={"data":world.journey.data.duplicate(true),"position":world.player.position,"health":world.health,"mana":world.techniques.mana,"stamina":world.techniques.stamina}
	lab_mode=true
	world.techniques.reset()
	world.enemies.clear()
	world.player.position=Vector3(90,.03,8)
	world.player.velocity=Vector3.ZERO
	var script:=load("res://training_target.gd")
	for i in range(3):
		var target: Node3D=script.new()
		target.setup(world,"training_%d"%i,"blade",Vector3(90+(i-1)*3,.03,i-2))
		world.add_child(target)
		target.max_hp=1000
		target.hp=1000
		target.display_name="Alvo de treino %d" % (i+1)
		for child in target.get_children():
			if child is Label3D:
				child.text=target.display_name
		Wardrobe.apply(target.rig,{"race":10,"robe":0,"hair":1,"skin":1,"style":2,"weapon":"quarterstaff"})
		lab_targets.append(target)
		world.enemies.append(target)
	world.update_camera()
	world.message("Pátio • P prepara equipamento e técnicas. E retorna. Alvos não atacam nem concedem recompensas.")
	world.set_paused(false)
	return true

func end_lab() -> void:
	if not lab_mode:
		return
	world.techniques.reset()
	for target in lab_targets:
		target.queue_free()
	lab_targets.clear()
	world.enemies.clear()
	for actor in field_enemies:
		world.enemies.append(actor)
	world.journey.data=lab_state.data.duplicate(true)
	world.encounters.stranger.position=Vector3(5,.03,26)
	world.encounters.stranger.visible=world.journey.data.encounter.met and not world.journey.data.encounter.done
	apply_character()
	world.prepare_player_spawn(lab_state.position)
	world.health=mini(world.max_health,int(lab_state.health))
	world.techniques.mana=lab_state.mana
	world.techniques.stamina=lab_state.stamina
	world.target=null
	world.attack_time=-1
	world.roll_time=-1
	lab_mode=false
	world.update_camera()
	world.ui.refresh()

func replay_prologue() -> bool:
	if world.get("current_region")!=null and int(world.get("current_region"))>=0:
		world.message("Retorne ao recinto inicial para usar este pátio.");return false
	if phase!="adventure" or not world.can_configure():
		return false
	if lab_mode:
		end_lab()
	replay_state={"data":world.journey.data.duplicate(true),"position":world.player.position,"health":world.health,"mana":world.techniques.mana,"stamina":world.techniques.stamina}
	replaying=true
	for actor in field_enemies:
		actor.enabled=false
	phase="hero"
	world.ui.show_hero()
	return true

func finish_replay() -> void:
	if not replaying:
		return
	world.techniques.reset()
	clear_actors()
	god.hide()
	world.journey.data=replay_state.data.duplicate(true)
	for actor in field_enemies:
		actor.enabled=true
	apply_character()
	world.player.position=replay_state.position
	world.player.velocity=Vector3.ZERO
	world.health=mini(world.max_health,int(replay_state.health))
	world.techniques.mana=replay_state.mana
	world.techniques.stamina=replay_state.stamina
	world.target=null
	world.attack_time=-1
	world.roll_time=-1
	world.camera.size=17
	replaying=false
	replay_state.clear()
	world.update_camera()
	world.ui.close_flow()
	world.set_paused(false)
	world.message("Memória da guerra encerrada. Sua jornada continua.")

func has_destination() -> bool:
	if phase!="adventure" or lab_mode:return false
	return not (world.journey.data.stage==5 and world.journey.data.rested and world.journey.data.get("ruins_explored",false))
