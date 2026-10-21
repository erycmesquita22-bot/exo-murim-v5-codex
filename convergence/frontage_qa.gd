extends SceneTree
var w: Node3D
var failures: Array=[]
var checks: Array=[]
var rows: Array=[]
func _initialize():call_deferred("run")
func check(value: bool,label: String):
	checks.append({"test":label,"pass":value});print("CHECK ",label," ",value)
	if not value:failures.append(label)
func run():
	w=load("res://convergence/game.gd").new();w.load_on_start=false;w.world_seed_override=101;w.save_path="user://frontage_qa_v3.json";root.add_child(w);await process_frame
	w.flow.phase="creator";w.flow.create_character({"name":"Frontage QA","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0});w.ui.resume()
	for rid in [86,15,78]:
		check(await w.change_region(rid),"open_"+str(rid)+":"+w.generation_failure)
		if w.active_region==null:w.free();quit(1);return
		w.set_physics_process(false)
		var region: Node3D=w.active_region
		var all_positions: Array=[];var intersections: Array=[];var min_distance:=INF;var depth_range:=0.0
		for lot in region.data.lots:
			var forward:=Vector3(sin(lot.yaw),0,cos(lot.yaw))
			var min_depth:=INF;var max_depth:=-INF
			for actor in w.residents:
				if actor.identity.home_slot!=lot.id and actor.identity.work_slot!=lot.id:continue
				var p: Vector3=actor.routes[lot.id+">"+lot.id][-1]
				var d: float=(p-region.station_points[lot.id]).dot(forward)
				min_depth=minf(min_depth,d);max_depth=maxf(max_depth,d)
				var query:=PhysicsShapeQueryParameters3D.new();query.shape=actor.get_child(0).shape;query.collision_mask=4
				query.transform=Transform3D(Basis.IDENTITY,p+Vector3(0,.96,0))
				if not w.get_world_3d().direct_space_state.intersect_shape(query).is_empty():intersections.append({"lot":lot.id,"person":actor.identity.id,"point":str(p)})
				for other in all_positions:min_distance=minf(min_distance,Vector2(p.x,p.z).distance_to(Vector2(other.x,other.z)))
				all_positions.append(p)
			if min_depth<INF:depth_range=maxf(depth_range,max_depth-min_depth)
		check(depth_range<.01,"facade_parallel_single_row_"+str(rid))
		check(min_distance>=1.49,"distinct_stations_"+str(rid)+":"+str(min_distance))
		check(intersections.is_empty(),"station_collisions_"+str(rid)+":"+str(intersections))
		rows.append({"rid":rid,"buildings":region.props.size(),"npcs":w.residents.size(),"min_station_distance":min_distance,"depth_range":depth_range,"intersections":intersections})
		var legacy: Dictionary=w.residents[0].snapshot()
		legacy.routine_version=2;legacy.position=[999.0,20.0,999.0];legacy.route_index=2;legacy.talks=7
		var migrated=load("res://convergence/resident.gd").new();w.add_child(migrated)
		migrated.setup(w.residents[0].identity,region.route_points[w.residents[0].identity.home_slot],legacy,w.residents[0].routes)
		check(migrated.position.distance_to(migrated.route[0])<.01 and migrated.route_index==0,"old_station_relocated_"+str(rid))
		check(migrated.talks==7 and migrated.identity==w.residents[0].identity,"identity_and_talks_preserved_"+str(rid))
		migrated.free()
		# Visibility must reject offscreen and an actual physics blocker, not just hide names.
		var actor: Node3D=w.residents[0];actor.sheltered=false
		w.player.position=actor.position+Vector3(0,0,2);w.update_camera()
		var target: Vector3=actor.position+Vector3.UP
		w.camera.position=target+Vector3(0,8,10);w.camera.look_at(target)
		var block:=StaticBody3D.new();var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(8,8,1);shape.shape=box;block.add_child(shape);block.collision_layer=4
		w.add_child(block);block.position=target+Vector3(0,4,5)
		await physics_frame;await physics_frame
		check(not w.resident_is_visible(actor),"occluded_body_hidden_"+str(rid))
		block.free();await physics_frame;await physics_frame
		var roof_visual:=MeshInstance3D.new();var roof_box:=BoxMesh.new();roof_box.size=Vector3(8,8,1);roof_visual.mesh=roof_box;w.add_child(roof_visual)
		roof_visual.position=target+Vector3(0,4,5);w.resident_roof_occluders.append(roof_visual)
		check(not w.resident_is_visible(actor),"roof_without_collider_hidden_"+str(rid))
		w.resident_roof_occluders.erase(roof_visual);roof_visual.free()
		w.camera.position=actor.position+Vector3(0,12,0);w.camera.look_at(actor.position,Vector3.FORWARD)
		check(w.resident_is_visible(actor),"clear_body_visible_"+str(rid))
		w.camera.position+=Vector3(1000,0,0)
		check(not w.resident_is_visible(actor),"offscreen_body_hidden_"+str(rid))
		w.set_physics_process(true)
	var state: Dictionary=JSON.parse_string(JSON.stringify(w.extension()))
	for version in [4.0,5.0,6.0,7.0]:
		state.regional_version=version
		check(preload("res://convergence/state.gd").valid(state)==(version<7),"json_layout_version_"+str(version))
	FileAccess.open("res://convergence/validation_frontage/frontage-result.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"regions":rows},"  "))
	print("FRONTAGE_QA checks=",checks.size()," failures=",failures)
	w.set_physics_process(false);w.audio_fx.shutdown();w.free();quit(int(not failures.is_empty()))
