extends RefCounted
## Trusted Combat adapter. Uses existing Techniques, enemies, Cultivation and JourneySave.
const Contract=preload("res://exo_skill_forge/runtime/host_contract.gd")
const Entity=preload("res://exo_core/contracts/entity_contracts.gd")
const Catalog=preload("res://catalog.gd")
var w:Node3D
var permits:Dictionary={}
var serial:int=0
var clock:float=0.0
var releases:int=0
var hits:int=0
func _init(world:Node3D):w=world
func state()->Dictionary:
 var ext:Dictionary=w.extension()
 if not ext.has("activation_v4"):ext.activation_v4={"schema":1,"receipts":{},"recovery":{},"library":{}}
 return ext.activation_v4
func initialize():
 var owner:RefCounted=w.exo_core.instances.exo_skill_forge
 owner.bind_trusted_host(Contract.HOST_ID,Callable(self,"permit_skill"),Callable(self,"commit_skill"))
 for id in state().recovery:w.techniques.recovery[id]=float(state().recovery[id])
func eligible_skill(id:String)->bool:
 if not bool(ProjectSettings.get_setting("exo_murim/convergence4/authorial_skills",true)):return false
 var skill:Dictionary=w.exo_core.services.invoke("skill_forge","skill",[id])
 if skill.is_empty() or not supported(id):return false
 if int(w.journey.data.get("journey_dynamic",{}).get("progress",{}).get("level",1))<int(skill.tags.min_level):return false
 if skill.tags.schools.is_empty() and skill.tags.styles.is_empty():return true
 var learner:String=Entity.player_id(w.journey.data)
 var martial:Dictionary=w.journey.data.get("exo_martial",{})
 for training in martial.get("training",{}).values():
  if str(training.get("learner_id",""))!=learner or not bool(training.get("active",false)):continue
  var profile:Dictionary=martial.get("profiles",{}).get(str(training.get("master_id","")),{})
  if (skill.tags.schools.is_empty() or str(profile.get("school_id","")) in skill.tags.schools) and (skill.tags.styles.is_empty() or str(profile.get("style_id","")) in skill.tags.styles):return true
 return false
func supported(id:String)->bool:
 for row in Catalog.SKILLS:
  if row.id==id:return row.has("forge_id")
 return false
func reason(plan:Dictionary)->String:
 var id:String=str(plan.get("skill_id",""))
 if not supported(id) or not eligible_skill(id):return "requirements"
 if w.flow.phase!="adventure" or w.flow.lab_mode or w.current_region<0 or w.changing_region:return "inactive_region"
 for action in plan.get("actions",[]):
  if str(action.get("op",""))=="damage" and w.is_safe(w.player.position):return "safe_zone"
 if w.get_tree().paused or w.health<=0 or w.attack_time>=0 or w.roll_time>=0 or w.techniques.busy():return "actor_busy"
 if w.activity!=null and w.activity.locked():return "activity_locked"
 if id not in w.journey.data.learned or id not in w.journey.data.loadout:return "not_learned_or_slotted"
 var skill:Dictionary=w.exo_core.services.invoke("skill_forge","skill",[id])
 var weapon:String=str(w.current_weapon().id)
 if weapon not in skill.tags.weapon_ids:return "weapon"
 if float(w.techniques.recovery.get(id,0))>0:return "cooldown"
 if w.techniques.mana<float(plan.cost.qi) or w.techniques.stamina<float(plan.cost.stamina):return "energy"
 return ""
func permit_skill(actor_id:String,plan:Dictionary)->Dictionary:
 if actor_id!="player" or not reason(plan).is_empty():return {"ok":false}
 var actual:Dictionary=w.exo_core.services.invoke("skill_forge","plan",[str(plan.skill_id),{"type":"player"}])
 if Contract.fingerprint(actual)!=Contract.fingerprint(plan):return {"ok":false}
 serial+=1
 var receipt:String="cast/v4/"+str(Time.get_ticks_usec())+"/"+str(serial)
 permits[receipt]=Contract.fingerprint(plan)
 return {"ok":true,"owner":"combat","schema_version":2,"receipt":receipt,"plan_sha256":permits[receipt]}
