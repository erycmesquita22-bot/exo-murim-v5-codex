extends RefCounted
# Owns only the additive journey_dynamic extension. The original saved attributes,
# regional XP bank, loot, living-world wallet and NPC identities remain authoritative.
const Generator=preload("res://journey_dynamic/quest_generator.gd")
const JourneyV4=preload("res://journey_dynamic/v4/extension.gd")
const EcologyRewards=preload("res://regional_ecology/rewards.gd")
const LivingState=preload("res://living_world/state.gd")
const Factions=preload("res://living_world/factions.gd")
const Narrative=preload("res://narrative/adapters/journey_bridge.gd")
const MAX_ACTIVE=5
var world: Node3D
func _init(owner: Node3D) -> void:world=owner
static func fresh() -> Dictionary:
	return {"schema":1,"quests":{},"rewarded":{},"history":[],"discovered":{},"local_reputation":{},"tracked":"","progress":{"xp":0,"level":1,"unspent":0,"combat_imported":0},"v4":JourneyV4.fresh()}
static func valid(state: Variant) -> bool:
	if not state is Dictionary or int(state.get("schema",0))!=1:return false
	if not state.get("quests") is Dictionary or not state.get("rewarded") is Dictionary or not state.get("history") is Array:return false
	if state.quests.size()>MAX_ACTIVE or state.rewarded.size()>2000 or state.history.size()>256:return false
	if state.has("v4") and not JourneyV4.valid_storage(state.v4):return false
	if not state.get("discovered") is Dictionary or state.discovered.size()>88:return false
	if not state.get("local_reputation") is Dictionary or state.local_reputation.size()>88:return false
	for value in state.local_reputation.values():
		if not (value is int or value is float) or int(value)!=value or absi(int(value))>100:return false
	if not state.get("tracked") is String or str(state.tracked).length()>128:return false
	var p: Variant=state.get("progress")
	if not p is Dictionary:return false
	for key in ["xp","level","unspent","combat_imported"]:
		if not (p.get(key) is float or p.get(key) is int) or not is_finite(float(p[key])):return false
	if p.xp<0 or p.xp>2000000000 or p.combat_imported<0 or p.combat_imported>p.xp:return false
	if p.level<1 or p.level>50 or p.unspent<0 or p.unspent>49:return false
	for key in state.quests:
		var q: Variant=state.quests[key]
		if not q is Dictionary or not str(key).begins_with("j01/") or str(key).length()>128:return false
		if str(q.get("state","")) not in ["ACCEPTED","ACTIVE","COMPLETED"]:return false
		if not q.get("seen") is Array or q.seen.size()>16:return false
		if int(q.get("goal",0))<1 or int(q.get("goal",0))>16 or int(q.get("progress",-1))<0 or int(q.progress)>int(q.goal):return false
	return true
func state() -> Dictionary:
	if not world.journey.data.has("journey_dynamic"):
		world.journey.data.journey_dynamic=fresh()
	return world.journey.data.journey_dynamic
func history(kind: String,title: String) -> void:
	var log: Array=state().history
	log.append({"kind":kind,"title":title,"region":world.current_region,"clock":float(world.extension().get("clock",0.0))})
	if log.size()>256:log.pop_front()
func sync_combat() -> int:
	var progress: Dictionary=state().progress
	var eco: Dictionary=world.extension().get("ecology",{})
	var earned: int=int(eco.get("xp_total",0))
	var delta: int=maxi(0,earned-int(progress.combat_imported))
	if delta>0:
		progress.combat_imported=earned
		grant_xp(delta)
	return delta
func grant_xp(amount: int) -> void:
	if amount<=0:return
	var progress: Dictionary=state().progress
	progress.xp=mini(2000000000,int(progress.xp)+amount)
	var previous: int=int(progress.level)
	progress.level=EcologyRewards.rank(int(progress.xp))
	if int(progress.level)>previous:
		progress.unspent=mini(49,int(progress.unspent)+int(progress.level)-previous)
		history("level","Nível %d alcançado"%int(progress.level))
func allocate(attribute_name: String) -> bool:
	if attribute_name not in world.journey.ATTRIBUTES or not world.can_configure():return false
	var p: Dictionary=state().progress
	if int(p.unspent)<1:return false
	var prev: Dictionary=world.journey.data.duplicate(true)
	# The first six founding attributes remain unchanged; additional level points
	# can be spent via the same authoritative attributes dictionary and stat API.
	if int(world.journey.data.attributes[attribute_name])>=30:return false
	world.journey.data.attributes[attribute_name]=int(world.journey.data.attributes[attribute_name])+1
	p.unspent=int(p.unspent)-1
	if not world.save_progress():world.journey.data=prev;return false
	world.apply_boon();return true
