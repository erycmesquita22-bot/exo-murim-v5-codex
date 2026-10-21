extends RefCounted
const Generator=preload("res://exo_dungeon/generator/dungeon_generator.gd")
const State=preload("res://exo_dungeon/persistence/dungeon_state.gd")
const Transition=preload("res://exo_dungeon/runtime/transition_service.gd")
const Explore=preload("res://exo_dungeon/runtime/exploration_logic.gd")
const Recovery=preload("res://exo_dungeon/persistence/visit_recovery.gd")
var core: RefCounted
var transition: Variant
var committed_reward_verifier: Callable=Callable()
var visit_checkpoint_callback: Callable=Callable()
# Only ONE combat/spawn authority: these are official Enemy actors in world.enemies.
const OfficialEnemy=preload("res://enemy.gd")
const Atomic=preload("res://exo_items/integration/atomic_reward_adapter.gd")
var encounter_actors: Dictionary={}
var pending_reward_proof: Dictionary={}
var discovery_timer:=0.0
var encounter_spawned: Dictionary={}
var suspended_exterior_actors: Array=[]
func initialize(context: RefCounted) -> bool:
 core=context
 if not core.world.journey.data.has("dungeon_genesis"):
  core.world.journey.data["dungeon_genesis"]=State.blank()
 if not State.valid(core.world.journey.data.dungeon_genesis):return false
 if not core.world.journey.save_coordinator.register_domain("dungeon_genesis","dungeon_genesis",State.valid):return false
 return core.services.register_service("dungeons","dungeon_genesis",self,["plan","visit","mark_discovered","mark_key_collected","mark_gate_opened","mark_secret_discovered","is_reward_claimed","confirm_reward_receipt","snapshot","enter_instance","leave_instance","interact_active","interaction_hint","active_status","recover_visit_context","recovery_status","recover_to_exterior","interrupt_active_visit","bind_reward_verifier","bind_visit_checkpoint","defeat_encounter","trusted_pickup_status","tick_active","map_snapshot"])
func plan(location_descriptor: Dictionary) -> Dictionary:
 return Generator.generate(location_descriptor)
func visit(location_descriptor: Dictionary) -> Dictionary:
 # Pin do gerador evita destruir identidade de masmorras v2 já exploradas.
 var request: Dictionary=location_descriptor.duplicate(true)
 var dungeon_id: String=Generator.identity(request)
 var existing: Dictionary=core.world.journey.data.dungeon_genesis.instances
 if existing.has(dungeon_id):request["generator_version"]=int(existing[dungeon_id].generator_version)
 var result: Dictionary=plan(request)
 if not bool(result.get("ok",false)):return result
 var state: Dictionary=core.world.journey.data.dungeon_genesis
 if state.instances.has(str(result.id)) and int(state.instances[str(result.id)].generator_version)!=int(result.generator_version):
  return {"ok":false,"error":"generator_version_mismatch","id":str(result.id)}
 if state.instances.has(str(result.id)) and str(state.instances[str(result.id)].get("plan_digest","")) not in ["",str(result.digest)]:
  return {"ok":false,"error":"persisted_layout_mismatch","id":str(result.id)}
 var changed: Dictionary=State.instance(state,str(result.id),int(result.generator_version),str(result.digest))
 changed.plan_digest=str(result.digest)
 # A contagem da visita só avança após montagem e checkpoint confirmados.
 return result
func mark_discovered(dungeon_id: String,room_id: String) -> bool:
 return State.mark(core.world.journey.data.dungeon_genesis,dungeon_id,"discovered",room_id) if core.world.journey.data.dungeon_genesis.instances.has(dungeon_id) else false
func mark_key_collected(dungeon_id: String,key_id: String) -> bool:
 return State.mark(core.world.journey.data.dungeon_genesis,dungeon_id,"activated",key_id) if key_id.begins_with("key_") and core.world.journey.data.dungeon_genesis.instances.has(dungeon_id) else false
func mark_gate_opened(dungeon_id: String,gate_id: String) -> bool:
 return State.mark(core.world.journey.data.dungeon_genesis,dungeon_id,"opened",gate_id) if gate_id.contains("~") and core.world.journey.data.dungeon_genesis.instances.has(dungeon_id) else false
