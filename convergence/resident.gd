extends CharacterBody3D
const Rig=preload("res://rig.gd")
const Wardrobe=preload("res://wardrobe.gd")
const People=preload("res://living_world/people.gd")
const Planner=preload("res://npc_system02/planner.gd")
const VisualR10=preload("res://convergence/visual_actor_r10.gd")
var identity: Dictionary={}
var route: Array=[]
var routes: Dictionary={}
var rig: Node3D
var caption: Label3D
var clock:=0.0
var route_index:=0
var waits:=0.0
var activity_name:=""
var blocked_seconds:=0.0
var travelled:=0.0
var paused_for_talk:=0.0
var from_slot:=""
var to_slot:=""
var arrived:=false
var sheltered:=false
var entries:=0
var exits:=0
var talks:=0
var recoveries:=0
var visits: Dictionary={}
var visual_active:=true
var presentation_visible:=true
var nearby_residents: Array=[]
var separation_clock:=0.0
var separation_force:=Vector3.ZERO
var work_cycles:=0
var action_elapsed:=0.0
var action_variant:=0
# NPC System 02: logical ticks, social breaks and out-of-view travel.
var game_clock:=0.0
var decision_timer:=0.0
var logical_slot: String=""
var near_player:=false
var danger_nearby:=false
var attention_near:=false
var player_interest_position:=Vector3.ZERO
var social_time:=0.0
var social_cooldown:=0.0
var social_target: Node3D
var social_events:=0
var social_last_partner: String=""
var unreachable_count:=0
var last_priority:=0
var patrol_leg:=0
var patrol_station_wait:=0.0
var patrol_observations:=0
func setup(person: Dictionary,points: Array,saved: Dictionary={},routine_paths: Dictionary={},now: float=0.0,seed_text: String="") -> void:
	identity=person;route=points;routes=routine_paths;game_clock=now
	collision_layer=8;collision_mask=1|2|4|8
	floor_snap_length=.4;floor_max_angle=deg_to_rad(50)
	var capsule:=CapsuleShape3D.new();capsule.radius=.26;capsule.height=1.9
	var collider:=CollisionShape3D.new();collider.shape=capsule;collider.position.y=.96;add_child(collider)
	var appearance: Dictionary=identity.appearance.duplicate(true)
	# Old NPC snapshots lack skin3d; new NPCs carry seed-derived cosmetics in their data.
	if not appearance.has("skin3d"):
		appearance.skin3d=preload("res://exo_skin3d/appearance_adapter.gd").npc_cosmetics(str(identity.get("id","")),str(identity.get("role","resident")),str(identity.get("faction","")),str(identity.get("generation_version",1)))
	rig=Rig.new();add_child(rig);Wardrobe.apply(rig,appearance)
	# R10 attaches after existing Wardrobe/Skin3D and before NPC presentation.
	VisualR10.apply_resident(rig,identity,saved,seed_text)
	rig.sword.hide()
	for weapon in rig.get_meta("weapon_nodes",[]):weapon.hide()
	caption=Label3D.new()
	caption.font_size=28;caption.pixel_size=.007;caption.outline_size=6
	caption.modulate=Color("f7f1e4");caption.outline_modulate=Color("161f25")
	caption.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	caption.position.y=2.46;caption.text=str(identity.get("name",identity.get("display_name","Morador")))
	add_child(caption)
	from_slot=str(saved.get("from_slot",identity.home_slot));to_slot=str(saved.get("to_slot",identity.home_slot))
	if not routes.has(from_slot+">"+to_slot):from_slot=identity.home_slot;to_slot=identity.home_slot
	if not routes.is_empty():route=routes[from_slot+">"+to_slot].duplicate()
	position=route[0];route_index=clampi(int(saved.get("route_index",0)),0,route.size()-1) if int(saved.get("routine_version",0))>=3 else 0
	if int(saved.get("routine_version",0))>=3 and saved.get("position") is Array:
		var p: Array=saved.position;var candidate:=Vector3(p[0],p[1],p[2]);var near:=false
		for i in range(route.size()):
			var a: Vector3=route[i];var b: Vector3=route[maxi(0,i-1)]
			if candidate.distance_to(Geometry3D.get_closest_point_to_segment(candidate,a,b))<1.5:near=true
		if near:position=candidate
		else:route_index=0
	work_cycles=int(saved.get("work_cycles",0));action_elapsed=float(saved.get("action_elapsed",0));talks=int(saved.get("talks",0));entries=int(saved.get("entries",0));exits=int(saved.get("exits",0));visits=saved.get("visits",{}).duplicate()
	arrived=position.distance_to(route[-1])<.3
	patrol_leg=int(saved.get("patrol_leg",0))%2
	patrol_station_wait=maxf(0.0,float(saved.get("patrol_station_wait",0.0)))
	patrol_observations=int(saved.get("patrol_observations",0))
	social_events=int(saved.get("social_events",0))
	social_last_partner=str(saved.get("social_last_partner",""))
	social_cooldown=clampf(float(saved.get("social_cooldown",0.0))-maxf(0.0,now-float(saved.get("snapshot_clock",now))),0.0,120.0)
	# A resident in an unloaded region progresses by schedule, not a frozen old pose.
	if saved.has("snapshot_clock") and now-float(saved.snapshot_clock)>45.0 and not routes.is_empty():
		var plan: Dictionary=Planner.choose(identity,now)
		var target: String=str(plan.slot)
		if routes.has(target+">"+target) and not routes[target+">"+target].is_empty():
			from_slot=target;to_slot=target;route=routes[target+">"+target].duplicate()
			position=route[0];route_index=route.size()-1;position=route[route_index]
			arrived=true
