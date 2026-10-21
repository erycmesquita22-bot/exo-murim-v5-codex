extends Node3D
## MOCKS DE QA, não substituir Combat/Itens, não registrar loot ou XP.
## Sinaliza eventos a um observador do laboratório. Efeitos são deliberadamente inertes.
signal trap_triggered(mock_id: String,actor: Node3D)
signal encounter_entered(mock_id: String,actor: Node3D)
signal reward_requested(mock_id: String,actor: Node3D)
var zones: Dictionary={}
func add_trigger(mock_id: String,kind: String,point: Vector3,dimensions: Vector3) -> Area3D:
 if kind not in ["trap","encounter","reward"] or zones.has(mock_id):return null
 var area:=Area3D.new()
 area.name="MOCK_"+kind+"_"+mock_id
 area.position=point
 area.collision_layer=0
 area.collision_mask=2
 area.monitoring=true
 var collision:=CollisionShape3D.new()
 var shape:=BoxShape3D.new()
 shape.size=dimensions
 collision.shape=shape
 area.add_child(collision)
 add_child(area)
 area.body_entered.connect(Callable(self,"_entered").bind(mock_id,kind))
 zones[mock_id]=area
 return area
func _entered(body: Node3D,mock_id: String,kind: String) -> void:
 if not body is CharacterBody3D:return
 match kind:
  "trap":trap_triggered.emit(mock_id,body)
  "encounter":encounter_entered.emit(mock_id,body)
  "reward":reward_requested.emit(mock_id,body)
## Sem inventário, IA ou HP paralelo; o host define a consequência.