func mark_secret_discovered(dungeon_id: String,room_id: String) -> bool:
 if not core.world.journey.data.dungeon_genesis.instances.has(dungeon_id):return false
 return State.mark(core.world.journey.data.dungeon_genesis,dungeon_id,"activated","secret_"+room_id)
func is_reward_claimed(dungeon_id: String,reward_id: String) -> bool:
 return State.has_reward(core.world.journey.data.dungeon_genesis,dungeon_id,reward_id)
func confirm_reward_receipt(dungeon_id: String,reward_id: String,receipt: String) -> bool:
 # SOMENTE após o coordenador central confirmar a transação associada ao loot.
 # Sem validador vinculado pelo integrador oficial: falha fechada, sem conceder/selar.
 if not committed_reward_verifier.is_valid():return false
 if not bool(committed_reward_verifier.call(dungeon_id,reward_id,receipt)):return false
 return State.record_reward_receipt(core.world.journey.data.dungeon_genesis,dungeon_id,reward_id,receipt)
func stage_atomic_reward(dungeon_id: String,reward_id: String,receipt: String) -> bool:
 # Dungeon owns reward markers. This method is NOT exported as an RPC or
 # ServiceRegistry method; EXO Core calls it only inside Inventory's domain_stage.
 if core==null or not is_instance_valid(core.world):return false
 var data: Dictionary=core.world.journey.data
 if not data.get("dungeon_genesis") is Dictionary:return false
 var domain: Dictionary=data.dungeon_genesis
 if str(domain.get("active_visit",{}).get("dungeon_id",""))!=dungeon_id:return false
 if not domain.get("instances",{}).has(dungeon_id):return false
 if not State.record_reward_receipt(domain,dungeon_id,reward_id,receipt):return false
 return State.valid(domain)
func bind_reward_verifier(verifier: Callable) -> bool:
 # Hook injetado exclusivamente pelo integrador do EXO Core após registrar serviço
 # oficial de recompensas; não existe fallback permissivo no laboratório.
 if not verifier.is_valid() or committed_reward_verifier.is_valid():return false
 committed_reward_verifier=verifier
 return true
func bind_visit_checkpoint(checkpoint: Callable) -> bool:
 # O host oficial implementa persistência pelo SaveCoordinator, inclusive as
 # proteções de snapshot da região. Sem isso a entrada REAL falha fechada.
 if not checkpoint.is_valid() or visit_checkpoint_callback.is_valid():return false
 visit_checkpoint_callback=checkpoint
 return true
func _checkpoint(stage: String,visit_ctx: Dictionary) -> bool:
 if not visit_checkpoint_callback.is_valid():return false
 return bool(visit_checkpoint_callback.call(stage,visit_ctx.duplicate(true)))
func snapshot(dungeon_id: String) -> Dictionary:
 var instances: Dictionary=core.world.journey.data.dungeon_genesis.instances
 return instances.get(dungeon_id,{}).duplicate(true)
func _host() -> Variant:
 if not is_instance_valid(transition):
  transition=Transition.new()
  transition.name="EXO_DungeonTransitionService"
  core.world.add_child(transition)
 return transition
func _instance() -> Variant:
 if not is_instance_valid(transition) or not transition.active():return null
 return transition.current.get("instance")