func _exit_tree() -> void:
	if is_instance_valid(rig):VisualR10.cleanup(rig)

func desired_slot(hour: int) -> String:
	return str(Planner.choose(identity,game_clock if game_clock>0 else float(hour)*90.0).slot)
func _change_destination(target: String) -> void:
	if to_slot==target or not routes.has(to_slot+">"+target):return
	var next_path: Array=routes[to_slot+">"+target]
	if next_path.is_empty():unreachable_count+=1;return
	from_slot=to_slot;to_slot=target;route=next_path.duplicate();route_index=0;arrived=false
	if sheltered:exits+=1
	sheltered=false
	waits=.08+float(abs(str(identity.id).hash())%9)*.08
func _decide(delta: float,now: float) -> void:
	game_clock=now
	decision_timer-=delta
	if decision_timer>0.0:return
	decision_timer=(.35 if near_player else .85)+float(abs(str(identity.id).hash())%7)*.023
	var context: Dictionary={"danger":danger_nearby,"patrol_leg":patrol_leg,
		"social_opportunity":not nearby_residents.is_empty() and not danger_nearby}
	var plan: Dictionary=Planner.choose(identity,game_clock,context)
	if bool(ProjectSettings.get_setting("exo_murim/convergence4/npc03_enabled",true)):
		var proposed:Dictionary=preload("res://npc_system03/core/agenda.gd").choose(identity,game_clock,context)
		var slot:String=str(proposed.get("slot",""))
		if str(proposed.get("status",""))=="PROPOSED" and (slot==to_slot or routes.has(to_slot+">"+slot)):
			plan={"activity":str(proposed.activity),"slot":slot,"priority":int(proposed.priority)}
			set_meta("npc03_accepted",int(get_meta("npc03_accepted",0))+1)
			set_meta("npc03_work_type",str(proposed.get("work_type","")))
	# Alternate existing road-graph corridors: square -> post -> square.
	# The real route contains multiple physical waypoints and observation stops.
	if plan.activity=="patrulhar" and arrived and patrol_station_wait<=0.0:
		patrol_leg=(patrol_leg+1)%2
		context.patrol_leg=patrol_leg
		plan=Planner.choose(identity,game_clock,context)
	activity_name=str(plan.activity);logical_slot=str(plan.slot);last_priority=int(plan.priority)
	if routes.is_empty() or logical_slot.is_empty():return
	# Normal errands finish their current commute. Threats can change route immediately.
	if (arrived or last_priority>=90) and logical_slot!=to_slot:
		if plan.activity=="patrulhar" and patrol_station_wait>0:return
		_change_destination(logical_slot)
func begin_social(other: Node3D) -> void:
	if not is_instance_valid(other) or other==self or social_time>0 or social_cooldown>0:return
	social_target=other
	social_last_partner=str((other.get("identity") as Dictionary).get("id",""))
	social_time=2.0+float(abs(str(identity.id).hash())%3)
	social_cooldown=(65.0 if str(identity.get("personality",""))=="reservado" else 23.0 if str(identity.get("personality",""))=="sociavel" else 35.0)+float(identity.get("social_cooldown_bias",0))
	social_events+=1
