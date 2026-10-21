extends SceneTree
var w:Node3D
var failures:Array=[]
var records:Array=[]
var baseline:bool=OS.get_environment("EXO_QA_BASELINE")=="1"
var out:String=OS.get_environment("EXO_QA_OUT")
func check(ok:bool,label:String):
	print("SCENE_CHECK ",label," ",ok)
	if not ok:failures.append(label)
func _initialize():call_deferred("run")
func shot(label:String,focus:Vector3,size:float):
	w.camera.far=1200.0
	w.camera.size=size;w.camera.position=focus+Vector3(size*.7,size*.95,size*.65);w.camera.look_at(focus)
	for i in range(6):await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(out+"/"+label+".png")==OK,"capture/"+label)
func rows()->Array:
	var result:Array=[]
	if not w.active_region.has_node("EXO_Crowd_Illusion_01"):return result
	for renderer in w.active_region.get_node("EXO_Crowd_Illusion_01").get_children():result.append(renderer)
	return result
func inspect_city(seed_value:int,rid:int):
	check(await w.change_region(rid),"city/"+str(seed_value)+"/"+str(rid))
	w.ui.resume();w.simulation_enabled=false;w.set_physics_process(false)
	var region:Node3D=w.active_region
	check(region.data.worldgen_v4 and region.data.settlement_plan.get("owner","")=="city_forge_r4","v4_authorities")
	check(not w.residents.is_empty(),"canonical_npcs")
	var mesh_count:int=0;var vertex_count:int=0;var bad_vertices:int=0
	for child in region.get_children():
		if not child is MeshInstance3D or not str(child.name).begins_with("TerrainR3Pavement"):continue
		mesh_count+=1
		for v in child.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			vertex_count+=1
			if not v.is_finite() or absf(v.x)>region.data.half-.249 or absf(v.z)>region.data.half-.249:bad_vertices+=1
	var crowd:Dictionary=w.exo_core.services.invoke("crowd.illusion","status")
	var lengths:Array=[];var route_points:int=0;var no_floor:int=0
	var atlased:int=0
	if not baseline:
		check(mesh_count>0 and bad_vertices==0,"materialized_pavement_bounds")
		check(region.get_meta("exo_crowd_npc_skin_receipt",{}).get("ok",false),"canonical_texture_receipt")
		var atlas:Image=region.get_meta("exo_crowd_npc_atlas").get_image()
		for i in range(64):
			var source:Image=w.residents[i%mini(64,w.residents.size())].rig.skin.albedo_texture.get_image()
			source.convert(Image.FORMAT_RGBA8)
			if source.get_data()==atlas.get_region(Rect2i((i%8)*256,(i/8)*256,256,256)).get_data():atlased+=1
		check(atlased==64,"64_tiles_equal_live_npc_textures")
		check(crowd.get("ghosts",0)>0,"crowd_materialized")
	for renderer in rows():
		for actor in renderer.agents:
			lengths.append(float(actor.get("route_length",actor.a.distance_to(actor.b))))
			if baseline:continue
			for p in actor.route:
				route_points+=1
				var hit:Dictionary=region.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p+Vector3.UP*3,p-Vector3.UP*3,1))
				if hit.is_empty() or absf(hit.position.y-(p.y-.04))>.08:no_floor+=1
	if not baseline:check(no_floor==0 and not lengths.is_empty() and lengths.min()>=8.999,"real_route_floor_and_length")
	var record:Dictionary={"seed":seed_value,"region":rid,"baseline":baseline,"pavements":region.get_meta("terrain_r3_pavements",{}),"materialized_meshes":mesh_count,"vertices":vertex_count,"invalid_or_outside_vertices":bad_vertices,"npcs":w.residents.size(),"crowd":crowd,"route_lengths":lengths,"route_points":route_points,"missing_or_wrong_floor":no_floor,"exact_npc_tiles":atlased,"geometry":region.get_meta("v4_crowd_check",{})}
	records.append(record);print("SCENE_RECORD ",JSON.stringify(record))
	if seed_value==101 and rid==78:
		var zone_rows:Array=rows()
		var focus:Vector3=w.residents[0].position
		if not zone_rows.is_empty():focus=zone_rows[0].agents[0].position
		w.player.position=focus+Vector3(3,0,3)
		if not baseline:
			var prior:Vector3=w.player.position;w.player.position=Vector3(220,region.data.center_h+2,220)
			check(w.interaction_hint().is_empty(),"no_permanent_hint_without_target")
			w.player.position=prior
		await shot("city78-wide",focus,120)
		await shot("crowd-t0",focus,22)
		# Actual wall-clock observation in the renderer; no fixed-fps benchmark claim.
		var observation_seconds:int=20 if baseline else 180
		if OS.get_environment("EXO_QA_SKIP_OBSERVATION")=="1":observation_seconds=0
		var start:int=Time.get_ticks_msec()
		var first_positions:Dictionary={};var previous_positions:Dictionary={}
		var inversions:int=0;var sampled:int=0
		for renderer in zone_rows:
			for actor in renderer.agents:
				first_positions[actor.id]=renderer._actor_pos(actor);previous_positions[actor.id]=renderer._actor_pos(actor)
		while Time.get_ticks_msec()-start<observation_seconds*1000:
			await create_timer(1.0).timeout
			for renderer in zone_rows:
				for actor in renderer.agents:
					var at:Vector3=renderer._actor_pos(actor)
					if (at-previous_positions[actor.id]).dot(actor.b-actor.a)<-.001:inversions+=1
					previous_positions[actor.id]=at;sampled+=1
			if Time.get_ticks_msec()-start>4500 and Time.get_ticks_msec()-start<6000:await shot("crowd-t5",focus,22)
		await shot("crowd-end",focus,22)
		var stopped:int=0
		for renderer in zone_rows:
			for actor in renderer.agents:
				if renderer._actor_pos(actor).distance_to(actor.b)<.01:stopped+=1
		var observation:Dictionary={"actual_elapsed_ms":Time.get_ticks_msec()-start,"samples":sampled,"reverse_samples":inversions,"stopped_at_destination":stopped,"baseline":baseline}
		print("OBSERVATION ",JSON.stringify(observation));records.append(observation)
		if not baseline and observation_seconds>=180:check(inversions==0 and stopped==crowd.ghosts,"180s_no_pingpong_and_stopped")
		# Replan through the authorized director, keeping the current scene receipt.
		w.exo_core.services.invoke("crowd.illusion","set_hour",[11])
		for i in range(3):await process_frame
		var after:Dictionary=w.exo_core.services.invoke("crowd.illusion","status")
		if not baseline:check(after.ghosts>0 and after.zones<=4 and after.hour==11,"replan_reuses_physical_lanes")
		w.player.position=w.regional_spawn(region,w.residents[0].position+Vector3(2,0,0))
		await shot("real-npc",w.residents[0].position,12)
	check(w.save_progress(),"save_scene")
