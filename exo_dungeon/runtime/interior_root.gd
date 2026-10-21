extends Node3D
## Cena separada: possui a geometria materializada e um único ator migrado.
const Instance=preload("res://exo_dungeon/runtime/dungeon_instance.gd")
var instance: Node3D
func initialize(plan: Dictionary,persisted: Dictionary={}) -> bool:
 if is_instance_valid(instance):return false
 var dungeon: Variant=Instance.new()
 add_child(dungeon)
 if not dungeon.materialize(plan,persisted):
  remove_child(dungeon)
  dungeon.queue_free()
  return false
 instance=dungeon
 return true
func entry_spawn() -> Vector3:
 if instance==null:return Vector3.ZERO
 return instance.call("exit_anchor")+Vector3(0,1.3,0)
