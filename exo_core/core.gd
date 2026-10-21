extends RefCounted
const Registry=preload("res://exo_core/module_registry.gd")
const Services=preload("res://exo_core/service_registry.gd")
const Bus=preload("res://exo_core/event_bus.gd")
const Contracts=preload("res://exo_core/contracts/event_contracts.gd")
const Bridge=preload("res://narrative/adapters/journey_bridge.gd")
var world: Node3D
var registry=Registry.new()
var services=Services.new()
var events: RefCounted
var errors: Array=[]
var instances: Dictionary={}
var ready:=false
var trusted_social_proof: Callable=Callable()
var trusted_dungeon_reward_proof: Callable=Callable()
var integration_warnings: Array[String]=[]
func _init(owner: Node3D) -> void:
 world=owner;events=Bus.new(world.journey)
func boot() -> bool:
 var manifest: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://exo_core/modules.json"))
 if not manifest is Array:return false
 for spec in manifest:
  if not registry.register(spec):return false
 if not registry.initialize(Callable(self,"initialize_module")):errors=registry.errors.duplicate();return false
 for spec in manifest:
  if registry.modules[str(spec.id)].get("state","")=="ready":world.journey.data.exo_core.module_versions[spec.id]=spec.version
 ready=true
 # Modules are inserted into the registry only when the declared dependency graph resolves.
 # The dungeon remains fail-closed unless an official SaveCoordinator checkpoint is bound.
 if services.has_service("dungeons"):
  var dungeon: Variant=instances.get("dungeon_genesis",null)
  if dungeon != null and world.has_method("save_progress"):
   if not dungeon.bind_visit_checkpoint(Callable(self,"_dungeon_checkpoint")):
    integration_warnings.append("dungeon_checkpoint_bind_failed")
  # Reward proof must originate from an actual E-interaction with a persisted
  # dungeon entrance/loot marker, never an unconditional callback.
  if dungeon != null and dungeon.has_method("verify_reward_pickup"):
   if not bind_trusted_dungeon_reward_proof(Callable(dungeon,"verify_reward_pickup")):
    integration_warnings.append("dungeon_reward_proof_bind_failed")
 observed=observation()
 publish("save_loaded","load/"+str(world.journey.data.exo_core.sequence),{},-2,false)
 return true
func initialize_module(id: String) -> bool:
 var save: RefCounted=world.journey
 match id:
  "persistence":
   if not preload("res://exo_core/persistence/migration_registry.gd").upgrade(save.data):return false
   return services.register_service("persistence",id,save,["write","load_progress","valid"])
  "world":return services.register_service("regions",id,world,["ensure_atlas","change_region","starting_region"])
  "living_world":
   save.save_coordinator.register_domain("living_world",id,preload("res://living_world/state.gd").valid)
   return services.register_service("npcs",id,self,["npc","clock"])
  "inventory":return services.register_service("inventory",id,world.inventory,["add","collect","equipped_item"])
  "combat":return services.register_service("combat",id,world,["enemy_defeated"])
  "journey":
   save.save_coordinator.register_domain("journey_dynamic",id,preload("res://journey_dynamic/quest_manager.gd").valid)
   services.register_service("progression",id,world.journey_manager,["state","allocate","objective"])
   events.subscribe("region_entered",id,Callable(self,"journey_event"))
   events.subscribe("enemy_defeated",id,Callable(self,"journey_event"))
   events.subscribe("npc_interacted",id,Callable(self,"journey_event"))
   events.subscribe("item_collected",id,Callable(self,"journey_event"))
   return services.register_service("quests",id,world.journey_manager,["options","accept","claim","track","deliver"])
  "narrative":
   save.save_coordinator.register_domain("narrative",id,preload("res://narrative/core/narrative_state.gd").valid)
   for type in ["region_entered","enemy_defeated","npc_interacted","item_collected","quest_completed","narrative_decision"]:events.subscribe(type,id,Callable(self,"narrative_event"))
   return services.register_service("narrative",id,self,["social_context","narrative_opportunities","master_disciple_status","request_master_disciple_change"])
  "appearance":return services.register_service("appearance",id,self,["appearance_profile"])
  "architecture":return services.register_service("architecture",id,self,["architecture_status"])
 var spec: Dictionary=registry.modules[id]
 if not spec.get("entrypoint") is String or not ResourceLoader.exists(spec.entrypoint):return false
 var module: RefCounted=load(spec.entrypoint).new()
 var old_services: Dictionary=services.entries.duplicate(true)
 var old_handlers: Dictionary=events.handlers.duplicate(true)
 var old_owners: Dictionary=world.journey.save_coordinator.owners.duplicate(true)
 var old_data: Dictionary=world.journey.data.duplicate(true)
 if not module.has_method("initialize") or not module.initialize(self):
  if module.has_method("shutdown"):module.shutdown()
  services.entries=old_services;events.handlers=old_handlers;world.journey.save_coordinator.owners=old_owners;world.journey.data=old_data
  return false
 instances[id]=module
 return true
