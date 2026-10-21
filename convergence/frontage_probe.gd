extends SceneTree
const Data=preload("res://genesis/region_data.gd")
const Planner=preload("res://genesis/world_planner.gd")
func _initialize():call_deferred("run")
func run():
	var atlas: Dictionary=Planner.read_atlas("res://genesis/atlas_seed_101.json")
	for rid in [86,15,78]:
		var d=Data.new(atlas,rid);var nearest:=0.0;var radius:=0.0
		for lot in d.lots:
			var best:=INF
			for other in d.lots:
				if other.id!=lot.id:best=minf(best,lot.p.distance_to(other.p))
			nearest+=best;radius=maxf(radius,lot.p.length())
		print("LAYOUT ",rid," count=",d.lots.size()," nearest=",nearest/d.lots.size()," radius=",radius)
	var w=load("res://convergence/game.gd").new();w.load_on_start=false;w.world_seed_override=101;w.save_path="user://frontage_probe_v3.json";root.add_child(w);await process_frame
	w.flow.phase="creator";w.flow.create_character({"name":"Probe","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0});w.ui.resume()
	if not await w.change_region(78):push_error(w.generation_failure);w.free();quit(1);return
	for lot in w.active_region.data.lots:
		var members: Array=[];var points: Array=[]
		for actor in w.residents:
			if actor.identity.home_slot==lot.id or actor.identity.work_slot==lot.id:members.append(actor.identity);points.append(actor.routes[lot.id+">"+lot.id][-1])
		if members.size()>4:print("CROWD ",lot.id," ",lot.function," members=",members.size()," base=",w.active_region.station_points[lot.id]," points=",points)
	w.audio_fx.shutdown();w.free();quit()
