extends RefCounted
static func make(rooms: Array,seed_key: String) -> Array:
 var rng:=RandomNumberGenerator.new();rng.seed=int(("traps|"+seed_key).hash())
 var out: Array=[]
 for room in rooms:
  if str(room.kind) not in ["trap","natural_hazard","puzzle"]:continue
  out.append({"id":"trap_"+str(room.id),"room":str(room.id),"kind":["pressure_plate","falling_stones","unstable_floor"][rng.randi_range(0,2)],"hint":"visible_marking","damage_owner":"existing_combat","status":"descriptor_only"})
 return out
