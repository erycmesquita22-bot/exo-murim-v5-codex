extends SceneTree
# Engine-driven inputs. Only camera and training fixture differ from a normal session.
class InspectionWorld:
	extends "res://main.gd"
	func update_camera() -> void:
		camera.position=player.position+Vector3(24,8,-7)
		camera.look_at(player.position+Vector3.UP*.95)
var w: Node3D
var target: Node3D
func _initialize() -> void:call_deferred("run")
func frames(n: int) -> void:
	for i in range(n):
		if is_instance_valid(target):target.position=target.home;target.forced_velocity=Vector3.ZERO
		await process_frame
func shot(label_value: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://evidencias/091-"+label_value+".png")
func tap(action: String) -> void:
	Input.action_press(action);await frames(2);Input.action_release(action)
func stage(text_value: String) -> void:w.message(text_value);print("STAGE ",text_value)
func run() -> void:
	root.size=Vector2i(960,600)
	w=InspectionWorld.new();w.load_on_start=false;w.save_path="user://demo091.json";w.settings_path="user://demo091.cfg";root.add_child(w);await process_frame
	w.flow.phase="creator";w.flow.create_character({"name":"Corpo Marcial 09.1","race":0,"path":0,"robe":0,"hair":0,"skin":0,"style":0});w.ui.resume();w.graphics.select(1);w.graphics.shake_enabled=false;w.camera.size=5.6
	for actor in w.enemies:actor.enabled=false
	w.player.position=Vector3(0,.03,28);await frames(12)
	stage("Espada embainhada • exploração");await shot("embainhada")
	Input.action_press("up");Input.action_press("sprint");await frames(16);await shot("corrida-embainhada");await frames(9);Input.action_release("up");Input.action_release("sprint");await frames(6)
	await tap("toggle_hands");await frames(10);stage("Mãos livres • caminhada e corrida")
	Input.action_press("down");await frames(15);await shot("caminhada-livre");Input.action_press("sprint");await frames(15);await shot("corrida-livre")
	Input.action_press("left");await frames(10);await shot("diagonal");Input.action_release("down");Input.action_release("left");Input.action_press("up");Input.action_press("right");await frames(12);Input.action_release("up");Input.action_release("right");Input.action_release("sprint");await frames(6)
	w.player.position=Vector3(0,.03,28);w.player.velocity=Vector3.ZERO;w.set_facing(Vector3.FORWARD);await frames(12)
	target=load("res://training_target.gd").new();target.setup(w,"demo091_target","blade",Vector3(0,.03,26.8));w.add_child(target);target.hp=10000;target.max_hp=10000;w.enemies.append(target)
	for label in target.find_children("*","Label3D",true,false):label.hide()
	await frames(3)
	stage("Combo: esquerdo • direito • palma • finalização")
	for i in range(4):
		await tap("attack")
		await frames(maxi(1,int(w.attack_hit*30)-2));await shot("desarmado-%d"%(i+1))
		await frames(maxi(1,int((w.attack_duration-w.attack_hit)*30)+2))
	stage("Esquiva e retorno à locomoção");await tap("dash");await frames(4);await shot("esquiva");await frames(18)
	w.combat_timer=0;w.combo_timeout=0;w.player.position=Vector3(0,.03,28);w.player.velocity=Vector3.ZERO
	await tap("toggle_hands");w.set_facing(Vector3.FORWARD);await frames(8)
	stage("Transição para combate armado");await tap("attack");await frames(6);await shot("saque-ataque");await frames(20)
	w.combat_timer=0;w.combo_timeout=0
	target.home=Vector3(12,.03,28);target.position=target.home;target.forced_velocity=Vector3.ZERO
	var uid: String=w.inventory.add("weapon","gauntlets");print("EQUIP_GAUNTLETS ",w.equip_weapon("gauntlets",uid));w.player.position=Vector3(0,.03,28);w.player.velocity=Vector3.ZERO;w.set_facing(Vector3.FORWARD);target.home=Vector3(0,.03,26.8);target.position=target.home;await frames(12)
	stage("Manoplas • equipamento e combo próprios")
	for i in range(3):
		await tap("attack");await frames(maxi(1,int(w.attack_hit*30)-2));await shot("manoplas-%d"%(i+1));await frames(maxi(1,int((w.attack_duration-w.attack_hit)*30)+2))
	stage("Guarda das Manoplas • mãos livres novamente");w.combat_timer=0;await tap("toggle_hands");await frames(12);await shot("manoplas-guardadas");await frames(10)
	print("DEMO091_RESULT ",JSON.stringify({"damage":target.damage_total,"events":w.audio_fx.history,"bare":w.martial.bare()}))
	w.audio_fx.shutdown();w.queue_free();await frames(4);quit()
