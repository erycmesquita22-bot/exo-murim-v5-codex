extends RefCounted
# Optional narrative threads. Does not grant a forced lineage or superpowers.
const Stream=preload("res://procedural/seed_stream.gd")
const OPTIONS=["nenhuma_ligacao_aparente","eco_distante","testemunho_perdido","trilha_de_artefatos"]
const QUIRKS=["persistente","observador","impulsivo","reservado","curioso","disciplinado"]

static func generate(seed_text: String,character_id: String) -> Dictionary:
	var s: RefCounted=Stream.new(Stream.hash_value("EXO|DESTINO|1|%s|%s"%[seed_text,character_id]))
	var fate_roll: int=s.below(100)
	var thread: String=OPTIONS[0]
	if fate_roll>=72 and fate_roll<85:thread=OPTIONS[1]
	elif fate_roll>=85 and fate_roll<95:thread=OPTIONS[2]
	elif fate_roll>=95:thread=OPTIONS[3]
	var quirk: String=QUIRKS[s.below(QUIRKS.size())]
	return {"version":1,"thread":thread,"personality":quirk,"clues":[],"revealed":false}

static func add_clue(fate: Dictionary,clue: String) -> bool:
	if clue.is_empty() or clue.length()>80 or clue in fate.get("clues",[]):return false
	fate.clues.append(clue)
	return true
