extends RefCounted
# Generates data only: does not spawn actors or assign world coordinates.
# The Forja provides a stable list of named building/occupation slots.
const Stream=preload("res://procedural/seed_stream.gd")
const Names=preload("res://living_world/names.gd")
static var PEOPLE: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://living_world/data/people.json"))

static func create(seed_text: String, region_id: int, slot: Dictionary, difficulty: int=1) -> Dictionary:
	var slot_id: String=str(slot.get("id",""))
	if slot_id.is_empty() or slot_id.length()>80:return {}
	var role: String=str(slot.get("role","resident"))
	if not PEOPLE.roles.has(role):return {}
	var spec: Dictionary=PEOPLE.roles[role]
	var identity: Dictionary=Names.generate(seed_text,region_id,slot_id,role)
	var stream: RefCounted=Stream.new(Stream.hash_value("EXO|LIVING|PERSON|1|%s|%d|%s"%[seed_text,region_id,slot_id]))
	var level: int=clampi(1+maxi(0,difficulty-1)*3+stream.below(3),1,30)
	var attrs: Dictionary={}
	var i: int=0
	for attr in PEOPLE.attributes:
		attrs[str(attr)]=clampi(int(spec.stats[i])+int(level/5)+stream.below(3),0,30)
		i+=1
	var appearance: Dictionary={"race":clampi(int(slot.get("race",0)),0,11),"robe":stream.below(6),
		"hair":stream.below(6),"skin":stream.below(6),"style":stream.below(3),"voice":stream.below(3)}
	appearance.skin3d=preload("res://exo_skin3d/appearance_adapter.gd").npc_cosmetics("npc/r%02d/%s"%[region_id,slot_id],role,str(spec.faction),seed_text)
	return {"id":"npc/r%02d/%s"%[region_id,slot_id],"generation_version":1,
		"slot_id":slot_id,"region_id":region_id,"role":role,"faction":str(spec.faction),
		"name":identity.name,"display_name":identity.display_name,
		"prefix":identity.prefix,"suffix":identity.suffix,
		"level":level,"attributes":attrs,"appearance":appearance,"work_slot":str(slot.get("work_slot",slot_id)),
		"home_slot":str(slot.get("home_slot","")),"active":true,
		"martial_site_id":str(slot.get("martial_site_id","")),"martial_school_id":str(slot.get("martial_school_id",""))}

static func roster(seed_text: String, region_id: int, slots: Array, difficulty: int=1) -> Array:
	# Sorting avoids name collision outcomes that depend on generation order.
	var ordered: Array=slots.duplicate(true)
	ordered.sort_custom(func(a,b):return str(a.get("id",""))<str(b.get("id","")))
	var seen_ids: Dictionary={}
	var seen_names: Dictionary={}
	var result: Array=[]
	for slot in ordered:
		if not slot is Dictionary:continue
		var npc: Dictionary=create(seed_text,region_id,slot,difficulty)
		if npc.is_empty() or seen_ids.has(npc.id):continue
		seen_ids[npc.id]=true
		if seen_names.has(npc.display_name):
			# Stable honorific based on the actual slot, not an arbitrary new name.
			npc.display_name+=" · "+str(npc.slot_id)
		seen_names[npc.display_name]=true
		result.append(npc)
	return result

static func activity(npc: Dictionary,hour: int) -> String:
	var h: int=posmod(hour,24)
	if h<5 or h>=21:return "descanso" if not str(npc.get("home_slot","")).is_empty() else "fora_de_servico"
	var role: String=str(npc.get("role","resident"))
	if role in ["guard","outlaw"]:return "ronda" if h<9 or h>=18 else "posto"
	if role in ["master","disciple"]:return "treino" if h<12 else "meditacao" if h<16 else "convivio"
	if role=="farmer":return "plantio" if h<12 else "colheita" if h<18 else "convivio"
	if role=="courier":return "viagem" if h>=7 and h<19 else "espera"
	return "trabalho" if h>=8 and h<18 else "convivio"
