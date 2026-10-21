extends SceneTree
const Generator=preload("res://journey_dynamic/quest_generator.gd")
const Manager=preload("res://journey_dynamic/quest_manager.gd")
const Planner=preload("res://genesis/world_planner.gd")
const RegionalData=preload("res://genesis/region_data.gd")
const Ecology=preload("res://regional_ecology/rewards.gd")
var checks:=0
var failures: Array=[]
func check(test: bool,description: String) -> void:
	checks+=1
	if not test:failures.append(description)
func _initialize() -> void:
	check(Manager.valid(Manager.fresh()),"fresh_schema")
	var broken: Dictionary=Manager.fresh();broken.progress.xp=-1
	check(not Manager.valid(broken),"negative_xp_rejected")
	check(Ecology.factor(0)==1.0 and Ecology.factor(8)==0.8 and Ecology.factor(16)==0.55 and Ecology.factor(30)==0.35,"farm_tiers")
	for seed in ["101","816204"]:
		var atlas: Dictionary=Planner.read_atlas("res://genesis/atlas_seed_"+seed+".json")
		check(Planner.validate(atlas).is_empty(),"atlas_%s"%seed)
		var save: Dictionary={"convergence":{"clock":900.0}}
		for rid in range(88):
			var spec: Dictionary=atlas.regions[rid]
			var n: int=Generator.nearest(atlas,rid,"ruins")
			check(n>=0 and Generator.reachable(atlas,rid,n),"reachable_ruins_%s_%d"%[seed,rid])
			var other: int=Generator.nearest(atlas,rid,"wild")
			check(other>=0 and Generator.reachable(atlas,rid,other),"reachable_wild_%s_%d"%[seed,rid])
			var fake: Dictionary={"id":"npc/r%02d/qa"%rid,"role":"resident"}
			var fake_other: Dictionary={"id":"npc/r%02d/qa2"%rid,"role":"resident"}
			for kind in Generator.TYPES:
				var offer: Dictionary=Generator.offer(atlas,rid,fake,[fake,fake_other],str(kind),save)
				if offer.is_empty():continue
				check(Generator.reachable(atlas,rid,int(offer.region)),"reachable_offer_%s_%d_%s"%[seed,rid,str(kind)])
				check(offer.goal>0 and offer.reward.xp>0,"valid_offer_%s_%d_%s"%[seed,rid,str(kind)])
				check(offer==Generator.offer(atlas,rid,fake,[fake,fake_other],str(kind),save),"deterministic_offer_%s_%d_%s"%[seed,rid,str(kind)])
	var result: Dictionary={"executed_in_godot":true,"checks":checks,"failures":failures,"result":"PASS" if failures.is_empty() else "FAIL"}
	print("JORNADA_01_NATIVE ",JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
