extends RefCounted
const WorldSeed=preload("res://procedural/world_state.gd")
const Inventory=preload("res://inventory.gd")
const Slots=preload("res://data/slot_rules.gd")
const Catalog=preload("res://catalog.gd")
const ATTRIBUTES=["forca","agilidade","vitalidade","inteligencia","vontade","sorte"]

const DEFAULT_PATH="user://journey.json"
const IDS=["road_blade","road_mage","ruin_blade_a","ruin_mage","ruin_blade_b","ascendant"]
const PHASES=["hero","prologue","omen","story","creator","adventure"]
var path: String
var status:=""
var recovered:=false
var allow_reset_invalid:=false
var data: Dictionary={"version":4,"stage":0,"coins":0,"claimed":false,"checkpoint":"camp","defeated":[],"seconds":0.0,"boon":"","phase":"hero","character":{},"visits":[],"rested":false,"ruins_explored":false,"lodging":false,"meditation":0.0}

func _init(file_path: String=DEFAULT_PATH,world_seed: int=-1) -> void:
	path=file_path
	data.world=WorldSeed.create(world_seed)
	data.merge(Inventory.defaults(),false)
	data.merge({"hero":6,"loadout":["corte_inicial","bola_de_gelo","salto_impetuoso"],"passives":[],"attributes":{"forca":0,"agilidade":0,"vitalidade":0,"inteligencia":0,"vontade":0,"sorte":0},"title":"Viajante"})

func valid(value: Variant) -> bool:
	if value is Dictionary and value.has("exo_core") and not preload("res://exo_core/persistence/migration_registry.gd").valid(value.exo_core):return false
	if value is Dictionary and value.has("convergence") and not preload("res://convergence/state.gd").valid(value.convergence):return false
	if value is Dictionary and value.has("living_world") and not preload("res://living_world/state.gd").valid(value.living_world):return false
	if value is Dictionary and value.has("journey_dynamic") and not preload("res://journey_dynamic/quest_manager.gd").valid(value.journey_dynamic):return false
	if value is Dictionary and value.has("narrative") and not preload("res://narrative/core/narrative_state.gd").valid(value.narrative):return false
	if not value is Dictionary or value.get("version")!=4 or (value.has("world") and not WorldSeed.valid(value.world)):
		return false
	for key in ["stage","coins","seconds","meditation"]:
		if not value.get(key) is int and not value.get(key) is float:
			return false
		if not is_finite(float(value[key])) or float(value[key])<0:
			return false
	if int(value.stage)!=value.stage or int(value.stage) not in [0,1,4,5] or value.coins!=(100 if value.get("claimed",false) else 0):
		return false
	if not value.get("claimed") is bool or value.claimed!=(value.stage==5):
		return false
	if value.get("phase") not in PHASES or value.get("checkpoint")!="camp":
		return false
	if value.get("boon") not in ["","blade","frost","vitality"] or (value.boon!="" and not value.claimed):
		return false
	if not value.get("ruins_explored",false) is bool or (value.get("ruins_explored",false) and not value.get("rested",false)):
		return false
	for key in ["rested","lodging"]:
		if not value.get(key) is bool:
			return false
	if value.lodging!=value.claimed or (value.rested and not value.lodging):
		return false
	for key in ["defeated","visits"]:
		if not value.get(key) is Array:
			return false
		var seen: Array=[]
		for entry in value[key]:
			if key=="visits" and (not entry is float and not entry is int):
				return false
			if key=="visits" and (int(entry)!=entry or int(entry) not in [0,1,2]):
				return false
			if (key=="defeated" and entry not in IDS) or entry in seen:
				return false
			seen.append(entry)
	if value.stage>=4 and (value.visits.size()!=3 or "road_blade" not in value.defeated or "road_mage" not in value.defeated):
		return false
	if not value.get("character") is Dictionary:
		return false
	if not valid_inventory(value) or not valid_foundations(value):
		return false
	if value.phase=="adventure":
		return valid_character(value.character)
	return true

