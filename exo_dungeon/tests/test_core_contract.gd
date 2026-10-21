extends RefCounted
const Module=preload("res://exo_dungeon/module/entrypoint.gd")
const State=preload("res://exo_dungeon/persistence/dungeon_state.gd")
## Mocks estritos do contrato, não são clones do core de produção.
class DomainStore extends RefCounted:
 var domain_owners: Dictionary={}
 func register_domain(key: String,owner: String,validator: Callable) -> bool:
  if domain_owners.has(key) or not validator.is_valid():return false
  domain_owners[key]={"owner":owner,"validator":validator}
  return true
class SaveMock extends RefCounted:
 var data: Dictionary={}
 var save_coordinator:=DomainStore.new()
class WorldMock extends RefCounted:
 var journey:=SaveMock.new()
class ServiceMock extends RefCounted:
 var entries: Dictionary={}
 func register_service(id: String,owner: String,obj: Object,methods: Array) -> bool:
  if entries.has(id):return false
  for method in methods:
   if not obj.has_method(method):return false
  entries[id]={"owner":owner,"target":obj,"methods":methods};return true
 func invoke(id: String,method: String,args: Array=[]) -> Variant:
  if not entries.has(id) or method not in entries[id].methods:return null
  return entries[id].target.callv(method,args)
class ReceiptVerifierMock extends RefCounted:
 func verified(_dungeon_id: String,_reward_id: String,receipt: String) -> bool:
  return receipt=="receipt_1"
class CoreMock extends RefCounted:
 var world:=WorldMock.new()
 var services:=ServiceMock.new()
static func run() -> Dictionary:
 var failures: Array=[]
 var core:=CoreMock.new();var module=Module.new()
 if not module.initialize(core):failures.append("module_init_failed")
 else:
  var q: Dictionary={"world_id":"QA","world_seed":102,"region_id":14,"location_id":"ruin_1","family":"ruins","floors":2,"rooms_per_floor":10,"difficulty":3}
  var response: Variant=core.services.invoke("dungeons","visit",[q])
  if not response is Dictionary or not bool(response.get("ok",false)):failures.append("service_generation_failed")
  else:
   var id: String=str(response.id)
   if not core.services.invoke("dungeons","mark_discovered",[id,str(response.entry)]):failures.append("discovery_failed")
   if core.services.invoke("dungeons","confirm_reward_receipt",[id,"loot_1","receipt_1"]):failures.append("unverified_receipt_accepted")
   var verifier:=ReceiptVerifierMock.new()
   if not core.services.invoke("dungeons","bind_reward_verifier",[Callable(verifier,"verified")]):failures.append("verifier_install_failed")
   if not core.services.invoke("dungeons","confirm_reward_receipt",[id,"loot_1","receipt_1"]):failures.append("verified_receipt_refused")
   if core.services.invoke("dungeons","confirm_reward_receipt",[id,"loot_1","receipt_2"]):failures.append("double_receipt")
   if not State.valid(core.world.journey.data.dungeon_genesis):failures.append("invalid_domain_state")
   if core.world.journey.data.dungeon_genesis.instances[id].visits!=0:failures.append("premature_visit_count")
   if int(response.generator_version)!=4:failures.append("default_generator_not_v4")
   var v2_req: Dictionary=q.duplicate(true)
   v2_req.location_id="legacy_v2_sample"
   v2_req.generator_version=2
   var old_plan: Dictionary=module.visit(v2_req)
   if not bool(old_plan.get("ok",false)) or int(old_plan.generator_version)!=2:failures.append("old_version_not_created")
   else:
    var retry: Dictionary=v2_req.duplicate(true)
    retry.erase("generator_version")
    var pinned: Dictionary=module.visit(retry)
    if not bool(pinned.get("ok",false)) or pinned.digest!=old_plan.digest:failures.append("old_version_not_pinned")
 module.shutdown()
 return {"ok":failures.is_empty(),"errors":failures}
