extends "res://validation_r3/support.gd"
const R=preload("res://regional_ecology/rewards.gd")
var stage:="A"
func _initialize():
	var args:=OS.get_cmdline_user_args();stage=args[0] if not args.is_empty() else "A";call_deferred("run")
func run():
	await boot(SAVE,stage!="A")
	if stage=="A":
		check(await w.change_region(52),"enter_wild")
		w.extension().clock=0.0
		var site: Dictionary=w.ecology_director.sites[0]
		await observe(site)
		var key: String=str(site.id)+"/m0"
		check(w.ecology_director.active.has(key),"native_group_spawn")
		if not w.ecology_director.active.has(key):await finish("lifecycle_A");return
		var actor: Node3D=w.ecology_director.active[key]
		facts["first_fight"]=await fight(actor,true)
		check(await loot(facts.first_fight.uid),"collect_partial_group_loot")
		var record: Dictionary=R.territory_state(w.extension().ecology,52,site.id)
		check(record.get("members_dead",[]).size()==1 and int(record.generation)==0,"partial_group_record")
		check(w.save_progress(),"save_partial_group")
		var expected: Dictionary={"site":site.id,"dead_key":key,"xp":w.extension().ecology.xp_total,"items":w.journey.data.items.duplicate(true),"clock":w.extension().clock}
		FileAccess.open("res://validation_r3/results/lifecycle_expected.json",FileAccess.WRITE).store_string(JSON.stringify(expected,"  "))
	elif stage=="B":
		var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://validation_r3/results/lifecycle_expected.json"))
		check(int(w.extension().ecology.xp_total)==int(expected.xp),"xp_after_new_process")
		check(JSON.parse_string(JSON.stringify(w.journey.data.items))==expected.items,"inventory_after_new_process")
		var site: Dictionary={}
		for candidate in w.ecology_director.sites:
			if candidate.id==expected.site:site=candidate
		await observe(site)
		check(not w.ecology_director.active.has(expected.dead_key),"dead_member_not_respawned_after_json")
		facts["active_members"]=w.ecology_director.active.keys()
		check(w.ecology_director.active.has(str(expected.site)+"/m1"),"surviving_member_present")
		if not failures.is_empty():await finish("lifecycle_B");return
		var survivor: Node3D=w.ecology_director.active[str(expected.site)+"/m1"]
		facts["survivor_fight"]=await fight(survivor)
		check(await loot(facts.survivor_fight.uid),"collect_completed_group_loot")
		var record: Dictionary=R.territory_state(w.extension().ecology,52,site.id)
		expected["deadline"]=float(record.defeated_at)+540.0;expected["generation"]=record.generation;expected.xp=w.extension().ecology.xp_total;expected["ecology"]=w.extension().ecology.duplicate(true)
		check(int(record.generation)==1,"generation_after_full_group")
		w.return_home();check(await w.change_region(52),"leave_and_return")
		await observe(site)
		check(not w.ecology_director.active.has(str(site.id)+"/m0") and not w.ecology_director.active.has(str(site.id)+"/m1"),"camp_stays_dead_before_deadline")
		check(w.save_progress(),"save_full_group")
		FileAccess.open("res://validation_r3/results/lifecycle_expected.json",FileAccess.WRITE).store_string(JSON.stringify(expected,"  "))
	elif stage=="C":
		var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://validation_r3/results/lifecycle_expected.json"))
		var site: Dictionary={}
		for candidate in w.ecology_director.sites:
			if candidate.id==expected.site:site=candidate
		check(int(w.extension().ecology.xp_total)==int(expected.xp),"full_group_xp_after_reopen")
		await observe(site)
		check(not w.ecology_director.active.has(str(site.id)+"/m0"),"full_group_absent_after_reopen")
		# Advance actual engine physics for the remaining cooldown; do not assign its deadline.
		var wait_frames:=0
		while float(w.extension().clock)<float(expected.deadline)-2.0 and wait_frames<34000:
			await physics_frame;wait_frames+=1
		check(not w.ecology_director.active.has(str(site.id)+"/m0"),"no_early_renewal")
		await frames(220)
		check(w.ecology_director.active.has(str(site.id)+"/m0") and w.ecology_director.active.has(str(site.id)+"/m1"),"renewal_after_540s")
		if w.ecology_director.active.has(str(site.id)+"/m0"):check(str(w.ecology_director.active[str(site.id)+"/m0"].uid).ends_with("/g0001"),"new_generation_uid")
		check(int(w.extension().ecology.xp_total)==int(expected.xp),"no_xp_from_reload_or_respawn")
		facts["cooldown_wait_frames"]=wait_frames;check(w.save_progress(),"save_renewed_camp")
	await finish("lifecycle_"+stage)
