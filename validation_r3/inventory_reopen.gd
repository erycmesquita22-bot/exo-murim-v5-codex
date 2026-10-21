extends "res://validation_r3/support.gd"
func _initialize():call_deferred("run")
func run():
	var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://validation_r3/results/repeat_combat.json"))
	var disk: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://functional_r3_repeat_v1.json"))
	await boot("user://functional_r3_repeat_v1.json",true)
	check(JSON.parse_string(JSON.stringify(w.journey.data.items))==disk.items,"complete_item_instances_survive_new_process")
	for uid in expected.facts.equipment:
		var item: Dictionary=w.inventory.find_item(uid)
		check(not item.is_empty() and preload("res://inventory.gd").valid_item(item) and item.has("generation"),"generated_weapon_preserved_"+uid)
	check(str(w.journey.data.equipped)==str(disk.equipped),"equipped_uid_preserved")
	var ids: Dictionary={}
	for item in w.journey.data.items:ids[str(item.uid)]=true
	check(ids.size()==w.journey.data.items.size(),"no_duplicate_item_uid")
	await finish("inventory_reopen")
