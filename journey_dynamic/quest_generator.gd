extends RefCounted
# Produces only viable, deterministic offers from the real atlas and materialized NPC roster.
const RegionalData=preload("res://genesis/region_data.gd")
const Territories=preload("res://regional_ecology/territories.gd")
const TYPES=["defeat","clear","visit","collect","deliver","talk","investigate"]
const TITLES={"defeat":"Estrada dos Salteadores","clear":"Território ameaçado","visit":"Reconhecer passagem","collect":"Ferro para a forja","deliver":"Entrega à comunidade","talk":"Mensagem entre moradores","investigate":"Vestígios nas ruínas"}

static func reachable(atlas: Dictionary,origin: int,target: int) -> bool:
	if origin==target:return true
	if origin<0 or origin>=88 or target<0 or target>=88:return false
	var queue: Array=[origin]
	var seen: Dictionary={}
	seen[origin]=true
	while not queue.is_empty():
		var rid: int=int(queue.pop_front())
		for entry in atlas.regions[rid].get("entrances",[]):
			var neighbor: int=int(entry.neighbor)
			if neighbor==target:return true
			if not seen.has(neighbor):seen[neighbor]=true;queue.append(neighbor)
	return false

static func nearest(atlas: Dictionary,origin: int,kind: String) -> int:
	var queue: Array=[origin]
	var seen: Dictionary={}
	seen[origin]=true
	while not queue.is_empty():
		var rid: int=int(queue.pop_front())
		if rid!=origin and str(atlas.regions[rid].kind)==kind:return rid
		for entry in atlas.regions[rid].get("entrances",[]):
			var n: int=int(entry.neighbor)
			if not seen.has(n):seen[n]=true;queue.append(n)
	return -1

static func territory(atlas: Dictionary,origin: int,save: Dictionary) -> Dictionary:
	var queue: Array=[origin]
	var seen: Dictionary={}
	seen[origin]=true
	while not queue.is_empty():
		var rid: int=int(queue.pop_front())
		if rid!=origin and str(atlas.regions[rid].kind) in ["wild","ruins","dungeon_approach"]:
			var data=RegionalData.new(atlas,rid)
			for site in Territories.build(data,str(atlas.seed)):
				var eco: Dictionary=save.get("convergence",{}).get("ecology",{})
				var record: Dictionary=eco.get("regions",{}).get(str(rid),{}).get(str(site.id),{})
				# A partially defeated group cannot be offered as a complete new objective.
				var last: float=float(record.get("defeated_at",-1))
				var now: float=float(save.get("convergence",{}).get("clock",0.0))
				if record.get("members_dead",[]).is_empty() and (last<0.0 or now>=last+540.0):return site
		for entry in atlas.regions[rid].get("entrances",[]):
			var n: int=int(entry.neighbor)
			if not seen.has(n):seen[n]=true;queue.append(n)
	return {}

static func offer(atlas: Dictionary,origin: int,npc: Dictionary,roster: Array,kind: String,save: Dictionary) -> Dictionary:
	if kind not in TYPES or origin<0 or origin>=88 or not atlas is Dictionary:return {}
	var giver: String=str(npc.get("id",""))
	if giver.is_empty():return {}
	var destination:=origin
	var target: String=""
	var goal:=1
	var other: String=""
	var location: Array=[]
	if kind in ["defeat","clear","collect","deliver"]:
		var site: Dictionary=territory(atlas,origin,save)
		if site.is_empty():return {}
		if kind in ["defeat","clear"]:
			destination=int(site.region);target=str(site.id)
			goal=int(site.group_size) if kind=="clear" else 1
			location=[site.p.x,site.y,site.p.y]
		else:
			target="iron";goal=2
			if kind=="collect":destination=int(site.region)
	elif kind=="visit":
		destination=nearest(atlas,origin,"wild")
		if destination<0:return {}
		target="region/%d"%destination
	elif kind=="investigate":
		destination=nearest(atlas,origin,"ruins")
		if destination<0:return {}
		var ruin_data=RegionalData.new(atlas,destination)
		if ruin_data.lots.is_empty():return {}
		var lot: Dictionary=ruin_data.lots[0]
		location=[lot.p.x,lot.height,lot.p.y]
		target="ruin/%d"%destination
	elif kind=="talk":
		for person in roster:
			if str(person.get("id",""))!=giver:
				other=str(person.id);break
		if other.is_empty():return {}
		target=other
	if not reachable(atlas,origin,destination):return {}
	var uid: String="j01/%s/%s"%[giver,kind]
	var xp: int=18 if kind in ["defeat","visit","talk"] else 30 if kind in ["collect","deliver"] else 50
	return {"id":uid,"title":str(TITLES[kind]),"type":kind,"giver":giver,"origin":origin,"region":destination,
		"target":target,"location":location,"goal":goal,"progress":0,"seen":[],"generation":int(save.get("convergence",{}).get("ecology",{}).get("regions",{}).get(str(destination),{}).get(target,{}).get("generation",0)),"state":"AVAILABLE",
		"reward":{"xp":xp,"bronze":int(12+xp/3),"iron":1 if kind in ["clear","investigate"] else 0,"reputation":3}}

static func offers(atlas: Dictionary,origin: int,npc: Dictionary,roster: Array,save: Dictionary) -> Array:
	if origin<0 or origin>=88:return []
	var role: String=str(npc.get("role","resident"))
	var service: String=str(npc.get("service",""))
	var preferred: Array=[]
	if role in ["guard","outlaw"] or service in ["guard","security"]:preferred=["defeat","clear"]
	elif role in ["merchant","courier","guild_agent"]:preferred=["defeat","deliver","visit"]
	elif role in ["farmer","healer"]:preferred=["collect","deliver","visit"]
	elif role in ["master","disciple"]:preferred=["investigate","visit","talk"]
	else:preferred=["talk","visit","collect","deliver","defeat","clear","investigate"]
	var options: Array=[]
	for kind in preferred:
		var entry: Dictionary=offer(atlas,origin,npc,roster,str(kind),save)
		if not entry.is_empty():options.append(entry)
		if options.size()>=2:break
	return options