func enter_instance(descriptor: Dictionary,entrance_anchor: Vector3) -> Dictionary:
 if core==null or not is_instance_valid(core.world):return {"ok":false,"error":"core_unavailable"}
 if is_instance_valid(transition) and transition.active():return {"ok":false,"error":"already_inside"}
 var actor: Node3D=core.world.player
 var exterior: Node3D=core.world.active_region
 if not is_instance_valid(actor) or not is_instance_valid(exterior):return {"ok":false,"error":"no_player_or_region"}
 if int(descriptor.get("region_id",-99))!=int(core.world.current_region):return {"ok":false,"error":"wrong_region"}
 if str(descriptor.get("location_id","")).is_empty():return {"ok":false,"error":"unregistered_entrance"}
 if actor.global_position.distance_to(entrance_anchor)>6.0:return {"ok":false,"error":"too_far"}
 if not visit_checkpoint_callback.is_valid():return {"ok":false,"error":"visit_checkpoint_host_unbound"}
 var result: Dictionary=visit(descriptor)
 if not bool(result.get("ok",false)):return result
 var visit_ctx: Dictionary=Recovery.prepare(result,descriptor,entrance_anchor,actor.global_position)
 if visit_ctx.is_empty():return {"ok":false,"error":"invalid_visit_checkpoint"}
 var domain: Dictionary=core.world.journey.data.dungeon_genesis
 # Gravar estado de transição ANTES da alteração de cena. Persistência efetiva
 # depende do save coordinator do Core, não de arquivo paralelo.
 domain.active_visit=visit_ctx
 if not _checkpoint("prepared_exterior",visit_ctx):
  core.world.journey.data.dungeon_genesis.active_visit={}
  return {"ok":false,"error":"exterior_checkpoint_failed"}
 var persisted: Dictionary=snapshot(str(result.id))
 var mounted: Dictionary=_host().enter(core.world,actor,exterior,entrance_anchor,result,persisted)
 if not bool(mounted.get("ok",false)):
  domain.active_visit=Recovery.with_phase(visit_ctx,"interrupted")
  _checkpoint("failed_entry",domain.active_visit)
  return mounted
 var dungeon: Variant=mounted.instance
 dungeon.key_collected.connect(Callable(self,"_on_key_collected").bind(str(result.id)))
 dungeon.gate_unlocked.connect(Callable(self,"_on_gate_unlocked").bind(str(result.id)))
 dungeon.transition_requested.connect(Callable(self,"_on_floor_transition").bind(str(result.id)))
 domain.active_visit=Recovery.with_phase(visit_ctx,"inside")
 domain.instances[str(result.id)].visits=int(domain.instances[str(result.id)].visits)+1
 if not _checkpoint("interior_active",domain.active_visit):
  domain.instances[str(result.id)].visits=int(domain.instances[str(result.id)].visits)-1
  transition.abort()
  domain.active_visit=Recovery.with_phase(visit_ctx,"interrupted")
  _checkpoint("failed_entry",domain.active_visit)
  return {"ok":false,"error":"interior_checkpoint_failed_and_rolled_back"}
 _suspend_exterior_actors()
 _spawn_official_encounters(result)
 return {"ok":true,"id":result.id,"floor":0,"scene_instanced":true,"encounters_instanced":encounter_actors.size()}
func leave_instance() -> bool:
 if not is_instance_valid(transition) or not transition.active():return false
 var actor: Node3D=transition.current_actor
 var dungeon: Variant=_instance()
 if not is_instance_valid(dungeon) or not is_instance_valid(actor):return false
 # Saída voluntária apenas no acesso exterior; morte/recuperação fica a cargo do host.
 if actor.global_position.distance_to(dungeon.to_global(dungeon.exit_anchor()+Vector3(0,1.2,0)))>3.5:return false
 var domain: Dictionary=core.world.journey.data.dungeon_genesis
 var old_visit: Dictionary=domain.active_visit.duplicate(true)
 domain.active_visit=Recovery.with_phase(domain.active_visit,"leaving")
 if not _checkpoint("leaving",domain.active_visit):
  domain.active_visit=old_visit
  return false
 var restored: bool=transition.leave()
 if restored:
  _clear_encounters()
  _resume_exterior_actors()
 if restored:
  domain.active_visit={}
  if not _checkpoint("exterior_restored",{}):
   domain.active_visit=Recovery.with_phase(old_visit,"interrupted")
 else:
  domain.active_visit=Recovery.with_phase(domain.active_visit,"interrupted")
 return restored
func _on_key_collected(key_id: String,_room_id: String,_actor: Node3D,dungeon_id: String) -> void:
 mark_key_collected(dungeon_id,key_id)
func _on_gate_unlocked(gate_id: String,_key_id: String,_actor: Node3D,dungeon_id: String) -> void:
 mark_gate_opened(dungeon_id,gate_id)
