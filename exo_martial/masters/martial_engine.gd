extends RefCounted
# Pure domain logic: incoming `save` is EXO journey v4 dictionary, not a separate save.
const State=preload("res://exo_martial/progression/martial_state.gd")
const Catalog=preload("res://exo_martial/styles/martial_catalog.gd")
const Entity=preload("res://exo_core/contracts/entity_contracts.gd")
const Bonds=preload("res://narrative/society/relationship_system.gd")
const Variants=preload("res://exo_martial/techniques/variants.gd")

static func result(ok: bool,reason: String="",changed: bool=false) -> Dictionary:
	return {"ok":ok,"reason":reason,"changed":changed}

static func domain(save: Dictionary) -> Dictionary:
	return save.get("exo_martial",{})

static func npc(save: Dictionary, id: String) -> Dictionary:
	return save.get("living_world",{}).get("npcs",{}).get(id,{})

static func actor(save: Dictionary,id: String) -> bool:
	return id==Entity.player_id(save) or (id.begins_with("npc/r") and not npc(save,id).is_empty())

static func identity(save: Dictionary,id: String) -> String:
	if id.begins_with("npc/r"):return Entity.npc_id(save,id)
	return id if id==Entity.player_id(save) else ""

static func pair_key(learner_id: String,master_id: String) -> String:
	return (learner_id+"|"+master_id).sha256_text()

static func bond(save: Dictionary,learner_id: String,master_id: String) -> bool:
	var a: String=identity(save,learner_id)
	var b: String=identity(save,master_id)
	if a.is_empty() or b.is_empty() or a==b:return false
	var rel: Dictionary=save.get("narrative",{}).get("relationships",{})
	var value: Dictionary=rel.get(Bonds.pair(a,b),{})
	return str(value.get("kind",""))=="master_disciple" and str(value.get("a","")) in [a,b] and str(value.get("b","")) in [a,b] and str(value.get("a",""))!=str(value.get("b",""))

static func eligible(save: Dictionary,master_id: String) -> bool:
	var entry: Dictionary=npc(save,master_id)
	if entry.is_empty():return false
	if not bool(entry.get("active",true)):return false
	var id_hash: int=(str(save.get("world",{}).get("seed","0"))+"|"+master_id+"|MARTIAL01").sha256_text().substr(0,7).hex_to_int()
	return str(entry.get("role",""))=="master" or int(entry.get("level",1))>=15 or id_hash%100<22

static func level_for_secret(seed: String,master_id: String,level: int) -> bool:
	return level>=15 and ("SECRET|"+seed+"|"+master_id).sha256_text().substr(0,7).hex_to_int()%7==0

static func profile_data(save: Dictionary,master_id: String) -> Dictionary:
	if not eligible(save,master_id):return {}
	var record: Dictionary=npc(save,master_id)
	var seed: String=str(save.get("world",{}).get("seed","0"))
	var h: String=("EXO-MARTIAL-MASTER-1|"+seed+"|"+master_id).sha256_text()
	var school_choices: Array=Catalog.schools()
	if school_choices.is_empty():return {}
	var school: Dictionary=school_choices[h.substr(0,7).hex_to_int()%school_choices.size()]
	# WorldGenesis may bind a curriculum to an actually built and occupied school.
	# Once discovered, profiles are persisted and never rerolled.
	var site_school:String=str(record.get("martial_school_id",""))
	if not site_school.is_empty() and not str(record.get("martial_site_id","")).is_empty():
		var approved:Dictionary=Catalog.school(site_school)
		if not approved.is_empty():school=approved
	var primary: Dictionary=Catalog.style(str(school.style_id))
	var temperaments: Array=["rigoroso","benevolente","mercenario","solitario","orgulhoso"]
	var temper: String=str(temperaments[h.substr(7,7).hex_to_int()%temperaments.size()])
	var secondary: Array=[]
	var all_styles: Array=Catalog.styles()
	if h.substr(28,7).hex_to_int()%100<35:
		var next_style: Dictionary=all_styles[h.substr(35,7).hex_to_int()%all_styles.size()]
		if str(next_style.id)!=str(primary.id):secondary.append(str(next_style.id))
	var knowledge: Array=[]
	for core_skill in primary.core_techniques:
		knowledge.append("exo_martial.technique."+str(core_skill))
	if not secondary.is_empty():
		var secondary_style: Dictionary=Catalog.style(str(secondary[0]))
		knowledge.append("exo_martial.technique."+str(secondary_style.core_techniques[0]))
	var secret: String=""
	if level_for_secret(seed,master_id,int(record.get("level",1))):secret="exo_martial.technique."+str(primary.core_techniques.back())
	var level: int=clampi(int(record.get("level",1)),1,30)
	return {"npc_id":master_id,"school_id":str(school.id),"style_id":str(primary.id),"temperament":temper,"techniques":knowledge,"secondary_styles":secondary,"secret_technique_id":secret,"max_disciples":clampi(1+h.substr(14,7).hex_to_int()%7,1,24),"power":clampi(level*24+h.substr(21,7).hex_to_int()%18,1,1000),"rarity":int(primary.rarity),"generation":1}

