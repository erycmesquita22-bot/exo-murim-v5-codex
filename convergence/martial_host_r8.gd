extends RefCounted
# R8 adapter. NO independent social state, roster, skills, inventory or save.
const Entity=preload("res://exo_core/contracts/entity_contracts.gd")
const Legacy=preload("res://exo_martial/masters/martial_engine.gd")
const Catalog=preload("res://exo_martial/styles/martial_catalog.gd")
var world: Node3D
var core: RefCounted
var martial: RefCounted
var last_master: String=""
var last_site: String=""
var contact_until: int=0
var action_seen: Dictionary={}
var meditation:Dictionary={}
var action_serial:int=0

func initialize(host: Node3D) -> bool:
 world=host;core=host.exo_core
 martial=core.instances.get("exo_martial",null)
 if martial==null or not core.services.has_service("martial"):return false
 if not core.bind_trusted_social_proof(Callable(self,"trusted_social_proof")):return false
 martial.configure_host_integrations(Callable(self,"trusted_lesson_proof"),Callable(self,"admission_attestation"))
 return true

func _resident(master_id: String) -> Node3D:
 for actor in world.residents:
  if is_instance_valid(actor) and str(actor.identity.get("id",""))==master_id and bool(actor.identity.get("active",false)):
   return actor
 return null

func _site_for(master_id:String, require_player:bool=true) -> Dictionary:
 if not bool(ProjectSettings.get_setting("exo_murim/r8/martial_enabled",true)):return {}
 if world.current_region<0 or not is_instance_valid(world.active_region) or world._institutional_inside() or world._dungeon_inside():return {}
 var actor:Node3D=_resident(master_id)
 if not is_instance_valid(actor) or str(actor.identity.get("role",""))!="master" or bool(actor.sheltered) or not actor.rig.visible:return {}
 if require_player and world.player.position.distance_to(actor.position)>3.4:return {}
 var profile:Dictionary=martial.master_profile(master_id)
 if profile.is_empty():return {}
 for station in world.active_region.monument_stations:
  if not station is Dictionary or str(station.get("kind",""))!="master_station" or int(station.get("capacity",0))<1:continue
  var pos:Vector3=station.get("world_position",Vector3.INF)
  if not pos.is_finite() or actor.position.distance_to(pos)>7.0:continue
  if require_player and world.player.position.distance_to(pos)>9.0:continue
  var site_id:String=str(station.get("site_id",""))
  # R9: a legitimate teacher is attached to a persistently generated occupational
  # slot for exactly this materialized school, never selected by proximity alone.
  if str(actor.identity.get("martial_site_id",""))!=site_id:continue
  if str(actor.identity.get("martial_school_id",""))!=str(profile.get("school_id","")):continue
  if int(actor.get("unreachable_count"))>0 and not bool(actor.get("arrived")):continue
  var matching:bool=false
  if station.get("source")=="city_forge_r4" and station.get("host_geometry_verified",false):
   for lot in world.active_region.data.lots:
    if str(lot.id)==site_id and str(lot.function)=="martial_school" and lot.has("city_model") and str(station.school_id)==str(profile.school_id):matching=true;break
  for plan in world.active_region.data.monumental_plans:
   if str(plan.get("id",""))!=site_id:continue
   if str(plan.get("kind","")) not in ["martial_medium","martial_grand"]:break
   var official_school:String=str(plan.get("school_id",""))
   matching=official_school.is_empty() or official_school==str(profile.get("school_id",""))
   break
  if not matching:continue
  # Check the physical sightline; do not teleport a master into a school.
  if require_player:
   var eye_from:Vector3=world.player.global_position+Vector3(0,1.1,0)
   var eye_to:Vector3=actor.global_position+Vector3(0,1.1,0)
   var params:=PhysicsRayQueryParameters3D.create(eye_from,eye_to,1|4)
   params.exclude=[world.player.get_rid(),actor.get_rid()]
   if not world.get_world_3d().direct_space_state.intersect_ray(params).is_empty():continue
  return station
 return {}

