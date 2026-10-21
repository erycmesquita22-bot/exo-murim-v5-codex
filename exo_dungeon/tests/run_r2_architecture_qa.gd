extends SceneTree
## Preparado para Godot 4.6.2 headless; NÃO executado fora da Godot.
const Generator=preload("res://exo_dungeon/generator/dungeon_generator.gd")
const Masks=preload("res://exo_dungeon/layouts/architectural_blueprint.gd")
const Renderer=preload("res://exo_dungeon/runtime/dungeon_renderer.gd")
const Validator=preload("res://exo_dungeon/generator/validator_v3.gd")
var failures: Array[String]=[]
var generated:=0
func _initialize() -> void:
 call_deferred("_run")
func _check(ok: bool,why: String) -> void:
 if not ok and failures.size()<80:failures.append(why)
func _run() -> void:
 var masks: Dictionary={}
 for family in ["ruins","cavern","temple","sect_hideout","mine","tomb"]:
  var shapes: Dictionary={}
  for seed in range(16):
   var spec: Dictionary={"world_id":"R2_QA","world_seed":seed,"region_id":12,"location_id":"q"+str(seed),"family":family,"floors":1+seed%2,"rooms_per_floor":8+seed%8,"difficulty":3}
   var plan: Dictionary=Generator.generate(spec)
   _check(bool(plan.get("ok",false)),"generation:"+family+str(seed))
   if not bool(plan.get("ok",false)):continue
   generated+=1
   _check(int(plan.generator_version)==4,"not_v4")
   _check(bool(Validator.validate(plan).ok),"topology:"+family)
   var data: Dictionary=Masks.mask(plan.rooms[0],family)
   _check(Masks.connected(data),"mask_disconnected:"+family)
   var sig: String=JSON.stringify(data.tiles.keys()).sha256_text()
   shapes[sig]=true
   if seed==0:
    var scene: Node3D=Renderer.build(plan,{})
    _check(scene!=null,"renderer_null:"+family)
    if scene!=null:
     var stats: Dictionary=scene.get_meta("batch_stats",{})
     _check(int(stats.get("static_bodies",0))<int(stats.get("blocks_merged",0)),"no_body_batching:"+family)
     _check(int(stats.get("colliders",0))<=int(stats.get("sectors",0)),"sector_colliders:"+family)
     scene.free()
  masks[family]=shapes.size()
 # Verifica roteamento imutável do legado e identidade de R2.
 var base: Dictionary={"world_id":"R2_QA","world_seed":19,"region_id":12,"location_id":"identity","family":"temple","floors":2,"rooms_per_floor":10,"difficulty":1}
 var v2: Dictionary=base.duplicate(true);v2.generator_version=2
 var v3: Dictionary=base.duplicate(true);v3.generator_version=3
 _check(int(Generator.generate(v2).get("generator_version",0))==2,"v2_broken")
 _check(int(Generator.generate(v3).get("generator_version",0))==3,"v3_broken")
 var report: Dictionary={"suite":"native_r2_architecture","generated":generated,"family_shape_signatures":masks,"failures":failures,"status":"PASS" if failures.is_empty() else "FAIL"}
 print("DUNGEON_R2_ARCH_QA="+JSON.stringify(report))
 quit(0 if failures.is_empty() else 1)