static func discover(save: Dictionary,master_id: String) -> Dictionary:
	var d: Dictionary=domain(save)
	if d.is_empty() or npc(save,master_id).is_empty():return result(false,"npc_inexistente")
	if d.profiles.has(master_id):return {"ok":true,"reason":"existing","changed":false,"profile":d.profiles[master_id].duplicate(true)}
	if d.profiles.size()>=State.MAX_PROFILES:return result(false,"limite_de_perfis")
	var p: Dictionary=profile_data(save,master_id)
	if p.is_empty():return result(false,"npc_nao_e_mestre")
	d.profiles[master_id]=p
	return {"ok":true,"reason":"discovered","changed":true,"profile":p.duplicate(true)}

static func factions_compatible(save: Dictionary,learner_id: String,master_id: String) -> bool:
	if not learner_id.begins_with("npc/r"):return true
	var a: String=str(npc(save,learner_id).get("faction","neutral"))
	var b: String=str(npc(save,master_id).get("faction","neutral"))
	return a==b or a in ["","neutral"] or b in ["","neutral"]

static func count_students(save: Dictionary,master_id: String) -> int:
	var value: int=0
	for t in domain(save).get("training",{}).values():
		if t is Dictionary and t.get("master_id")==master_id and bool(t.get("active",false)) and bond(save,str(t.learner_id),master_id):value+=1
	return value

static func requirements(save: Dictionary,learner_id: String,master_id: String,context: Dictionary={}) -> Dictionary:
	var d: Dictionary=domain(save)
	if not actor(save,learner_id) or learner_id==master_id or not d.get("profiles",{}).has(master_id):return result(false,"identidade_ou_mestre_invalido")
	if pair_key(learner_id,master_id) in d.training and bool(d.training[pair_key(learner_id,master_id)].get("active",false)):
		return result(false,"ja_e_discipulo")
	var p: Dictionary=d.profiles[master_id]
	if count_students(save,master_id)>=int(p.max_disciples):return result(false,"limite_discípulos")
	if not factions_compatible(save,learner_id,master_id):return result(false,"faccao_incompativel")
	var threshold: int={"rigoroso":3,"benevolente":0,"mercenario":-2,"solitario":12,"orgulhoso":5}[p.temperament]
	var trust: int=int(context.get("trust",-100))
	var reputation: int=int(context.get("reputation",-100))
	if trust<threshold:return result(false,"confianca_insuficiente")
	if reputation<0 and p.temperament not in ["mercenario","solitario"]:return result(false,"reputacao_insuficiente")
	var level: int=1
	if learner_id.begins_with("npc/r"):
		level=int(npc(save,learner_id).get("level",1))
	else:
		level=int(save.get("journey_dynamic",{}).get("progress",{}).get("level",1))
	if level<int(Catalog.style(str(p.style_id)).minimum_level):return result(false,"nivel_insuficiente")
	var other_masters: int=0
	for other in d.training.values():
		if other is Dictionary and str(other.get("learner_id",""))==learner_id and bool(other.get("active",false)) and bond(save,learner_id,str(other.get("master_id",""))):other_masters+=1
	if other_masters>=2:return result(false,"numero_maximo_de_mestres")
	return result(true,"requisitos_satisfeitos")

