extends RefCounted
# R2 is a deterministic educational state machine, never an alternative combat engine.
const Legacy=preload("res://exo_martial/masters/martial_engine.gd")
const Catalog=preload("res://exo_martial/styles/martial_catalog.gd")
const State=preload("res://exo_martial/r2/state_r2.gd")
const Entity=preload("res://exo_core/contracts/entity_contracts.gd")
const Bonds=preload("res://narrative/society/relationship_system.gd")

static func reply(ok: bool,reason: String,changed: bool=false) -> Dictionary:
	return {"ok":ok,"reason":reason,"changed":changed}
static func d(save: Dictionary) -> Dictionary:return save.get("exo_martial",{})
static func key(learner: String,master: String) -> String:return Legacy.pair_key(learner,master)
static func school_for(save: Dictionary,master: String) -> Dictionary:
	return Catalog.school(str(d(save).get("profiles",{}).get(master,{}).get("school_id","")))
static func live_npc(save: Dictionary,master: String) -> bool:
	var n: Dictionary=Legacy.npc(save,master)
	return not n.is_empty() and bool(n.get("active",false)) and int(n.get("hp",1))>0
static func verified_bond(save: Dictionary,learner: String,master: String) -> bool:
	return Legacy.bond(save,learner,master)
static func sole_school(save: Dictionary,learner: String,master: String) -> bool:
	# Both martial active/pending relationships AND authoritative narrative bonds are checked.
	for item in d(save).get("training",{}).values():
		if item is Dictionary and str(item.get("learner_id",""))==learner and str(item.get("master_id",""))!=master and bool(item.get("active",false)):
			return false
	for item in d(save).get("applications",{}).values():
		if item is Dictionary and str(item.get("learner_id",""))==learner and str(item.get("master_id",""))!=master and str(item.get("status","")) in ["pending","withdrawal_requested"]:
			return false
	var identity: String=Legacy.identity(save,learner)
	if identity.is_empty():return false
	var current: String=Legacy.identity(save,master)
	for entry in save.get("narrative",{}).get("relationships",{}).values():
		if not entry is Dictionary or str(entry.get("kind",""))!="master_disciple":continue
		if identity in [str(entry.get("a","")),str(entry.get("b",""))]:
			var other: String=str(entry.get("b","")) if str(entry.get("a",""))==identity else str(entry.get("a",""))
			if other!=current:return false
	return true
static func unique(save: Dictionary,receipt: String) -> bool:
	return not receipt.is_empty() and receipt.length()<=160 and not d(save).get("receipts",{}).has(receipt) and d(save).get("receipts",{}).size()<60000
static func rank_level(save: Dictionary,learner: String) -> int:
	if learner.begins_with("npc/r"):return int(Legacy.npc(save,learner).get("level",1))
	return int(save.get("journey_dynamic",{}).get("progress",{}).get("level",1))

static func examine_application(save: Dictionary,learner: String,master: String,context: Dictionary) -> Dictionary:
	if not Legacy.actor(save,learner) or learner==master:return reply(false,"aprendiz_invalido")
	if bool(d(save).get("training",{}).get(key(learner,master),{}).get("active",false)):return reply(false,"disciplina_ja_ativa")
	if not live_npc(save,master) or not d(save).get("profiles",{}).has(master):return reply(false,"mestre_inexistente_ou_inativo")
	if not sole_school(save,learner,master):return reply(false,"escola_primaria_exclusiva")
	if not Legacy.factions_compatible(save,learner,master):return reply(false,"faccao_incompativel")
	var s: Dictionary=school_for(save,master)
	if s.is_empty():return reply(false,"escola_desconhecida")
	var policy: Dictionary=s.admission_policy
	if int(context.get("trust",-100))<int(policy.min_trust):return reply(false,"confianca_insuficiente")
	if int(context.get("reputation",-100))<int(policy.min_reputation):return reply(false,"reputacao_insuficiente")
	if rank_level(save,learner)<int(policy.min_level):return reply(false,"nivel_insuficiente")
	if int(context.get("proofs_completed",0))<int(policy.min_completed_proofs):return reply(false,"prova_de_entrada_pendente")
	if bool(policy.requires_trial) and not bool(context.get("admission_trial_verified",false)):return reply(false,"avaliacao_de_entrada_nao_validada")
	if Legacy.count_students(save,master)>=int(d(save).profiles[master].max_disciples):return reply(false,"sem_vagas")
	return reply(true,"requisitos_cumpridos")