func trusted_social_proof(request:Dictionary) -> bool:
 if str(request.get("action",""))!="establish" or Time.get_ticks_msec()>contact_until:return false
 var master:String=last_master
 if master.is_empty():return false
 var save:Dictionary=world.journey.data
 if str(request.get("master_id",""))!=Legacy.identity(save,master):return false
 if str(request.get("disciple_id",""))!=Entity.player_id(save):return false
 var site:Dictionary=_site_for(master)
 return not site.is_empty() and str(site.get("station_id",""))==last_site and martial.master_available(master)

func admission_attestation(_learner:String,_master:String) -> Dictionary:
 # No laboratory proof and no fabricated trial outcomes. Schools without an
 # actual admission-trial witness remain locked until gameplay evidence exists.
 return {"proofs_completed":0,"trial_verified":false}

func _training_context() -> Dictionary:
 if world.current_region<0 or not is_instance_valid(world.active_region) or world._institutional_inside() or world._dungeon_inside():return {}
 var learner:String=Entity.player_id(world.journey.data)
 for training in world.journey.data.get("exo_martial",{}).get("training",{}).values():
  if not training is Dictionary or str(training.get("learner_id",""))!=learner or not bool(training.get("active",false)):continue
  var master:String=str(training.get("master_id",""))
  var profile:Dictionary=martial.master_profile(master)
  if str(profile.get("school_id",""))!="exo_martial.school.mosteiro_jade":continue
  var site:Dictionary=_site_for(master,false)
  if site.is_empty():continue
  var study:Dictionary={}
  for station in world.active_region.monument_stations:
   if str(station.get("site_id",""))==str(site.get("site_id","")) and str(station.get("kind",""))=="meditation_circle":study=station;break
  if study.is_empty():continue
  var near:Vector3=study.get("world_position",Vector3.INF)
  if not near.is_finite() or world.player.position.distance_to(near)>2.65:continue
  return {"learner":learner,"master":master,"training":training,"station":study,"master_actor":_resident(master)}
 return {}

func trusted_lesson_proof(kind:String,payload:Dictionary) -> bool:
 if kind=="site":
  var master_id:String=str(payload.get("master_id",""))
  if str(payload.get("learner_id",""))!=Entity.player_id(world.journey.data):return false
  var active_site:Dictionary=_site_for(master_id,true)
  if active_site.is_empty():return false
  for item in world.active_region.monument_stations:
   if str(item.get("site_id",""))==str(active_site.get("site_id","")) and str(item.get("kind",""))=="meditation_circle":
    return str(payload.get("marker_id",""))=="site/"+str(item.get("station_id",""))
  return false
 var ctx:Dictionary=_training_context()
 if ctx.is_empty() or kind!="action":return false
 if str(payload.get("learner_id",""))!=str(ctx.learner) or str(payload.get("master_id",""))!=str(ctx.master):return false
 var marker:String="site/"+str(ctx.station.get("station_id",""))
 var event:String=str(payload.get("event_id",""))
 if not action_seen.has(event):return false
 var witness:Dictionary=action_seen[event]
 action_seen.erase(event)
 return str(payload.get("marker_id",""))==marker and str(witness.get("marker_id",""))==marker and str(witness.get("lesson_id",""))==str(payload.get("lesson_id","")) and str(witness.get("action",""))==str(payload.get("action","")) and int(witness.get("qi_spent",-1))==int(payload.get("qi_spent",-2)) and int(witness.get("stamina_spent",-1))==int(payload.get("stamina_spent",-2)) and Time.get_ticks_msec()-int(witness.get("issued_msec",0))<2000

