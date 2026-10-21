extends "res://validation_r3/support.gd"
func _initialize():call_deferred("run")
func run():
	var disk: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://functional_r3_npc_day_v1.json"))
	var expected: Dictionary={"identities":disk.living_world.npcs,"actors":disk.convergence.actors,"population":65,"region":78}
	await boot("user://functional_r3_npc_day_v1.json",true)
	check(w.current_region==int(expected.region),"same_city_after_new_process")
	check(JSON.parse_string(JSON.stringify(w.journey.data.living_world.npcs))==expected.identities,"identities_homes_professions_after_new_process")
	var seen: Dictionary={};var state_ok:=true
	for actor in w.residents:
		seen[actor.identity.id]=true
		var saved: Dictionary=expected.actors.get(actor.identity.id,{})
		state_ok=state_ok and actor.talks==int(saved.get("talks",-1)) and actor.work_cycles>=int(saved.get("work_cycles",-1)) and JSON.parse_string(JSON.stringify(actor.visits))==saved.get("visits",{})
	check(seen.size()==int(expected.population) and seen.size()==w.residents.size(),"no_population_duplication_after_new_process")
	check(state_ok,"talks_work_visits_preserved")
	facts["population"]=w.residents.size()
	await finish("npc_reopen")