static func apply(save: Dictionary,learner: String,master: String,context: Dictionary,receipt: String) -> Dictionary:
	var k: String=key(learner,master)
	if d(save).get("applications",{}).has(k):return reply(false,"candidatura_existente")
	if not unique(save,receipt):return reply(false,"recibo_duplicado")
	if d(save).applications.size()>=4096:return reply(false,"limite_candidaturas")
	var check: Dictionary=examine_application(save,learner,master,context)
	if not check.ok:return check
	d(save).applications[k]={"learner_id":learner,"master_id":master,"status":"pending","receipt":receipt,"proofs_completed":int(context.get("proofs_completed",0)),"attempts":1}
	d(save).receipts[receipt]="martial_application"
	return reply(true,"aguardando_narrativo",true)

static func appeal(save: Dictionary,learner: String,master: String,context: Dictionary,receipt: String) -> Dictionary:
	var k: String=key(learner,master)
	var old: Dictionary=d(save).applications.get(k,{})
	if str(old.get("status",""))!="refused":return reply(false,"sem_recusa_anterior")
	if int(old.get("attempts",1))>=3:return reply(false,"limite_de_recursos")
	if int(context.get("proofs_completed",0))<=int(old.get("proofs_completed",0)):return reply(false,"necessaria_nova_prova")
	if not unique(save,receipt):return reply(false,"recibo_ja_usado")
	var requirements: Dictionary=examine_application(save,learner,master,context)
	if not requirements.ok:return requirements
	d(save).applications[k]={"learner_id":learner,"master_id":master,"status":"pending","receipt":receipt,"proofs_completed":int(context.get("proofs_completed",0)),"attempts":int(old.get("attempts",1))+1}
	d(save).receipts[receipt]="martial_appeal/"+k
	return reply(true,"novo_pedido_apos_prova",true)

static func refuse(save: Dictionary,learner: String,master: String,receipt: String,reason: String) -> Dictionary:
	var k: String=key(learner,master)
	if not d(save).applications.has(k) or str(d(save).applications[k].status)!="pending":return reply(false,"candidatura_nao_pendente")
	if not unique(save,receipt) or reason not in ["conduta","vaga","prova","conflito","decisao_do_mestre"]:return reply(false,"recusa_invalida")
	d(save).applications[k].status="refused"
	d(save).applications[k]["reason"]=reason
	d(save).receipts[receipt]="refusal/"+k
	return reply(true,"recusado",true)

static func confirm(save: Dictionary,learner: String,master: String) -> Dictionary:
	var k: String=key(learner,master)
	var training: Dictionary=d(save).training.get(k,{})
	if bool(training.get("active",false)) and verified_bond(save,learner,master) and sole_school(save,learner,master):return reply(true,"matricula_ja_confirmada")
	if not d(save).applications.has(k) or str(d(save).applications[k].status)!="pending":return reply(false,"candidatura_nao_pendente")
	if not verified_bond(save,learner,master):return reply(false,"confirmacao_narrativa_ausente")
	if not sole_school(save,learner,master):return reply(false,"outro_mestre_ativo")
	if not live_npc(save,master):return reply(false,"mestre_indisponivel")
	if not Legacy.factions_compatible(save,learner,master):return reply(false,"faccao_incompativel")
	if Legacy.count_students(save,master)>=int(d(save).profiles[master].max_disciples):return reply(false,"sem_vagas")
	if d(save).training.size()>=8192 and not d(save).training.has(k):return reply(false,"limite_treinamentos")
	if training.is_empty():
		training={"learner_id":learner,"master_id":master,"rank":3,"mastery":0,"practice":0,"lesson_goal":0,"completed_lessons":0,"phase":"ready","lesson_id":"","pending_technique":"","method":"","learned":{},"active":true}
		training["r2"]={"lesson_seq":0,"observation_done":false,"practice_done":0,"exam_passed":false,"pending_unlock":"","exam_history":{},"outcome":"active","school_id":str(d(save).profiles[master].school_id),"transfer_from":"","refusals":0}
	else:
		# Reinstatement preserves mastery, school history and learned records.
		training.active=true;training.phase="ready";training.r2.outcome="active"
	d(save).training[k]=training
	d(save).applications.erase(k)
	return reply(true,"discipulo_externo",true)

