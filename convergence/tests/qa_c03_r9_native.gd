extends SceneTree
# Native script/parser smoke only: never describe as an end-to-end gameplay PASS.
const Catalog=preload("res://exo_martial/styles/martial_catalog.gd")
const State=preload("res://exo_martial/r2/state_r2.gd")
const Occupancy=preload("res://convergence/martial_occupancy_r9.gd")
const Physical=preload("res://convergence/martial_sites_r9.gd")
const Host=preload("res://convergence/martial_host_r8.gd")
const MartialEngine=preload("res://exo_martial/r2/engine_r2.gd")
func _initialize() -> void:
 var passed:bool=true
 var ids:Dictionary={}
 for school in Catalog.schools():ids[str(school.id)]=true
 if ids.size()!=9 or Catalog.styles().size()!=12 or Catalog.techniques().size()!=16:
  passed=false;push_error("R9 native: official catalog modified")
 var site:String="r26_martial_medium_v1"
 var initial:String=Occupancy.school_for_site("816204",site,"")
 if initial.is_empty() or not ids.has(initial) or initial!=Occupancy.school_for_site("816204",site,""):
  passed=false;push_error("R9 native: deterministic school failure")
 if Occupancy.school_for_site("816204",site,"invalid_school")!="":
  passed=false;push_error("R9 native: unauthorized school accepted")
 if not State.valid(State.fresh("101")):
  passed=false;push_error("R9 native: martial schema invalid")
 if not Host.new().has_method("handle_training_station") or not Host.new().has_method("tick_training"):
  passed=false;push_error("R9 native: missing trusted training hooks")
 if not MartialEngine.new().has_method("record_action"):
  passed=false;push_error("R9 native: missing existing state machine")
 print("C03_R9_NATIVE_CONTRACT ","PASS" if passed else "FAIL","; not gameplay proof")
 quit(0 if passed else 1)
