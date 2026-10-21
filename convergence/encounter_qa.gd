extends SceneTree
const Game=preload("res://convergence/game.gd")
var w: Node3D
var failures: Array=[]
func _initialize():call_deferred("run")
func check(ok: bool,label: String):
 print("CHECK ",label," ",ok)
 if not ok:failures.append(label)
func frames(n: int):
 for i in range(n):await physics_frame
func run():
 w=Game.new();w.load_on_start=false;w.world_seed_override=101;w.save_path="user://convergence_encounter.json";root.add_child(w);await process_frame
 w.flow.phase="creator";w.flow.create_character({"name":"Encounter QA","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0,"weapon":"sword"});w.ui.resume()
 check(await w.change_region(32),"enter_existing_ruins")
 await frames(10);check(w.enemies.size()==4,"existing_opponents_materialized")
 for actor in w.enemies:actor.enabled=false
 var foe: Node3D=w.enemies[0];foe.hp=1
 # Fixture: stationary existing opponent with 1HP to abbreviate the real sword attack.
 w.player.position=foe.position+Vector3(0,0,1.3);w.player.velocity=Vector3.ZERO;w.set_facing(Vector3.FORWARD)
 await frames(8);Input.action_press("attack");await frames(2);Input.action_release("attack");await frames(50)
 check(foe.hp==0 and foe.uid in w.journey.data.defeated,"sword_defeat_and_persisted_identity")
 check(not w.journey.data.pending_loot.is_empty(),"unique_existing_loot")
 var source: String=str(foe.uid)
 w.player.position=foe.position;await frames(10)
 check(w.inventory.nearby_drop()==source,"regional_loot_height")
 check(w.inventory.collect(source),"collect_actual_regional_drop")
 check(w.save_progress(),"save_loot_and_inventory")
 var save: RefCounted=w.JourneySave.new(w.save_path)
 check(save.load_progress() and save.data.items.size()==w.journey.data.items.size(),"reload_inventory")
 w.return_home();await frames(8);check(w.current_region==-1 and w.player.is_on_floor(),"return_home_grounded")
 w.health=20;w.combat_timer=0;w.attack_time=-1;w.roll_time=-1;w.techniques.reset()
 var uid: String=""
 for item in w.journey.data.items:
  if item.ref=="potion":uid=item.uid
 var before: int=w.inventory.find_item(uid).qty
 check(w.inventory.use(uid) and w.health==60 and w.inventory.find_item(uid).qty==before-1,"consume_real_potion")
 var report={"failures":failures,"fixture":"Existing enemy, AI disabled and 1HP; sword attack via Input; original damage, loot and inventory systems, real collision."}
 FileAccess.open("res://convergence/encounter_result.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("ENCOUNTER_RESULT ",JSON.stringify(report))
 w.set_paused(false);w.audio_fx.shutdown();OS.delay_msec(120);w.free();await process_frame;quit(0 if failures.is_empty() else 1)
