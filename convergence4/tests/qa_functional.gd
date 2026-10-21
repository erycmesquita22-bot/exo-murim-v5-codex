extends SceneTree
# Explicit progression fixtures are test-only. Production never grants these states.
var w:Node3D
var failures:Array=[]
var executed:Array=[]
func check(ok:bool,label:String):
 print("FUNCTIONAL_CHECK ",label," ",ok)
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
 w=preload("res://convergence/game.gd").new();w.load_on_start=false;w.save_path="user://convergence4_functional.json";root.add_child(w);await process_frame
 check(w.exo_core.ready,"core_boot")
 if not w.exo_core.ready:quit(1);return
 w.flow.phase="creator";check(w.flow.create_character({"name":"V4 fixture QA","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0,"weapon":"sword","outfit":0},101),"new_campaign")
 for i in range(1800):
  await physics_frame
  if w.current_region>=0 and not w.changing_region:break
 check(await w.change_region(78),"city78")
 if w.current_region!=78:quit(1);return
 w.ui.resume();w.simulation_enabled=false
 var portals:Array=[]
 for p in w.active_region.monument_portals:
  if p.get("source")=="interior_forge_r2":portals.append(p)
 print("INTERIOR_PHYSICAL ",w.active_region.get_meta("interior_forge_physical",{}))
 check(not portals.is_empty(),"verified_interior_door")
 if not portals.is_empty():
  var portal:Dictionary=portals[0]
  w.player.position=portal.entrance_world
  var entry:Dictionary=w._enter_institutional_interior(portal)
  print("INTERIOR_ENTRY ",entry)
  check(entry.get("ok",false),"interior_entry")
  if entry.get("ok",false):
   check(w.institutional_root.visible,"interior_rendered")
   check(preload("res://convergence4/interiors.gd").clear_capsule(w.get_world_3d().direct_space_state,w.player.position),"interior_physical_floor")
   check(w.save_progress(),"save_inside")
   # A failed disk write must not retain staged interior position, Core receipts
   # or runtime snapshots in journey.data (previously copied too late).
   var state_before_failed_save:Dictionary=w.journey.data.duplicate(true)
   var live_before_failed_save:Vector3=w.player.global_position
   var failed_save_path:String=w.journey.path
   w.journey.path="user://missing_v4_dir/forced_save_failure.json"
   w.player.global_position+=Vector3(0.0,0.0,-0.25)
   check(not w.save_progress(),"interior_forced_save_failure")
   check(w.journey.data==state_before_failed_save,"failed_save_prep_rollback")
   w.player.global_position=live_before_failed_save
   w.journey.path=failed_save_path
   var return_marker:Node3D=w.institutional_root.get_node_or_null("InteriorExit") as Node3D
   check(is_instance_valid(return_marker),"interior_exit_marker")
   if is_instance_valid(return_marker):
    var saved_position:Vector3=w.player.position
    w.player.position=return_marker.global_position+Vector3(0.0,0.0,-4.0)
    check(not w._near_institutional_exit() and not w._exit_institutional_interior().get("ok",true) and w._institutional_inside(),"interior_exit_rejects_remote_E")
    check(w.interaction_hint().is_empty(),"interior_remote_hint_hidden")
    w.player.position=return_marker.global_position
    check(w._near_institutional_exit(),"interior_exit_authorized_at_door")
    check(w.save_progress(),"save_inside_at_door")
   var path:String=w.journey.path;w.journey.path="user://missing_v4_dir/fail.json"
   check(not w._exit_institutional_interior().get("ok",true) and w._institutional_inside(),"interior_exit_rollback")
   w.journey.path=path
   check(w._exit_institutional_interior().get("ok",false),"interior_exit")
 for actor in w.residents:
  w.activation_v4.npc_dialogue(actor)
  w.journey_manager.options(actor.identity)
 print("LIBRARY_CONSUMED ",JSON.stringify(w.activation_v4.state().get("consumed",{})))
 check(w.activation_v4.state().get("consumed",{}).size()>0,"library_real_consumers")
 check(await w.change_region(0),"wild_region")
 w.simulation_enabled=false;w.ui.resume()
 var learner:String=preload("res://exo_core/contracts/entity_contracts.gd").player_id(w.journey.data)
 w.journey.data.journey_dynamic.progress.level=50
 var master:String="npc/r0/qa_teacher"
 var key:String=(learner+"|"+master).sha256_text()
 var training:Dictionary={"learner_id":learner,"master_id":master,"rank":3,"mastery":0,"practice":0,"lesson_goal":0,"completed_lessons":0,"phase":"ready","lesson_id":"","pending_technique":"","method":"","learned":{},"active":true,"r2":{"lesson_seq":0,"observation_done":false,"practice_done":0,"exam_passed":false,"pending_unlock":"","exam_history":{},"outcome":"active","school_id":"","transfer_from":"","refusals":0}}
 w.journey.data.exo_martial.training[key]=training
 var foe:CharacterBody3D=preload("res://enemy.gd").new();w.add_child(foe)
 foe.setup(w,"enemy/qa/v4","melee",w.player.position+Vector3.FORWARD*1.5);foe.enabled=false
 var original:Array=w.enemies.duplicate();w.enemies.assign([foe])
 await physics_frame
 for row in preload("res://catalog.gd").SKILLS:
  if not row.has("forge_id"):continue
  var spec:Dictionary=w.exo_core.services.invoke("skill_forge","skill",[str(row.id)])
  var school:String=str(spec.tags.schools[0]) if not spec.tags.schools.is_empty() else "exo_martial.school.seita_bambu"
  var style:String=str(spec.tags.styles[0]) if not spec.tags.styles.is_empty() else "exo_martial.style.sword_swift"
  w.journey.data.exo_martial.profiles[master]={"npc_id":master,"school_id":school,"style_id":style,"temperament":"benevolente","power":50,"max_disciples":8,"techniques":[],"secondary_styles":[],"secret_technique_id":""}
  training.r2.school_id=school
  var weapon:String=str(spec.tags.weapon_ids[0])
  var uid:String=""
  for item in w.journey.data.items:
   if item.kind=="weapon" and item.ref==weapon:uid=str(item.uid);break
  if uid.is_empty():uid=w.inventory.add("weapon",weapon)
  w.journey.data.equipped=uid;w.journey.data.character.weapon=weapon;w.journey.data.character.hands_free=false
  if row.id not in w.journey.data.known:w.journey.data.known.append(row.id)
  if row.id not in w.journey.data.learned:w.journey.data.learned.append(row.id)
  w.journey.data.loadout=[row.id,"corte_inicial","bola_de_gelo"];w.techniques.configure(w.journey.data.loadout)
  w.techniques.finish();w.attack_time=-1;w.roll_time=-1;w.combat_timer=0;w.facing=Vector3.FORWARD
  w.techniques.recovery.clear();w.techniques.mana=100;w.techniques.stamina=100;w.health=20
  foe.hp=100000;foe.max_hp=100000;foe.position=w.player.position+Vector3.FORWARD*1.5
  var plan:Dictionary=w.exo_core.services.invoke("skill_forge","plan",[str(row.id),{"type":"player"}])
  var before:int=w.activation_v4.releases
  var cast:bool=w.techniques.cast(0)
  if cast:
   check(is_equal_approx(w.techniques.mana,100.0-float(plan.cost.qi)) and is_equal_approx(w.techniques.stamina,100.0-float(plan.cost.stamina)),"cost/"+str(row.id))
   w.techniques.tick(float(row.cast)+.05)
   var effect:bool=false
   for action in plan.actions:
    if action.op=="damage":effect=effect or foe.hp<100000
    elif action.op=="heal":effect=effect or w.health>20
    elif action.op=="shield":effect=effect or w.techniques.shield>0
   check(w.activation_v4.releases==before+1 and effect,"physical/"+str(row.id))
   if effect:executed.append(row.id)
   check(not w.techniques.cast(0),"cooldown/"+str(row.id))
  else:
   print("CAST_BLOCKED ",row.id," ",w.activation_v4.reason(plan));check(false,"cast/"+str(row.id))
 w.techniques.finish();w.techniques.recovery.clear();w.techniques.mana=100;w.techniques.stamina=100
 var valid_plan:Dictionary=w.exo_core.services.invoke("skill_forge","plan",[str(w.journey.data.loadout[0]),{"type":"player"}])
 var forged:Dictionary=valid_plan.duplicate(true);forged.cost.qi=0
 check(not w.activation_v4.permit_skill("player",forged).get("ok",false),"forged_plan_rejected")
 var selected_weapon:String=str(w.journey.data.character.weapon)
 w.journey.data.character.weapon="staff" if selected_weapon!="staff" else "sword"
 check(not w.techniques.cast(0),"wrong_weapon_rejected")
 w.journey.data.character.weapon=selected_weapon
 var wall:=StaticBody3D.new();wall.collision_layer=4;w.add_child(wall)
 wall.position=w.player.position+Vector3.FORWARD*.75+Vector3.UP*1.5
 var box:=CollisionShape3D.new();box.shape=BoxShape3D.new();box.shape.size=Vector3(3,3,.2);wall.add_child(box)
 foe.hp=100000;foe.position=w.player.position+Vector3.FORWARD*1.5
 await physics_frame
 check(w.techniques.cast(0),"cast_against_wall")
 w.techniques.tick(1.0)
 check(foe.hp==100000,"solid_building_wall_blocks_damage")
 wall.queue_free();await physics_frame;await physics_frame
 w.techniques.finish();w.techniques.recovery.clear();w.techniques.mana=100;w.techniques.stamina=100
 foe.position=w.player.position+Vector3.FORWARD*100
 check(w.techniques.cast(0),"cast_out_of_range")
 w.techniques.tick(1.0);check(foe.hp==100000,"range_blocks_damage")
 w.techniques.finish();w.techniques.recovery.clear();w.techniques.mana=0;w.techniques.stamina=0
 check(not w.techniques.cast(0),"qi_stamina_rejection")
 w.techniques.mana=100;w.techniques.stamina=100
 var saved_path:String=w.journey.path;w.journey.path="user://missing_v4_dir/fail.json"
 var before_qi:float=w.techniques.mana
 check(not w.techniques.cast(0) and is_equal_approx(w.techniques.mana,before_qi) and not w.techniques.busy(),"cast_save_failure_rollback")
 w.journey.path=saved_path
 check(w.techniques.cast(0),"final_commit")
 var receipt:String=str(w.activation_v4.state().receipts.keys().back())
 var committed:Dictionary=w.techniques.casting.forge_plan
 var qi:float=w.techniques.mana
 var duplicate:Dictionary=w.activation_v4.commit_skill("player",committed,receipt)
 check(duplicate.status=="duplicate" and not duplicate.committed and is_equal_approx(qi,w.techniques.mana),"receipt_replay_no_debit")
 w.techniques.finish();check(w.save_progress(),"final_save")
 var saved:Dictionary=w.journey.data.duplicate(true)
 var loaded:RefCounted=preload("res://journey_save.gd").new(w.journey.path)
 loaded.load_progress()
 check(not loaded.recovered and loaded.data.get("convergence",{}).get("activation_v4",{}).has("receipts"),"disk_reload")
 check(loaded.data.convergence.activation_v4.receipts==saved.convergence.activation_v4.receipts and loaded.data.convergence.activation_v4.recovery==saved.convergence.activation_v4.recovery,"ledger_cooldown_roundtrip")
 w.enemies.assign(original);foe.queue_free()
 print("FUNCTIONAL_RESULT ",JSON.stringify({"failures":failures,"executed":executed,"count":executed.size(),"progression":"explicit test fixture, not natural enrollment"}))
 w.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)