func shutdown() -> void:
 var reverse: Array=registry.order.duplicate();reverse.reverse()
 for id in reverse:
  if instances.has(id) and instances[id].has_method("shutdown"):instances[id].shutdown()
 instances.clear();events.handlers.clear();services.entries.clear();trusted_social_proof=Callable();trusted_dungeon_reward_proof=Callable();ready=false

# EXO Core Integration Gate: one persistence writer, one service owner, no duplicate buses.
func integration_status() -> Dictionary:
 var states: Dictionary={}
 for id in registry.modules:
  states[str(id)]={"state":str(registry.modules[id].get("state","unknown")),"policy":str(registry.modules[id].get("integration_mode","original"))}
 return {"modules":states,"dungeon_checkpoint_bound":services.has_service("dungeons") and instances.has("dungeon_genesis") and instances["dungeon_genesis"].visit_checkpoint_callback.is_valid(),"social_write_bound":trusted_social_proof.is_valid(),"dungeon_reward_proof_bound":trusted_dungeon_reward_proof.is_valid(),"warnings":integration_warnings.duplicate()}

func _dungeon_checkpoint(stage: String, _visit: Dictionary) -> bool:
 if not ready or not world.has_method("save_progress") or not services.has_service("dungeons"):return false
 if stage not in ["prepared_exterior","failed_entry","interior_active","interaction","encounter_defeat","leaving","exterior_restored","interrupted","recovered_exterior"]:return false
 return bool(world.save_progress())

func bind_trusted_dungeon_reward_proof(proof: Callable) -> bool:
 # Only the official Inventory/encounter owner may bind a trusted pickup verifier.
 if trusted_dungeon_reward_proof.is_valid() or not proof.is_valid():return false
 trusted_dungeon_reward_proof=proof
 return true

func claim_dungeon_reward(dungeon_id: String,reward_id: String,source: String,fingerprint: String) -> Dictionary:
 # One save: items + world ledger receipt + dungeon reward marker.
 # No fallback to two commits, no untrusted pickup claims, no 'always true' verifier.
 if not ready or not services.has_service("dungeons") or not trusted_dungeon_reward_proof.is_valid():return {"ok":false,"reason":"trusted_dungeon_reward_host_unbound"}
 if dungeon_id.is_empty() or reward_id.is_empty() or source.is_empty() or source.length()>123:return {"ok":false,"reason":"invalid_reward_identity"}
 var instance_status: Variant=services.invoke("dungeons","active_status")
 if not instance_status is Dictionary or not bool(instance_status.get("active",false)) or str(instance_status.get("id",""))!=dungeon_id:return {"ok":false,"reason":"dungeon_not_active"}
 if bool(services.invoke("dungeons","is_reward_claimed",[dungeon_id,reward_id])):return {"ok":false,"reason":"already_claimed"}
 if not bool(trusted_dungeon_reward_proof.call(dungeon_id,reward_id,source)):
  return {"ok":false,"reason":"pickup_proof_rejected"}
 return preload("res://exo_items/integration/atomic_reward_adapter.gd").confirm_pending(world,source,fingerprint,Callable(self,"_stage_dungeon_reward").bind(dungeon_id,reward_id))

