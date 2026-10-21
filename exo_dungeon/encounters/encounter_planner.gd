extends RefCounted
const Catalog=preload("res://exo_dungeon/layouts/room_catalog.gd")
## Descritores somente. Nenhuma IA ou entidade funcional é criada aqui.
static func make(rooms: Array,family: String,seed_key: String,level: int) -> Array:
 var rng:=RandomNumberGenerator.new();rng.seed=int(("encounters|"+seed_key).hash())
 var out: Array=[];var tags: Array=Catalog.profile(family).get("enemy_tags",[])
 for room in rooms:
  if str(room.kind) not in ["combat","boss","training","natural_hazard"]:continue
  var enemies:=1 if room.kind=="boss" else rng.randi_range(1,3)
  out.append({"id":"enc_"+str(room.id),"room":str(room.id),"allowed_tags":tags.duplicate(),"count":enemies,"level_min":maxi(1,level-1),"level_max":level+2,"activation":"on_enter","safe_radius":3.0,"respawn":"external_policy","status":"descriptor_only"})
 return out