func _on_floor_transition(_source: String,target: String,actor: Node3D,dungeon_id: String) -> void:
 var dungeon: Variant=_instance()
 if not is_instance_valid(dungeon) or not is_instance_valid(actor):return
 if str(dungeon.plan.id)!=dungeon_id:return
 actor.global_position=dungeon.to_global(dungeon.transition_anchor(target)+Vector3(0,1.2,0))
 if actor is CharacterBody3D:(actor as CharacterBody3D).velocity=Vector3.ZERO
 dungeon.acknowledge_floor_transition(actor)
func interact_active() -> Dictionary:
 var dungeon: Variant=_instance()
 if not is_instance_valid(dungeon):return {"ok":false,"error":"not_inside"}
 var actor: Node3D=transition.current_actor
 var choice: Dictionary=Explore.nearby(dungeon,actor)
 var kind: String=str(choice.get("kind","none"))
 if kind=="reward":return _collect_physical_reward(choice)
 if kind=="exit":return {"ok":leave_instance(),"action":"exit"}
 if kind=="none":return {"ok":false,"error":"no_interaction_in_range"}
 var before: Dictionary=core.world.journey.data.duplicate(true)
 var result: Dictionary={"ok":false,"error":"unavailable"}
 match kind:
  "key":
   var key_id: String=str(choice.get("key_id",""))
   var room_id: String=""
   for room in dungeon.plan.rooms:
    if room.get("keys",[]).has(key_id):room_id=str(room.id);break
   result={"ok":dungeon.collect_key(room_id,key_id,actor),"action":"key","id":key_id}
  "gate":
   var gate_id: String=str(choice.get("gate_id",""))
   result={"ok":dungeon.unlock_gate(gate_id,actor),"action":"gate","id":gate_id}
  "secret":
   var secret_room: String=str(choice.get("room_id",""))
   var found: bool=dungeon.reveal_secret(secret_room)
   if found:found=mark_secret_discovered(str(dungeon.plan.id),secret_room)
   result={"ok":found,"action":"secret","room":secret_room}
  "floor":
   # Save the destination discovery before moving the one official player.
   var room_id: String=str(choice.get("room_id",""))
   var target: String=str(dungeon.floor_destination(room_id))
   if not target.is_empty() and mark_discovered(str(dungeon.plan.id),target):
    if _checkpoint("interaction",recover_visit_context()):
     result={"ok":dungeon.request_floor_transition(room_id,actor),"action":"floor","room":room_id}
    else:
     core.world.journey.data=before
     return {"ok":false,"error":"checkpoint_failed"}
   return result
 if not bool(result.get("ok",false)):return result
 if not _checkpoint("interaction",recover_visit_context()):
  core.world.journey.data=before
  # Restore already removed key/door/secret geometry to the persisted view.
  var saved_instance: Dictionary=before.get("dungeon_genesis",{}).get("instances",{}).get(str(dungeon.plan.id),{})
  var original_plan: Dictionary=dungeon.plan.duplicate(true)
  dungeon.materialize(original_plan,saved_instance)
  return {"ok":false,"error":"interaction_save_failed_and_rolled_back"}
 return result

func interaction_hint() -> String:
 var dungeon: Variant=_instance()
 if not is_instance_valid(dungeon):return ""
 var choice: Dictionary=Explore.nearby(dungeon,transition.current_actor)
 match str(choice.get("kind","none")):
  "key":return "E - Obter chave"
  "gate":return "E - Destrancar passagem"
  "reward":return "E - Recolher tesouro"
  "secret":return "E - Investigar passagem oculta"
  "floor":return "E - Mudar de andar"
  "exit":return "E - Retornar ao exterior"
 return ""
# R6: physical encounters are materialized by the official Enemy class and
# registered with the existing world.enemies combat authority. No second AI.
# No exterior NPC/enemy logic may chase the player through 4096m of depth.
func _suspend_exterior_actors() -> void:
 suspended_exterior_actors.clear()
 for actor in core.world.enemies:
  if not is_instance_valid(actor) or actor.has_meta("exo_dungeon_id"):continue
  if not actor.get("enabled") is bool:continue
  suspended_exterior_actors.append({"actor":actor,"enabled":bool(actor.get("enabled"))})
  actor.set("enabled",false)
