extends SceneTree
func _initialize():call_deferred("run")
func run():
	var w=preload("res://convergence/game.gd").new();w.load_on_start=false;w.world_seed_override=101;w.save_path="user://qa012_architecture.json";root.add_child(w);await process_frame
	w.flow.phase="creator";w.flow.create_character({"name":"Architecture QA","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0});w.ui.resume()
	var ok: bool=await w.change_region(78);var failures: Array=[];var rows: Array=[]
	var essential: Dictionary={"smithy":"blacksmith_anvil","herbalist":"herbalist_medicine_jars","market":"merchant_counter_2m","martial_school":"silk_vertical_banner","administration":"merchant_counter_2m","shrine":"bronze_incense_burner","warehouse":"timber_handcart","farmstead":"garden_bed_2x2"}
	for i in range(w.active_region.props.size()):
		var holder: Node3D=w.active_region.props[i];var house: Node3D=holder.get_child(0);var lot: Dictionary=w.active_region.data.lots[i];var bp: Dictionary=w.active_region.blueprints[i]
		var type_ok: bool=house.get_meta("semantic_function")==lot.function and bp.semantic_function==lot.function
		var position_ok: bool=holder.position.distance_to(Vector3(lot.p.x,lot.height,lot.p.y))<.001
		var yaw_ok: bool=absf(angle_difference(holder.rotation.y,float(lot.yaw)))<.001
		var ids: Array=[]
		for node in house.find_children("*","Node3D",true,false):
			if node.has_meta("asset_id"):ids.append(node.get_meta("asset_id"))
		var asset_ok: bool=not essential.has(lot.function) or essential[lot.function] in ids
		if not(type_ok and position_ok and yaw_ok and asset_ok):failures.append(lot.id)
		rows.append({"id":lot.id,"function":lot.function,"composition":bp.composition,"palette":bp.palette,"position":position_ok,"orientation":yaw_ok,"type":type_ok,"profession_asset":asset_ok})
	ok=ok and failures.is_empty();FileAccess.open("res://convergence/architecture_result012.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":ok,"failures":failures,"buildings":rows},"\t"));print("ARCHITECTURE012 ",ok," buildings=",rows.size()," failures=",failures)
	w.simulation_enabled=false;w.audio_fx.shutdown();OS.delay_msec(120);w.free();quit(int(not ok))
