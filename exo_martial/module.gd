extends RefCounted
# R2 EXO Core service. No Core/Narrative/Inventory patch is applied here.
const State=preload("res://exo_martial/r2/state_r2.gd")
const MartialEngine=preload("res://exo_martial/r2/engine_r2.gd")
const Catalog=preload("res://exo_martial/styles/martial_catalog.gd")
const Legacy=preload("res://exo_martial/masters/martial_engine.gd")
const LivingPeople=preload("res://living_world/people.gd")
const Clock=preload("res://ai_core/world_clock.gd")
var core: RefCounted
var proof_validator: Callable
var admission_validator: Callable

func initialize(context: RefCounted) -> bool:
	core=context
	if not Catalog.valid_catalogs().get("ok",false):return false
	if not core.services.has_service("npcs") or not core.services.has_service("narrative"):return false
	var journey: RefCounted=core.world.journey
	var seed: String=str(journey.data.get("world",{}).get("seed","0"))
	if not journey.data.has("exo_martial"):
		journey.data.exo_martial=State.fresh(seed)
	else:
		var upgraded: Dictionary=State.upgrade(journey.data.exo_martial)
		if upgraded.is_empty():return false
		journey.data.exo_martial=upgraded
	if str(journey.data.exo_martial.seed)!=seed or not State.valid(journey.data.exo_martial):return false
	if not journey.save_coordinator.register_domain("exo_martial","exo_martial",Callable(State,"valid")):return false
	return core.services.register_service("martial","exo_martial",self,["discover","master_profile","status","catalogue","request_enrollment","appeal_enrollment","refuse_enrollment","confirm_enrollment","start_lesson","lesson_preview","record_action","finish_lesson","confirm_core_unlock","promote","request_separation","finalize_separation"],"1.2.0")

# Called by the creator before the first campaign commit; never migrates learned progress.
func prepare_new_campaign_seed(seed:String) -> bool:
	if core==null or core.world.flow.phase!="creator":return false
	var domain:Dictionary=data().get("exo_martial",{})
	for key in ["profiles","applications","training","receipts","exams"]:
		if not domain.get(key,{}).is_empty():return false
	data()["exo_martial"]=State.fresh(seed)
	return true

func shutdown() -> void:
	core=null;proof_validator=Callable();admission_validator=Callable()
func data() -> Dictionary:return core.world.journey.data
func _transaction(method: Callable,args: Array=[]) -> Dictionary:
	if not method.is_valid():return {"ok":false,"reason":"operacao_invalida"}
	var journey: RefCounted=core.world.journey
	var snapshot: Dictionary=journey.data.duplicate(true)
	var params: Array=[journey.data]
	params.append_array(args)
	var raw: Variant=method.callv(params)
	if not raw is Dictionary:
		journey.data=snapshot
		return {"ok":false,"reason":"retorno_invalido"}
	var out: Dictionary=raw
	if not bool(out.get("ok",false)):
		journey.data=snapshot
		return out
	if not bool(out.get("changed",false)):return out
	# R10: use the host save path so the same commit includes authoritative Qi/stamina.
	# Direct journey.write bypassed the Convergence energy snapshot.
	if not State.valid(journey.data.exo_martial) or not core.world.save_progress():
		journey.data=snapshot
		return {"ok":false,"reason":"save_v4_ou_schema_falhou"}
	return out

func discover(master_id: String) -> Dictionary:return _transaction(Callable(Legacy,"discover"),[master_id])
func master_profile(master_id: String) -> Dictionary:
	var p: Dictionary=data().get("exo_martial",{}).get("profiles",{}).get(master_id,{}).duplicate(true)
	if not p.is_empty():p.erase("secret_technique_id")
	return p
func status(learner: String,master: String) -> Dictionary:return MartialEngine.relation(data(),learner,master)
func catalogue() -> Dictionary:return {"styles":Catalog.styles().duplicate(true),"schools":Catalog.schools().duplicate(true),"techniques":Catalog.techniques().duplicate(true),"methods":Catalog.methods().duplicate(true)}

func configure_host_integrations(proof: Callable,admission: Callable) -> void:
	# Trusted integrator ONLY. Never expose as a service endpoint.
	proof_validator=proof
	admission_validator=admission
func _verify(kind: String,payload: Dictionary) -> bool:
	if not proof_validator.is_valid():return false
	return bool(proof_validator.call(kind,payload.duplicate(true)))
func _admission(learner: String,master: String) -> Dictionary:
	if not admission_validator.is_valid():return {}
	var attestation: Variant=admission_validator.call(learner,master)
	return attestation if attestation is Dictionary else {}

