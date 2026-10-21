extends SceneTree
const Game=preload("res://convergence/game.gd")
var w: Node3D
var failures: Array=[]
var checks: Array=[]
var rows: Array=[]
var capture:=false
var extreme:=false
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	print("CHECK ",label," ",ok)
	checks.append({"test":label,"pass":ok})
	if not ok:failures.append(label);print("FAIL ",label)
func frames(n: int) -> void:
	for k in range(n):await physics_frame
func run() -> void:
	capture="capture" in OS.get_cmdline_user_args()
	extreme="extreme" in OS.get_cmdline_user_args()
	root.size=Vector2i(1152,720)
	w=Game.new();w.load_on_start=false;w.world_seed_override=101;w.save_path="user://convergence_qa_extreme012.json" if extreme else "user://convergence_qa.json";w.settings_path="user://convergence_qa.cfg";root.add_child(w)
	await process_frame
	w.flow.phase="creator";check(w.flow.create_character({"name":"Convergencia QA","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0,"weapon":"sword"}),"create_character")
	w.ui.resume();await frames(10)
	check(w.current_region==-1 and w.flow.phase=="adventure","legacy_adventure")
	# Keep existing initial mission/combat untouched; generated regions are tested here.
	for seed_text in (["9007199254740993","9223372036854775807"] if extreme else ["101"] if capture else ["101","707","816204"]):
		if w.current_region>=0:w.return_home()
		# Each seed is a distinct test world. Reset all seed-bound extensions together.
		for domain in ["living_world","journey_dynamic","narrative","exo_core"]:w.journey.data.erase(domain)
		preload("res://exo_core/persistence/migration_registry.gd").upgrade(w.journey.data)
		w.exo_core.observed={};w.journey_manager.state()
		w.extension().actors.clear()
		w.atlas.clear();w.extension().atlas_seed=seed_text;w.extension().erase("atlas")
		check(w.ensure_atlas(),"atlas_"+seed_text)
		var ids: Array=([48] if seed_text=="9007199254740993" else [35,63]) if extreme else [32,46,52,61,63,78,86] if seed_text=="101" else []
		if ids.is_empty():
			for scale in ["village","town","city"]:
				for spec in w.atlas.regions:
					if spec.kind=="settlement" and spec.settlement_scale==scale:ids.append(int(spec.id));break
		for rid in ids:
			print("BUILD ",seed_text," ",rid)
			var ok: bool=await w.change_region(rid)
			check(ok,"region_%s_%d:%s"%[seed_text,rid,w.generation_failure])
			if not ok:continue
			await frames(8)
			check(w.player.is_on_floor(),"arrival_grounded_%s_%d"%[seed_text,rid])
			var region: Node3D=w.active_region
			var blocked: Array=[];var supports: Array=[];var crossings: Array=[]
			if region.data.spec.kind=="settlement":
				check(region.props.size()==int(region.data.settlement_plan.target),"all_houses_%s_%d"%[seed_text,rid])
				check(w.residents.size()==region.assigned_slots.size() and w.residents.size()>region.props.size(),"physical_npcs_%s_%d"%[seed_text,rid])
				# Physical capsule sweep and support rays along every actual entrance approach.
				for lot in region.data.lots:
					var route: Array=region.route_points[lot.id]
					var start: Vector3=route[0];var end: Vector3=route[2]
					for k in range(17):
						var point: Vector3=start.lerp(end,float(k)/16)
						point.y=region.data.height_at(Vector2(point.x,point.z))+.07
						var hit: Dictionary=w.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(point+Vector3.UP*3,point-Vector3.UP*4,1))
						if hit.is_empty():supports.append(lot.id);break
						var q:=PhysicsShapeQueryParameters3D.new();q.shape=w.player.get_child(0).shape;q.transform=Transform3D(Basis.IDENTITY,point+Vector3(0,.98,0));q.collision_mask=4
						if not w.get_world_3d().direct_space_state.intersect_shape(q).is_empty():blocked.append(lot.id);break
					# Walk a character body from the exterior through the open door to floor.
					var holder: Node3D=region.props[region.data.lots.find(lot)]
					var house: Node3D=holder.get_child(0)
					var entrance: Vector3=house.get_node("AnchorEntrance").global_position
					var inside: Vector3=house.global_transform*Vector3(entrance_to_local(house).x,.48,0)
					w.player.position=start;w.player.velocity=Vector3.ZERO
					var reached:=false
					for step in range(160):
						var offset: Vector3=inside-w.player.position;offset.y=0
						if offset.length()<.35:reached=true;break
						w.simulation_enabled=false
						w.player.velocity=offset.normalized()*3.6;w.player.velocity.y=-3
						w.player.move_and_slide();await physics_frame
					w.simulation_enabled=true
					if not reached:crossings.append(lot.id)
				check(blocked.is_empty(),"approach_capsules_%s_%d:%s"%[seed_text,rid,blocked])
				check(supports.is_empty(),"approach_support_%s_%d"%[seed_text,rid])
				check(crossings.is_empty(),"door_crossings_%s_%d:%s"%[seed_text,rid,crossings])
				var moved:=0
				for actor in w.residents:
					if actor.travelled>.5:moved+=1
				check(moved>0,"residents_move_%s_%d"%[seed_text,rid])
				if not w.residents.is_empty():
					var actor: Node3D=w.residents[0];actor.paused_for_talk=4;w.player.position=actor.position+Vector3(0,0,.8);w.player.velocity=Vector3.ZERO;await frames(24);w.interaction_cooldown=0;w.gate_cooldown=0
					var before: int=w.npc_interactions;w.interact();check(w.npc_interactions==before+1,"npc_interaction_%s_%d"%[seed_text,rid]);w.ui.resume()
			rows.append(w.region_metrics[-1].duplicate())
			if capture:
				w.player.position=Vector3(0,region.data.center_h+.08,0);w.camera.size=75 if region.data.spec.kind=="settlement" else 36;w.update_camera()
				await process_frame;await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://convergence/capture_%02d.png"%rid)
	# Same atlas and physical population must survive JSON and a new process.
	check(w.save_progress(),"save_integrated")
	var reload: RefCounted=w.JourneySave.new(w.save_path,101)
	check(reload.load_progress(),"reload_integrated")
	check(reload.data.get("convergence",{}).get("current")==w.current_region,"region_survives_reload")
	check(reload.data.get("living_world",{}).get("npcs",{})==w.journey.data.get("living_world",{}).get("npcs",{}),"identities_survive_reload")
	var report: Dictionary={"engine":Engine.get_version_info(),"checks":checks,"failures":failures,"regions":rows,"metrics":w.region_metrics,"rendered":capture}
	var f:=FileAccess.open("res://convergence/qa_result_extreme012.json" if extreme else "res://convergence/qa_result_render.json" if capture else "res://convergence/qa_result.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close()
	print("CONVERGENCE_RESULT ",JSON.stringify({"passed":checks.size()-failures.size(),"failures":failures,"regions":rows.size()}))
	w.set_paused(false);w.audio_fx.shutdown();w.free();await process_frame;quit(0 if failures.is_empty() else 1)
func entrance_to_local(house: Node3D) -> Vector3:
	return house.get_node("AnchorEntrance").position