func _stage_dungeon_reward(owner_world: Node3D,source: String,pending_items: Array,dungeon_id: String,reward_id: String) -> bool:
 # Called by INVENTORY R3 only inside its single staged journey.data snapshot.
 if owner_world!=world or pending_items.is_empty():return false
 var data: Dictionary=world.journey.data
 if not data.get("dungeon_genesis") is Dictionary:return false
 if not data.dungeon_genesis.get("instances",{}).has(dungeon_id):return false
 var active_visit: Dictionary=data.dungeon_genesis.get("active_visit",{})
 if str(active_visit.get("dungeon_id",""))!=dungeon_id:return false
 var dungeon: Variant=instances.get("dungeon_genesis",null)
 if dungeon==null or not dungeon.has_method("stage_atomic_reward"):return false
 return bool(dungeon.stage_atomic_reward(dungeon_id,reward_id,"loot/"+source))

func bind_trusted_social_proof(proof: Callable) -> bool:
 if trusted_social_proof.is_valid() or not proof.is_valid():return false
 trusted_social_proof=proof
 return true

func master_disciple_status(master: String,disciple: String) -> Dictionary:
 if master.is_empty() or disciple.is_empty():return {}
 var key: String=preload("res://narrative/society/relationship_system.gd").pair(master,disciple)
 return world.journey.data.get("narrative",{}).get("relationships",{}).get(key,{}).duplicate(true)

func request_master_disciple_change(request: Dictionary) -> Dictionary:
 # EXO Core authenticates and commits; Narrative domain owns the relation rules.
 # R8: do not permit a stand-alone durable bond while Martial enrollment is
 # pending; callers must use the one-commit cross-domain coordinator above.
 if str(request.get("action",""))=="establish" and services.has_service("martial"):
  return {"ok":false,"reason":"use_core_atomic_martial_enrollment"}
 if not trusted_social_proof.is_valid():return {"ok":false,"reason":"trusted_social_proof_unbound"}
 if not ready or not services.has_service("narrative"):return {"ok":false,"reason":"narrative_not_ready"}
 if not bool(trusted_social_proof.call(request.duplicate(true))):return {"ok":false,"reason":"host_proof_rejected"}
 var save: RefCounted=world.journey
 var snapshot: Dictionary=save.data.duplicate(true)
 if not snapshot.get("narrative") is Dictionary:return {"ok":false,"reason":"narrative_state_missing"}
 var outcome: Dictionary=preload("res://narrative/society/authorized_master_disciple.gd").stage(save.data.narrative,request,clock())
 if not bool(outcome.get("ok",false)):
  save.data=snapshot
  return outcome
 if not bool(outcome.get("changed",false)):return outcome
 if not preload("res://narrative/core/narrative_state.gd").valid(save.data.narrative) or not bool(world.save_progress()):
  save.data=snapshot
  return {"ok":false,"reason":"narrative_commit_failed"}
 return outcome