static func relation(save: Dictionary,learner: String,master: String) -> Dictionary:
	var k: String=key(learner,master)
	var t: Dictionary=d(save).get("training",{}).get(k,{})
	if t.is_empty():return {"status":"candidato" if d(save).get("applications",{}).has(k) else "desconhecido","bond":verified_bond(save,learner,master)}
	var status: String="ativo"
	if not bool(t.active):status="encerrado"
	elif not verified_bond(save,learner,master):status="aguardando_regularizacao_narrativa"
	elif not live_npc(save,master):status="mestre_indisponivel"
	elif not Legacy.factions_compatible(save,learner,master):status="faccao_conflitante"
	return {"status":status,"rank":int(t.rank),"mastery":int(t.mastery),"lesson_phase":str(t.phase),"school_id":str(t.r2.school_id),"pending_unlock":str(t.r2.pending_unlock),"learned":t.learned.duplicate(true)}

static func active(save: Dictionary,learner: String,master: String) -> Dictionary:
	var t: Dictionary=d(save).get("training",{}).get(key(learner,master),{})
	return t if not t.is_empty() and bool(t.get("active",false)) and verified_bond(save,learner,master) and sole_school(save,learner,master) and live_npc(save,master) and Legacy.factions_compatible(save,learner,master) else {}

static func equipment_ok(save: Dictionary,learner: String,profile: Dictionary,tech: Dictionary) -> bool:
	if learner.begins_with("npc/r"):return true # NPC loadout not available; authoritative NPC gear adapter required in integration
	var style: Dictionary=Catalog.style(str(profile.style_id))
	var allowed: Array=style.get("weapon_families",[])
	if allowed.is_empty():return true
	var uid: String=str(save.get("equipped",""))
	var ref: String=""
	for entry in save.get("items",[]):
		if entry is Dictionary and str(entry.get("uid",""))==uid and str(entry.get("kind",""))=="weapon":ref=str(entry.get("ref",""))
	if ref.is_empty():return false
	var pose: String=Catalog.weapon_pose(ref)
	var aliases: Dictionary={"sword":"blade","katana":"draw","spear":"thrust","unarmed":"fists","dagger":"reverse"}
	for fam in allowed:
		if pose==str(fam) or pose==str(aliases.get(str(fam),"never")):return true
	return false

