extends SceneTree
var w: Node3D
var failures: Array=[]
var checks: Array=[]
var facts: Dictionary={}
const SAVE="user://functional_r3_lifecycle_v1.json"
func check(value: bool,label: String):
	checks.append({"test":label,"pass":value});print("CHECK ",label," ",value)
	if not value:failures.append(label)
func frames(n: int):
	for i in range(n):await physics_frame
func boot(path: String=SAVE,restore: bool=false):
	root.size=Vector2i(1152,720)
	w=load("res://convergence/game.gd").new();w.load_on_start=restore;w.world_seed_override=101;w.save_path=path;w.settings_path="user://functional_r3.cfg";root.add_child(w);await process_frame
	# Headless validation keeps the same physics timestep without a display FPS cap.
	if DisplayServer.get_name()=="headless":w.graphics.set_option("fps_limit",0)
	if restore:
		for i in range(900):
			if w.current_region>=0 and not w.changing_region:break
			await physics_frame
		check(w.current_region>=0,"restore_region")
		w.ui.resume()
	else:
		w.flow.phase="creator";check(w.flow.create_character({"name":"R3 QA","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0,"weapon":"sword"}),"create_character");w.ui.resume()
		for i in range(600):
			if w.current_region>=0 and not w.changing_region:break
			await physics_frame
		check(w.current_region>=0,"automatic_v5_campaign_entry")
func ground(p: Vector2) -> Vector3:return Vector3(p.x,w.active_region.data.height_at(p)+.08,p.y)
func inputs(direction: Vector3):
	var axis:=Vector2(direction.x-direction.z,direction.x+direction.z).normalized() if direction.length()>.001 else Vector2.ZERO
	for action in ["left","right","up","down"]:Input.action_release(action)
	if axis.x>0:Input.action_press("right",axis.x)
	elif axis.x<0:Input.action_press("left",-axis.x)
	if axis.y>0:Input.action_press("down",axis.y)
	elif axis.y<0:Input.action_press("up",-axis.y)
func walk(target: Vector3,range_m: float=1.4,limit: int=1600) -> bool:
	for i in range(limit):
		var delta: Vector3=target-w.player.position;delta.y=0
		if delta.length()<range_m:inputs(Vector3.ZERO);return true
		inputs(delta);await physics_frame
	inputs(Vector3.ZERO);return false
func observe(site: Dictionary):
	await frames(4)
	for offset in [Vector2(0,35),Vector2(35,0),Vector2(0,-35),Vector2(-35,0)]:
		var p: Vector3=w.regional_spawn(w.active_region,ground(site.p+offset))
		if not p.is_finite():continue
		w.player.position=p;w.player.velocity=Vector3.ZERO;w.camera.size=15;w.update_camera()
		if w.ecology_director.visible_spawn(Vector3(site.p.x,site.y,site.p.y)):continue
		await frames(110);return
	check(false,"observer_space")
func loot(source: String) -> bool:
	# Keep the long QA fixture alive between fights, without changing enemy HP.
	if w.health<40:
		facts["between_fight_heals"]=int(facts.get("between_fight_heals",0))+1;w.health=w.max_health
	var point:=Vector3.INF
	for entry in w.journey.data.pending_loot:
		if entry.source==source:point=Vector3(entry.x,entry.y,entry.z)
	if not point.is_finite():return false
	if not await walk(point,1.5,1200):
		facts["loot_failure"]={"source":source,"health":w.health,"phase":w.flow.phase,"paused":paused,"player":str(w.player.position),"drop":str(point)}
		return false
	await frames(45)
	return w.inventory.collect(source)
func fight(actor: Node3D,receive: bool=false) -> Dictionary:
	var id: String=actor.uid;var max_hp: int=actor.hp;var health: int=w.health;var before: int=int(w.extension().ecology.xp_total);var landed:=false
	if receive:
		for i in range(1200):
			var d: Vector3=actor.position-w.player.position;d.y=0
			inputs(d if d.length()>1.4 else Vector3.ZERO)
			await physics_frame
			if w.health<health:landed=true;break
		inputs(Vector3.ZERO);check(landed,"enemy_inflicts_damage");facts["received_damage"]=health-w.health
	var elapsed_frames:=0
	while is_instance_valid(actor) and actor.hp>0 and elapsed_frames<2400:
		var d: Vector3=actor.position-w.player.position;d.y=0
		inputs(d if d.length()>1.45 else Vector3.ZERO)
		w.set_facing(d)
		if d.length()<2.0 and w.attack_time<0 and w.roll_time<0:
			Input.action_press("attack");await frames(2);Input.action_release("attack")
		await physics_frame;elapsed_frames+=1
		if w.health<20:
			facts["safety_heals"]=int(facts.get("safety_heals",0))+1;w.health=w.max_health
	inputs(Vector3.ZERO);Input.action_release("attack");await frames(5)
	var defeated: bool=not is_instance_valid(actor) or actor.hp<=0
	var xp: int=int(w.extension().ecology.xp_total)-before
	check(defeated,"defeat_"+id);check(xp>0,"xp_"+id)
	return {"uid":id,"hp":max_hp,"xp":xp,"frames":elapsed_frames,"defeated":defeated}
func finish(label: String):
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://validation_r3/results"))
	inputs(Vector3.ZERO)
	FileAccess.open("res://validation_r3/results/"+label+".json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"facts":facts},"  "))
	print("R3_RESULT ",label," checks=",checks.size()," failures=",failures)
	if w!=null:
		w.process_mode=Node.PROCESS_MODE_DISABLED;w.audio_fx.shutdown();OS.delay_msec(150);w.free()
	await process_frame;quit(int(not failures.is_empty()))
