extends "res://validation_r3/support.gd"
const OUT="res://exo_core/evidence/"
const TEST_SAVE="user://exo_core_acceptance.json"
var shot_count:=0
func _initialize() -> void:call_deferred("run_acceptance")
func shot(label: String) -> void:
 RenderingServer.render_loop_enabled=true
 for i in range(4):await process_frame
 await RenderingServer.frame_post_draw
 var img: Image=root.get_texture().get_image()
 check(img!=null and img.save_png(OUT+label+".png")==OK,"capture_"+label)
 shot_count+=1
 RenderingServer.render_loop_enabled=false
func present_npc(actor: Node3D) -> void:
 actor.paused_for_talk=120
 w.player.position=actor.position+Vector3(0,0,2.4);w.player.velocity=Vector3.ZERO;w.camera.size=14;w.update_camera()
 await frames(8)
 actor.presentation_visible=true;actor.rig.visible=true
func path_to(from_id: int,to_id: int) -> Array:
 var queue: Array=[from_id];var prev: Dictionary={};prev[from_id]=-1
 while not queue.is_empty():
  var id: int=int(queue.pop_front())
  if id==to_id:break
  for gate in w.atlas.regions[id].entrances:
   var next: int=int(gate.neighbor)
   if not prev.has(next):prev[next]=id;queue.append(next)
 var path: Array=[];var cursor: int=to_id
 while cursor!=from_id and prev.has(cursor):path.push_front(cursor);cursor=int(prev[cursor])
 return path
