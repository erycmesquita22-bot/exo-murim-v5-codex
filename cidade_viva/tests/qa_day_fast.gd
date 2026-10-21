extends "res://validation_r3/support.gd"
## Isolated continuous NPC timeline: actual actors, routes, floor collision and save.
## Player/ecology/render updates are suspended; this is not a 60Hz full-game session.
var probe:=false
var manual_npc_clock:=false
func frames(n: int):
	for i in range(n):
		await physics_frame
		if manual_npc_clock:
			preload("res://ai_core/world_clock.gd").advance(w.extension(),.2)
			var hour: int=preload("res://ai_core/world_clock.gd").hour(w.extension())
			for actor in w.residents:
				actor.visual_active=false;actor.presentation_visible=true;actor.step(.2,hour)
func _initialize():
	Engine.physics_ticks_per_second=60
	probe="probe" in OS.get_cmdline_user_args();call_deferred("run")
func run():
	await boot("user://functional_r3_npc_day_v1.json")
	# Begin at midnight before spawning the roster, without rewinding a commute.
	w.extension().clock=0.0
	check(await w.change_region(78),"city_65_residents")
	await frames(30)
	var grounded:=true
	for actor in w.residents:grounded=grounded and actor.is_on_floor() and absf(actor.position.y-w.active_region.data.height_at(Vector2(actor.position.x,actor.position.z)))<.15
	check(grounded,"all_residents_settle_at_production_60hz")
	var targets: Array=[];var minimum:=INF;var overlaps: Array=[]
	for actor in w.residents:
		var p: Vector3=actor.routes[str(actor.identity.home_slot)+">@activity"][-1]
		for point in targets:minimum=minf(minimum,p.distance_to(point))
		targets.append(p)
	check(minimum>=1.0,"work_points_separated:"+str(minimum))
	facts["min_work_point_distance"]=minimum
	if probe:await finish("npc_probe");return
	w.set_physics_process(false);w.encounters.set_physics_process(false);w.ui.set_process(false)
	# Keep real character bodies/terrain in physics, without updating visual subtrees.
	for actor in w.residents:
		actor.remove_child(actor.rig);actor.remove_child(actor.caption)
	manual_npc_clock=true
	Engine.physics_ticks_per_second=5
	facts["fixture"]={"physics_hz":5,"continuous_npc_clock":true,"real_actor_step":true,"visual_subtrees_detached":true,"world_player_ecology_updates":false,"production_physics_hz":60}
	w.extension().clock=0.0
	var roster: Dictionary=w.journey.data.living_world.npcs.duplicate(true)
	var roles: Dictionary={};var sampled: Array=[];var hours: Dictionary={};var interrupted:=false;var collision_ids: Dictionary={}
	var start_clock: float=w.extension().clock
	while float(w.extension().clock)<start_clock+2160.0:
		await frames(1)
		var hour: int=preload("res://ai_core/world_clock.gd").hour(w.extension())
		var half_hour: int=int(float(w.extension().clock)/45.0)
		if not hours.has(half_hour):
			hours[half_hour]=true
			var counts: Dictionary={"hour":hour,"clock":w.extension().clock,"travel":0,"work":0,"rest":0,"community":0}
			for actor in w.residents:
				var role: String=str(actor.identity.role)
				if not roles.has(role):roles[role]={"activities":{},"cycles":0}
				roles[role].activities[actor.activity_name]=true;roles[role].cycles=maxi(int(roles[role].cycles),actor.work_cycles)
				if not actor.arrived:counts.travel+=1
				if actor.sheltered:counts.rest+=1
				if actor.arrived and actor.to_slot=="@activity":counts.work+=1
				if actor.arrived and actor.to_slot=="@square":counts.community+=1
				var q:=PhysicsShapeQueryParameters3D.new();q.shape=actor.get_child(0).shape;q.collision_mask=4;q.transform=actor.get_child(0).global_transform
				if not w.get_world_3d().direct_space_state.intersect_shape(q).is_empty():collision_ids[actor.identity.id]=str(actor.position)
			sampled.append(counts);print("NPC_HOUR ",JSON.stringify(counts))
		if not interrupted and hour==10:
			for actor in w.residents:
				if not actor.arrived or actor.sheltered:continue
				var talk_point:=Vector3.INF
				for offset in [Vector3(0,0,.65),Vector3(.65,0,0),Vector3(0,0,-.65),Vector3(-.65,0,0)]:
					var candidate: Vector3=w.regional_spawn(w.active_region,actor.position+offset)
					if candidate.is_finite():talk_point=candidate;break
				if not talk_point.is_finite():continue
				w.player.position=talk_point;w.player.velocity=Vector3.ZERO;w.update_camera()
				await frames(30)
				if not actor.rig.visible:continue
				w.player.velocity=Vector3(0,-1,0);w.player.move_and_slide();w.player.apply_floor_snap();w.player.velocity=Vector3.ZERO
				w.interaction_cooldown=0;w.gate_cooldown=0
				facts["interaction_fixture"]={"player_on_floor":w.player.is_on_floor(),"paused":paused,"actor_distance":w.player.position.distance_to(actor.position),"target":actor.identity.id}
				var before: int=actor.talks;var cycles: int=actor.work_cycles;w.interact();w.ui.resume()
				check(actor.talks>before,"day_dialogue_interruption")
				await frames(720)
				check(actor.work_cycles>cycles,"work_resumes_after_dialogue")
				interrupted=true;break
	var active_visits:=0;var sleepers:=0;var travellers:=0
	for actor in w.residents:
		if int(actor.visits.get("@activity",0))>0:active_visits+=1
		if actor.entries>0 and actor.exits>0:sleepers+=1
		if actor.travelled>2:travellers+=1
	check(active_visits==w.residents.size(),"all_work_arrivals:%d/%d"%[active_visits,w.residents.size()])
	check(sleepers==w.residents.size(),"sleep_and_resume:%d/%d"%[sleepers,w.residents.size()])
	check(travellers==w.residents.size(),"all_residents_physically_move")
	check(collision_ids.is_empty(),"no_sampled_building_penetration:"+str(collision_ids))
	check(interrupted,"dialogue_test_executed")
	check(w.journey.data.living_world.npcs==roster,"day_preserves_identities")
	check(roles.has("master") and roles.has("disciple") and roles.has("merchant") and roles.has("courier"),"different_professions")
	for actor in w.residents:
		actor.add_child(actor.rig);actor.add_child(actor.caption)
	check(w.save_progress(),"save_day_state")
	facts["hours"]=sampled;facts["roles"]=roles;facts["population"]=w.residents.size();facts["simulated_seconds"]=float(w.extension().clock)-start_clock
	await finish("npc_day")
