extends RefCounted
## Dispatch by generator version: preserves v2 explored dungeons without reroll.
const V2=preload("res://exo_dungeon/generator/generator_v2.gd")
const V3=preload("res://exo_dungeon/generator/generator_v3.gd")
static func identity(spec: Dictionary) -> String:
 return V2.identity(spec)
static func generate(spec: Dictionary) -> Dictionary:
 var version: int=int(spec.get("generator_version",4))
 if version==2:return V2.generate(spec)
 if version==3:return V3.generate(spec)
 if version==4:return V3.generate_r2(spec)
 return {"ok":false,"error":"unsupported_generator_version"}
