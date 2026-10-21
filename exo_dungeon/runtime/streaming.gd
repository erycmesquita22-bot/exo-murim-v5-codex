extends RefCounted
## Somente um interior materializado; instanciamento sob demanda.
const Instance=preload("res://exo_dungeon/runtime/dungeon_instance.gd")
var active: Node3D
func enter(parent: Node3D,plan: Dictionary) -> Dictionary:
 if active!=null:return {"ok":false,"error":"already_inside"}
 var room: Node3D=Instance.new()
 if not room.materialize(plan):room.queue_free();return {"ok":false,"error":"invalid_plan"}
 parent.add_child(room);active=room
 return {"ok":true,"node":room,"entry_anchor":room.exit_anchor()}
func leave() -> bool:
 if active==null:return false
 active.queue_free();active=null
 return true