# R8: stage Narrative's authoritative bond and Martial R2 enrollment into ONE
# JourneySave.data and ONE Core SaveCoordinator transaction. Fail closed on all
# host, source NPC, schema and persistence errors; never call two commits.
func confirm_martial_enrollment_atomic(learner: String,master: String,receipt: String) -> Dictionary:
 if not ready or not services.has_service("martial") or not services.has_service("narrative"):
  return {"ok":false,"reason":"martial_or_narrative_unavailable"}
 if not trusted_social_proof.is_valid():return {"ok":false,"reason":"trusted_social_proof_missing"}
 var save: RefCounted=world.journey
 var Entity=preload("res://exo_core/contracts/entity_contracts.gd")
 var Legacy=preload("res://exo_martial/masters/martial_engine.gd")
 var Engine=preload("res://exo_martial/r2/engine_r2.gd")
 if learner!=Entity.player_id(save.data) or not master.begins_with("npc/r") or master.is_empty():
  return {"ok":false,"reason":"unauthorized_learner_or_master"}
 var npc_data:Dictionary=npc(master)
 if npc_data.is_empty() or not bool(npc_data.get("active",false)):
  return {"ok":false,"reason":"master_not_live"}
 var app_key:String=Engine.key(learner,master)
 var application:Dictionary=save.data.get("exo_martial",{}).get("applications",{}).get(app_key,{})
 if str(application.get("status",""))!="pending":return {"ok":false,"reason":"no_pending_application"}
 if receipt.is_empty() or receipt.length()>120:return {"ok":false,"reason":"invalid_receipt"}
 var canonical_master:String=Legacy.identity(save.data,master)
 if canonical_master.is_empty():return {"ok":false,"reason":"missing_canonical_master"}
 var request:Dictionary={"action":"establish","master_id":canonical_master,"disciple_id":learner,"receipt":receipt}
 if not bool(trusted_social_proof.call(request.duplicate(true))):
  return {"ok":false,"reason":"no_real_master_site_proof"}
 var snapshot:Dictionary=save.data.duplicate(true)
 var staged:Dictionary=preload("res://narrative/society/authorized_master_disciple.gd").stage(save.data.narrative,request,clock())
 if not bool(staged.get("ok",false)) or not bool(staged.get("changed",false)):
  save.data=snapshot
  return {"ok":false,"reason":str(staged.get("reason","narrative_receipt_replay"))}
 var outcome:Dictionary=Engine.confirm(save.data,learner,master)
 if not bool(outcome.get("ok",false)) or not bool(outcome.get("changed",false)):
  save.data=snapshot
  return {"ok":false,"reason":str(outcome.get("reason","martial_enrollment_rejected"))}
 if not preload("res://narrative/core/narrative_state.gd").valid(save.data.narrative) or not preload("res://exo_martial/r2/state_r2.gd").valid(save.data.exo_martial):
  save.data=snapshot
  return {"ok":false,"reason":"cross_domain_validation_failed"}
 if not bool(world.save_progress()):
  save.data=snapshot
  return {"ok":false,"reason":"joint_commit_failed"}
 return {"ok":true,"reason":"bond_and_martial_enrollment_committed","changed":true,"receipt":receipt}

# R9 single-commit skill grant: Cultivation remains the skill owner and Martial
# only clears its own pending ticket after observing the staged Core knowledge.
func confirm_martial_unlock_atomic(learner:String,master:String,technique:String) -> Dictionary:
 if not ready or not services.has_service("martial"):return {"ok":false,"reason":"martial_unavailable"}
 var save:RefCounted=world.journey
 var Engine=preload("res://exo_martial/r2/engine_r2.gd")
 var Catalog=preload("res://exo_martial/styles/martial_catalog.gd")
 var Entity=preload("res://exo_core/contracts/entity_contracts.gd")
 if learner!=Entity.player_id(save.data):return {"ok":false,"reason":"learner_invalid"}
 var t:Dictionary=Engine.active(save.data,learner,master)
 if t.is_empty() or str(t.get("phase",""))!="awaiting_unlock" or str(t.get("r2",{}).get("pending_unlock",""))!=technique:
  return {"ok":false,"reason":"no_authorized_ticket"}
 var tech:Dictionary=Catalog.technique(technique)
 var core_id:String=str(tech.get("core_skill_id",""))
 if core_id.is_empty():return {"ok":false,"reason":"unmapped_technique"}
 if not world.can_configure():return {"ok":false,"reason":"unsafe_configuration"}
 var before:Dictionary=save.data.duplicate(true)
 # Reveal and eligibility are owned by the existing cultivation system.
 if not world.cultivation.stage_martial_reveal(core_id):
  save.data=before
  return {"ok":false,"reason":"cultivation_reveal_denied"}
 if not world.cultivation.stage_martial_learn(core_id):
  save.data=before
  return {"ok":false,"reason":"cultivation_not_eligible"}
 var complete:Dictionary=Engine.confirm_core_unlock(save.data,learner,master,technique)
 if not bool(complete.get("ok",false)) or not bool(complete.get("changed",false)):
  save.data=before
  return {"ok":false,"reason":str(complete.get("reason","martial_rejected"))}
 if not preload("res://exo_martial/r2/state_r2.gd").valid(save.data.exo_martial) or not world.save_progress():
  save.data=before
  return {"ok":false,"reason":"atomic_learn_save_failed"}
 return {"ok":true,"reason":"core_and_martial_committed","core_skill_id":core_id}