static func lesson_plan(save: Dictionary,learner: String,master: String,technique: String,method: String,marker: String="") -> Dictionary:
	var t: Dictionary=active(save,learner,master)
	if t.is_empty():return reply(false,"relacao_inativa")
	if str(t.phase)!="ready":return reply(false,"aula_em_andamento")
	var p: Dictionary=d(save).profiles[master]
	var school: Dictionary=school_for(save,master)
	var guide: Dictionary=school.get("teaching",{})
	var tech: Dictionary=Catalog.technique(technique)
	var form: Dictionary=Catalog.method(method)
	if tech.is_empty() or form.is_empty():return reply(false,"catalogo_invalido")
	if technique not in p.techniques:return reply(false,"mestre_nao_ensina")
	if str(p.style_id) not in tech.style_ids and not any_secondary(p,tech):return reply(false,"estilo_incompativel")
	if technique==str(p.get("secret_technique_id","")) and int(t.rank)<6:return reply(false,"tecnica_secreta")
	if method not in guide.allowed_methods:return reply(false,"metodo_nao_ensinado_na_escola")
	if tech.category not in form.categories and "*" not in form.categories:return reply(false,"metodo_nao_serve_para_tecnica")
	if rank_level(save,learner)<int(tech.requires.level) or int(t.rank)<int(tech.requires.rank):return reply(false,"requisitos_nao_cumpridos")
	if not equipment_ok(save,learner,p,tech):return reply(false,"arma_incompativel")
	if learner==Entity.player_id(save) and str(tech.core_skill_id) in save.get("learned",[]):return reply(false,"ja_aprendida_no_core")
	if str(t.r2.pending_unlock)!="":return reply(false,"desbloqueio_anterior_pendente")
	if t.learned.has(technique):return reply(false,"tecnica_ja_dominada_neste_vinculo")
	var marker_type: String=str(guide.class_marker)
	if not marker.is_empty() and not marker.begins_with("site/") and not marker.begins_with("lab/"):return reply(false,"marcador_invalido")
	var index: int=int(t.r2.lesson_seq)+1
	var lesson_id: String="lesson/"+key(learner,master).substr(0,24)+"/"+str(index)+"/"+str(tech.core_skill_id)
	return {"ok":true,"lesson_id":lesson_id,"technique_id":technique,"method_id":method,"marker_type":marker_type,"marker_id":marker,"required_actions":int(guide.practice_repetitions),"stage":"observe","observation_action":str(guide.observation_action),"practice_action":str(guide.practice_action),"exam_action":str(guide.examination_action),"exam_marker":str(guide.exam_marker),"cost":{"qi":int(guide.qi_cost),"stamina":int(guide.stamina_cost)}}

static func any_secondary(p: Dictionary,tech: Dictionary) -> bool:
	for id in p.get("secondary_styles",[]):
		if str(id) in tech.style_ids:return true
	return false

static func begin_lesson(save: Dictionary,learner: String,master: String,technique: String,method: String,marker: String="") -> Dictionary:
	var plan: Dictionary=lesson_plan(save,learner,master,technique,method,marker)
	if not plan.get("ok",false):return plan
	var t: Dictionary=active(save,learner,master)
	t.r2.lesson_seq=int(t.r2.lesson_seq)+1
	t.r2.observation_done=false;t.r2.practice_done=0;t.r2.exam_passed=false
	t.phase="observing";t.practice=0;t.lesson_goal=int(plan.required_actions)
	t.lesson_id=str(plan.lesson_id);t.pending_technique=technique;t.method=method
	t.r2["marker_id"]=marker;t.r2["marker_type"]=str(plan.marker_type)
	plan["changed"]=true
	return plan

# Action evidence is admitted ONLY by a trusted host validator. Caller never gets to assert 'verified=true'.
# The public module validates action/event/marker/cost using an injected trusted interface first.
static func record_action(save: Dictionary,learner: String,master: String,proof: Dictionary) -> Dictionary:
	var t: Dictionary=active(save,learner,master)
	if t.is_empty():return reply(false,"relacao_inativa")
	var school: Dictionary=school_for(save,master)
	var guide: Dictionary=school.teaching
	var phase: String=str(t.phase)
	if phase not in ["observing","practicing","examining"]:return reply(false,"fase_invalida")
	var name: String="observation_action" if phase=="observing" else "practice_action" if phase=="practicing" else "examination_action"
	var expected: String=str(guide[name])
	var marker_type: String=str(guide.exam_marker) if phase=="examining" else str(guide.class_marker)
	if str(proof.get("lesson_id",""))!=str(t.lesson_id) or str(proof.get("action",""))!=expected:return reply(false,"acao_ou_aula_divergente")
	if str(proof.get("marker_type",""))!=marker_type:return reply(false,"marcador_de_treino_invalido")
	var event: String=str(proof.get("event_id",""))
	if not unique(save,event):return reply(false,"evento_repetido")
	if str(proof.get("learner_id",""))!=learner or str(proof.get("master_id",""))!=master:return reply(false,"atores_divergentes")
	if int(proof.get("qi_spent",-1))<int(guide.qi_cost) or int(proof.get("stamina_spent",-1))<int(guide.stamina_cost):return reply(false,"custo_nao_confirmado")
	var marker_id: String=str(proof.get("marker_id",""))
	if marker_id.is_empty() or (not marker_id.begins_with("site/") and not marker_id.begins_with("lab/")):return reply(false,"local_nao_autorizado")
	if phase!="examining" and str(t.r2.get("marker_id",""))!="" and str(t.r2.marker_id)!=marker_id:return reply(false,"local_trocado")
	if marker_id.begins_with("lab/") and str(proof.get("mode",""))!="lab":return reply(false,"marcador_de_laboratorio_em_producao")
	if phase=="examining" and not bool(proof.get("success",false)):return reply(false,"prova_nao_aprovada")
	d(save).receipts[event]=phase+"/"+str(t.lesson_id)
	if phase=="observing":
		t.r2.observation_done=true;t.phase="practicing"
	elif phase=="practicing":
		t.r2.practice_done=int(t.r2.practice_done)+1;t.practice=int(t.r2.practice_done)
		# No XP awarded until exam passes; rehearsal spamming cannot inflate progress.
		if int(t.r2.practice_done)>=int(t.lesson_goal):t.phase="examining"
	else:
		t.r2.exam_passed=true;t.phase="demonstrated"
	return {"ok":true,"reason":"acao_validada","changed":true,"phase":str(t.phase),"practice":int(t.practice)}

