extends RefCounted
const Stream=preload("res://procedural/seed_stream.gd")
const ORIGINS=["campones","mercador","viajante","artesao","refugiado","desconhecida"]
const CONDITIONS=["caminho_seguro","perda_recente","apoio_local","familia_distante","nenhuma_pista"]
static func build(seed: String,character_id: String) -> Dictionary:
	var r=Stream.new(Stream.hash_value("EXO|NARRATIVE|DESTINY|1|"+seed+"|"+character_id))
	var origin: String=ORIGINS[r.below(ORIGINS.size())]
	var condition: String=CONDITIONS[r.below(CONDITIONS.size())]
	# Optional hooks only, never assert a relationship to divine heroes.
	var thread: String="sem_indicios" if r.below(100)<82 else "registro_historico_possivel"
	return {"version":1,"origin":origin,"condition":condition,"hero_thread":thread,"revealed":false}