func valid_character(profile: Dictionary) -> bool:
	if not profile.get("name") is String or profile.name.strip_edges().is_empty() or profile.name.length()>24:
		return false
	for key in ["race","path","robe","hair","skin","style"]:
		if not profile.get(key) is int and not profile.get(key) is float:
			return false
		if int(profile[key])!=profile[key] or int(profile[key])<0 or int(profile[key])>={"race":12,"path":3,"robe":6,"hair":6,"skin":6,"style":3}[key]:
			return false
	# EXO original cosmetic options; existing saves without them are valid.
	for cosmetic in ["body", "outfit", "haircut", "eyes", "eye_color", "muscles", "mark"]:
		if profile.has(cosmetic) and not integer_range(profile[cosmetic], 0, {"body":6,"outfit":3,"haircut":3,"eyes":3,"eye_color":5,"muscles":2,"mark":2}[cosmetic]):
			return false
	if profile.has("skin_file"):
		if not profile.skin_file is String or not str(profile.skin_file).begins_with("user://exo_skins/") or not str(profile.skin_file).ends_with(".png"):return false
	if profile.has("skin3d") and not preload("res://exo_skin3d/profile_codec.gd").valid(profile.skin3d):return false
	if profile.has("visual_r2") and not preload("res://exo_humanoids03_r2/scripts/preset_selector.gd").valid(profile.visual_r2):return false
	if profile.has("hands_free") and not profile.hands_free is bool:return false
	if profile.has("voice") and not integer_range(profile.voice,0,2):return false
	if profile.has("race_id") and profile.race_id!=Catalog.RACES[int(profile.race)].id:
		return false
	if profile.has("weapon") and not has_id(Catalog.WEAPONS,profile.weapon):
		return false
	if profile.has("element") and not integer_range(profile.element,0,11):
		return false
	return true

func decode(text: String) -> Variant:
	var parser:=JSON.new()
	if parser.parse(text)!=OK:return null
	var value: Variant=parser.data
	# JSON parses numeric seeds as floats. Keep their canonical integer text
	# for all existing generation, appearance and module identity contracts.
	if value is Dictionary and value.get("world") is Dictionary:
		for field in ["seed","schema","generation_version"]:
			var number:Variant=value.world.get(field)
			if (number is int or number is float) and is_finite(float(number)) and absf(float(number))<2147483647.0 and number==int(number):
				value.world[field]=int(number)
	if value is Dictionary and value.has("living_world"):
		value.living_world=preload("res://living_world/state.gd").restore_numbers(value.living_world)
	if value is Dictionary and value.has("journey_dynamic"):
		value.journey_dynamic=preload("res://living_world/state.gd").restore_numbers(value.journey_dynamic)
	if value is Dictionary and value.has("narrative"):
		value.narrative=preload("res://living_world/state.gd").restore_numbers(value.narrative)
	if value is Dictionary and value.get("character") is Dictionary and value.character.get("skin3d") is Dictionary:
		if value.character.skin3d.get("version")==1:value.character.skin3d.version=1
	return value

func load_progress() -> bool:
	for candidate in [path,path+".bak",path+".tmp"]:
		if not FileAccess.file_exists(candidate):
			continue
		var original: Variant=decode(FileAccess.get_file_as_string(candidate))
		var value: Variant=upgrade(original)
		if valid(value):
			if int(original.get("version",0)) in [2,3] and not FileAccess.file_exists(path+".pre04.json"):
				var snapshot:=FileAccess.open(path+".pre04.json",FileAccess.WRITE)
				if snapshot!=null:
					snapshot.store_string(JSON.stringify(original))
					snapshot.close()
			if not original.has("world") and not FileAccess.file_exists(path+".pre092.json"):
				var snapshot:=FileAccess.open(path+".pre092.json",FileAccess.WRITE)
				if snapshot==null:status="Não foi possível preservar o save legado.";return false
				snapshot.store_string(FileAccess.get_file_as_string(candidate));snapshot.close()
			recovered=candidate!=path
			data=value
			for i in range(data.visits.size()):
				data.visits[i]=int(data.visits[i])
			for key in ["race","path","robe","hair","skin","style"]:
				if data.character.has(key):
					data.character[key]=int(data.character[key])
			status="Progresso carregado." if candidate==path else "Progresso recuperado."
			return true
	status="Nova jornada." if not FileAccess.file_exists(path) else "Arquivo inválido. Inicie uma nova jornada."
	return false

var save_coordinator=preload("res://exo_core/persistence/save_coordinator.gd").new()
func write() -> bool:
	return save_coordinator.commit(self)

func _commit_legacy() -> bool:
	if not data.has("world"):WorldSeed.migrate_legacy(data)
	if FileAccess.file_exists(path) and not valid(upgrade(decode(FileAccess.get_file_as_string(path)) )):
		if not recovered and not allow_reset_invalid:
			status="Save inválido preservado. Use Nova jornada explicitamente ou restaure uma cópia.";return false
		var rejected:=FileAccess.open(path+".invalid.json",FileAccess.WRITE)
		if rejected==null:status="Não foi possível preservar o save inválido.";return false
		rejected.store_string(FileAccess.get_file_as_string(path));rejected.close()
	if not valid(data):
		status="Não foi possível validar o progresso."
		return false
	var file:=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null:
		status="Não foi possível salvar."
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	if not valid(decode(FileAccess.get_file_as_string(path+".tmp"))):
		status="Falha ao conferir o salvamento."
		return false
	if FileAccess.file_exists(path):
		if valid(upgrade(decode(FileAccess.get_file_as_string(path)))):
			if FileAccess.file_exists(path+".bak"):
				DirAccess.remove_absolute(path+".bak")
			if DirAccess.rename_absolute(path,path+".bak")!=OK:
				status="Falha ao guardar o progresso anterior."
				return false
		else:
			if DirAccess.remove_absolute(path)!=OK:status="Não foi possível substituir o arquivo preservado.";return false
	save_coordinator.checkpoint("before_replace")
	if DirAccess.rename_absolute(path+".tmp",path)!=OK:
		status="Falha ao concluir o salvamento."
		return false
	status="Progresso salvo."
	return true