func commit_skill(actor_id:String,plan:Dictionary,receipt:String)->Dictionary:
 var reply:Dictionary={"ok":false,"committed":false,"status":"rejected","schema_version":2,"receipt":receipt}
 if actor_id!="player":return reply
 var digest:String=Contract.fingerprint(plan)
 if state().receipts.has(receipt):
  if str(state().receipts[receipt])==digest:reply.merge({"ok":true,"status":"duplicate"},true)
  return reply
 if str(permits.get(receipt,""))!=digest or not reason(plan).is_empty():return reply
 permits.erase(receipt)
 var before:Dictionary=w.journey.data.duplicate(true)
 var qi:float=w.techniques.mana;var stamina:float=w.techniques.stamina
 var recovery:Dictionary=w.techniques.recovery.duplicate(true)
 var id:String=str(plan.skill_id)
 w.techniques.mana-=float(plan.cost.qi);w.techniques.stamina-=float(plan.cost.stamina)
 w.techniques.recovery[id]=float(plan.cooldown)
 state().receipts[receipt]=digest
 while state().receipts.size()>128:state().receipts.erase(state().receipts.keys()[0])
 if not w.save_progress():
  w.journey.data=before;w.techniques.mana=qi;w.techniques.stamina=stamina;w.techniques.recovery=recovery
  return reply
 var data:Dictionary=Catalog.skill(id).duplicate(true)
 w.techniques.cast_serial+=1;data["_cast"]=w.techniques.cast_serial;data["forge_plan"]=plan.duplicate(true)
 w.techniques.casting=data;w.techniques.active=w.journey.data.loadout.find(id);w.techniques.time=0;w.techniques.released=false
 w.techniques.direction=w.facing;w.techniques.regen_delay=1.2;w.techniques.struck.clear()
 w.model.rotation.y=atan2(-w.facing.x,-w.facing.z);w.message(str(data.name))
 w.audio_fx.skill(data,true)
 reply.merge({"ok":true,"committed":true,"status":"committed"},true)
 return reply
func release_skill(data:Dictionary):
 var plan:Dictionary=data.forge_plan
 var facing:Vector3=w.techniques.direction
 var color:Color=w.techniques.color_for(data)
 w.techniques.ring(w.player.position,maxf(1.0,float(plan.actions[0].get("radius",1.0))),color,.3)
 releases+=1
 w.audio_fx.skill(data)
 var targets:Array=[]
 for action in plan.actions:
  if str(action.op)=="damage":
   var shape:String=str(action.get("shape",""))
   var radius:float=float(action.radius) if shape=="circle" else float(action.range)
   var cone:float=-1.0 if shape=="circle" else cos(deg_to_rad(float(action.cone_degrees))*.5)
   for enemy in w.enemies:
    if targets.size()>=int(action.get("max_targets",5)):break
    if not is_instance_valid(enemy) or enemy.hp<=0:continue
    if not w.can_hit(w.player.position,enemy.position,facing,radius,cone):continue
    var ray:=PhysicsRayQueryParameters3D.create(w.player.position+Vector3.UP,enemy.position+Vector3.UP,1|4)
    ray.exclude=[w.player.get_rid(),enemy.get_rid()]
    if not w.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():continue
    if shape=="line" and absf((enemy.position-w.player.position).cross(facing).y)>.7:continue
    if enemy.hurt(w.techniques.scaled_damage(float(action.base_damage),data),Vector3.ZERO,0,w.audio_fx.technique_context(data)):
     targets.append(enemy);hits+=1
  elif str(action.op)=="status":
   for enemy in targets:
    if not is_instance_valid(enemy) or enemy.hp<=0:continue
    var duration:float=float(action.duration)
    match str(action.status):
     "slow":enemy.slow=maxf(enemy.slow,duration)
     "stagger":enemy.stagger=maxf(enemy.stagger,duration)
     "root":enemy.apply_control(Vector3.ZERO,duration)
     "knockback":enemy.apply_control(facing*maxf(1.0,float(action.strength)*12.0),0)
  elif str(action.op)=="shield":
   w.techniques.shield=float(action.value);w.techniques.shield_time=float(action.duration);w.techniques.shield_source=data.duplicate(true)
  elif str(action.op)=="heal":w.health=mini(w.max_health,w.health+int(action.value))
func prepare_save():
 var cooldown:Dictionary={}
 for id in w.techniques.recovery:
  if supported(str(id)):cooldown[id]=float(w.techniques.recovery[id])
 state().recovery=cooldown
func tick(delta:float):
 clock-=delta
 if clock>0:return
 clock=2.0
 if w.flow.phase!="adventure" or w.current_region<0:return
 var changed:bool=false
 for row in Catalog.SKILLS:
  if row.has("forge_id") and row.id not in w.journey.data.known and eligible_skill(str(row.id)):
   w.journey.data.known.append(row.id);changed=true
 if changed:w.save_progress()
func library_context(key:String)->Dictionary:
 return {"world_id":str(w.journey.data.world.id),"seed":int(w.journey.data.world.seed),"region_id":w.current_region,"biome":str(w.active_region.data.spec.biome),"settlement_type":str(w.active_region.data.spec.get("settlement_scale","none")),"player_tier":int(w.journey_manager.state().progress.level),"flags":[],"tags":[],"instance_key":key}