func _resume_exterior_actors() -> void:
 for record in suspended_exterior_actors:
  var actor: Variant=record.get("actor",null)
  if is_instance_valid(actor):actor.set("enabled",bool(record.get("enabled",true)))
 suspended_exterior_actors.clear()

func _spawn_official_encounters(plan: Dictionary) -> void:
 _clear_encounters()
 encounter_spawned.clear()
 _spawn_nearby_encounters(plan)

func _spawn_nearby_encounters(plan: Dictionary) -> void:
 if not bool(ProjectSettings.get_setting("exo_murim/r6/dungeon_encounters_enabled",true)):return
 var dungeon: Variant=_instance()
 if not is_instance_valid(dungeon) or not is_instance_valid(transition.current_actor):return
 var saved: Dictionary=snapshot(str(plan.id))
 var budget: int=maxi(0,8-encounter_actors.size())
 if budget<=0:return
 for spec in plan.get("encounters",[]):
  if budget<=0:break
  var encounter_id: String=str(spec.get("id",""))
  if encounter_id.is_empty() or encounter_spawned.has(encounter_id) or saved.get("bosses_defeated",{}).has(encounter_id):continue
  var room: Dictionary={}
  for candidate in plan.get("rooms",[]):
   if str(candidate.get("id",""))==str(spec.get("room","")):room=candidate;break
  if room.is_empty():continue
  var center: Vector3=dungeon.to_global(Vector3(float(room.cx),float(room.floor)*dungeon._floor_height()+1.0,float(room.cz)))
  if center.distance_to(transition.current_actor.global_position)>25.0:continue
  var count: int=int(spec.get("count",1))
  if count<=0 or count>budget:continue # room is spawned atomically, no partial clears
  encounter_spawned[encounter_id]=true
  for index in range(count):
   var uid: String="dng/"+str(plan.id).sha256_text().substr(0,14)+"/"+encounter_id+"/"+str(index)
   var role: String="mage" if index%3==2 else "blade"
   var position: Vector3=dungeon.to_global(Vector3(float(room.cx)+float(index)*1.5,float(room.floor)*dungeon._floor_height()+0.2,float(room.cz)+3.0))
   var enemy: Node3D=OfficialEnemy.new()
   core.world.add_child(enemy)
   enemy.call("setup",core.world,uid,role,position)
   enemy.call("configure_regional",9.0,int(spec.get("level_min",1)))
   enemy.set_meta("exo_dungeon_id",str(plan.id))
   enemy.set_meta("exo_dungeon_encounter",encounter_id)
   enemy.set_meta("exo_dungeon_room",str(room.id))
   encounter_actors[uid]=enemy
   core.world.enemies.append(enemy)
  budget-=count

func tick_active(delta: float) -> Dictionary:
 if not is_instance_valid(transition) or not transition.active():return {"ok":false,"reason":"not_inside"}
 discovery_timer-=maxf(0.0,delta)
 if discovery_timer>0:return {"ok":true}
 discovery_timer=0.6
 var dungeon: Variant=_instance()
 if not is_instance_valid(dungeon):return {"ok":false,"reason":"no_instance"}
 _spawn_nearby_encounters(dungeon.plan)
 var actor: Node3D=transition.current_actor
 var local: Vector3=dungeon.to_local(actor.global_position)
 for room in dungeon.plan.get("rooms",[]):
  var dx: float=absf(local.x-float(room.cx))
  var dz: float=absf(local.z-float(room.cz))
  var dy: float=absf(local.y-float(room.floor)*dungeon._floor_height())
  if dx>float(room.width)*0.45 or dz>float(room.width)*0.45 or dy>4.0:continue
  var did: String=str(dungeon.plan.id)
  var instance_state: Dictionary=snapshot(did)
  if instance_state.get("discovered",{}).has(str(room.id)):break
  var before: Dictionary=core.world.journey.data.duplicate(true)
  if not mark_discovered(did,str(room.id)) or not _checkpoint("interaction",recover_visit_context()):
   core.world.journey.data=before
   return {"ok":false,"reason":"discovery_checkpoint_failed"}
  return {"ok":true,"discovered":str(room.id)}
 return {"ok":true}