static func finish_lesson(save: Dictionary,learner: String,master: String) -> Dictionary:
	var t: Dictionary=active(save,learner,master)
	if t.is_empty() or str(t.phase)!="demonstrated" or not bool(t.r2.exam_passed):return reply(false,"prova_pendente")
	var tech: Dictionary=Catalog.technique(str(t.pending_technique))
	if tech.is_empty():return reply(false,"tecnica_ausente")
	var receipt: String="martial/r2/lesson/"+str(t.lesson_id)
	if not unique(save,receipt):return reply(false,"aula_ja_concluida")
	var school: Dictionary=school_for(save,master)
	d(save).receipts[receipt]="completed/"+str(t.pending_technique)
	t.completed_lessons=int(t.completed_lessons)+1
	t.mastery=mini(1000,int(t.mastery)+int(school.teaching.practice_mastery_award))
	var obtained: String=str(t.pending_technique)
	t.r2.exam_passed=false;t.r2.observation_done=false;t.r2.practice_done=0
	t.practice=0;t.lesson_goal=0;t.lesson_id="";t.pending_technique="";t.method=""
	if int(t.mastery)<int(tech.requires.mastery):
		t.phase="ready"
		return {"ok":true,"reason":"reforco_necessario","changed":true,"mastery":int(t.mastery),"required_mastery":int(tech.requires.mastery)}
	if learner.begins_with("npc/r"):
		# Logical NPC knowledge belongs to this domain; no physical skill cast here.
		if t.learned.has(obtained):return reply(false,"ja_aprendida")
		t.learned[obtained]=1;t.phase="ready"
		return {"ok":true,"reason":"tecnica_npc_registrada","changed":true,"technique_id":obtained}
	# Player does not gain skill here. The authorized Core skill owner must apply it.
	t.phase="awaiting_unlock";t.r2.pending_unlock=obtained
	return {"ok":true,"reason":"aguardando_desbloqueio_core","changed":true,"ticket":unlock_ticket(save,learner,master,obtained)}

static func unlock_ticket(save: Dictionary,learner: String,master: String,technique: String) -> Dictionary:
	var tech: Dictionary=Catalog.technique(technique)
	return {"ticket_id":"martial_unlock/"+key(learner,master)+"/"+str(tech.get("core_skill_id","")),"learner_id":learner,"master_id":master,"technique_id":technique,"core_skill_id":str(tech.get("core_skill_id","")),"authority":"Core cultivation learn()/reveal(); no slot modification"}

