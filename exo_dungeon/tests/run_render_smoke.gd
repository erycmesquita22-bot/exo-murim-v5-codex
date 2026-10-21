extends SceneTree
const Generator=preload("res://exo_dungeon/generator/dungeon_generator.gd")
const Instance=preload("res://exo_dungeon/runtime/dungeon_instance.gd")
func _initialize() -> void:
 call_deferred("_run")
func _run() -> void:
 var result: Array=[];var failed:=false
 for family in ["ruins","cavern","temple","sect_hideout","mine","tomb"]:
  var start: int=Time.get_ticks_usec()
  var plan: Dictionary=Generator.generate({"world_id":"QA","world_seed":7,"region_id":14,"location_id":"render_test","family":family,"floors":2,"rooms_per_floor":11})
  var dungeon: Node3D=Instance.new();get_root().add_child(dungeon)
  var ok: bool=dungeon.materialize(plan)
  var geometry_count: int=0
  if ok:geometry_count=dungeon.find_children("*","MeshInstance3D",true,false).size()
  if not ok:failed=true
  result.append({"family":family,"rendered":ok,"mesh_count":geometry_count,"duration_ms":float(Time.get_ticks_usec()-start)/1000.0})
  get_root().remove_child(dungeon);dungeon.free()
 print("DUNGEON_RENDER_SMOKE="+JSON.stringify(result))
 quit(1 if failed else 0)
