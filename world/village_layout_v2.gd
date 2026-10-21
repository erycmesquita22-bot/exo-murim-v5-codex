extends RefCounted
# Data-only, deterministic layout. Gameplay and rendering both consume these same anchors.
const WorldSeed=preload("res://procedural/world_state.gd")
const KINDS=["empobrecida","comum","prospera","especial"]
const TITLES={"empobrecida":"Aldeia das Dificuldades","comum":"Aldeia do Primeiro Eco","prospera":"Aldeia das Rotas Douradas","especial":"Aldeia dos Ecos Ocultos"}
const PATTERNS=["cruzamento","rua_alta","patios","encruzilhada"]
const COLUMNS=[-28.0,-14.0,14.0,28.0]
const ROWS=[23.0,35.0,47.0,61.0]

static func create(world_data: Dictionary) -> Dictionary:
	var rng: RefCounted=WorldSeed.stream(world_data,"landscape/layout_v2","birth/village")
	var roll: int=rng.below(100)
	var kind: String="comum"
	if roll<20:kind="empobrecida"
	elif roll>=70 and roll<95:kind="prospera"
	elif roll>=95:kind="especial"
	var pattern: String=PATTERNS[rng.below(PATTERNS.size())]
	var inner: Array[int]=[1,2,5,6,9,10]
	for i in range(inner.size()-1,0,-1):
		var j: int=rng.below(i+1)
		var swap: int=inner[i]
		inner[i]=inner[j]
		inner[j]=swap
	var reserved: Array[int]=[inner[0],inner[1],inner[2]]
	var sites: Dictionary={}
	for i in range(3):
		var slot: int=reserved[i]
		var cell: Dictionary=_plot(world_data,slot)
		sites[["guild","inn","training"][i]]=cell
	var remaining: Array[int]=[]
	for i in range(16):
		if i not in reserved:remaining.append(i)
	for i in range(remaining.size()-1,0,-1):
		var j: int=rng.below(i+1)
		var swap: int=remaining[i]
		remaining[i]=remaining[j]
		remaining[j]=swap
	var count: int=2 if kind=="empobrecida" else 4 if kind=="comum" else 8 if kind=="prospera" else 6
	var houses: Array=[]
	for i in range(count):
		var cell: Dictionary=_plot(world_data,remaining[i])
		cell["asset"]="shop" if (i%3==0 or kind=="empobrecida") else "building_1"
		houses.append(cell)
	var start_z: float=32.0
	var service_guild: Dictionary=sites["guild"]
	var service_inn: Dictionary=sites["inn"]
	var service_training: Dictionary=sites["training"]
	var anchors: Dictionary={
		"npc":_entrance(service_guild,-0.8),
		"bed":_entrance(service_inn,1.8),
		"mat":_entrance(service_training,0.7),
		"camp":{"x":0.0,"z":start_z},
		"board":_entrance(service_guild,2.3)
	}
	var regional: RefCounted=WorldSeed.stream(world_data,"landscape/layout_v2","regions")
	return {"version":2,"kind":kind,"title":TITLES[kind],"roll":roll,"pattern":pattern,"sites":sites,"houses":houses,"anchors":anchors,
		"forest_offset":regional.between(-12.0,12.0),"highland_offset":regional.between(-12.0,12.0),"ruins_offset":regional.between(-8.0,8.0)}

static func _plot(world_data: Dictionary,slot: int) -> Dictionary:
	var rng: RefCounted=WorldSeed.stream(world_data,"landscape/layout_v2","building/%d"%slot)
	var column: int=slot%4
	var row: int=int(slot/4)
	var x: float=COLUMNS[column]+rng.between(-0.85,0.85)
	var z: float=ROWS[row]+rng.between(-1.0,1.0)
	return {"slot":slot,"x":x,"z":z,"width":rng.between(5.0,6.1)}

static func _entrance(cell: Dictionary,z_offset: float) -> Dictionary:
	var x: float=float(cell.x)
	return {"x":x+(4.9 if x<0 else -4.9),"z":float(cell.z)+z_offset}

static func anchor(plan: Dictionary,name: String) -> Vector3:
	var value: Dictionary=plan.anchors.get(name,{"x":0.0,"z":30.0})
	return Vector3(float(value.x),0.03,float(value.z))

static func safe_layout(plan: Dictionary) -> bool:
	if int(plan.get("version",0))!=2 or str(plan.get("kind","")) not in KINDS or str(plan.get("pattern","")) not in PATTERNS:return false
	if not plan.get("sites") is Dictionary or not plan.get("houses") is Array or not plan.get("anchors") is Dictionary:return false
	var used: Array=[]
	for role in ["guild","inn","training"]:
		if not plan.sites.has(role):return false
		var cell: Dictionary=plan.sites[role]
		if int(cell.get("slot",-1)) in used:return false
		used.append(int(cell.slot))
	for cell in plan.houses:
		if int(cell.get("slot",-1)) in used:return false
		used.append(int(cell.slot))
	for role in ["npc","bed","mat","camp","board"]:
		if not plan.anchors.has(role):return false
		var pos: Vector3=anchor(plan,role)
		if absf(pos.x)>36 or pos.z<17 or pos.z>65:return false
	return true