func handle_training_station() -> bool:
 var ctx:Dictionary=_training_context()
 if ctx.is_empty():return false
 var phase:String=str(ctx.training.get("phase",""))
 if phase=="ready" or phase=="awaiting_unlock":return false
 if phase=="demonstrated":
  _finish_training(ctx);return true
 if phase not in ["observing","practicing","examining"]:return false
 if not meditation.is_empty():
  world.message("Concentre-se até concluir a prática atual.");return true
 if world.combat_timer>0 or not world.player.is_on_floor() or not world.can_configure():
  world.message("Treinamento indisponível durante combate ou movimento.");return true
 var actor:Node3D=ctx.master_actor
 if not is_instance_valid(actor) or not actor.arrived or actor.activity_name!="meditacao":
  world.message("O mestre precisa estar meditando e disponível.");return true
 meditation={"phase":phase,"learner":str(ctx.learner),"master":str(ctx.master),"lesson_id":str(ctx.training.get("lesson_id","")),
  "station_id":str(ctx.station.get("station_id","")),"start":world.player.position,"clock":0.0,
  "cycle":int(actor.work_cycles),"region":world.current_region}
 world.message("Meditação iniciada. Permaneça imóvel na área ritual.")
 return true

func tick_training(delta:float) -> void:
 if meditation.is_empty():return
 var ctx:Dictionary=_training_context()
 if ctx.is_empty() or str(ctx.master)!=str(meditation.master) or str(ctx.training.get("phase",""))!=str(meditation.phase) or str(ctx.training.get("lesson_id",""))!=str(meditation.lesson_id) or world.current_region!=int(meditation.region):
  meditation={};return
 if world.health<=0 or world.combat_timer>0 or world.attack_time>=0 or world.roll_time>=0 or world.techniques.busy() or not world.player.is_on_floor() or world.player.position.distance_to(meditation.start)>.48:
  meditation={};world.message("A meditação foi interrompida.");return
 var actor:Node3D=ctx.master_actor
 if not is_instance_valid(actor) or actor.sheltered or actor.activity_name!="meditacao":meditation={};return
 meditation.clock=float(meditation.clock)+delta
 var phase:String=str(meditation.phase)
 var duration:float=3.0 if phase=="observing" else 5.0 if phase=="practicing" else 8.0
 if float(meditation.clock)<duration:return
 # Watching the master's REAL activity cycle is the observation witness.
 if phase=="observing" and int(actor.work_cycles)<=int(meditation.cycle):return
 meditation={}
 var school:Dictionary=Catalog.school("exo_martial.school.mosteiro_jade")
 var guide:Dictionary=school.get("teaching",{})
 var action:String=str(guide.get("observation_action","")) if phase=="observing" else str(guide.get("practice_action","")) if phase=="practicing" else str(guide.get("examination_action",""))
 var qi:int=int(guide.get("qi_cost",0));var stamina:int=int(guide.get("stamina_cost",0))
 if world.techniques.mana<float(qi) or world.techniques.stamina<float(stamina):world.message("Qi ou stamina insuficientes.");return
 var before_qi:float=world.techniques.mana;var before_stamina:float=world.techniques.stamina
 world.techniques.mana-=qi;world.techniques.stamina-=stamina;world.techniques.regen_delay=maxf(world.techniques.regen_delay,1.2)
 action_serial+=1
 var event:String="martial/r9/witness/"+(str(ctx.learner)+"|"+str(ctx.master)+"|"+str(action_serial)+"|"+str(Time.get_ticks_usec())).sha256_text().substr(0,48)
 var marker:String="site/"+str(ctx.station.get("station_id",""))
 action_seen[event]={"marker_id":marker,"lesson_id":str(ctx.training.lesson_id),"action":action,"qi_spent":qi,"stamina_spent":stamina,"issued_msec":Time.get_ticks_msec()}
 var proof:Dictionary={"mode":"runtime","event_id":event,"learner_id":str(ctx.learner),"master_id":str(ctx.master),"lesson_id":str(ctx.training.lesson_id),
  "action":action,"marker_id":marker,"marker_type":"meditation_circle","qi_spent":qi,"stamina_spent":stamina,"success":true}
 var result:Dictionary=martial.record_action(str(ctx.learner),str(ctx.master),proof)
 action_seen.erase(event)
 if not bool(result.get("ok",false)):
  world.techniques.mana=before_qi;world.techniques.stamina=before_stamina
  world.message("Prova rejeitada: "+str(result.get("reason","erro")));return
 world.message("Prática confirmada: "+str(result.get("phase","progresso salvo")))
 if str(result.get("phase",""))=="demonstrated":_finish_training(ctx)