static func confirm_core_unlock(save: Dictionary,learner: String,master: String,technique: String) -> Dictionary:
	var t: Dictionary=active(save,learner,master)
	if t.is_empty() or str(t.phase)!="awaiting_unlock" or str(t.r2.pending_unlock)!=technique:return reply(false,"ticket_inexistente")
	var tech: Dictionary=Catalog.technique(technique)
	if tech.is_empty() or learner!=Entity.player_id(save):return reply(false,"tecnica_ou_jogador_invalido")
	var core_id: String=str(tech.core_skill_id)
	if core_id not in save.get("known",[]) or core_id not in save.get("learned",[]):return reply(false,"core_nao_confirmou")
	if t.learned.has(technique):return reply(false,"registro_duplicado")
	t.learned[technique]=1;t.r2.pending_unlock="";t.phase="ready"
	return reply(true,"core_confirmado",true)

static func request_separation(save: Dictionary,learner: String,master: String,reason: String,receipt: String) -> Dictionary:
	var t: Dictionary=d(save).get("training",{}).get(key(learner,master),{})
	# A dead, expelled, missing or hostile master must not trap the learner forever.
	if t.is_empty() or not bool(t.get("active",false)):return reply(false,"sem_matricula_ativa")
	if reason not in ["withdrawal","expulsion","transfer"] or not unique(save,receipt):return reply(false,"desligamento_invalido")
	var k: String=key(learner,master)
	if d(save).applications.has(k):return reply(false,"processo_ja_aberto")
	d(save).applications[k]={"learner_id":learner,"master_id":master,"status":"withdrawal_requested","reason":reason,"receipt":receipt}
	d(save).receipts[receipt]="separation_requested/"+k
	return reply(true,"aguardando_remocao_narrativa",true)

static func finalize_separation(save: Dictionary,learner: String,master: String) -> Dictionary:
	var k: String=key(learner,master)
	var t: Dictionary=d(save).training.get(k,{})
	if t.is_empty():return reply(false,"disciplina_nao_encontrada")
	if not bool(t.active):return reply(true,"desligamento_ja_confirmado")
	var a: Dictionary=d(save).applications.get(k,{})
	if str(a.get("status",""))!="withdrawal_requested":return reply(false,"processo_nao_solicitado")
	if verified_bond(save,learner,master):return reply(false,"narrativo_ainda_mantem_vinculo")
	t.active=false;t.phase="suspended";t.r2.outcome=str(a.get("reason","withdrawal"))
	t.r2.pending_unlock="";t.pending_technique="";t.lesson_id="";t.method="";t.practice=0;t.lesson_goal=0
	d(save).applications.erase(k)
	return reply(true,"desligamento_confirmado",true)

static func promotion_exam(save: Dictionary,learner: String,master: String,proof: Dictionary) -> Dictionary:
	var t: Dictionary=active(save,learner,master)
	if t.is_empty() or str(t.phase)!="ready":return reply(false,"treino_ou_desbloqueio_pendente")
	var school: Dictionary=school_for(save,master)
	var new_rank: int=int(t.rank)+1
	if not school.ranks.any(func(rank_value):return rank_value==new_rank):return reply(false,"graduacao_nao_prevista")
	var conditions: Dictionary=school.promotion
	if int(t.mastery)<int(conditions.mastery_thresholds.get(str(new_rank),9999)) or int(t.completed_lessons)<int(conditions.lesson_thresholds.get(str(new_rank),9999)):return reply(false,"requisitos_de_graduacao")
	var exam_id: String="exam/"+key(learner,master).substr(0,32)+"/rank/"+str(new_rank)
	if d(save).exams.has(exam_id):return reply(false,"exame_repetido")
	if str(proof.get("exam_id",""))!=exam_id or str(proof.get("action",""))!=str(school.teaching.examination_action) or str(proof.get("marker_type",""))!=str(school.teaching.exam_marker) or not bool(proof.get("success",false)):return reply(false,"prova_marcial_invalida")
	if not unique(save,str(proof.get("event_id",""))):return reply(false,"evento_ja_usado")
	d(save).receipts[str(proof.event_id)]="promotion/"+exam_id
	d(save).exams[exam_id]={"learner_id":learner,"master_id":master,"school_id":str(school.id),"rank":new_rank,"receipt":str(proof.event_id)}
	t.r2.exam_history[str(new_rank)]=exam_id;t.rank=new_rank
	return {"ok":true,"reason":"promovido","changed":true,"rank":new_rank,"exam_id":exam_id}