func _clear_encounters() -> void:
 if core!=null and is_instance_valid(core.world):
  for uid in encounter_actors.keys():
   var enemy: Variant=encounter_actors[uid]
   if is_instance_valid(enemy):
    core.world.enemies.erase(enemy)
    enemy.queue_free()
 encounter_actors.clear()
 encounter_spawned.clear()
 pending_reward_proof.clear()

func defeat_encounter(actor: Node3D) -> Dictionary:
 if core==null or not is_instance_valid(actor) or not is_instance_valid(transition) or not transition.active():return {"ok":false,"error":"inactive"}
 var uid: String=str(actor.get("uid"))
 var did: String=str(actor.get_meta("exo_dungeon_id",""))
 var encounter: String=str(actor.get_meta("exo_dungeon_encounter",""))
 if not encounter_actors.has(uid) or encounter_actors[uid]!=actor or did!=transition.dungeon_id or int(actor.get("hp"))>0:return {"ok":false,"error":"untrusted_enemy"}
 var before: Dictionary=core.world.journey.data.duplicate(true)
 encounter_actors.erase(uid)
 # Persist the room as cleared ONLY after the final official actor dies.
 var remaining: bool=false
 for other in encounter_actors.values():
  if is_instance_valid(other) and str(other.get_meta("exo_dungeon_encounter",""))==encounter and int(other.get("hp"))>0:remaining=true
 if not remaining:
  if not State.mark(core.world.journey.data.dungeon_genesis,did,"bosses_defeated",encounter):
   encounter_actors[uid]=actor;return {"ok":false,"error":"encounter_stage_failed"}
 var gained: int=0
 if core.world.ecology_director!=null:
  gained=int(core.world.ecology_director.award_dungeon_encounter(str(actor.get("kind")),int(actor.get_meta("ecology_level",1))))
 if not _checkpoint("encounter_defeat",recover_visit_context()):
  core.world.journey.data=before
  encounter_actors[uid]=actor
  return {"ok":false,"error":"encounter_save_failed"}
 core.world.enemies.erase(actor)
 actor.call_deferred("queue_free")
 return {"ok":true,"xp":gained,"room_cleared":not remaining}

# Only the true E-interaction within 3.2m can mint this transient proof.
func _physical_reward_node(reward_id: String) -> Node3D:
 var dungeon: Variant=_instance()
 if not is_instance_valid(dungeon) or not is_instance_valid(dungeon.geometry):return null
 for marker in dungeon.geometry.find_children("TreasureReward_*","Node3D",true,false):
  if not marker.is_queued_for_deletion() and str(marker.get_meta("exo_reward_id",""))==reward_id:return marker
 return null
func verify_reward_pickup(dungeon_id: String,reward_id: String,source: String) -> bool:
 if pending_reward_proof.is_empty() or str(pending_reward_proof.get("dungeon_id",""))!=dungeon_id or str(pending_reward_proof.get("reward_id",""))!=reward_id or str(pending_reward_proof.get("source",""))!=source:return false
 if not is_instance_valid(transition) or not transition.active() or transition.dungeon_id!=dungeon_id:return false
 var node: Node3D=_physical_reward_node(reward_id)
 if not is_instance_valid(node) or not is_instance_valid(transition.current_actor):return false
 if transition.current_actor.global_position.distance_to(node.global_position)>3.2:return false
 if is_reward_claimed(dungeon_id,reward_id):return false
 for enemy in encounter_actors.values():
  if is_instance_valid(enemy) and int(enemy.get("hp"))>0 and str(enemy.get_meta("exo_dungeon_room",""))==str(node.get_meta("exo_reward_room","")):return false
 return true
func trusted_pickup_status() -> Dictionary:
 return {"pending":not pending_reward_proof.is_empty(),"proof_bound":core!=null and core.trusted_dungeon_reward_proof.is_valid()}

