extends SceneTree

var world: Node3D
var deaths:=0
var frames:=0
var started:=0

func _initialize() -> void:
	call_deferred("run")

func move_toward_point(point: Vector3,stop: float) -> void:
	var direction: Vector3=point-world.player.position
	direction.y=0
	if direction.length()<stop:
		direction=Vector3.ZERO
	else:
		direction=direction.normalized()
	var axis:=Vector2(direction.x-direction.z,direction.x+direction.z)/sqrt(2.0)
	Input.action_press("right",maxf(0,axis.x))
	Input.action_press("left",maxf(0,-axis.x))
	Input.action_press("down",maxf(0,axis.y))
	Input.action_press("up",maxf(0,-axis.y))

func run() -> void:
	world=load("res://main.tscn").instantiate()
	world.settings_path="user://qa_murim_graphics.cfg"
	world.save_path="user://qa_murim_playthrough.json"
	world.load_on_start=false
	root.add_child(world)
	world.flow.start_prologue()
	world.flow.begin_omen()
	world.flow.tick(8.1)
	for i in range(4):
		world.flow.advance_story()
	world.flow.create_character(world.ui.profile)
	world.ui.resume()
	started=Time.get_ticks_msec()
	while not world.journey.data.rested and frames<10800:
		await physics_frame
		await process_frame
		frames+=1
		if paused:
			if world.health<=0:
				deaths+=1
			world.ui.resume()
		var goal: Vector3=world.destination()
		var victim: Node3D=null
		var nearest:=8.0
		for actor in world.enemies:
			if actor.hp>0 and actor.uid in ["road_blade","road_mage"]:
				var distance: float=actor.position.distance_to(world.player.position)
				if distance<nearest:
					nearest=distance
					victim=actor
		if victim!=null and world.journey.data.stage==1:
			world.set_facing(victim.position-world.player.position)
			move_toward_point(victim.position,1.4)
			if victim.attack_time>=victim.windup_time()-0.2 and victim.attack_time<victim.windup_time() and world.roll_cooldown<=0:
				world.start_dash(Vector3(-world.facing.z,0,world.facing.x))
			if nearest<8:
				world.techniques.cast(1)
			if nearest<4:
				world.techniques.cast(0)
			if nearest<3:
				world.techniques.cast(2)
			if nearest<2.3:
				world.start_attack()
		else:
			move_toward_point(goal,1.8)
			if world.player.position.distance_to(goal)<3.2:
				world.interact()
		if frames%900==0:
			print("BOT stage=",world.journey.data.stage," position=",world.player.position," health=",world.health," deaths=",deaths)
	var ok: bool=world.journey.data.rested and world.journey.data.stage==5
	var report:="Primeira jornada completa: %s\nContrato: %d • Descanso: %s • Mortes: %d\nTempo simulado: %.1f s\nBot usou movimento e combate normais, sem teletransporte durante a jornada, bônus de dano ou invulnerabilidade adicional.\nO bot avançou o prólogo e as páginas pelas mesmas funções da interface.\n" % ["PASSOU" if ok else "FALHOU",world.journey.data.stage,world.journey.data.rested,deaths,world.journey.data.seconds]
	FileAccess.open("res://playthrough-result.txt",FileAccess.WRITE).store_string(report)
	print("PLAYTHROUGH ","PASS" if ok else "FAIL"," stage=",world.journey.data.stage," deaths=",deaths," simulated_seconds=",world.journey.data.seconds," wall_ms=",Time.get_ticks_msec()-started)
	for action in ["left","right","up","down"]:
		Input.action_release(action)
	paused=false
	world.audio_fx.shutdown();OS.delay_msec(100)
	world.queue_free()
	await process_frame
	for suffix in ["",".bak",".tmp"]:
		DirAccess.remove_absolute("user://qa_murim_playthrough.json"+suffix)
	quit(0 if ok else 1)