func _social_tick(delta: float) -> void:
	social_time=maxf(0.0,social_time-delta)
	social_cooldown=maxf(0.0,social_cooldown-delta)
	if social_time>0 and is_instance_valid(social_target):
		var direction: Vector3=social_target.position-position
		rig.rotation.y=lerp_angle(rig.rotation.y,atan2(-direction.x,-direction.z),minf(1.0,delta*3.0))
	if social_time<=0:social_target=null
func step(delta: float,hour: int,now: float=-1.0) -> void:
	clock+=delta;paused_for_talk=maxf(0.0,paused_for_talk-delta)
	patrol_station_wait=maxf(0.0,patrol_station_wait-delta)
	_social_tick(delta)
	_decide(delta,now if now>=0.0 else game_clock+delta)
	waits=maxf(0.0,waits-delta)
	if arrived and activity_name in ["descanso","fora_de_servico"] and paused_for_talk<=0:
		if not sheltered:entries+=1
		sheltered=true
	else:sheltered=false
	collision_layer=0 if sheltered else 8
	rig.visible=not sheltered and presentation_visible;caption.visible=rig.visible
	if route.is_empty():return
	var destination: Vector3=route[route_index]
	var offset:=destination-position;offset.y=0
	if offset.length()<.25:
		if route_index<route.size()-1:
			route_index+=1
			# Observe at separated waypoints instead of only walking between two posts.
			if activity_name=="patrulhar" and route_index%3==0:
				waits=1.0+float(abs(str(identity.id).hash())%4)*.25
				patrol_observations+=1
		elif not arrived:
			arrived=true;visits[to_slot]=int(visits.get(to_slot,0))+1
			if activity_name=="patrulhar":patrol_station_wait=2.0+float(abs(str(identity.id).hash())%4)
	var moving: bool=not arrived and offset.length()>.12 and waits<=0 and paused_for_talk<=0 and social_time<=0
	if moving:
		# Light avoidance within a short radius. This is not crowd pathfinding:
		# it prevents residents from visually overlapping on shared street paths.
		separation_clock-=delta
		if separation_clock<=0.0:
			separation_clock=0.24
			separation_force=Vector3.ZERO
			for another in nearby_residents:
				if another==self or not is_instance_valid(another) or another.sheltered:continue
				var away: Vector3=position-another.position;away.y=0
				var d2: float=away.length_squared()
				if d2>0.01 and d2<2.25:
					var d: float=sqrt(d2)
					separation_force+=away/d*(1.5-d)/1.5
		var motion: Vector3=(offset.normalized()+separation_force*0.52).normalized()*1.65
		velocity.x=motion.x;velocity.z=motion.z
		rig.rotation.y=lerp_angle(rig.rotation.y,atan2(-offset.x,-offset.z),minf(1,delta*8))
	else:
		velocity.x=0;velocity.z=0
		if arrived and not sheltered and paused_for_talk<=0 and social_time<=0:
			if (attention_near and str(identity.get("personality",""))=="sociavel") or (danger_nearby and activity_name in ["alerta","observar_risco"]):
				var facing_player: Vector3=player_interest_position-position
				rig.rotation.y=lerp_angle(rig.rotation.y,atan2(-facing_player.x,-facing_player.z),minf(1.0,delta*3.0))
			else:rig.rotation.y=lerp_angle(rig.rotation.y,sin(clock*.18+float(abs(identity.id.hash())%10))*.6,minf(1,delta*.5))
	if not is_on_floor():velocity.y-=20*delta
	var before:=position
	# Settled residents stand on static terrain. Resume the full sweep as soon as
	# a route starts or floor contact is absent; no offscreen navigation is skipped.
	if moving or not is_on_floor():move_and_slide()
	var distance:=Vector2(position.x-before.x,position.z-before.z).length();travelled+=distance
	blocked_seconds=blocked_seconds+delta if moving and distance<delta*.15 else 0.0
	if blocked_seconds>2:
		# Backtrack physically to the preceding waypoint, then retry. Never teleport.
		route_index=maxi(0,route_index-1);waits=.8+float(recoveries%3)*.25;blocked_seconds=0;recoveries+=1
		if recoveries%5==0:
			# Give temporarily blocked passages time to clear; no NPC teleport.
			unreachable_count+=1;waits=3.0
	if visual_active:
		rig.pose(clock,false,false,is_on_floor());rig.locomotion(get_real_velocity() if moving else Vector3.ZERO,delta,false,is_on_floor(),true)
	# Activity cycles are logical and continue even offscreen. Rendering is optional.
	if arrived and not sheltered and paused_for_talk<=0 and activity_name in ["treino","meditacao","plantio","colheita","trabalho","posto","preparar_banca","fechar_banca","atendimento","preparar_remedios","administracao","revisar_registros","organizar_oficina","organizar_mercadorias","treino_individual"]:
		action_elapsed+=delta
		if action_elapsed>=6.0:
			action_elapsed-=6.0
			work_cycles+=1
			action_variant=(action_variant+1)%3
	else:action_elapsed=0.0
	if visual_active and arrived and not sheltered:
		if social_time>0.0 and is_instance_valid(social_target):
			var facing: Vector3=social_target.position-position
			rig.rotation.y=lerp_angle(rig.rotation.y,atan2(-facing.x,-facing.z),minf(1.0,delta*4.0))
		if social_time>0.0:rig.forearms[0].rotation.x=-.25+.25*sin(clock*4.0)
		if activity_name in ["treino","treino_individual"]:
			rig.forearms[0].rotation.x=-.75-.55*sin(clock*3.4);rig.torso.rotation.y=sin(clock*1.7)*.17
		elif activity_name in ["plantio","colheita","trabalho","preparar_banca","fechar_banca","atendimento","preparar_remedios","administracao","revisar_registros","organizar_oficina","organizar_mercadorias","treino_individual"]:
			rig.forearms[0].rotation.x=-.52-.35*sin(clock*(2.0+float(action_variant)*.3));rig.torso.rotation.x=.16
		elif activity_name in ["alerta","observar_risco","investigar"]:
			rig.forearms[0].rotation.x=-.7;rig.forearms[1].rotation.x=-.55
		elif activity_name=="meditacao":
			rig.forearms[0].rotation.x=-.4;rig.torso.rotation.y=sin(clock*.4)*.03