func _collect_physical_reward(choice: Dictionary) -> Dictionary:
 if core==null or not is_instance_valid(transition) or not transition.active():return {"ok":false,"error":"not_inside"}
 var did: String=transition.dungeon_id
 var reward_id: String=str(choice.get("reward_id",""))
 var node: Node3D=_physical_reward_node(reward_id)
 var dungeon: Variant=_instance()
 if reward_id.is_empty() or not is_instance_valid(node) or not is_instance_valid(dungeon):return {"ok":false,"error":"invalid_reward"}
 if is_reward_claimed(did,reward_id):return {"ok":false,"error":"reward_already_collected"}
 if not bool(ProjectSettings.get_setting("exo_murim/r6/dungeon_atomic_rewards_enabled",true)):return {"ok":false,"error":"atomic_rewards_disabled"}
 var descriptor: Dictionary={}
 for spec in dungeon.plan.get("rewards",[]):
  if str(spec.get("id",""))==reward_id:descriptor=spec;break
 if descriptor.is_empty() or str(descriptor.get("room",""))!=str(node.get_meta("exo_reward_room","")):return {"ok":false,"error":"unregistered_reward"}
 # Boss rewards require a real defeated encounter receipt, not an empty room.
 for encounter in dungeon.plan.get("encounters",[]):
  if str(encounter.get("room",""))==str(descriptor.get("room","")):
   if not snapshot(did).get("bosses_defeated",{}).has(str(encounter.get("id",""))):return {"ok":false,"error":"encounter_not_defeated"}
 var source: String="dungeon/"+did.sha256_text().substr(0,24)+"/"+reward_id.sha256_text().substr(0,16)
 # The reward is intentionally limited to validated material/consumable IDs;
 # generated equipment remains blocked until its official owner provides proof.
 var rewards: Array=[{"kind":"material","ref":"iron","qty":2 if int(descriptor.get("rarity_tier",0))<2 else 3}]
 var before: Dictionary=core.world.journey.data.duplicate(true)
 pending_reward_proof={"dungeon_id":did,"reward_id":reward_id,"source":source}
 if not verify_reward_pickup(did,reward_id,source):
  pending_reward_proof.clear();return {"ok":false,"error":"untrusted_physical_pickup"}
 if not core.world.inventory.queue_dungeon_pending(did,reward_id,source,rewards):
  pending_reward_proof.clear();core.world.journey.data=before;return {"ok":false,"error":"pending_ownership_rejected"}
 var plan: Dictionary=Atomic.prepare_pending(core.world.journey.data,source)
 if not bool(plan.get("ok",false)):
  pending_reward_proof.clear();core.world.journey.data=before;return {"ok":false,"error":str(plan.get("reason","pending_invalid"))}
 var result: Dictionary=core.claim_dungeon_reward(did,reward_id,source,str(plan.fingerprint))
 pending_reward_proof.clear()
 if not bool(result.get("ok",false)):
  core.world.journey.data=before
  return {"ok":false,"error":str(result.get("reason","atomic_commit_failed"))}
 node.queue_free()
 return {"ok":true,"action":"reward","reward_id":reward_id,"items":rewards.duplicate(true),"atomic":true}

func active_status() -> Dictionary:
 var active_now: bool=is_instance_valid(transition) and transition.active()
 var domain: Dictionary=core.world.journey.data.dungeon_genesis
 var pending: bool=not domain.get("active_visit",{}).is_empty()
 if not active_now:return {"active":false,"recovery_pending":pending}
 return {"active":true,"recovery_pending":pending,"id":transition.dungeon_id,"actor_reused":true,"scene_instanced":true}
func recover_visit_context() -> Dictionary:
 return core.world.journey.data.dungeon_genesis.get("active_visit",{}).duplicate(true)
func recovery_status() -> Dictionary:
 return Recovery.recovery_report(recover_visit_context())
func interrupt_active_visit(reason: String) -> bool:
 if reason not in ["death","shutdown","materialization_error","host_error","manual_rollback"]:return false
 var state: Dictionary=core.world.journey.data.dungeon_genesis
 if state.get("active_visit",{}).is_empty():return false
 if is_instance_valid(transition) and transition.active():transition.abort()
 _clear_encounters()
 _resume_exterior_actors()
 state.active_visit=Recovery.with_phase(state.active_visit,"interrupted")
 return _checkpoint("interrupted",state.active_visit)