func run_acceptance() -> void:
 DirAccess.make_dir_recursive_absolute(OUT)
 var args: PackedStringArray=OS.get_cmdline_user_args()
 if "reload" in args:
  await boot(TEST_SAVE,true)
  var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OUT+"acceptance_expected.json"))
  check(w.exo_core.ready,"core_reopened")
  check(w.journey.data.journey_dynamic.rewarded.has(expected.quest),"contract_retained")
  check(int(w.journey.data.journey_dynamic.progress.xp)==int(expected.xp),"xp_exact_new_process")
  check(JSON.parse_string(JSON.stringify(w.journey.data.items))==expected.items,"inventory_exact_new_process")
  check(JSON.parse_string(JSON.stringify(w.journey.data.character))==expected.character,"appearance_exact_new_process")
  check(JSON.parse_string(JSON.stringify(w.journey.data.narrative))==expected.narrative,"narrative_exact_new_process")
  check(not w.journey_manager.claim(expected.quest),"reward_cannot_repeat")
  var old_xp: int=int(w.journey_manager.state().progress.xp)
  check(await w.change_region(int(expected.region)),"same_region_reenter")
  check(int(w.journey_manager.state().progress.xp)==old_xp,"discovery_xp_no_duplicate")
  await shot("12-reaberto")
  await finish("exo_core_acceptance_reopen");return
 # Create through the existing creator and importer; no fabricated NPC/enemy.
 root.size=Vector2i(1152,720)
 w=load("res://convergence/game.gd").new();w.load_on_start=false;w.world_seed_override=101;w.save_path=TEST_SAVE;w.settings_path="user://exo_core_acceptance.cfg";root.add_child(w);await process_frame
 check(w.exo_core.ready,"core_boot_ready")
 w.flow.phase="creator";w.ui.show_creator();await shot("01-criacao")
 var profile: Dictionary={"name":"EXO Core QA","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0,"weapon":"sword"}
 profile.skin_file=preload("res://exo_skin3d/skin_importer.gd").import_file(ProjectSettings.globalize_path("res://exo_skin3d/fixtures/hybrid_test_64.png"))
 profile.skin3d=preload("res://exo_skin3d/profile_codec.gd").defaults();profile.skin3d.accessories={"hair":"topknot","waist":"jade_belt"}
 check(not profile.skin_file.is_empty(),"import_actual_64px_skin")
 check(w.flow.create_character(profile),"create_integrated_character");w.ui.resume();await frames(8)
 w.camera.size=5;w.update_camera();await shot("02-skin3d")
 check(await w.change_region(86),"enter_actual_village")
 check(w.residents.size()>0,"persistent_residents_present")
 w.player.position=w.active_region.station_points[w.active_region.data.lots[0].id]+Vector3(0,0,5)
 w.camera.size=24;w.update_camera();await shot("03-aldeia-proxima")
 w.camera.size=85;w.update_camera();await shot("04-aldeia-ampla")
 var giver_id:="";var offer: Dictionary={}
 for resident in w.residents:
  for option in w.journey_manager.options(resident.identity):
   if option.type=="defeat":offer=option;giver_id=str(resident.identity.id);break
  if not offer.is_empty():break
 if offer.is_empty():
  check(await w.change_region(15),"seek_town_contract_giver")
  for resident in w.residents:
   for option in w.journey_manager.options(resident.identity):
    if option.type=="defeat":offer=option;giver_id=str(resident.identity.id);break
   if not offer.is_empty():break
 check(not offer.is_empty(),"real_npc_offers_road_bandits")
 if offer.is_empty():await finish("exo_core_acceptance_A");return
 var giver: Node3D
 for actor in w.residents:
  if actor.identity.id==giver_id:giver=actor
 await present_npc(giver)
 w.combat_timer=0;w.gate_cooldown=0;w.interaction_cooldown=0;w.interact();await shot("05-npc-interacao");w.ui.resume()
 check(w.journey_manager.accept(offer),"accept_road_bandits")
 w.ui.exo.open("jornada");await shot("06-diario-contrato");w.ui.exo.close_menu()
 var origin: int=w.current_region
 for rid in path_to(origin,int(offer.region)):
  check(await w.change_region(int(rid)),"connected_transition_%d"%rid)
 var site: Dictionary={}
 for candidate in w.ecology_director.sites:
  if candidate.id==offer.target:site=candidate
 check(not site.is_empty(),"objective_territory_exists")
 if site.is_empty():await finish("exo_core_acceptance_A");return
 await observe(site)
 var key: String=str(site.id)+"/m0"
 check(w.ecology_director.active.has(key),"physical_enemy_materialized")
 if not w.ecology_director.active.has(key):await finish("exo_core_acceptance_A");return
 var enemy: Node3D=w.ecology_director.active[key]
 w.camera.size=22;w.update_camera();await shot("07-inimigos")
 facts["fight"]=await fight(enemy,true)
 check(await loot(str(facts.fight.uid)),"loot_from_real_combat")
 check(w.journey_manager.state().quests[offer.id].state=="COMPLETED","quest_objective_from_death")
 # Continue fighting the original regional enemies until the native level threshold is reached.
 for zone in w.ecology_director.sites.duplicate():
  if int(w.journey_manager.state().progress.level)>=2:break
  await observe(zone)
  for foe in w.ecology_director.active.values().duplicate():
   if int(w.journey_manager.state().progress.level)>=2:break
   if not is_instance_valid(foe) or foe.hp<=0:continue
   var extra: Dictionary=await fight(foe)
   check(await loot(str(extra.uid)),"additional_real_loot_"+str(extra.uid))
 check(int(w.journey_manager.state().progress.level)>=2,"level_from_real_combat")
 await shot("08-combate-e-saque")
 for rid in path_to(w.current_region,origin):check(await w.change_region(int(rid)),"return_connected_%d"%rid)
 for actor in w.residents:
  if actor.identity.id==giver_id:giver=actor
 check(giver.identity.id==giver_id,"giver_identity_same_after_travel")
 await present_npc(giver)
 var xp_before: int=int(w.journey_manager.state().progress.xp)
 check(w.journey_manager.claim(str(offer.id)),"claim_reward")
 check(not w.journey_manager.claim(str(offer.id)),"claim_reward_no_repeat")
 check(int(w.journey_manager.state().progress.xp)==xp_before+int(offer.reward.xp),"reward_xp_exact")
 check(int(w.journey_manager.state().local_reputation[str(origin)])==3,"local_reputation")
 check(w.journey.data.narrative.npc_memories.has(giver_id),"social_memory_real_giver")
 w.ui.exo.open("jornada");await shot("09-recompensa-memoria");w.ui.exo.close_menu()
 w.combat_timer=0
 var weapon: Dictionary={}
 for item in w.journey.data.items:
  if item.kind=="weapon" and item.uid!=w.journey.data.equipped:weapon=item;break
 if weapon.is_empty():weapon=w.inventory.equipped_item()
 check(not weapon.is_empty() and w.inventory.use(str(weapon.get("uid",""))),"equip_owned_weapon")
 check(w.roll_time<0,"roll_state_idle")
 Input.action_press("dash");await frames(2);Input.action_release("dash");await frames(50)
 var expected: Dictionary={"quest":offer.id,"region":origin,"xp":w.journey_manager.state().progress.xp,"items":w.journey.data.items.duplicate(true),"character":w.journey.data.character.duplicate(true),"narrative":w.journey.data.narrative.duplicate(true)}
 check(w.save_progress(),"save_integrated")
 FileAccess.open(OUT+"acceptance_expected.json",FileAccess.WRITE).store_string(JSON.stringify(expected,"  "))
 # Additional real settlement captures use the same running game, then restore acceptance location.
 check(await w.change_region(15),"visit_town");w.camera.size=70;w.update_camera();await shot("10-vila")
 check(await w.change_region(78),"visit_city");w.camera.size=95;w.update_camera();await shot("11-cidade-muralhas")
 facts["fortifications"]=w.exo_core.architecture_status().get("status","")
 check(facts.fortifications=="ready","city_perimeter_complete")
 var plan: Dictionary=w.exo_core.architecture_status().get("plan",{})
 for opening in plan.get("openings",[]):
  if opening.type!="gate":continue
  var p: Vector2=opening.point
  var desired: Vector3=w.regional_spawn(w.active_region,Vector3(p.x,w.active_region.data.height_at(p),p.y)+Vector3(0,0,4))
  if desired.is_finite():w.player.position=desired;w.camera.size=26;w.update_camera();await shot("11b-portao-real");break
 check(await w.change_region(origin),"restore_acceptance_region")
 # Update expected narrative with additional real visits; no scripted story scenarios claimed.
 expected.narrative=w.journey.data.narrative.duplicate(true);expected.xp=w.journey_manager.state().progress.xp
 check(w.save_progress(),"save_final_acceptance")
 FileAccess.open(OUT+"acceptance_expected.json",FileAccess.WRITE).store_string(JSON.stringify(expected,"  "))
 facts["captures"]=shot_count
 await finish("exo_core_acceptance_A")
