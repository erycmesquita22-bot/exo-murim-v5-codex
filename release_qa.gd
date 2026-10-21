extends SceneTree
const World=preload("res://main.gd")
const Catalog=preload("res://catalog.gd")
var w: Node3D
var passed:=0
var failed:=0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool,label: String) -> void:
	print(("OK " if value else "FAIL ")+label)
	passed+=int(value)
	failed+=int(not value)
func run() -> void:
	w=World.new()
	w.load_on_start=false
	w.save_path="user://release03-test.json"
	w.settings_path="user://release03-graphics.cfg"
	root.add_child(w)
	await process_frame
	w.simulation_enabled=false
	w.flow.start_prologue()
	var base: float=w.basic_multiplier()/3.0
	check(w.peak_power() and w.basic_multiplier()>base*2.9,"Prólogo aplica poder temporário")
	var actor: Node3D=w.enemies[0]
	actor.hurt(9999,Vector3.ZERO)
	w.flow.tick(1.1)
	check(actor.hp==actor.max_hp and actor.visible and actor.collision_layer==4,"Reposição restaura vida e colisão")
	check(w.enemies.size()==11 and w.flow.actors.size()==11 and w.flow.reinforcements==1,"Reposição mantém população limitada")
	check(actor.position.distance_to(w.flow.WAR_CENTER)>15,"Reforços chegam pelas bordas")
	w.techniques.mana=0
	w.techniques.stamina=0
	w.flow.tick(.5)
	check(w.techniques.mana>=14 and w.techniques.stamina>=16,"Recuperação de auge funciona")
	w.techniques.reset()
	w.techniques.cast(0)
	var skill: Dictionary=w.techniques.DATA[0]
	check(is_equal_approx(float(w.techniques.recovery[skill.id]),float(skill.cooldown)*.35),"Auge reduz recarga real da técnica")
	w.flow.clock=89.9
	w.flow.tick(.2)
	check(w.flow.phase=="omen" and not w.techniques.busy(),"Intervenção interrompe batalha ativa")
	w.flow.tick(2)
	check(w.flow.god.visible and w.flow.god.position.y>1,"Deus Supremo desce na arena")
	w.flow.tick(1.6)
	check(w.flow.god_arrived and w.flow.god.position.distance_to(w.flow.WAR_CENTER)<.01,"Deus Supremo chega ao centro")
	w.flow.tick(4.5)
	for i in range(4):
		w.flow.advance_story()
	check(w.flow.phase=="creator","Primeiro prólogo conduz à criação")
	w.flow.create_character(w.ui.profile)
	w.ui.resume()
	check(not w.peak_power() and w.basic_multiplier()<3,"Personagem novo recupera progressão inicial")
	var saved: Dictionary=w.journey.data.duplicate(true)
	var disk: String=FileAccess.get_file_as_string(w.save_path)
	w.combat_timer=0
	check(w.flow.replay_prologue(),"Rever prólogo aceita jornada existente")
	w.journey.data.hero=5
	w.flow.start_prologue()
	w.save_progress()
	check(FileAccess.get_file_as_string(w.save_path)==disk,"Rever prólogo não sobrescreve o progresso salvo")
	w.flow.begin_omen()
	w.flow.tick(8.1)
	for i in range(4):
		w.flow.advance_story()
	check(w.flow.phase=="adventure" and not w.flow.replaying and w.journey.data==saved,"Rever prólogo retorna com personagem e missão intactos")
	w.simulation_enabled=false
	for id in ["bow","crossbow"]:
		w.Arsenal.equip(w.model,id)
		var frame: Node3D=w.model.get_meta("weapon_root")
		check(frame.get_parent()==w.model.torso,"Suporte próprio de "+id)
		for progress in [-1.0,.2,.43,.7,.95]:
			w.model.pose(1,false,false,true)
			w.Arsenal.animate(w.model,Catalog.weapon(id),0,progress)
			var hand: Vector3=w.model.forearms[0].to_global(Vector3(0,-.375,0))
			check(hand.distance_to(frame.global_position)<.001,"Empunhadura conectada %s %.2f"%[id,progress])
		var release: float=Catalog.weapon(id).hit
		w.Arsenal.ranged_pose(w.model,id,release-.01)
		var loaded: Node3D=frame.get_meta("ammo")
		var before_release:=loaded.visible
		w.Arsenal.ranged_pose(w.model,id,release+.01)
		check(before_release and not loaded.visible,"Flecha / virote sincronizado com disparo "+id)
		w.attack_time=-1
		w.roll_time=-1
		w.techniques.reset()
		w.techniques.weapon_shot(Catalog.weapon(id),Vector3.FORWARD,10)
		var muzzle: Node3D=frame.get_meta("muzzle")
		check(w.techniques.projectiles.back().node.global_position.distance_to(muzzle.global_position)<.001,"Projétil sai da arma "+id)
	for race in [3,4,5,7]:
		w.Anatomy.apply(w.model,race)
		var tail: Node3D=w.model.get_meta("anatomy_animated")[0].node
		check(tail.get_parent()==w.model.pelvis and tail.position==Vector3.ZERO,"Cauda presa ao quadril %d"%race)
	for level in range(3):
		w.graphics.select(level)
		check(is_equal_approx(w.get_viewport().scaling_3d_scale,1.0) and not w.sun.shadow_enabled,"Perfil %d usa resolução nativa e sombras pintadas sem atlas"%level)
	print("RELEASE03: %d passaram / %d falharam"%[passed,failed])
	w.audio_fx.shutdown()
	OS.delay_msec(100) # Give the independent audio mixer time to release OGG playback before headless exit.
	await create_timer(.15,true,false,true).timeout
	w.queue_free()
	await process_frame
	quit(0 if failed==0 else 1)
