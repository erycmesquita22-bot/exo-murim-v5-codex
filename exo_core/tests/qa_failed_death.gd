extends "res://validation_r3/support.gd"
func _initialize() -> void:call_deferred("run_failure")
func run_failure() -> void:
 await boot("user://core_failed_death.json")
 check(await w.change_region(52),"real_ecology")
 await observe(w.ecology_director.sites[0])
 var actor: Node3D=w.ecology_director.active.values()[0]
 var old_path: String=w.journey.path
 w.set_physics_process(false);w.encounters.set_physics_process(false)
 var before: Dictionary=w.journey.data.duplicate(true)
 w.journey.path="user://nonexistent_core_failure_folder/sub/save.json"
 actor.hp=0;w.enemy_defeated(actor);await frames(2)
 check(is_instance_valid(actor) and actor.hp==1,"actor_restored_on_write_failure")
 check(w.journey.data==before,"all_gameplay_and_receipts_rolled_back")
 check(not actor.get_meta("ecology_rewarded",false),"reward_flag_rolled_back")
 check(actor in w.enemies,"combat_actor_reinserted")
 w.journey.path=old_path
 actor.hp=0;w.enemy_defeated(actor);await frames(4)
 check(not is_instance_valid(actor),"retry_committed_death")
 check(int(w.extension().ecology.xp_total)>int(before.convergence.ecology.xp_total),"xp_once_after_success")
 await finish("exo_core_failed_death")
