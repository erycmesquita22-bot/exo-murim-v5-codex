extends RefCounted
## Changes only layout metrics and semantic scale; R2 topology preserved and version-pinned.
const V2=preload("res://exo_dungeon/generator/generator_v2.gd")
const Validator=preload("res://exo_dungeon/generator/validator_v3.gd")
const CELL_SPACING:=36.0
const FLOOR_HEIGHT:=12.0
const VERSION:=3
static func generate(spec: Dictionary) -> Dictionary:
 var original: Dictionary=V2.generate(spec)
 if not bool(original.get("ok",false)):return original
 var plan: Dictionary=original.duplicate(true)
 plan.generator_version=VERSION
 plan.render_metrics={"cell_spacing":CELL_SPACING,"floor_height":FLOOR_HEIGHT}
 for room in plan.rooms:
  var kind: String=str(room.kind)
  var width: float=12.0 if float(room.width)<=8.0 else (14.0 if float(room.width)<=10.0 else 16.0)
  if kind=="boss":width=28.0
  elif kind in ["training","combat","shrine"]:width=22.0
  elif kind=="stairs":width=18.0
  elif kind=="entrance":width=20.0
  room.width=width
  room.depth=width
  room.cx=float(room.gx)*CELL_SPACING
  room.cz=float(room.gz)*CELL_SPACING
  room["visual_archetype"]=kind
 var check: Dictionary=Validator.validate(plan)
 if not bool(check.get("ok",false)):
  return {"ok":false,"error":"v3_validation_failed","details":check.get("errors",[])}
 plan.digest=JSON.stringify([plan.id,plan.generator_version,plan.rooms,plan.links,plan.encounters,plan.rewards,plan.traps]).sha256_text()
 return plan


## R2: mesma topologia V2, mesma expansão V3, arquitetura revisada em versão 4.
## NÃO modificar generate() acima: instâncias V3 já exploradas dependem desse digest.
static func generate_r2(spec: Dictionary) -> Dictionary:
 var base: Dictionary=generate(spec)
 if not bool(base.get("ok",false)):return base
 base.generator_version=4
 base["architectural_revision"]=2
 base["geometry_contract"]="exo_architectural_masks_r2"
 base.digest=JSON.stringify([base.id,4,2,base.rooms,base.links,base.encounters,base.rewards,base.traps]).sha256_text()
 return base
