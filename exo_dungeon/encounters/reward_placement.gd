extends RefCounted
## Pontos de possível recompensa, NÃO itens gerados nem concedidos.
static func make(rooms: Array,family: String,seed_key: String) -> Array:
 var rng:=RandomNumberGenerator.new();rng.seed=int(("rewards|"+seed_key).hash())
 var out: Array=[]
 for room in rooms:
  if str(room.kind) not in ["treasure","secret","boss","resource","shrine"]:continue
  out.append({"id":"reward_"+str(room.id),"room":str(room.id),"source_type":family,"rarity_tier":3 if room.kind=="boss" else (2 if room.kind=="secret" else rng.randi_range(0,1)),"item_id":"","status":"pending_item_catalog"})
 return out