func _finish_training(ctx:Dictionary) -> void:
 var result:Dictionary=martial.finish_lesson(str(ctx.learner),str(ctx.master))
 if not bool(result.get("ok",false)):
  world.message("Conclusão pendente: "+str(result.get("reason","erro")));return
 if str(result.get("reason",""))=="aguardando_desbloqueio_core":
  var ticket:Dictionary=result.get("ticket",{})
  var committed:Dictionary=core.confirm_martial_unlock_atomic(str(ctx.learner),str(ctx.master),str(ticket.get("technique_id","")))
  world.message("Técnica confirmada." if bool(committed.get("ok",false)) else "Técnica pendente: "+str(committed.get("reason","requisitos")))
 else:world.message("Lição concluída: "+str(result.get("reason","")))


func _show(master:String, heading:String,extra:String) -> void:
 var profile:Dictionary=martial.master_profile(master)
 var school:Dictionary=Catalog.school(str(profile.get("school_id","")))
 var npc:Dictionary=core.npc(master)
 var policy:Dictionary=school.get("admission_policy",{})
 var requirements:String="Nível mínimo: "+str(policy.get("min_level",1))+" • Reputação: "+str(policy.get("min_reputation",0))+" • Confiança: "+str(policy.get("min_trust",0))
 var name:String=str(npc.get("display_name",npc.get("name","Mestre")))
 world.ui.dialogue(name,heading+"\nEscola: "+str(school.get("name","Desconhecida"))+"\n"+requirements+"\n"+extra)

func _friendly(reason:String) -> String:
 var terms:Dictionary={"requisitos_cumpridos":"Requisitos atendidos", "aguardando_narrativo":"Pedido registrado. Pressione E novamente para avaliação.",
  "bond_and_martial_enrollment_committed":"Matrícula aceita! Vínculo e progressão salvos juntos.",
  "prova_de_entrada_pendente":"A escola exige atividades e provas de entrada que ainda não foram verificadas.",
  "avaliacao_de_entrada_nao_validada":"A avaliação presencial ainda não foi comprovada.",
  "confianca_insuficiente":"O mestre ainda não confia no candidato.","reputacao_insuficiente":"Reputação insuficiente para essa escola.",
  "nivel_insuficiente":"Nível insuficiente.","sem_vagas":"O mestre não tem vagas disponíveis.",
  "no_real_master_site_proof":"O mestre não está disponível numa estação marcial acessível.",
  "no_pending_application":"Não existe candidatura pendente para confirmar.","mestre_indisponivel":"O mestre não está disponível agora.",
  "outside_school":"O mestre não está na escola.","joint_commit_failed":"Falha no salvamento: nenhum vínculo foi concluído.",
  "save_v4_ou_schema_falhou":"Não foi possível salvar. Nenhuma matrícula foi concluída."}
 return str(terms.get(reason,reason.replace("_"," ").capitalize()))

