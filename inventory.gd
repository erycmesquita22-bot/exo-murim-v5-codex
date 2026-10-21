extends RefCounted
const Loot=preload("res://procedural/loot_generator.gd")
const WorldSeed=preload("res://procedural/world_state.gd")
const Catalog=preload("res://catalog.gd")
const CAPACITY=24
const SPECIAL={"potion":{"name":"Infusão restauradora","kind":"consumable","description":"Recupera 40 de vida. Use fora de combate."},"iron":{"name":"Fragmento de ferro","kind":"material","description":"Material de ofício. Reservado para a futura forja."},"hide":{"name":"Couro de fera","kind":"material","description":"Recurso obtido de fauna regional."},"fang":{"name":"Presa de fera","kind":"material","description":"Recurso obtido de fauna predadora."}}
var world: Node3D
var drops: Array[Node3D]=[]
func _init(w: Node3D) -> void:
	world=w
static func defaults() -> Dictionary:
	return {"items":[],"equipped":"","next_item":1,"pending_loot":[],"known":[],"learned":[],"rumors":[],"mastery":{},"encounter":{"met":false,"done":false},"race_lock":""}
static func title(item: Dictionary) -> String:
	if item.kind=="weapon":
		return Loot.title(item) if item.has("generation") else Catalog.weapon(item.ref).name
	if item.kind=="manual":
		return "Manual de técnicas • não lido"
	return SPECIAL.get(item.ref,{}).get("name","Objeto")
static func skill_exists(id: String) -> bool:
	for s in Catalog.SKILLS:
		if s.id==id:
			return true
	return false
static func valid_item(item: Variant) -> bool:
	if not item is Dictionary or not item.get("uid") is String or not item.uid.begins_with("item_"):
		return false
	if item.get("kind") not in ["weapon","manual","consumable","material"] or not item.get("ref") is String:
		return false
	if not item.get("qty") is float and not item.get("qty") is int:
		return false
	if item.qty<1 or item.qty>99 or int(item.qty)!=item.qty:
		return false
	if item.kind=="weapon":
		return item.qty==1 and Catalog.WEAPONS.any(func(s):return s.id==item.ref) and Loot.valid(item)
	if item.kind=="manual":
		return item.qty==1 and (skill_exists(item.ref) or item.ref=="percepcao_qi")
	return SPECIAL.has(item.ref) and SPECIAL[item.ref].kind==item.kind
func seed_profile() -> void:
	var d: Dictionary=world.journey.data
	for key in defaults():
		if not d.has(key):d[key]=defaults()[key]
	d.race_lock=d.character.get("race_id","")
	if d.items.is_empty():
		var uid:=add("weapon",d.character.get("weapon","sword"),1)
		d.equipped=uid
		add("consumable","potion",3)
	for id in d.loadout:
		if id not in d.known:d.known.append(id)
		if id not in d.learned:d.learned.append(id)
func add(kind: String,ref: String,qty: int=1) -> String:
	var d: Dictionary=world.journey.data
	if qty<1 or qty>99:return ""
	if kind in ["consumable","material"]:
		for item in d.items:
			if item.kind==kind and item.ref==ref and item.qty+qty<=99:
				item.qty+=qty
				return item.uid
	if d.items.size()>=CAPACITY:return ""
	var uid: String="item_%d"%int(d.next_item)
	var item: Dictionary={"uid":uid,"kind":kind,"ref":ref,"qty":qty,"rarity":"Comum","affixes":[]}
	if not valid_item(item):return ""
	d.next_item+=1
	d.items.append(item)
	return uid
func find_item(uid: String) -> Dictionary:
	for item in world.journey.data.items:
		if item.uid==uid:return item
	return {}
func owns_weapon(id: String) -> bool:
	for item in world.journey.data.items:
		if item.kind=="weapon" and item.ref==id:return true
	return false
func use(uid: String) -> bool:
	if not world.can_configure():return false
	var item:=find_item(uid)
	if item.is_empty():return false
	if item.kind=="weapon":
		return world.equip_weapon(item.ref,uid)
	if item.kind not in ["consumable","manual"]:return false
	var before: Dictionary=world.journey.data.duplicate(true)
	var hp: int=world.health
	if item.kind=="consumable":
		if world.health>=world.max_health:return false
		world.health=mini(world.max_health,world.health+40)
	else:
		world.cultivation.reveal(item.ref)
	item.qty-=1
	if item.qty<=0:world.journey.data.items.erase(item)
	if not world.save_progress():
		world.journey.data=before
		world.health=hp
		return false
	return true
func drop_for(actor: Node3D) -> void:
	if world.flow.lab_mode or world.trial_mode:return
	var key: String="loot/"+str(actor.uid)
	if WorldSeed.has_event(world.journey.data.world,key):return
	for pending in world.journey.data.pending_loot:
		if pending.source==actor.uid:return
	var rewards: Array=[{"kind":"material","ref":"iron","qty":2}]
	if actor.uid=="road_blade":rewards=[{"kind":"weapon","ref":"bow","qty":1},{"kind":"manual","ref":"golpe_circular","qty":1}]
	if actor.uid=="road_mage":rewards=[{"kind":"weapon","ref":"wand","qty":1},{"kind":"manual","ref":"nova_glacial","qty":1}]
	if actor.uid=="ruin_mage":rewards.append({"kind":"manual","ref":"jato_de_fogo","qty":1})
	if actor.uid=="ruin_blade_a":rewards.append({"kind":"manual","ref":"onda_de_repulsao","qty":1})
	if actor.uid=="ascendant":rewards.append({"kind":"manual","ref":"investida_brutal","qty":1})
	var data: Dictionary=world.journey.data
	var uid: String="item_%d"%int(data.next_item)
	var tier:=3 if actor.kind=="boss" else 2 if str(actor.uid).begins_with("ruin_") else 1
	var pool: String="boss" if actor.kind=="boss" else "mage" if actor.kind=="mage" else "blade"
	var equipment: Dictionary=Loot.generate(data.world,key,pool,tier,uid)
	rewards.append(equipment)
	if not WorldSeed.mark_pending(data.world,key,{"item_uid":uid}):return
	data.next_item+=1
	world.journey.data.pending_loot.append({"source":actor.uid,"x":actor.position.x,"z":actor.position.z,"y":actor.position.y+.15,"region":int(world.get("current_region")) if world.get("current_region")!=null else -1,"items":rewards})
	rebuild_drops()
