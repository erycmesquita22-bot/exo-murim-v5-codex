extends "res://validation_r3/support.gd"
const Reward=preload("res://regional_ecology/rewards.gd")
func _initialize():call_deferred("run")
func run():
	await boot("user://functional_r3_repeat_v1.json")
	check(await w.change_region(52),"enter_wild")
	w.extension().clock=0.0
	var results: Array=[];var equipped: Array=[]
	var start_items: Array=[]
	for item in w.journey.data.items:start_items.append(str(item.uid))
	for cycle in range(3):
		for site in w.ecology_director.sites:
			var group_loot: Array=[]
			await observe(site)
			for member in range(int(site.group_size)):
				var key: String=str(site.id)+"/m%d"%member
				check(w.ecology_director.active.has(key),"native_spawn_"+key+"_cycle"+str(cycle))
				if not w.ecology_director.active.has(key):continue
				var actor: Node3D=w.ecology_director.active[key]
				w.health=w.max_health
				var before: int=int(w.extension().ecology.farm_counts.get("52/blade",{}).get("count",0))
				var outcome: Dictionary=await fight(actor)
				outcome["prior_kills"]=before;outcome["cycle"]=cycle
				check(int(outcome.xp)==maxi(1,int(round(16*Reward.factor(before)))),"xp_factor_%d"%before)
				group_loot.append(outcome.uid)
				results.append(outcome)
			for source in group_loot:check(await loot(source),"collect_"+source)
			for item in w.journey.data.items:
				if item.kind=="weapon" and str(item.uid) not in start_items and str(item.uid) not in equipped:
					for delay in range(300):
						if w.can_configure():break
						await physics_frame
					check(w.inventory.use(item.uid),"equip_dropped_weapon_"+str(item.uid))
					equipped.append(str(item.uid))
		if cycle<2:
			var deadline:=0.0
			for site in w.ecology_director.sites:
				deadline=maxf(deadline,float(Reward.territory_state(w.extension().ecology,52,site.id).defeated_at)+541)
			while float(w.extension().clock)<deadline:await physics_frame
	check(results.size()==12,"twelve_real_defeats")
	check(not equipped.is_empty(),"generated_equipment_collected_and_equipped")
	check(int(results[8].xp)==13 if results.size()>8 else false,"ninth_kill_reduced_from_16_to_13")
	# Pure boundary checks supplement, and do not replace, the physical defeats.
	var boundaries: Array=[]
	for n in [0,7,8,15,16,29,30]:
		var state: Dictionary={"farm_counts":{"52/blade":{"day":0,"count":n}},"xp_total":0}
		var amount: int=Reward.award(state,52,"blade",1,0)
		check(amount==int(round(16*Reward.factor(n))),"boundary_%d"%n)
		boundaries.append({"prior_kills":n,"xp":amount,"fixture":true})
	facts["fights"]=results;facts["equipment"]=equipped;facts["boundaries"]=boundaries;facts["clock"]=w.extension().clock
	check(w.save_progress(),"save_repeat_combat")
	await finish("repeat_combat")