func run():
	if out.is_empty():out=ProjectSettings.globalize_path("res://REPARACAO_CHAT_V4/evidence/after")
	DirAccess.make_dir_recursive_absolute(out)
	for seed_value in ([101] if baseline else [101,707,2026]):
		w=preload("res://convergence/game.gd").new();w.load_on_start=false;w.save_path="user://repair_v4_"+str(seed_value)+".json";root.add_child(w);await process_frame
		w.flow.phase="creator"
		check(w.flow.create_character({"name":"QA reparacao","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0,"weapon":"sword","outfit":0},seed_value),"new_campaign/"+str(seed_value))
		for i in range(1800):
			await physics_frame
			if w.current_region>=0 and not w.changing_region:break
		w.ui.resume();w.simulation_enabled=false;w.extension().clock=1080.0
		var city_ids:Array=[]
		for spec in w.atlas.regions:
			if str(spec.get("kind",""))=="settlement" and str(spec.get("settlement_scale",""))=="city":city_ids.append(int(spec.id))
		check(not city_ids.is_empty(),"seed_has_actual_cities")
		var selected:int=78 if seed_value==101 else int(city_ids[0])
		await inspect_city(seed_value,selected)
		if not baseline and seed_value==101:await inspect_city(seed_value,14)
		if not baseline and seed_value==707 and city_ids.size()>1:await inspect_city(seed_value,int(city_ids[1]))
		if not baseline:
			check(await w.change_region(0),"wild_traversal")
			check(w.active_region.data.worldgen_v4,"wild_keeps_worldgen_v4")
			check(w.exo_core.services.invoke("crowd.illusion","status").ghosts==0,"wild_no_unapproved_crowd")
			check(w.save_progress(),"save_wild")
		w.queue_free();await process_frame;await process_frame
	FileAccess.open(out+"/scene-results.json",FileAccess.WRITE).store_string(JSON.stringify({"failures":failures,"records":records},"  "))
	print("SCENE_RESULT ",JSON.stringify({"failures":failures,"records":records.size()}))
	quit(0 if failures.is_empty() else 1)