# R6: Inventory owns the pending-loot record. Called only by the dungeon host
# after checking a real interaction point. This is RAM-only until atomic confirm.
func queue_dungeon_pending(dungeon_id: String,reward_id: String,source: String,rewards: Array) -> bool:
	if world==null or world.exo_core==null or not world.exo_core.ready:return false
	if dungeon_id.is_empty() or reward_id.is_empty() or source.is_empty() or source.length()>123:return false
	if not world.exo_core.services.has_service("dungeons"):return false
	var visit: Variant=world.exo_core.services.invoke("dungeons","active_status")
	if not visit is Dictionary or not bool(visit.get("active",false)) or str(visit.get("id",""))!=dungeon_id:return false
	var data: Dictionary=world.journey.data
	if not data.get("world") is Dictionary or not data.get("pending_loot") is Array:return false
	if data.pending_loot.any(func(drop):return str(drop.get("source",""))==source):return false
	if rewards.is_empty():return false
	for item in rewards:
		if not item is Dictionary or str(item.get("kind","")) not in ["material","consumable"] or not SPECIAL.has(str(item.get("ref",""))) or SPECIAL[str(item.ref)].kind!=item.kind:return false
		if int(item.get("qty",0))<1 or int(item.get("qty",0))>99:return false
	var claim: String="loot/"+source
	if not WorldSeed.mark_pending(data.world,claim,{"dungeon_id":dungeon_id,"reward_id":reward_id}):return false
	data.pending_loot.append({"source":source,"x":0.0,"y":0.0,"z":0.0,"region":int(world.current_region),"dungeon_id":dungeon_id,"reward_id":reward_id,"items":rewards.duplicate(true)})
	return true

func rebuild_drops() -> void:
	for node in drops:node.queue_free()
	drops.clear()
	for entry in world.journey.data.pending_loot:
		var current: int=int(world.get("current_region")) if world.get("current_region")!=null else -1
		if int(entry.get("region",-1))!=current:continue
		var node:=Node3D.new()
		world.add_child(node)
		node.position=Vector3(entry.x,float(entry.get("y",.2)),entry.z)
		preload("res://wardrobe.gd").piece(node,Vector3(0,.12,0),Vector3(.42,.24,.3),Color("89744e"))
		preload("res://wardrobe.gd").piece(node,Vector3(0,.25,0),Vector3(.3,.04,.2),Color("bcb298"))
		node.set_meta("source",entry.source)
		drops.append(node)
func nearby_drop() -> String:
	if world.flow.phase!="adventure" or world.flow.lab_mode:return ""
	for node in drops:
		if is_instance_valid(node) and node.position.distance_to(world.player.position)<2.1:
			return str(node.get_meta("source"))
	return ""
func collect(source: String) -> bool:
	if source!=nearby_drop():return false
	var before: Dictionary=world.journey.data.duplicate(true)
	for entry in world.journey.data.pending_loot:
		if entry.source==source:
			for reward in entry.items:
				var accepted:=false
				if reward.has("generation"):
					if world.journey.data.items.size()<CAPACITY and valid_item(reward) and find_item(reward.uid).is_empty():
						world.journey.data.items.append(reward.duplicate(true));accepted=true
				else:accepted=not add(reward.kind,reward.ref,int(reward.qty)).is_empty()
				if not accepted:
					world.journey.data=before
					world.message("Inventário cheio • 24 espaços.")
					return false
			world.journey.data.pending_loot.erase(entry)
			if not WorldSeed.mark_collected(world.journey.data.world,"loot/"+source):
				world.journey.data=before
				return false
			# Update quest progress in the exact same save transaction as the loot.
			if world.get("exo_core")!=null:
				var emitted: Dictionary=world.exo_core.publish("item_collected","collected/"+source,{"source":source,"items":entry.items})
				if not emitted.ok:world.journey.data=before;return false
			elif world.get("journey_manager")!=null:world.journey_manager.on_collect(source,entry.items)
			if not world.save_progress():
				world.journey.data=before
				return false
			rebuild_drops()
			world.message("Objetos recolhidos • confira P > Inventário.")
			return true
	return false

func test_kit() -> void:
	if not world.flow.lab_mode:return
	for id in ["bow","crossbow","spear"]:add("weapon",id)
	for id in ["golpe_circular","nova_glacial","percepcao_qi"]:add("manual",id)
	add("material","iron",6)
	for id in ["golpe_circular","nova_glacial","percepcao_qi"]:world.cultivation.rumor(id)

func equipped_item() -> Dictionary:
	return find_item(str(world.journey.data.equipped))
func equipment_stats() -> Dictionary:
	if world.martial!=null and world.martial.bare():return {}
	return equipped_item().get("stats",{})

# Bound privately by the C3 host. Stages supported item changes; never saves here.
func stage_economy_trade(document: Dictionary, intent: Dictionary, quote: Dictionary) -> Dictionary:
	return preload("res://exo_economy/trade_goods.gd").stage_authorized(document, intent, quote)