func options(npc: Dictionary) -> Array:
	var offers:Array=Generator.offers(world.atlas,world.current_region,npc,roster(),world.journey.data)
	return world.activation_v4.order_quest_offers(npc,offers) if world.get("activation_v4")!=null else offers
func roster() -> Array:
	var people: Array=[]
	for resident in world.residents:people.append(resident.identity)
	return people
func nearby_giver(q: Dictionary) -> bool:
	if world.current_region!=int(q.origin):return false
	for actor in world.residents:
		if actor.identity.id==q.giver and actor.rig.visible and actor.position.distance_to(world.player.position)<3.3:return true
	return false
func accept(offer: Dictionary) -> bool:
	if world.flow.lab_mode or world.flow.phase!="adventure" or world.changing_region:return false
	var st: Dictionary=state()
	if st.quests.size()>=MAX_ACTIVE or st.quests.has(offer.id) or st.rewarded.has(offer.id):return false
	if not nearby_giver(offer):return false
	var real: Dictionary={}
	for resident in world.residents:
		if resident.identity.id==offer.giver:
			for candidate in options(resident.identity):
				if str(candidate.id)==str(offer.id):real=candidate;break
	if real.is_empty() or real!=offer:return false
	var previous: Dictionary=world.journey.data.duplicate(true)
	var q: Dictionary=real.duplicate(true);q.state="ACCEPTED";q.state="ACTIVE"
	st.quests[q.id]=q
	if str(st.tracked).is_empty():st.tracked=q.id
	if not world.save_progress():world.journey.data=previous;return false
	world.message("Contrato aceito • "+str(q.title));return true
func emit(kind: String,target: String,region: int,receipt: String,amount: int=1) -> int:
	if receipt.is_empty() or amount<=0:return 0
	var advanced:=0
	for id in state().quests.keys():
		var q: Dictionary=state().quests[id]
		if q.state!="ACTIVE":continue
		var type_id: String=str(q.type)
		var qualifying:=false
		if kind=="kill" and type_id in ["defeat","clear"]:qualifying=(q.region==region and q.target==target and receipt.ends_with("/g%04d"%int(q.get("generation",0))))
		elif kind=="visit" and type_id=="visit":qualifying=(q.region==region)
		elif kind=="investigate" and type_id=="investigate":qualifying=(q.region==region)
		elif kind=="collect" and type_id=="collect":qualifying=(q.region==region and target=="iron")
		elif kind=="talk" and type_id=="talk":qualifying=(q.origin==region and q.target==target)
		if not qualifying or receipt in q.seen:continue
		q.seen.append(receipt)
		var before: int=int(q.progress)
		q.progress=mini(int(q.goal),before+amount)
		advanced+=int(q.progress)-before
		if int(q.progress)>=int(q.goal):
			q.state="COMPLETED"
			history("quest","Objetivos cumpridos: "+str(q.title))
	return advanced
func on_enter(region: int) -> void:
	var st: Dictionary=state()
	if not st.discovered.has(str(region)):
		st.discovered[str(region)]=true
		grant_xp(5)
		history("visit","Região %02d descoberta"%region)
	emit("visit","region/%d"%region,region,"arrival/%d"%region)
func on_near_ruin() -> void:
	if world.current_region<0 or world.active_region==null:return
	for id in state().quests.keys():
		var q: Dictionary=state().quests[id]
		if q.type!="investigate" or q.state!="ACTIVE" or int(q.region)!=world.current_region:continue
		if q.location.size()!=3:continue
		var point:=Vector3(float(q.location[0]),float(q.location[1]),float(q.location[2]))
		if world.player.position.distance_to(point)<7.0:
			if emit("investigate",str(q.target),world.current_region,"investigated/"+str(q.id))>0:
				world.save_progress();world.message("Vestígios investigados • retorne ao contratante")
func on_kill(actor: Node3D) -> void:
	var site: String=str(actor.get_meta("ecology_territory",""))
	if site.is_empty():return
	if emit("kill",site,world.current_region,str(actor.uid))>0:world.message("Objetivo de combate atualizado")
	var ecology: Dictionary=world.extension().get("ecology",{})
	var record: Dictionary=ecology.get("regions",{}).get(str(world.current_region),{}).get(site,{})
	if int(record.get("generation",0))>0 and str(actor.uid).ends_with("/g%04d"%(int(record.generation)-1)):
		history("clear","Território pacificado na região %02d"%world.current_region)
func on_collect(source: String,items: Array) -> void:
	var qty:=0
	for item in items:
		if item.get("kind")=="material" and item.get("ref")=="iron":qty+=int(item.get("qty",0))
	if qty>0:
		emit("collect","iron",world.current_region,"collected/"+source,qty)
