extends RefCounted
# Terrain/world data reader. Does not edit World Genesis, lots or roads.
const Stream=preload("res://procedural/seed_stream.gd")
const BUDGETS={"wild":3,"ruins":4,"dungeon_approach":4}
static func build(data: RefCounted,seed_text: String) -> Array:
	var kind: String=str(data.spec.get("kind",""))
	if not BUDGETS.has(kind):return []
	var rng: RefCounted=Stream.new(Stream.hash_value("ECO/1/%s/%s"%[seed_text,str(data.spec.id)]))
	var result: Array=[]
	var count: int=int(BUDGETS[kind]);var attempts:=0
	while result.size()<count and attempts<maxi(320,count*130):
		attempts+=1
		var limit: float=minf(float(data.half)-24.0,185.0)
		if limit<40:break
		var p:=Vector2(rng.between(-limit,limit),rng.between(-limit,limit))
		if p.length()<42 or data.gate_road_distance(p)<9 or data.river_distance(p)<15 or data.pad_distance(p)<16:continue
		if absf(data.height_at(p+Vector2(1.5,0))-data.height_at(p))>0.65:continue
		if absf(data.height_at(p+Vector2(0,1.5))-data.height_at(p))>0.65:continue
		var clear:=true
		for old in result:
			if p.distance_to(old.p)<34:clear=false;break
		if not clear:continue
		var index: int=result.size()
		var role: String="mage" if kind!="wild" and index%3==2 else "blade"
		result.append({"id":"eco/r%02d/t%02d"%[int(data.spec.id),index],"region":int(data.spec.id),"p":p,"y":data.height_at(p)+0.07,"kind":role,"radius":19.0,"group_size":2 if index%3==0 else 1,"danger":int(data.spec.get("difficulty",1))})
	return result

# R4 fauna: utiliza o mesmo Regional Ecology, com IDs estáveis e sem segunda ecologia.
const FAUNA_BIOMES={"grassland":["meadow"],"temperate_forest":["forest"],"bamboo_forest":["bamboo","forest"],"mixed_woodland":["forest","meadow"],"dry_valley":["meadow","rock"],"wetland":["wetland"],"rocky_highlands":["mountain","cliff","rock"],"alpine":["mountain","cliff"]}
static func build_fauna(data: RefCounted,seed_text: String,profiles: Array, occupied: Array) -> Array:
	var kind: String=str(data.spec.get("kind",""))
	if kind not in ["wild","ruins","dungeon_approach"]:return []
	var tags: Array=FAUNA_BIOMES.get(str(data.spec.get("biome","")),[]).duplicate()
	if kind=="ruins":tags.append("ruins")
	var available: Array=[]
	for profile in profiles:
		if not profile is Dictionary or str(profile.get("category","")) in ["humanoid","elite","boss"]:continue
		for tag in profile.get("biomes",[]):
			if tag in tags:
				available.append(profile);break
	available.sort_custom(func(a,b):return str(a.get("id",""))<str(b.get("id","")))
	if available.is_empty():return []
	var rng: RefCounted=Stream.new(Stream.hash_value("ECO/FAUNA/R4/%s/%s"%[seed_text,str(data.spec.id)]))
	var result: Array=[]
	var count: int=2 if kind=="wild" else 1
	for attempt in range(240):
		if result.size()>=count:break
		var limit: float=minf(float(data.half)-25.0,185.0)
		if limit<=45:return result
		var p:=Vector2(rng.between(-limit,limit),rng.between(-limit,limit))
		if p.length()<44 or data.gate_road_distance(p)<12 or data.road_distance(p)<11 or data.river_distance(p)<18 or data.pad_distance(p)<18:continue
		if absf(data.height_at(p+Vector2(1.5,0))-data.height_at(p))>0.60:continue
		if absf(data.height_at(p+Vector2(0,1.5))-data.height_at(p))>0.60:continue
		var clear:=true
		for site in occupied+result:
			if p.distance_to(site.p)<29:clear=false;break
		if not clear:continue
		var index: int=result.size()
		var profile: Dictionary=available[posmod(Stream.hash_value("fauna/%s/%d/%d"%[seed_text,int(data.spec.id),index]),available.size())]
		result.append({"id":"eco/r%02d/f%02d"%[int(data.spec.id),index],"region":int(data.spec.id),"p":p,"y":data.height_at(p)+0.07,"kind":"fauna","species":str(profile.id),"radius":float(profile.get("territory_radius",24.0)),"group_size":1,"danger":int(data.spec.get("difficulty",1)),"fauna":true})
	return result
