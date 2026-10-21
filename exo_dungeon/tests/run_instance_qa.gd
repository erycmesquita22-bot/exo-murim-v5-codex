extends SceneTree
## Nativo: cria a mesma cena independente e troca o MESMO ator sem duplicação.
const Generator=preload("res://exo_dungeon/generator/dungeon_generator.gd")
const Transition=preload("res://exo_dungeon/runtime/transition_service.gd")
const State=preload("res://exo_dungeon/persistence/dungeon_state.gd")
const Validator=preload("res://exo_dungeon/generator/connectivity_validator.gd")
var fails: Array[String]=[]
var cases:=0
func _initialize() -> void:
 call_deferred("_run")
func check(assertion: bool,message: String) -> void:
 if not assertion and fails.size()<120:fails.append(message)
func _run() -> void:
 var world:=Node3D.new()
 get_root().add_child(world)
 var exterior:=Node3D.new()
 exterior.name="Exterior"
 world.add_child(exterior)
 var body:=StaticBody3D.new()
 body.collision_layer=1
 exterior.add_child(body)
 var actor:=CharacterBody3D.new()
 actor.collision_layer=2
 world.add_child(actor)
 actor.global_position=Vector3(0,1,0)
 var original_id:=actor.get_instance_id()
 var host: Variant=Transition.new()
 world.add_child(host)
 for family in ["ruins","cavern","temple","sect_hideout","mine","tomb"]:
  for seed in range(8):
   cases+=1
   var req: Dictionary={"world_id":"QA","world_seed":seed,"region_id":14,"location_id":"ENTRY"+str(seed),"family":family,"floors":1+seed%3,"rooms_per_floor":8+seed%12,"difficulty":3}
   var plan: Dictionary=Generator.generate(req)
   check(bool(plan.get("ok",false)),"generate:"+family+str(seed))
   if not bool(plan.get("ok",false)):continue
   check(Validator.validate(plan).ok,"validate:"+family+str(seed))
   var prior: Dictionary=State.blank()
   var snapshot: Dictionary=State.instance(prior,"QA",3)
   var entered: Dictionary=host.enter(world,actor,exterior,Vector3(0,1,0),plan,snapshot)
   check(bool(entered.get("ok",false)),"enter:"+family+str(seed))
   if not bool(entered.get("ok",false)):continue
   check(actor.get_instance_id()==original_id,"player_duplicated")
   check(not exterior.visible and body.collision_layer==0,"exterior_not_suspended")
   check(not host.enter(world,actor,exterior,Vector3(0,1,0),plan).ok,"double_enter")
   check(actor.global_position.y>4000.0,"interior_not_isolated")
   check(host.leave(),"leave:"+family+str(seed))
   check(not host.active(),"active_after_leave")
   check(exterior.visible and body.collision_layer==1,"exterior_not_restored")
   check(actor.global_position.distance_to(Vector3(0,1,0))<0.001,"incorrect_return_anchor")
 check(not host.leave(),"double_leave")
 var report: Dictionary={"suite":"dungeon02_native_instance","cases":cases,"failures":fails,"status":"PASS" if fails.is_empty() else "FAIL"}
 print("DUNGEON_INSTANCE_QA="+JSON.stringify(report))
 quit(0 if fails.is_empty() else 1)