func step_far(delta: float,now: float) -> void:
	# Far residents follow the already computed safe road waypoints. No rendering,
	# physics sweeps, scene spawn, or expensive perception while well outside view.
	clock+=delta
	paused_for_talk=maxf(0.0,paused_for_talk-delta)
	_social_tick(delta)
	_decide(delta,now)
	if route.is_empty():return
	waits=maxf(0.0,waits-delta)
	if arrived and activity_name in ["descanso","fora_de_servico"]:
		if not sheltered:entries+=1
		sheltered=true
	else:sheltered=false
	collision_layer=0
	rig.visible=false;caption.visible=false
	if arrived or waits>0 or paused_for_talk>0:return
	var target: Vector3=route[route_index]
	var distance: float=position.distance_to(target)
	if distance<.25:
		if route_index<route.size()-1:route_index+=1
		else:arrived=true;visits[to_slot]=int(visits.get(to_slot,0))+1
	else:
		var move: float=minf(distance,delta*1.6)
		position=position.move_toward(target,move)
		travelled+=move
func snapshot(at_clock: float=-1.0) -> Dictionary:
	var visual_r2:Dictionary=rig.get_meta("exo_humanoid_r2_selection",{}) if is_instance_valid(rig) else {}
	return {"visual_r2":visual_r2.duplicate(true),"snapshot_clock":at_clock if at_clock>=0.0 else game_clock,"social_events":social_events,"social_last_partner":social_last_partner,"social_cooldown":social_cooldown,"unreachable_count":unreachable_count,"patrol_leg":patrol_leg,"patrol_station_wait":patrol_station_wait,"patrol_observations":patrol_observations,"position":[position.x,position.y,position.z],"route_index":route_index,"activity":activity_name,"from_slot":from_slot,"to_slot":to_slot,"sheltered_proxy":sheltered,"entries":entries,"exits":exits,"talks":talks,"work_cycles":work_cycles,"action_elapsed":action_elapsed,"visits":visits.duplicate(),"routine_version":3}