func consume(owner:String,key:String,domains:Array,context_override:Dictionary={})->Array:
 if state().library.has(key):return state().library[key]
 var proposal:Dictionary=w.exo_core.services.invoke("content.library","preview",[owner,library_context(key) if context_override.is_empty() else context_override,domains])
 if proposal.get("status")!="PROPOSAL_ONLY":return []
 var rows:Array=proposal.proposals.duplicate(true)
 state().library[key]=rows
 while state().library.size()>480:state().library.erase(state().library.keys()[0])
 return rows
func apply_npc_content():
 for actor in w.residents:
  var rows:Array=consume("living_world","npc/"+str(actor.identity.id),["personality","npc_motivation"])
  for row in rows:
   if str(row.domain)=="personality":
    var hints:Dictionary=row.variables.get("npc_system_traits_hint",{})
    for key in ["risk","social","duty","ambition","curiosity"]:
     if hints.has(key):actor.identity.preferences[key]=clampi(int(hints[key]),0,100)
    actor.identity["personality"]=str(row.variables.get("personality",actor.identity.get("personality","prudente")))
    actor.set_meta("library_personality",str(row.record_id))
    record_use(row,"npc_traits")
   elif str(row.domain)=="npc_motivation":actor.set_meta("library_motivation",str(row.variables.get("goal","")))
  if w.journey.data.living_world.npcs.has(str(actor.identity.id)):
   w.journey.data.living_world.npcs[actor.identity.id].preferences=actor.identity.preferences.duplicate(true)
   w.journey.data.living_world.npcs[actor.identity.id].personality=actor.identity.personality
func order_quest_offers(npc:Dictionary,offers:Array)->Array:
 var rows:Array=consume("journey","quest/"+str(npc.id),["quest_pattern"])
 if rows.is_empty():return offers
 var hint:String=str(rows[0].variables.get("canonical_objective_hint",""))
 var type:String={"eliminate_enemy":"defeat","clear_group":"clear","explore_region":"visit","collect_iron":"collect","deliver_iron":"deliver","speak_npc":"talk","investigate_ruin":"investigate"}.get(hint,"")
 if type.is_empty():return offers
 var matching:bool=false
 for offer in offers:
  if str(offer.type)==type:matching=true
 if matching:record_use(rows[0],"quest_offer_priority")
 offers.sort_custom(func(a,b):return int(str(a.type)!=type)<int(str(b.type)!=type))
 return offers

func record_use(row:Dictionary,consumer:String):
 if not state().has("consumed"):state().consumed={}
 var key:String=str(row.record_id)+"|"+consumer
 state().consumed[key]={"record_id":str(row.record_id),"consumer":consumer}
func npc_dialogue(actor:Node3D)->String:
 var text:String=""
 for row in consume("living_world","npc/"+str(actor.identity.id),["personality","npc_motivation"]):
  if str(row.domain)!="npc_motivation":continue
  var goals:Dictionary={"seek_teacher":"Procuro um mestre que aceite me ensinar.","protect_family":"Quero manter minha família em segurança.","pay_debt":"Preciso quitar uma dívida.","repair_honor":"Quero reparar a honra de minha família.","find_herb":"Procuro uma erva medicinal.","trade_route":"Busco uma rota segura para comerciar.","recover_manual":"Quero recuperar um manual perdido.","return_home":"Desejo voltar para casa.","find_missing":"Procuro alguém que desapareceu.","prove_skill":"Quero demonstrar minha habilidade.","protect_sect":"Preciso proteger minha seita.","warn_village":"Trago um aviso para a aldeia.","sell_heirloom":"Preciso vender uma herança.","escape_clan":"Quero deixar meu clã.","atone":"Busco reparar meus erros.","investigate_ruin":"Quero investigar as ruínas.","healing":"Procuro tratamento.","expose_fraud":"Quero revelar uma fraude.","deliver_message":"Tenho uma mensagem para entregar.","challenge_rival":"Quero desafiar um rival.","seek_revenge":"Ainda busco justiça por uma antiga ofensa.","explore_world":"Quero conhecer as terras além desta região.","gain_power":"Treino para me tornar mais forte.","serve_sect":"Quero honrar minha seita."}
  var goal:String=str(row.variables.get("goal",""))
  if goals.has(goal):
   text="\n\n"+str(goals[goal]);record_use(row,"npc_dialogue")
 return text

func encounter_danger(site:Dictionary)->int:
 var danger:int=int(site.danger)
 for row in consume("bestiary","encounter/"+str(site.id),["encounter_theme"]):
  var hint:int=int(row.variables.get("threat_tier_hint",0))
  if hint in [1,2]:
   danger=clampi(danger+hint-1,1,20)
   record_use(row,"enemy_danger")
 return danger