func request_enrollment(learner: String,master: String,receipt: String) -> Dictionary:
	var context: Variant=core.services.invoke("narrative","social_context",[master])
	if not context is Dictionary:return {"ok":false,"reason":"narrativo_indisponivel"}
	var values: Dictionary=context.duplicate()
	var rec: Variant=core.services.invoke("npcs","npc",[master])
	if not rec is Dictionary or rec.is_empty():return {"ok":false,"reason":"npc_indisponivel"}
	var faction: String=str(rec.get("faction",""))
	values.reputation=int(data().get("living_world",{}).get("reputation",{}).get(faction,0))
	var admission: Dictionary=_admission(learner,master)
	values.proofs_completed=int(admission.get("proofs_completed",0))
	values.admission_trial_verified=bool(admission.get("trial_verified",false))
	return _transaction(Callable(MartialEngine,"apply"),[learner,master,values,receipt])
func appeal_enrollment(learner: String,master: String,receipt: String) -> Dictionary:
	var c: Variant=core.services.invoke("narrative","social_context",[master])
	if not c is Dictionary:return {"ok":false,"reason":"narrativo_indisponivel"}
	var values: Dictionary=c.duplicate()
	var npc: Variant=core.services.invoke("npcs","npc",[master])
	if not npc is Dictionary or npc.is_empty():return {"ok":false,"reason":"npc_indisponivel"}
	values.reputation=int(data().get("living_world",{}).get("reputation",{}).get(str(npc.get("faction","")),0))
	var at: Dictionary=_admission(learner,master)
	values.proofs_completed=int(at.get("proofs_completed",0))
	values.admission_trial_verified=bool(at.get("trial_verified",false))
	return _transaction(Callable(MartialEngine,"appeal"),[learner,master,values,receipt])
func refuse_enrollment(learner: String,master: String,receipt: String,reason: String) -> Dictionary:
	if not _verify("master_decision",{"learner_id":learner,"master_id":master,"receipt":receipt,"reason":reason}):return {"ok":false,"reason":"autoridade_do_mestre_ausente"}
	return _transaction(Callable(MartialEngine,"refuse"),[learner,master,receipt,reason])
func confirm_enrollment(_learner: String,_master: String) -> Dictionary:
	# R8: Core.confirm_martial_enrollment_atomic owns the joint narrative/martial commit.
	return {"ok":false,"reason":"use_core_atomic_martial_enrollment"}
func master_available(master: String) -> bool:
	var rec: Variant=core.services.invoke("npcs","npc",[master])
	if not rec is Dictionary or not bool(rec.get("active",false)):return false
	var hour: int=Clock.hour(core.world.extension())
	return LivingPeople.activity(rec,hour) in ["treino","meditacao","convivio"]
func lesson_preview(learner: String,master: String,technique: String,method: String,marker: String="") -> Dictionary:
	return MartialEngine.lesson_plan(data(),learner,master,technique,method,marker)
func start_lesson(learner: String,master: String,technique: String,method: String,marker: String="") -> Dictionary:
	if not master_available(master):return {"ok":false,"reason":"fora_da_rotina_do_mestre"}
	if marker.begins_with("lab/"):return {"ok":false,"reason":"laboratorio_nao_permitido_em_producao"}
	if marker.is_empty() or not _verify("site",{"learner_id":learner,"master_id":master,"marker_id":marker}):return {"ok":false,"reason":"ponto_de_ensino_nao_verificado"}
	return _transaction(Callable(MartialEngine,"begin_lesson"),[learner,master,technique,method,marker])
func record_action(learner: String,master: String,proof: Dictionary) -> Dictionary:
	# The validator checks actual animation/combat/meditation event IDs, real resource
	# consumption (runtime Qi/mana + stamina), spatial marker and server/trusted owner.
	if str(proof.get("mode",""))=="lab":return {"ok":false,"reason":"prova_lab_nao_autorizada"}
	if not _verify("action",proof):return {"ok":false,"reason":"acao_nao_verificada"}
	return _transaction(Callable(MartialEngine,"record_action"),[learner,master,proof])
func finish_lesson(learner: String,master: String) -> Dictionary:return _transaction(Callable(MartialEngine,"finish_lesson"),[learner,master])
func confirm_core_unlock(learner: String,master: String,technique: String) -> Dictionary:
	# Read-only confirmation of Core owned known/learned. Never append from here.
	return _transaction(Callable(MartialEngine,"confirm_core_unlock"),[learner,master,technique])
func promote(learner: String,master: String,proof: Dictionary) -> Dictionary:
	if not _verify("promotion",proof):return {"ok":false,"reason":"exame_nao_verificado"}
	return _transaction(Callable(MartialEngine,"promotion_exam"),[learner,master,proof])
func request_separation(learner: String,master: String,reason: String,receipt: String) -> Dictionary:
	if reason=="expulsion" and not _verify("expulsion",{"learner_id":learner,"master_id":master,"receipt":receipt}):return {"ok":false,"reason":"expulsao_nao_autorizada"}
	return _transaction(Callable(MartialEngine,"request_separation"),[learner,master,reason,receipt])
func finalize_separation(learner: String,master: String) -> Dictionary:return _transaction(Callable(MartialEngine,"finalize_separation"),[learner,master])