func npc(id: String) -> Dictionary:return world.journey.data.get("living_world",{}).get("npcs",{}).get(id,{})
func clock() -> float:return float(world.extension().get("clock",0.0))
func social_context(id: String) -> Dictionary:return Bridge.context_for(world.journey.data,world.atlas,id,clock())
func narrative_opportunities(region: int) -> Array:return Bridge.opportunities(world.journey.data,world.atlas,region)
func appearance_profile() -> Dictionary:return world.journey.data.character.duplicate(true)
func architecture_status() -> Dictionary:return world.active_region.get_meta("exo_architecture",{}) if is_instance_valid(world.active_region) else {}
func publish(type: String,id: String,context: Dictionary={},region: int=-2,persistent: bool=true) -> Dictionary:
 var event: Dictionary={"id":id,"type":type,"source":Contracts.OWNERS.get(type,""),"schema":1,"region":world.current_region if region==-2 else region,"context":context}
 return events.publish(event,persistent)
func journey_event(e: Dictionary) -> bool:
 var jm: RefCounted=world.journey_manager
 match e.type:
  "region_entered":jm.on_enter(int(e.region))
  "npc_interacted":jm.on_talk(str(e.context.npc_id))
  "item_collected":jm.on_collect(str(e.context.source),e.context.items)
  "enemy_defeated":
   jm.emit("kill",str(e.context.territory),int(e.region),str(e.context.enemy_uid))
 return true
func narrative_event(e: Dictionary) -> bool:
 if world.atlas.is_empty():return false
 var kind: String={"region_entered":"region_entered","enemy_defeated":"enemy_defeated","npc_interacted":"npc_met","item_collected":"item_discovered","quest_completed":"quest_completed","narrative_decision":"story_choice_made"}[e.type]
 var context: Dictionary=e.context.duplicate(true)
 if e.type=="item_collected":
  var iron:=false
  for item in context.items:
   if item.get("ref")=="iron":iron=true
  if not iron:return true
  context={"knowledge_id":"iron_resource"}
 var result: Dictionary=Bridge.ingest(world.journey.data,world.atlas,{"id":("meet/"+str(e.context.npc_id)) if e.type=="npc_interacted" else ("travel/region/%02d"%int(e.region)) if e.type=="region_entered" else str(e.id),"type":kind,"source":str(e.source),"region":int(e.region),"clock":clock(),"npc_id":str(e.context.get("npc_id","")),"context":context})
 return bool(result.get("ok",false))
var observed: Dictionary={}
func observation() -> Dictionary:
 var d: Dictionary=world.journey.data;var j: Dictionary=d.get("journey_dynamic",{});var p: Dictionary=j.get("progress",{})
 return {"xp":int(p.get("xp",0)),"level":int(p.get("level",1)),"equipment":str(d.get("equipped","")),"appearance":JSON.stringify(d.get("character",{})),"quests":j.get("quests",{}).keys(),"rewarded":j.get("rewarded",{}).keys(),"reputation":JSON.stringify(j.get("local_reputation",{}))}
func prepare_save() -> bool:
 var current: Dictionary=observation()
 if observed.is_empty():observed=current;return true
 var seq: String=str(world.journey.data.exo_core.sequence)
 for key in ["xp","level","equipment","appearance","reputation"]:
  if current[key]==observed[key]:continue
  var type: String={"xp":"xp_gained","level":"level_changed","equipment":"equipment_changed","appearance":"appearance_changed","reputation":"reputation_changed"}[key]
  var result: Dictionary=publish(type,type+"/"+seq,{"before":observed[key],"after":current[key]})
  if not result.ok:return false
 for id in current.quests:
  if id not in observed.quests:
   if not publish("quest_accepted","accepted/"+str(id),{"quest_id":str(id)}).ok:return false
 for id in current.rewarded:
  if id not in observed.rewarded:
   if not publish("reward_claimed","reward/"+str(id),{"quest_id":str(id)}).ok:return false
 return true
func committed() -> void:
 observed=observation()
 publish("save_completed","save/"+str(world.journey.data.exo_core.sequence),{},-2,false)