static func apply(save: Dictionary,learner_id: String,master_id: String,context: Dictionary,receipt: String) -> Dictionary:
	var d: Dictionary=domain(save)
	if receipt.is_empty() or receipt.length()>160:return result(false,"receipt_invalido")
	var key: String=pair_key(learner_id,master_id)
	if d.get("applications",{}).has(key):return result(false,"candidatura_existente")
	if d.get("receipts",{}).has(receipt):return result(false,"receipt_ja_usado")
	if d.applications.size()>=State.MAX_APPLICATIONS:return result(false,"limite_de_candidaturas")
	var req: Dictionary=requirements(save,learner_id,master_id,context)
	if not req.ok:return req
	# No relationship is created here; narrative owner must record master_disciple.
	d.applications[key]={"learner_id":learner_id,"master_id":master_id,"status":"pending","receipt":receipt}
	d.receipts[receipt]="application"
	return result(true,"aguardando_confirmacao_narrativa",true)

static func confirm_enrollment(save: Dictionary,learner_id: String,master_id: String) -> Dictionary:
	var d: Dictionary=domain(save)
	var key: String=pair_key(learner_id,master_id)
	if d.is_empty() or not d.applications.has(key):return result(false,"candidatura_ausente")
	if not bond(save,learner_id,master_id):return result(false,"vinculo_narrativo_ausente")
	if not bool(npc(save,master_id).get("active",false)):return result(false,"mestre_indisponivel")
	if not factions_compatible(save,learner_id,master_id):return result(false,"faccao_incompativel")
	if d.training.has(key) and bool(d.training[key].get("active",false)):return result(true,"ja_confirmado")
	if not d.profiles.has(master_id) or count_students(save,master_id)>=int(d.profiles[master_id].max_disciples):return result(false,"sem_vaga")
	if d.training.size()>=State.MAX_TRAINING and not d.training.has(key):return result(false,"limite_de_treinamentos")
	d.training[key]={"learner_id":learner_id,"master_id":master_id,"rank":3,"mastery":0,"practice":0,"lesson_goal":0,"completed_lessons":0,"phase":"ready","lesson_id":"","pending_technique":"","method":"","learned":{},"active":true}
	d.applications.erase(key)
	return result(true,"discipulo_externo",true)

static func relationship_status(save: Dictionary,learner_id: String,master_id: String) -> Dictionary:
	var key: String=pair_key(learner_id,master_id)
	var t: Dictionary=domain(save).get("training",{}).get(key,{})
	if t.is_empty():
		var applications: Dictionary=domain(save).get("applications",{})
		var status_text: String="candidato" if applications.has(key) else "conhecido" if domain(save).get("profiles",{}).has(master_id) else "desconhecido"
		return {"rank":2 if status_text=="candidato" else 1 if status_text=="conhecido" else 0,"status":status_text,"bond":bond(save,learner_id,master_id)}
	var state: String="suspenso" if not bond(save,learner_id,master_id) else "mestre_indisponivel" if not bool(npc(save,master_id).get("active",false)) else "conflito_de_faccao" if not factions_compatible(save,learner_id,master_id) else ["","conhecido","candidato","externo","interno","pessoal","herdeiro"][int(t.rank)]
	return {"rank":int(t.rank),"status":state,"bond":bond(save,learner_id,master_id),"mastery":int(t.mastery),"techniques":t.learned.duplicate(true),"phase":t.phase}

static func active_training(save: Dictionary,learner_id: String,master_id: String) -> Dictionary:
	var t: Dictionary=domain(save).get("training",{}).get(pair_key(learner_id,master_id),{})
	if t.is_empty() or not bool(t.get("active",false)) or not bond(save,learner_id,master_id):return {}
	if not bool(npc(save,master_id).get("active",false)) or not factions_compatible(save,learner_id,master_id):return {}
	return t

static func compatible_equipment(save: Dictionary,learner_id: String,master_profile: Dictionary) -> bool:
	# NPC loadouts are authoritative in Living World / arsenal, so only validate known player gear.
	if learner_id.begins_with("npc/r"):return true
	var allowed: Array=Catalog.style(str(master_profile.style_id)).get("weapon_families",[])
	if allowed.is_empty():return true
	var pose: String=Catalog.weapon_pose(str(save.get("equipped","")))
	var mapped: Dictionary={"sword":"blade","katana":"draw","spear":"thrust","unarmed":"fists","dagger":"reverse"}
	for fam in allowed:
		if pose==str(fam) or pose==str(mapped.get(str(fam),"_undefined")):return true
	return false

