extends RefCounted
# Deterministic world-design layer. No meshes, gameplay nodes or global RNG here.
# Layout v1 is separate from loot generation v1: new cosmetics do not reroll items.
const WorldSeed=preload("res://procedural/world_state.gd")
const V2=preload("res://world/village_layout_v2.gd")
const LAYOUT_VERSION=1
const KINDS=["empobrecida","comum","prospera","especial"]
const TITLES={"empobrecida":"Aldeia das Dificuldades","comum":"Aldeia do Primeiro Eco","prospera":"Aldeia das Rotas Douradas","especial":"Aldeia dos Ecos Ocultos"}
const SLOT_POINTS=[Vector2(-13,49),Vector2(13,49),Vector2(-25,43),Vector2(25,43),Vector2(-33,28),Vector2(33,28),Vector2(-33,43),Vector2(33,43)]
static func create(w: Dictionary) -> Dictionary:
	if int(w.get("landscape_version",1))>=2:return V2.create(w)
	var rng: RefCounted=WorldSeed.stream(w,"landscape/layout_v1","village/birth")
	var roll: int=rng.below(100)
	var kind: String="comum"
	if roll<20:kind="empobrecida"
	elif roll>=70 and roll<95:kind="prospera"
	elif roll>=95:kind="especial"
	var slots: Array=[]
	for i in range(SLOT_POINTS.size()):slots.append(i)
	var shuffle: RefCounted=WorldSeed.stream(w,"landscape/layout_v1","village/plots")
	for i in range(slots.size()-1,0,-1):
		var j: int=shuffle.below(i+1)
		var swap: int=slots[i];slots[i]=slots[j];slots[j]=swap
	var count: int=2 if kind=="empobrecida" else 4 if kind=="comum" else 7 if kind=="prospera" else 5
	var houses: Array=[]
	for i in range(count):
		var idx: int=slots[i]
		var jitter: RefCounted=WorldSeed.stream(w,"landscape/layout_v1","plot_%d"%idx)
		houses.append({"slot":idx,"x":SLOT_POINTS[idx].x+jitter.between(-.9,.9),"z":SLOT_POINTS[idx].y+jitter.between(-.9,.9),"width":jitter.between(4.3,5.5),"asset":"shop" if kind=="empobrecida" and i%2==0 else "building_1" if i%3!=0 else "shop"})
	var scenery: RefCounted=WorldSeed.stream(w,"landscape/layout_v1","regional_identity")
	return {"version":LAYOUT_VERSION,"kind":kind,"title":TITLES[kind],"roll":roll,"houses":houses,"forest_offset":scenery.between(-12,12),"highland_offset":scenery.between(-12,12),"ruins_offset":scenery.between(-8,8)}
static func safe_layout(plan: Dictionary) -> bool:
	if int(plan.get("version",1))==2:return V2.safe_layout(plan)
	if plan.get("version")!=LAYOUT_VERSION or plan.get("kind") not in KINDS:return false
	var slots: Array=[]
	for house in plan.get("houses",[]):
		if not house is Dictionary or house.get("slot") in slots or int(house.get("slot",-1))<0 or int(house.get("slot",-1))>=SLOT_POINTS.size():return false
		if absf(float(house.get("x",0)))<10 or float(house.get("z",0))<25:return false
		slots.append(house.slot)
	return true
