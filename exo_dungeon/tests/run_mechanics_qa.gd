extends SceneTree
## Suite nativa recomendada, testando geometria, colisores e contratos de interacao.
## godot --headless --path . --script res://exo_dungeon/tests/run_mechanics_qa.gd
const Generator=preload("res://exo_dungeon/generator/dungeon_generator.gd")
const Dungeon=preload("res://exo_dungeon/runtime/dungeon_instance.gd")
const Validator=preload("res://exo_dungeon/generator/connectivity_validator.gd")
var failures: Array[String]=[]
var checked: int=0
func _initialize() -> void:
 call_deferred("_run")
func _check(ok: bool,message: String) -> void:
 if not ok and failures.size()<150:failures.append(message)
func _run() -> void:
 for family in ["ruins","cavern","temple","sect_hideout","mine","tomb"]:
  for index in range(24):
   var request: Dictionary={"world_id":"QA","world_seed":index*73,"region_id":14,"location_id":"mechanics_"+str(index),"family":family,"floors":2,"rooms_per_floor":18}
   var plan: Dictionary=Generator.generate(request)
   if not bool(plan.get("ok",false)):
    _check(false,"generation:"+family+":"+str(index))
    continue
   checked+=1
   _check(bool(Validator.validate(plan).ok),"validator:"+family+":"+str(index))
   var instance= Dungeon.new()
   get_root().add_child(instance)
   _check(instance.materialize(plan),"materialize:"+family+":"+str(index))
   var corridor_count:=0
   var gate_count:=0
   for link in plan.links:
    if str(link.kind)=="corridor":corridor_count+=1
    if not str(link.get("requires","")).is_empty():gate_count+=1
   var rendered_rails: int=instance.find_children("CorridorRail","Node3D",true,false).size()
   _check(rendered_rails==corridor_count*2,"missing_corridor_rails:"+family+":"+str(index))
   _check(instance.find_children("LockedSeal_*","Node3D",true,false).size()==gate_count,"missing_gate_physics:"+family+":"+str(index))
   var actor:=Node3D.new()
   get_root().add_child(actor)
   for room in plan.rooms:
    for key in room.get("keys",[]):
     actor.global_position=Vector3(float(room.cx)-2.4,float(room.floor)*float(plan.get("render_metrics",{}).get("floor_height",9.0))+0.4,float(room.cz)+2.2)
     _check(instance.collect_key(str(room.id),str(key),actor),"cannot_take_key:"+str(key))
     _check(not instance.collect_key(str(room.id),str(key),actor),"duplicate_take_key:"+str(key))
   var room_map: Dictionary={}
   for room in plan.rooms:room_map[str(room.id)]=room
   for link in plan.links:
    if str(link.get("requires","")).is_empty():continue
    var a: String=str(link.a)
    var b: String=str(link.b)
    var gate: String=a+"~"+b if a<b else b+"~"+a
    var ra: Dictionary=room_map[a]
    var rb: Dictionary=room_map[b]
    actor.global_position=Vector3((float(ra.cx)+float(rb.cx))*0.5,float(ra.floor)*float(plan.get("render_metrics",{}).get("floor_height",9.0))+1.0,(float(ra.cz)+float(rb.cz))*0.5)
    _check(instance.unlock_gate(gate,actor),"cannot_open_gate:"+gate)
    _check(not instance.unlock_gate(gate,actor),"double_open_gate:"+gate)
   var remaining_gates:=0
   for seal in instance.find_children("LockedSeal_*","Node3D",true,false):
    if not seal.is_queued_for_deletion():remaining_gates+=1
   _check(remaining_gates==0,"locked_seals_remain_after_unlock:"+family+":"+str(index))
   for link in plan.links:
    if str(link.get("kind",""))!="stairs_portal":continue
    var source: String=str(link.a)
    var target_room: Dictionary=room_map[source]
    actor.global_position=Vector3(float(target_room.cx),float(target_room.floor)*float(plan.get("render_metrics",{}).get("floor_height",9.0))+0.2,float(target_room.cz))
    _check(instance.request_floor_transition(source,actor),"portal_did_not_request")
    _check(not instance.request_floor_transition(source,actor),"duplicate_portal_request")
    instance.acknowledge_floor_transition(actor)
   get_root().remove_child(actor)
   actor.free()
   get_root().remove_child(instance)
   instance.free()
 var report: Dictionary={"suite":"dungeon_genesis_mechanics","checked":checked,"failures":failures,"result":"PASS" if failures.is_empty() else "FAIL"}
 print("DUNGEON_MECHANICS="+JSON.stringify(report))
 quit(0 if failures.is_empty() else 1)