static func start_lesson(save: Dictionary,learner_id: String,master_id: String,technique_id: String,method_id: String) -> Dictionary:
	var t: Dictionary=active_training(save,learner_id,master_id)
	if t.is_empty():return result(false,"vinculo_inativo")
	if t.phase!="ready":return result(false,"aula_em_andamento")
	var d: Dictionary=domain(save)
	var teacher: Dictionary=d.profiles[master_id]
	var tech: Dictionary=Catalog.technique(technique_id)
	var method: Dictionary=Catalog.method(method_id)
	if tech.is_empty() or method.is_empty():return result(false,"tecnica_ou_metodo_invalido")
	var teaches_style: bool=str(teacher.style_id) in tech.style_ids
	for secondary_style in teacher.get("secondary_styles",[]):
		if str(secondary_style) in tech.style_ids:teaches_style=true
	if technique_id not in teacher.techniques or not teaches_style:return result(false,"mestre_nao_ensina")
	if technique_id==str(teacher.get("secret_technique_id","")) and int(t.rank)<6:return result(false,"ensinamento_secreto")
	if not compatible_equipment(save,learner_id,teacher):return result(false,"arma_incompativel")
	if tech.category not in method.categories and "*" not in method.categories:return result(false,"metodo_incompativel")
	if int(t.rank)<int(tech.requires.rank):return result(false,"rank_insuficiente")
	t.practice=0;t.lesson_goal=int(method.required_actions);t.pending_technique=technique_id;t.method=method_id
	t.lesson_id="lesson/"+pair_key(learner_id,master_id).substr(0,20)+"/"+str(t.completed_lessons+1)+"/"+technique_id
	t.phase="instructed"
	return {"ok":true,"reason":"aula_iniciada","changed":true,"lesson_id":t.lesson_id,"goal":t.lesson_goal}

static func record_verified_practice(save: Dictionary,learner_id: String,master_id: String,lesson_id: String,evidence_receipt: String) -> Dictionary:
	var t: Dictionary=active_training(save,learner_id,master_id)
	if t.is_empty() or t.phase!="instructed" or t.lesson_id!=lesson_id:return result(false,"aula_invalida")
	if evidence_receipt.is_empty() or evidence_receipt.length()>160:return result(false,"prova_invalida")
	var d: Dictionary=domain(save)
	if d.receipts.has(evidence_receipt):return result(false,"prova_duplicada")
	if d.receipts.size()>=State.MAX_RECEIPTS:return result(false,"limite_de_recibos")
	d.receipts[evidence_receipt]="practice/"+str(t.lesson_id)
	t.practice=mini(int(t.lesson_goal),int(t.practice)+1)
	var method: Dictionary=Catalog.method(str(t.method))
	t.mastery=mini(1000,int(t.mastery)+int(method.xp))
	if int(t.practice)>=int(t.lesson_goal):t.phase="practiced"
	return {"ok":true,"reason":"pratica_registrada","changed":true,"practice":t.practice,"mastery":t.mastery}

static func demonstrate(save: Dictionary,learner_id: String,master_id: String,trial_receipt: String) -> Dictionary:
	var t: Dictionary=active_training(save,learner_id,master_id)
	if t.is_empty() or t.phase!="practiced":return result(false,"sem_pratica_completa")
	var d: Dictionary=domain(save)
	if trial_receipt.is_empty() or trial_receipt.length()>160 or d.receipts.has(trial_receipt):return result(false,"prova_repetida")
	if d.receipts.size()>=State.MAX_RECEIPTS:return result(false,"limite_de_recibos")
	d.receipts[trial_receipt]="trial/"+str(t.lesson_id)
	t.phase="demonstrated"
	return result(true,"prova_concluida",true)

static func finish_lesson(save: Dictionary,learner_id: String,master_id: String) -> Dictionary:
	var t: Dictionary=active_training(save,learner_id,master_id)
	if t.is_empty() or t.phase!="demonstrated":return result(false,"prova_pendente")
	var tech: Dictionary=Catalog.technique(str(t.pending_technique))
	if tech.is_empty():return result(false,"tecnica_invalida")
	if int(t.mastery)<int(tech.requires.mastery):
		# The same lesson can be reinforced without granting duplicated rewards.
		t.phase="instructed";t.practice=0
		return result(true,"reforco_necessario",true)
	var d: Dictionary=domain(save)
	var reward_receipt: String="martial_reward/"+str(t.lesson_id)
	if d.receipts.has(reward_receipt):return result(false,"recompensa_duplicada")
	if d.receipts.size()>=State.MAX_RECEIPTS:return result(false,"limite_de_recibos")
	d.receipts[reward_receipt]="learned/"+str(tech.id)
	var grade: int=mini(int(tech.grade_max),1+int(int(t.mastery)/250))
	t.learned[tech.id]=maxi(int(t.learned.get(tech.id,0)),grade)
	t.completed_lessons=int(t.completed_lessons)+1
	t.phase="ready";t.practice=0;t.lesson_goal=0;t.pending_technique="";t.method="";t.lesson_id=""
	return {"ok":true,"reason":"tecnica_aprendida","changed":true,"technique_id":tech.id,"core_skill_id":tech.core_skill_id,"grade":grade,"variant":Variants.descriptor(str(save.get("world",{}).get("seed","0")),str(d.profiles[master_id].school_id),str(tech.id))}

