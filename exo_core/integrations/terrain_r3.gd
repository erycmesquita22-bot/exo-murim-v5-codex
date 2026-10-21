extends RefCounted
const Resolver=preload("res://exo_terrain_forge/r3/terrain_material_resolver.gd")
func initialize(host:RefCounted)->bool:
 return host.services.register_service("terrain.resolution","terrain_r3",self,["preview"],"1.0.0")
func preview(biome:String,moisture:float,elevation:float,paved:bool,x:int,z:int,seed:int)->Dictionary:
 return Resolver.resolve(biome,moisture,elevation,paved,x,z,seed)
func shutdown()->void:
 pass