func recover_to_exterior(verified_safe_position: Vector3,region_id: int,location_id: String) -> Dictionary:
 # Usar APENAS depois do WorldGenesis confirmar piso, colisões e âncora regional.
 # Este serviço não pode fingir que ele mesmo verificou o terreno.
 var state: Dictionary=core.world.journey.data.dungeon_genesis
 var visit_ctx: Dictionary=state.get("active_visit",{})
 if visit_ctx.is_empty():return {"ok":false,"error":"no_pending_visit"}
 if not Recovery.valid(visit_ctx):return {"ok":false,"error":"invalid_pending_visit"}
 if not verified_safe_position.is_finite():return {"ok":false,"error":"bad_safe_position"}
 if int(visit_ctx.region_id)!=region_id or int(core.world.current_region)!=region_id:return {"ok":false,"error":"region_not_loaded"}
 var expected_location: String=str(visit_ctx.get("location_id",visit_ctx.get("descriptor",{}).get("location_id","")))
 if expected_location!=location_id:return {"ok":false,"error":"wrong_entrance"}
 var expected: Vector3=Recovery.vec_from(visit_ctx.get("entrance_anchor",visit_ctx.outside_position))
 if expected.distance_to(verified_safe_position)>24.0:return {"ok":false,"error":"safe_anchor_too_far"}
 if not is_instance_valid(core.world.player) or not is_instance_valid(core.world.active_region):return {"ok":false,"error":"host_not_ready"}
 if is_instance_valid(transition) and transition.active():transition.abort()
 # Posição fornecida pelo host: cabe ao WorldGenesis garantir piso/collision sweep.
 core.world.player.global_position=verified_safe_position
 if core.world.player is CharacterBody3D:(core.world.player as CharacterBody3D).velocity=Vector3.ZERO
 state.active_visit={}
 if not _checkpoint("recovered_exterior",{}):
  state.active_visit=Recovery.with_phase(visit_ctx,"interrupted")
  return {"ok":false,"error":"recovered_position_but_commit_pending"}
 return {"ok":true,"recovered_to":"exterior","requires_core_save":false}
func shutdown() -> void:
 _clear_encounters()
 _resume_exterior_actors()
 if is_instance_valid(transition):
  if transition.active():interrupt_active_visit("shutdown")
  transition.queue_free()
 transition=null
 committed_reward_verifier=Callable()
 visit_checkpoint_callback=Callable()
 core=null

func map_snapshot() -> Dictionary:
 # Read-only projection of the current official instance and saved discovery.
 var dungeon:Variant=_instance()
 if not is_instance_valid(dungeon) or not is_instance_valid(transition.current_actor):return {"active":false}
 var local:Vector3=dungeon.to_local(transition.current_actor.global_position)
 var floor_index:int=maxi(0,roundi((local.y-0.8)/dungeon._floor_height()))
 var discovered:Dictionary=snapshot(str(dungeon.plan.id)).get("discovered",{})
 var rooms:Array=[];var accepted:Dictionary={}
 for room in dungeon.plan.rooms:
  if int(room.floor)!=floor_index or not discovered.has(str(room.id)):continue
  rooms.append({"id":str(room.id),"x":float(room.cx),"z":float(room.cz),"width":float(room.width)})
  accepted[str(room.id)]=room
 var links:Array=[]
 for link in dungeon.plan.links:
  if not accepted.has(str(link.a)) or not accepted.has(str(link.b)):continue
  if str(link.kind)=="stairs_portal":continue
  links.append({"a":Vector2(float(accepted[str(link.a)].cx),float(accepted[str(link.a)].cz)),"b":Vector2(float(accepted[str(link.b)].cx),float(accepted[str(link.b)].cz))})
 return {"active":true,"floor":floor_index+1,"player":Vector2(local.x,local.z),"rooms":rooms,"links":links,"owner":"dungeon_genesis"}
