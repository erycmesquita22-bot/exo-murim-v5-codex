extends RefCounted
## Converte apenas dados aprovados pela localização exterior; não gera regiões.
static func descriptor(world_id: String,world_seed: Variant,region_id: int,location_id: String,family: String,floors: int=1,difficulty: int=1) -> Dictionary:
 return {"world_id":world_id,"world_seed":str(world_seed),"region_id":region_id,"location_id":location_id,"family":family,"floors":floors,"rooms_per_floor":11,"difficulty":difficulty}
