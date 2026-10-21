extends SceneTree
const World=preload("res://main.gd")
var w: Node3D
var max_population:=0
var used:=0
var captured:=false
func _initialize() -> void:
	call_deferred("run")
func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/exo03-"+label+".png")
func run() -> void:
	w=World.new()
	w.load_on_start=false
	w.save_path="user://war03.json"
	w.settings_path="user://war03.cfg"
	root.add_child(w)
	await process_frame
	w.journey.data.hero=5
	w.flow.start_prologue()
	Engine.time_scale=6
	var render:=DisplayServer.get_name()!="headless"
	while w.flow.phase=="prologue":
		await physics_frame
		max_population=maxi(max_population,w.enemies.size())
		var nearest: Node3D
		var distance:=100.0
		for actor in w.enemies:
			if actor.hp>0 and w.player.position.distance_to(actor.position)<distance:
				distance=w.player.position.distance_to(actor.position)
				nearest=actor
		if nearest!=null:
			w.set_facing(nearest.position-w.player.position)
		for slot in range(3):
			used+=int(w.techniques.cast(slot))
		if distance<3:
			w.start_attack()
		if render and w.flow.clock>40 and not captured:
			captured=true
			await shot("guerra-em-andamento")
	Engine.time_scale=1
	while w.flow.phase=="omen" and w.flow.omen_time<3.7:
		await physics_frame
	if render:
		await shot("deus-supremo")
	while w.flow.phase=="omen":
		await physics_frame
	print("WAR03: phase=%s; elapsed=%.1f; reinforcements=%d; max_population=%d; skills=%d; god_center=%s"%[w.flow.phase,w.flow.clock,w.flow.reinforcements,max_population,used,str(w.flow.god_arrived)])
	var ok: bool=w.flow.phase=="story" and w.flow.reinforcements>0 and max_population==11 and used>5 and w.flow.god_arrived
	w.process_mode=Node.PROCESS_MODE_DISABLED;w.audio_fx.shutdown();OS.delay_msec(120)
	await create_timer(.2,true,false,true).timeout
	w.queue_free()
	await process_frame
	await process_frame
	w=null
	await create_timer(.35,true,false,true).timeout
	quit(0 if ok else 1)