func claim_reward() -> bool:
	if data.stage!=4 or data.claimed:
		return false
	var previous:=data.duplicate(true)
	data.stage=5
	data.claimed=true
	data.coins=100
	data.lodging=true
	if not write():
		data=previous
		return false
	return true

func choose_boon(id: String) -> bool:
	if not data.claimed or data.boon!="" or id not in ["blade","frost","vitality"]:
		return false
	var previous:=data.duplicate(true)
	data.boon=id
	if not write():
		data=previous
		return false
	return true

func has_id(items: Array,id: Variant) -> bool:
	for item in items:
		if item.id==id:
			return true
	return false

func integer_range(value: Variant,minimum: int,maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and int(value)==value and value>=minimum and value<=maximum

func valid_foundations(value: Dictionary) -> bool:
	if not integer_range(value.get("hero"),0,11):
		return false
	if not value.get("loadout") is Array or (value.loadout.size()<Slots.ACTIVE or value.loadout.size()>Slots.MAX_ACTIVE):
		return false
	var seen: Array=[]
	for id in value.loadout:
		if not has_id(Catalog.SKILLS,id) or id in seen:
			return false
		seen.append(id)
	if not value.get("passives") is Array or value.passives.size()>Slots.PASSIVE:
		return false
	seen.clear()
	for id in value.passives:
		if not has_id(Catalog.PASSIVES,id) or id in seen:
			return false
		seen.append(id)
	if not value.get("attributes") is Dictionary or value.attributes.size()!=6:
		return false
	var total:=0
	for key in ATTRIBUTES:
		if not integer_range(value.attributes.get(key),0,30):
			return false
		total+=int(value.attributes[key])
	var bonus_limit: int=0
	if value.has("journey_dynamic") and value.journey_dynamic is Dictionary:
		bonus_limit=maxi(0,int(value.journey_dynamic.get("progress",{}).get("level",1))-1-int(value.journey_dynamic.get("progress",{}).get("unspent",0)))
	if total>6+bonus_limit:
		return false
	return value.get("title") in ["Viajante","Vigia das Estradas"] and (value.title!="Vigia das Estradas" or value.claimed)

func upgrade(value: Variant) -> Variant:
	if not value is Dictionary:
		return value
	if value.get("version")==2:
		value=value.duplicate(true)
		value.version=3
		value.merge({"hero":6,"loadout":["corte_inicial","bola_de_gelo","salto_impetuoso"],"passives":[],"attributes":{"forca":0,"agilidade":0,"vitalidade":0,"inteligencia":0,"vontade":0,"sorte":0},"title":"Viajante"},false)
		if value.get("character") is Dictionary and not value.character.is_empty():
			value.character.merge({"weapon":"sword","element":6},false)
	if value.get("version")==3 and value.get("character") is Dictionary and not value.character.is_empty():
		if value.character.has("race_id"):
			for i in range(Catalog.RACES.size()):
				if Catalog.RACES[i].id==value.character.race_id:
					value.character.race=i
		elif integer_range(value.character.get("race"),0,Catalog.RACES.size()-1):
			value.character.race_id=Catalog.RACES[int(value.character.race)].id
	if value is Dictionary and value.get("version")==3:
		value=value.duplicate(true)
		value.version=4
		value.merge(Inventory.defaults(),false)
		value.known=value.get("loadout",[]).duplicate()
		value.learned=value.known.duplicate()
		for id in value.get("passives",[]):
			if id not in value.known:value.known.append(id)
			if id not in value.learned:value.learned.append(id)
		if not value.get("character",{}).is_empty():
			value.race_lock=value.character.get("race_id","")
			value.items=[{"uid":"item_1","kind":"weapon","ref":value.character.get("weapon","sword"),"qty":1,"rarity":"Comum","affixes":[]},{"uid":"item_2","kind":"consumable","ref":"potion","qty":3,"rarity":"Comum","affixes":[]}]
			value.equipped="item_1"
			value.next_item=3
	if value is Dictionary and value.get("version")==4:
		value=value.duplicate(true)
		value.merge({"ruins_explored":false},false)
		WorldSeed.migrate_legacy(value)
	return value

func valid_inventory(v: Dictionary) -> bool:
	if not v.get("items") is Array or v.items.size()>Inventory.CAPACITY or not integer_range(v.get("next_item"),1,1000000000):return false
	var uids: Array=[]
	var equipped: Dictionary={}
	for item in v.items:
		if not Inventory.valid_item(item) or item.uid in uids:return false
		var number: String=item.uid.trim_prefix("item_")
		if not number.is_valid_int() or int(number)<1 or int(number)>=int(v.next_item):return false
		uids.append(item.uid)
		if item.uid==v.get("equipped"):equipped=item
	var instances: Array=[]
	for item in v.items:
		if item.has("generation"):
			if item.instance_id in instances:return false
			instances.append(item.instance_id)
	var all_ids: Array=[]
	for s in Catalog.SKILLS+Catalog.PASSIVES:all_ids.append(s.id)
	for key in ["known","learned","rumors"]:
		if not v.get(key) is Array:return false
		var seen: Array=[]
		for id in v[key]:
			if id not in all_ids or id in seen:return false
			seen.append(id)
	for id in v.learned:
		if id not in v.known:return false
	if not v.get("mastery") is Dictionary:return false
	if v.has("mastery_fraction"):
		if not v.mastery_fraction is Dictionary:return false
		for id in v.mastery_fraction:
			if id not in all_ids or not integer_range(v.mastery_fraction[id],0,999):return false
	for id in v.mastery:
		if id not in all_ids or not integer_range(v.mastery[id],0,1000000000):return false
	if not v.get("race_lock") is String or not v.get("encounter") is Dictionary:return false
	if not v.encounter.get("met") is bool or not v.encounter.get("done") is bool:return false
	if v.encounter.done and not v.encounter.met:return false
	for key in ["clock","check_clock","attempts"]:
		if v.encounter.has(key):
			var number: Variant=v.encounter[key]
			if (not number is int and not number is float) or not is_finite(float(number)) or number<0 or number>1000000000:return false
	if v.encounter.has("attempts") and int(v.encounter.attempts)!=v.encounter.attempts:return false
	# Regional ecology uses bounded procedural encounters; campaign IDs are still
	# validated exactly as before. New IDs must be within the regional namespace.
	if not v.get("pending_loot") is Array or v.pending_loot.size()>210:return false
	var sources: Array=[]
	for drop in v.pending_loot:
		if not drop is Dictionary or not drop.get("source") is String:return false
		var source_id: String=drop.source
		var regional: bool=source_id.begins_with("eco/r") and source_id.contains("/m") and source_id.contains("/g") and source_id.length()<90
		if (source_id not in IDS and not regional) or source_id in sources or not drop.get("items") is Array:return false
		if drop.has("region") and not integer_range(drop.region,-1,87):return false
		if drop.has("y") and (not (drop.y is float or drop.y is int) or not is_finite(float(drop.y)) or absf(drop.y)>10000):return false
		sources.append(drop.source)
		for coordinate in ["x","z"]:
			if not (drop.get(coordinate) is int or drop.get(coordinate) is float) or not is_finite(float(drop[coordinate])) or absf(float(drop[coordinate]))>(512.0 if regional else 200.0):return false
		for reward in drop.items:
			if not reward is Dictionary:return false
			var item: Dictionary=reward.duplicate(true)
			if reward.has("generation"):
				if not reward.get("uid") is String or not reward.uid.trim_prefix("item_").is_valid_int():return false
				var number:=int(reward.uid.trim_prefix("item_"))
				if number<1 or number>=int(v.next_item) or reward.uid in uids:return false
				uids.append(reward.uid)
				if reward.get("instance_id","") in instances:return false
				instances.append(reward.get("instance_id",""))
			else:item.uid="item_1"
			if not Inventory.valid_item(item):return false
	if v.has("world"):
		for item in v.items:
			if item.has("generation") and item.instance_id!=str(v.world.id)+"/"+str(item.generation.source):return false
		for drop in v.pending_loot:
			for item in drop.items:
				if item.has("generation") and (item.instance_id!=str(v.world.id)+"/"+str(item.generation.source) or item.generation.source!="loot/"+drop.source):return false
	if v.phase=="adventure":
		if v.race_lock!=v.character.get("race_id","") or equipped.is_empty() or equipped.kind!="weapon" or equipped.ref!=v.character.get("weapon"):return false
		for id in v.loadout+v.passives:
			if id not in v.learned:return false
	return true