func on_talk(npc_id: String) -> void:
	emit("talk",npc_id,world.current_region,"talk/"+npc_id)
func deliver(id: String) -> bool:
	var st: Dictionary=state()
	if not st.quests.has(id):return false
	var q: Dictionary=st.quests[id]
	if q.type!="deliver" or q.state!="ACTIVE" or not nearby_giver(q):return false
	var remaining: int=int(q.goal)
	var previous: Dictionary=world.journey.data.duplicate(true)
	for item in world.journey.data.items:
		if item.kind!="material" or item.ref!="iron":continue
		var removed: int=mini(int(item.qty),remaining)
		item.qty-=removed;remaining-=removed
		if item.qty<=0:world.journey.data.items.erase(item)
		if remaining<=0:break
	if remaining>0:world.journey.data=previous;return false
	q.progress=q.goal;q.state="COMPLETED";history("quest","Materiais entregues: "+str(q.title))
	if not world.save_progress():world.journey.data=previous;return false
	return true
func claim(id: String) -> bool:
	var st: Dictionary=state()
	if not st.quests.has(id) or st.rewarded.has(id):return false
	var q: Dictionary=st.quests[id]
	if q.state!="COMPLETED" or not nearby_giver(q):return false
	var previous: Dictionary=world.journey.data.duplicate(true)
	var reward: Dictionary=q.reward
	var balance: Dictionary=LivingState.ensure(world.journey.data).balances
	if int(balance.bronze)+int(reward.bronze)>1000000000:return false
	if int(reward.iron)>0 and world.inventory.add("material","iron",int(reward.iron)).is_empty():
		world.journey.data=previous;return false
	balance.bronze=int(balance.bronze)+int(reward.bronze)
	Factions.adjust(world.journey.data.living_world,"comunidade",int(reward.reputation))
	var place_key: String=str(q.origin)
	st.local_reputation[place_key]=clampi(int(st.local_reputation.get(place_key,0))+int(reward.reputation),-100,100)
	grant_xp(int(reward.xp))
	q.state="REWARDED"
	st.rewarded[id]={"type":q.type,"region":q.region,"title":q.title}
	st.quests.erase(id)
	if st.tracked==id:st.tracked=str(st.quests.keys()[0]) if not st.quests.is_empty() else ""
	history("quest","Contrato concluído: "+str(q.title))
	if world.get("exo_core")!=null:
		var result: Dictionary=world.exo_core.publish("quest_completed","quest/"+id,{"npc_id":str(q.giver),"quest_id":id,"quest_type":str(q.type)},int(q.origin))
		if not result.ok:world.journey.data=previous;return false
	if not world.save_progress():world.journey.data=previous;return false
	world.message("Contrato concluído • +%d XP • +%d bronze"%[reward.xp,reward.bronze]);return true
func cancel(id: String) -> bool:
	var st: Dictionary=state()
	if not st.quests.has(id):return false
	var before: Dictionary=world.journey.data.duplicate(true)
	var title: String=str(st.quests[id].title)
	st.quests.erase(id)
	if st.tracked==id:st.tracked=str(st.quests.keys()[0]) if not st.quests.is_empty() else ""
	history("cancel","Contrato abandonado: "+title)
	if not world.save_progress():world.journey.data=before;return false
	return true

func track(id: String) -> bool:
	if id!="" and not state().quests.has(id):return false
	var before: String=str(state().tracked)
	state().tracked=id
	if not world.save_progress():state().tracked=before;return false
	return true
func objective() -> String:
	var st: Dictionary=state()
	var key: String=str(st.tracked)
	if key.is_empty() or not st.quests.has(key):return ""
	var q: Dictionary=st.quests[key]
	return "%s • %d/%d\n%s"%[str(q.title),int(q.progress),int(q.goal),"Retorne ao NPC de origem" if q.state=="COMPLETED" else "Região %02d"%int(q.region)]

# EXO Jornada 02 — additive capabilities; no second quest manager/save/wallet.
func v4_status() -> Dictionary:
	return JourneyV4.inspect(state())
func v4_preview_story(record: Dictionary, context: Dictionary) -> Dictionary:
	return JourneyV4.preview(world,record,context)
func v4_request_accept(proposal: Dictionary) -> Dictionary:
	return JourneyV4.request_accept(world,proposal)
func v4_request_choice(instance: Dictionary,choice_id: String) -> Dictionary:
	return JourneyV4.request_choice(world,instance,choice_id)
func v4_request_reward(instance: Dictionary) -> Dictionary:
	return JourneyV4.request_reward(world,instance)
