extends RefCounted
const Catalog=preload("res://catalog.gd")
const World=preload("res://procedural/world_state.gd")
static var rules: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/loot_rules.json"))
static func compatible(a: Dictionary,ref: String,excluded_group: String="") -> bool:
	return (a.refs.is_empty() or ref in a.refs) and a.group!=excluded_group
static func pick_affix(w: Dictionary,key: String,domain: String,ref: String,excluded: String="") -> Dictionary:
	var options: Array=[]
	for a in rules[domain]:
		if compatible(a,ref,excluded):options.append(a)
	if options.is_empty():return {}
	return options[World.stream(w,"loot/"+domain,key).below(options.size())]
static func generate(w: Dictionary,key: String,kind: String,tier: int,uid: String,base_override: String="") -> Dictionary:
	if not World.valid(w) or tier<1 or tier>3 or not rules.pools.has(kind):return {}
	if not base_override.is_empty() and not Catalog.WEAPONS.any(func(a):return a.id==base_override):return {}
	var pool: Array=rules.pools[kind]
	var ref: String=base_override if not base_override.is_empty() else str(pool[World.stream(w,"loot/base",key).below(pool.size())])
	var total:=0
	for r in rules.rarities:total+=int(r.weights[tier-1])
	var roll: int=World.stream(w,"loot/rarity",key).below(total)
	var rarity: Dictionary=rules.rarities[0]
	for r in rules.rarities:
		roll-=int(r.weights[tier-1])
		if roll<0:rarity=r;break
	var quality: RefCounted=World.stream(w,"loot/quality",key)
	var stats: Dictionary={"damage_pct":snappedf(quality.between(rarity.quality[0],rarity.quality[1]),.001)}
	var item: Dictionary={"uid":uid,"kind":"weapon","ref":ref,"qty":1,"rarity":rarity.name,"affixes":[],"prefix":"","suffix":"","affinity":-1,"stats":stats,"instance_id":str(w.id)+"/"+key,"generation":{"version":1,"source":key,"tier":tier}}
	var prefix: Dictionary={}
	if rarity.affixes>=1:prefix=pick_affix(w,key,"prefixes",ref)
	if not prefix.is_empty():append_affix(item,w,key,prefix,"prefix")
	if rarity.affixes>=2:
		var suffix:=pick_affix(w,key,"suffixes",ref,str(prefix.get("group","")))
		if not suffix.is_empty():append_affix(item,w,key,suffix,"suffix")
	return item
static func append_affix(item: Dictionary,w: Dictionary,key: String,a: Dictionary,slot: String) -> void:
	item[slot]=a.id;item.affixes.append(a.id)
	if a.has("affinity"):item.affinity=int(a.affinity)
	var rng: RefCounted=World.stream(w,"loot/values/"+slot,key)
	for stat in a.stats:
		var bounds: Array=a.stats[stat]
		var amount: float=rng.between(bounds[0],bounds[1])
		if stat in ["guard","agilidade","inteligencia"]:amount=roundf(amount)
		item.stats[stat]=minf(float(rules.caps[stat]),snappedf(float(item.stats.get(stat,0))+amount,.001))
static func definition(id: String) -> Dictionary:
	for a in rules.prefixes+rules.suffixes:
		if a.id==id:return a
	return {}
static func title(item: Dictionary) -> String:
	var name_value: String=Catalog.weapon(item.ref).name
	if not item.get("prefix","").is_empty():name_value+=" • "+str(definition(item.prefix).get("text",item.prefix))
	if not item.get("suffix","").is_empty():name_value+=" "+str(definition(item.suffix).get("text",item.suffix))
	return name_value
static func valid(item: Dictionary) -> bool:
	if not item.has("generation"):return not item.has("stats") and not item.has("instance_id")
	if not item.generation is Dictionary or item.generation.get("version")!=1:return false
	var tier: Variant=item.generation.get("tier")
	if (not tier is int and not tier is float) or not is_finite(float(tier)) or int(tier)!=tier or int(tier)<1 or int(tier)>3:return false
	if not item.generation.get("source") is String or item.generation.source.length()>128:return false
	if not item.get("instance_id") is String or not item.instance_id.begins_with("world_") or item.instance_id.length()>240:return false
	if item.kind!="weapon" or not item.get("stats") is Dictionary or not item.get("affixes") is Array or item.affixes.size()>2:return false
	var rarity: Dictionary={}
	for r in rules.rarities:
		if r.name==item.get("rarity"):rarity=r
	if rarity.is_empty() or item.affixes.size()!=int(rarity.affixes):return false
	var element: Variant=item.get("affinity")
	if (not element is int and not element is float) or not is_finite(float(element)) or int(element)!=element or int(element) not in [-1,0,5,6]:return false
	var seen_groups: Array=[];var expected: Array=[];var affinity:=-1
	for slot in ["prefix","suffix"]:
		if not item.get(slot) is String:return false
		if item[slot].is_empty():continue
		var a:=definition(item[slot])
		if a.is_empty() or not compatible(a,item.ref) or a.group in seen_groups:return false
		if not rules["prefixes" if slot=="prefix" else "suffixes"].has(a):return false
		seen_groups.append(a.group);expected.append(a.id)
		if a.has("affinity"):affinity=int(a.affinity)
	if expected!=item.affixes or affinity!=int(item.affinity):return false
	var bounds: Dictionary={"damage_pct":rarity.quality.duplicate()}
	for id in expected:
		for stat in definition(id).stats:
			if not bounds.has(stat):bounds[stat]=[0.0,0.0]
			bounds[stat][0]+=float(definition(id).stats[stat][0]);bounds[stat][1]+=float(definition(id).stats[stat][1])
	if bounds.size()!=item.stats.size():return false
	for key in item.stats:
		var value: Variant=item.stats[key]
		if not bounds.has(key) or not rules.caps.has(key) or (not value is float and not value is int) or not is_finite(float(value)) or value<0 or value>rules.caps[key]+.0001:return false
		if value<minf(float(rules.caps[key]),bounds[key][0])-.0015 or value>minf(float(rules.caps[key]),bounds[key][1])+.0015:return false
		if key in ["guard","agilidade","inteligencia"] and int(value)!=value:return false
	return item.stats.has("damage_pct")
static func weapon(item: Dictionary) -> Dictionary:
	var spec: Dictionary=Catalog.weapon(item.ref).duplicate(true)
	if item.has("generation"):spec.damage+=maxi(int(rules.minimum_damage_bonus),roundi(float(spec.damage)*float(item.stats.get("damage_pct",0))))
	return spec
static func describe(item: Dictionary) -> String:
	if not item.has("generation"):return "Equipamento legado • atributos-base."
	var lines: PackedStringArray=[]
	var labels: Dictionary={"damage_pct":"dano da arma","move_pct":"movimento","guard":"redução de dano recebido","mana_regen":"mana por segundo","stamina_regen":"vigor por segundo","elemental_pct":"dano de técnicas da afinidade","agilidade":"agilidade","inteligencia":"inteligência"}
	for key in item.stats:
		var value: float=item.stats[key]
		lines.append("+%.1f%% %s"%[value*100,labels[key]] if key.ends_with("_pct") else "+%.1f %s"%[value,labels[key]])
	if item.affinity>=0:lines.append("Afinidade: "+str(Catalog.ELEMENTS[int(item.affinity)]))
	lines.append("Qualidade garante ao menos +%d dano-base."%int(rules.minimum_damage_bonus))
	return "\n".join(lines)
