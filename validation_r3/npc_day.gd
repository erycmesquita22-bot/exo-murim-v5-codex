extends "res://validation_r3/support.gd"
var probe:=false
func _initialize():probe="probe" in OS.get_cmdline_user_args();call_deferred("run")
func run():
	await boot("user://functional_r3_npc_day_v1.json")
	check(await w.change_region(78),"city_65_residents")
	await frames(5)
	var targets: Array=[];var minimum:=INF;var overlaps: Array=[]
	for actor in w.residents:
		var p: Vector3=actor.routes[str(actor.identity.home_slot)+">@activity"][-1]
		for point in targets:minimum=minf(minimum,p.distance_to(point))
		targets.append(p)
	check(minimum>=1.0,"work_points_separated:"+str(minimum))
	facts["min_work_point_distance"]=minimum
	if probe:await finish("npc_probe");return
	w.extension().clock=0.0
	var roster: Dictionary=w.journey.data.living_world.npcs.duplicate(true)
	var roles: Dictionary={};var sampled: Array=[];var hours: Dictionary={};var interrupted:=false;var collision_ids: Dictionary={}
	var start_clock: float=w.extension().clock
	while float(w.extension().clock)<start_clock+2160.0:
		await physics_frame
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
				w.player.position=actor.position+Vector3(0,0,1);w.player.velocity=Vector3.ZERO;w.update_camera()
				await frames(30)
				if not actor.rig.visible:continue
				w.interaction_cooldown=0;w.gate_cooldown=0
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
	check(w.save_progress(),"save_day_state")
	facts["hours"]=sampled;facts["roles"]=roles;facts["population"]=w.residents.size();facts["simulated_seconds"]=float(w.extension().clock)-start_clock
	await finish("npc_day")
