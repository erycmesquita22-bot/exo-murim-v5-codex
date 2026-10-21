extends RefCounted
var world: Node3D
var blend:=0.0
var support_y:=0.0
var anchor:=Vector3.ZERO
var queued:=""
func _init(w: Node3D) -> void:world=w
func locked() -> bool:return world.flow.meditating or blend>.02
func aligning() -> bool:
	return world.flow.meditating and Vector2(world.player.position.x-anchor.x,world.player.position.z-anchor.z).length()>.06 and blend<.01
func approach_velocity(delta: float) -> Vector3:
	var offset: Vector3=anchor-world.player.position;offset.y=0
	return offset.normalized()*minf(3.0,offset.length()/maxf(delta,.001))
func start() -> bool:
	if world.player.position.distance_to(world.flow.MAT)>2.5 or world.flow.phase!="adventure" or world.combat_timer>0 or world.attack_time>=0 or world.roll_time>=0 or world.techniques.busy():return false
	var mat: Vector3=world.flow.MAT
	var ray:=PhysicsRayQueryParameters3D.create(mat+Vector3.UP*2,mat+Vector3.DOWN,1)
	var hit: Dictionary=world.get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty() or Vector3(hit.normal).dot(Vector3.UP)<.95:return false
	support_y=hit.position.y;anchor=Vector3(mat.x,support_y+.03,mat.z)
	world.player.velocity=Vector3.ZERO;world.flow.meditating=true;queued=""
	world.set_facing(Vector3.FORWARD);world.message("Meditação • E para levantar")
	return true
func stop(action: String="") -> void:world.flow.meditating=false;queued=action
func tick(delta: float) -> void:
	if world.flow.meditating:
		var interrupt:=""
		for action in ["attack","dash","jump","skill_1","skill_2","skill_3","skill_4","skill_5","skill_6"]:
			if Input.is_action_just_pressed(action):interrupt=action;break
		if interrupt!="" or Input.get_vector("left","right","up","down").length()>.01 or world.health<=0:stop(interrupt)
		elif not aligning():
			world.flow.practice_clock+=delta;world.journey.data.meditation+=delta
			world.techniques.mana=minf(100,world.techniques.mana+12*delta);world.techniques.stamina=minf(100,world.techniques.stamina+16*delta)
	blend=move_toward(blend,1.0 if world.flow.meditating and not aligning() else 0.0,delta/.28)
	var collider: CollisionShape3D=world.player.get_child(0)
	collider.shape.height=lerpf(1.95,1.2,blend);collider.position.y=lerpf(.98,.61,blend)
	if locked():world.player.velocity.x=0;world.player.velocity.z=0
	elif queued!="":
		var action:=queued;queued=""
		if action=="attack":world.start_attack()
		elif action=="dash":world.start_dash()
		elif action=="jump" and world.player.is_on_floor():world.player.velocity.y=7.3
		elif action.begins_with("skill_"):world.techniques.cast(int(action.trim_prefix("skill_"))-1)
func pose() -> void:
	if blend>0:world.model.meditation_pose(world.elapsed,smoothstep(0,1,blend))
	var weapon: Node3D=world.model.get_meta("weapon_root") if world.model.has_meta("weapon_root") else null
	if is_instance_valid(weapon):weapon.visible=blend<.15
