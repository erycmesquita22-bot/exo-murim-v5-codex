extends SceneTree
var failures: Array[String] = []
func check(value: bool, label: String) -> void:
 if not value: failures.append(label)
 print("CHECK ",label," ","PASS" if value else "FAIL")
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var scene = load("res://modules/village_npcs/VillageNPCs_V11.tscn").instantiate()
 root.add_child(scene)
 await process_frame
 await process_frame
 scene.title_flow.visible=false;scene.heart_menu.visible=false;scene.heart_menu.has_session=true
 paused=false;scene.enable_training_rival=false
 var p = scene.cultivation_path
 p.reset_state(false)
 check(p != null,"module_loaded")
 check(p.rank == 0,"starts_common")
 check(p._required() == 2,"foundation_requires_two_cycles")
 check(not p.breakthrough(),"cannot_breakthrough_without_teacher")
 p.on_talk("ji_wol")
 p.on_talk("estate_master_weak")
 check(p.talked_ji and p.talked_master,"mentor_quest")
 var marker: Node3D = scene.village_npcs.cultivation_sites[0]
 scene.actor.global_position = marker.global_position+Vector3(0,2,0)
 for i in 50: await physics_frame
 check(not p._site().is_empty(),"training_zone_detected")
 print("PRE_CULTIVATE floor=",scene.actor.is_on_floor()," action=",scene.action_kind," armed=",scene.armed," health_stun=",scene.health.stun)
 p.fatigue=0;p.toggle_cultivate()
 print("CULTIVATE_MESSAGE ",p.message)
 check(p.cultivating,"cultivation_started")
 check(not scene.tree.active,"locomotion_animation_paused")
 p.elapsed=8.99
 await physics_frame
 await physics_frame
 check(p.cycles>=1 and not p.cultivating,"cycle_completed")
 check(scene.tree.active,"locomotion_animation_restored")
 p.fatigue=0;p.cycles=2
 check(p.breakthrough(),"first_breakthrough")
 check(p.rank==1 and p.stage==0,"third_class_initial")
 check(scene.health.maximum>p.old_hp_max,"health_bonus")
 p.cycles=5;p.fatigue=0
 check(p.breakthrough() and p.stage==1,"third_class_intermediate")
 p.cycles=9;p.fatigue=0
 check(p.breakthrough() and p.stage==2,"third_class_advanced")
 p.cycles=14;p.fatigue=0
 check(p.breakthrough() and p.rank==2,"second_class")
 p.cycles=999;p.fatigue=0;p.stage=2
 check(not p.breakthrough(),"higher_realm_locked")
 p.reset_state(false)
 check(p.rank==0 and p.cycles==0,"new_game_reset")
 print("RESULT failures=",failures.size()," list=",failures)
 quit(0 if failures.is_empty() else 1)