func handle_master_interaction(actor:Node3D) -> bool:
 if not bool(ProjectSettings.get_setting("exo_murim/r8/martial_enabled",true)) or not is_instance_valid(actor):return false
 var master:String=str(actor.identity.get("id",""))
 if str(actor.identity.get("role",""))!="master" or not bool(actor.identity.get("active",false)):return false
 if not Legacy.eligible(world.journey.data,master):return false
 # Real persisted NPC; discovery uses the original R2 module and write authority.
 if martial.master_profile(master).is_empty():
  var found:Dictionary=martial.discover(master)
  if not bool(found.get("ok",false)):
   _show(master,"Perfil indisponível",str(found.get("reason","erro")));return true
 var site:Dictionary=_site_for(master)
 if site.is_empty():
  _show(master,"Mestre em circulação","Matrícula indisponível: não há estação marcial física acessível e vinculada a este mestre.")
  return true
 var learner:String=Entity.player_id(world.journey.data)
 var status:Dictionary=martial.status(learner,master)
 var now:int=Time.get_ticks_msec()
 var repeat:bool=last_master==master and last_site==str(site.get("station_id","")) and now<contact_until
 last_master=master;last_site=str(site.get("station_id",""));contact_until=now+15000
 var situation:String=str(status.get("status","desconhecido"))
 if situation=="desconhecido":
  if not repeat:
   _show(master,"Mestre encontrado","Pressione E novamente perto do mestre para solicitar admissão. Requisitos são conferidos pelo Núcleo Narrativo e pela escola.")
   return true
  var receipt:String="application/r8/"+str(master+"|"+learner+"|"+str(world.journey.data.exo_core.sequence)).sha256_text().substr(0,40)
  var apply:Dictionary=martial.request_enrollment(learner,master,receipt)
  _show(master,"Candidatura",_friendly(str(apply.get("reason","erro"))))
  return true
 if situation=="candidato":
  var receipt:String="bond/r8/"+str(master+"|"+learner+"|"+str(world.journey.data.exo_core.sequence)).sha256_text().substr(0,40)
  var result:Dictionary=core.confirm_martial_enrollment_atomic(learner,master,receipt)
  _show(master,"Avaliação e matrícula",_friendly(str(result.get("reason","erro"))))
  return true
 if situation=="ativo":
  var profile:Dictionary=martial.master_profile(master)
  var names:PackedStringArray=PackedStringArray()
  for tech_id in martial.master_profile(master).get("techniques",[]):
   var record:Dictionary=Catalog.technique(str(tech_id))
   if not record.is_empty():names.append(str(record.get("name","Arte marcial")))
  if names.size()>4:names=names.slice(0,4)
  var info:String="Técnicas do mestre: "+", ".join(names)
  if str(profile.get("school_id",""))=="exo_martial.school.mosteiro_jade":
   var station:Dictionary={}
   for item in world.active_region.monument_stations:
    if str(item.get("site_id",""))==str(site.get("site_id","")) and str(item.get("kind",""))=="meditation_circle":station=item;break
   if not station.is_empty():
    var learner_id:String=Entity.player_id(world.journey.data)
    if repeat:
     for technique in profile.get("techniques",[]):
      var marker:String="site/"+str(station.get("station_id",""))
      var preview:Dictionary=martial.lesson_preview(learner_id,master,str(technique),"meditacao",marker)
      if bool(preview.get("ok",false)):
       var started:Dictionary=martial.start_lesson(learner_id,master,str(technique),"meditacao",marker)
       _show(master,"Início da aula",("Aula iniciada. Vá ao círculo de meditação e pressione E." if bool(started.get("ok",false)) else _friendly(str(started.get("reason","erro")))))
       return true
    var phase_label:String=str(status.get("lesson_phase","ready"))
    var hint:String="Pressione E novamente para solicitar uma aula de meditação; depois use o círculo ritual no pátio." if phase_label=="ready" else "Aula em andamento: "+phase_label+". No círculo ritual, pressione E e complete a ação física." if phase_label in ["observing","practicing","examining"] else "Desbloqueio ou conclusão ainda pendente de confirmação."
    _show(master,"Discípulo matriculado",info+"\n"+hint)
    return true
  _show(master,"Discípulo matriculado",info+"\nEsta escola ainda depende de provas físicas específicas; nenhuma técnica é desbloqueada pelo diálogo.")
  return true
 _show(master,"Estado do discipulado",situation)
 return true
