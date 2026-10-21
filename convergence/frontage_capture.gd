extends SceneTree
var w: Node3D
var shots:=0
const OUT="res://convergence/evidence_frontage_final/"
func _initialize():call_deferred("run")
func frames(n: int):
	for i in range(n):await physics_frame
func shot(label: String):
	w.ui.hide()
	for i in range(5):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+label+".png");shots+=1;print("SHOT ",label)
func view(p: Vector3,size: float):
	w.player.position=p;w.player.velocity=Vector3.ZERO;w.camera.size=size;w.update_camera()
func run():
	DirAccess.make_dir_recursive_absolute(OUT);root.size=Vector2i(1440,900)
	w=load("res://convergence/game.gd").new();w.load_on_start=false;w.world_seed_override=101
	w.save_path="user://frontage_capture05.json";w.settings_path="user://frontage_capture05.cfg";root.add_child(w);await process_frame
	w.graphics.select(1);w.flow.phase="creator";w.flow.create_character({"name":"Eryc","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0});w.ui.resume()
	for rid in [86,15,78]:
		if not await w.change_region(rid):push_error(w.generation_failure);w.free();quit(1);return
		for enemy in w.enemies:enemy.enabled=false
		w.extension().clock=10*3600
		RenderingServer.render_loop_enabled=false
		await frames(6000)
		RenderingServer.render_loop_enabled=true
		w.set_physics_process(false)
		var region: Node3D=w.active_region
		var selected: Dictionary=region.data.lots[0]
		# Choose an actual facade facing the normal player camera.
		var score:=-INF
		for lot in region.data.lots:
			var people:=0
			for actor in w.residents:
				if actor.to_slot==lot.id and actor.arrived:people+=1
			var facing: float=Vector2(sin(lot.yaw),cos(lot.yaw)).dot(Vector2.ONE.normalized())
			var value: float=float(people)*10.0+facing
			if facing>.3 and value>score:score=value;selected=lot
		view(region.station_points[selected.id]+Vector3(0,0,3),24)
		for actor in w.residents:
			actor.presentation_visible=w.resident_is_visible(actor);actor.rig.visible=not actor.sheltered and actor.presentation_visible
		w.update_resident_labels()
		await shot("01-Aldeia-Moradores" if rid==86 else "03-Vila-Moradores" if rid==15 else "05-Cidade-Fila-na-Fachada")
		view(Vector3(0,region.data.center_h+.08,0),72 if rid==86 else 115 if rid==15 else 80)
		w.camera.position=w.player.position+Vector3(90,120,105);w.camera.look_at(w.player.position+Vector3.UP)
		for actor in w.residents:
			actor.presentation_visible=w.resident_is_visible(actor);actor.rig.visible=not actor.sheltered and actor.presentation_visible
		w.update_resident_labels()
		await shot("02-Aldeia-Compacta" if rid==86 else "04-Vila-Compacta" if rid==15 else "06-Cidade-Visibilidade")
		w.set_physics_process(true)
	print("FRONTAGE_CAPTURE images=",shots)
	w.set_physics_process(false);w.audio_fx.shutdown();OS.delay_msec(120);w.free();quit(int(shots!=6))
