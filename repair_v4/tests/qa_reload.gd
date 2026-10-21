extends SceneTree
var failures:Array=[]
func check(ok:bool,label:String):
	print("RELOAD_CHECK ",label," ",ok)
	if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
	for seed_value in [101,707,2026]:
		var w:Node3D=preload("res://convergence/game.gd").new();w.load_on_start=true;w.save_path="user://repair_v4_"+str(seed_value)+".json";root.add_child(w);await process_frame
		for i in range(1800):
			await physics_frame
			if w.current_region>=0 and not w.changing_region:break
		check(w.current_region==0,"saved_region/"+str(seed_value))
		check(int(w.journey.data.world.seed)==seed_value,"saved_seed")
		check(w.active_region.data.worldgen_v4,"saved_v4_generator")
		var selected:int=78
		if seed_value!=101:
			for spec in w.atlas.regions:
				if str(spec.get("kind",""))=="settlement" and str(spec.get("settlement_scale",""))=="city":selected=int(spec.id);break
		check(await w.change_region(selected),"revisit_city")
		w.ui.resume();w.simulation_enabled=false;w.set_physics_process(false)
		check(w.active_region.data.settlement_plan.get("owner","")=="city_forge_r4","city_authority_restored")
		check(w.active_region.get_meta("exo_crowd_npc_skin_receipt",{}).get("ok",false),"atlas_rebuilt_from_saved_npcs")
		check(w.exo_core.services.invoke("crowd.illusion","status").ghosts>0,"crowd_reapproved_after_reload")
		if seed_value==101:
			var atlas:Image=w.active_region.get_meta("exo_crowd_npc_atlas").get_image()
			check(atlas.save_png("res://REPARACAO_CHAT_V4/evidence/atlas-npc-real.png")==OK,"atlas_evidence")
			FileAccess.open("res://REPARACAO_CHAT_V4/evidence/atlas-sources.json",FileAccess.WRITE).store_string(JSON.stringify(w.active_region.get_meta("exo_crowd_npc_skin_receipt",{}),"  "))
			var portals:Array=[]
			for p in w.active_region.monument_portals:
				if p.get("source")=="interior_forge_r2":portals.append(p)
			check(not portals.is_empty(),"physical_interior_still_available")
			if not portals.is_empty():
				w.player.position=portals[0].entrance_world
				check(w._enter_institutional_interior(portals[0]).get("ok",false),"interior_entry_regression")
				check(w._exit_institutional_interior().get("ok",false),"interior_exit_regression")
		check(w.save_progress(),"save_after_reload")
		w.queue_free();await process_frame;await process_frame
	print("RELOAD_RESULT ",JSON.stringify({"failures":failures}))
	quit(0 if failures.is_empty() else 1)