static func promote(save: Dictionary,learner_id: String,master_id: String) -> Dictionary:
	var t: Dictionary=active_training(save,learner_id,master_id)
	if t.is_empty() or t.phase!="ready":return result(false,"treinamento_pendente")
	var teacher: Dictionary=domain(save).profiles[master_id]
	var school: Dictionary=Catalog.school(str(teacher.school_id))
	var new_rank: int=int(t.rank)+1
	if new_rank not in school.ranks:return result(false,"graduacao_nao_prevista")
	if int(t.completed_lessons)<(new_rank-3)*2 or int(t.mastery)<(new_rank-3)*80:return result(false,"requisitos_de_graduacao")
	t.rank=new_rank
	return result(true,"promocao",true)

static func request_separation(save: Dictionary,learner_id: String,master_id: String,receipt: String) -> Dictionary:
	var t: Dictionary=active_training(save,learner_id,master_id)
	if t.is_empty():return result(false,"sem_relacao_ativa")
	var d: Dictionary=domain(save)
	var key: String=pair_key(learner_id,master_id)
	if d.applications.has(key) or d.receipts.has(receipt) or receipt.is_empty() or receipt.length()>160:return result(false,"pedido_duplicado_ou_invalido")
	if d.receipts.size()>=State.MAX_RECEIPTS:return result(false,"limite_de_recibos")
	d.applications[key]={"learner_id":learner_id,"master_id":master_id,"status":"withdrawal_requested","receipt":receipt}
	d.receipts[receipt]="withdrawal"
	return result(true,"aguardando_rescisao_narrativa",true)

static func finalize_separation(save: Dictionary,learner_id: String,master_id: String) -> Dictionary:
	var d: Dictionary=domain(save)
	var key: String=pair_key(learner_id,master_id)
	if not d.training.has(key):return result(false,"nao_matriculado")
	if bond(save,learner_id,master_id):return result(false,"vinculo_narrativo_ainda_ativo")
	if not bool(d.training[key].get("active",false)):return result(true,"ja_rescindido")
	d.training[key].active=false;d.training[key].phase="suspended"
	d.applications.erase(key)
	return result(true,"relacao_rescindida",true)

static func simulate_npc_day(save: Dictionary,day: int,limit: int=128) -> Dictionary:
	var d: Dictionary=domain(save)
	if day<=int(d.get("npc_sim_day",-1)) or limit<1 or limit>512:return result(false,"dia_repetido_ou_limite_invalido")
	var keys: Array=d.training.keys();keys.sort()
	if keys.is_empty():
		d.npc_sim_day=day
		return {"ok":true,"reason":"sem_discipulos","changed":true,"npc_progressed":0}
	var cursor: int=int(d.get("npc_sim_cursor",0))%keys.size()
	var visited: int=0
	var count: int=0
	while visited<keys.size() and count<limit:
		var key: String=str(keys[(cursor+visited)%keys.size()])
		visited+=1
		var t: Dictionary=d.training[key]
		if not str(t.learner_id).begins_with("npc/r") or active_training(save,str(t.learner_id),str(t.master_id)).is_empty():continue
		var receipt: String="npc_training/day/%d/%s"%[day,key.substr(0,40)]
		if d.receipts.has(receipt):continue
		if d.receipts.size()>=State.MAX_RECEIPTS:break
		d.receipts[receipt]="npc_sim"
		t.mastery=mini(1000,int(t.mastery)+7)
		count+=1
	d.npc_sim_cursor=(cursor+visited)%keys.size()
	d.npc_sim_day=day
	return {"ok":true,"reason":"dia_simulado","changed":true,"npc_progressed":count}
