extends Node
## Instância em cena própria: mantém o MESMO player no parent original (câmera, HUD, scripts).
## Compatível com integração explícita. Não supõe scene changer ou save API fictícia.
const INTERIOR=preload("res://exo_dungeon/runtime/interior_root.tscn")
const Presentation=preload("res://exo_dungeon/runtime/dungeon_presentation.gd")
signal entered(dungeon_id: String)
signal left(dungeon_id: String)
signal failure(code: String)
var current: Node3D
var current_actor: Node3D
var outside_parent: Node
var outside_scene: Node3D
var outside_position: Vector3
var outside_process_mode: int=Node.PROCESS_MODE_INHERIT
var scene_visibility:=true
var colliders: Array=[]
var dungeon_id: String=""
func active() -> bool:
 return is_instance_valid(current)
func _suspend_exterior(scene: Node3D) -> void:
 outside_process_mode=scene.process_mode
 scene_visibility=scene.visible
 scene.visible=false
 scene.process_mode=Node.PROCESS_MODE_DISABLED
 colliders=[]
 for body in scene.find_children("*","CollisionObject3D",true,false):
  if body is CollisionObject3D:
   colliders.append({"ref":weakref(body),"layer":body.collision_layer,"mask":body.collision_mask})
   body.collision_layer=0
   body.collision_mask=0
 if scene is CollisionObject3D:
  var cb: CollisionObject3D=scene as CollisionObject3D
  colliders.append({"ref":weakref(cb),"layer":cb.collision_layer,"mask":cb.collision_mask})
  cb.collision_layer=0
  cb.collision_mask=0
func _resume_exterior() -> void:
 if is_instance_valid(outside_scene):
  outside_scene.visible=scene_visibility
  outside_scene.process_mode=outside_process_mode
 for state in colliders:
  var obj: Object=state["ref"].get_ref()
  if is_instance_valid(obj):
   (obj as CollisionObject3D).collision_layer=state.layer
   (obj as CollisionObject3D).collision_mask=state.mask
 colliders=[]
func enter(host: Node3D,actor: Node3D,exterior: Node3D,anchor: Vector3,plan: Dictionary,persisted: Dictionary={}) -> Dictionary:
 if active():return {"ok":false,"error":"already_inside"}
 if not is_instance_valid(host) or not is_instance_valid(actor) or not is_instance_valid(exterior):return {"ok":false,"error":"missing_host_or_actor"}
 if actor==exterior or not host.is_ancestor_of(actor) or not host.is_ancestor_of(exterior):return {"ok":false,"error":"actor_not_in_host"}
 if exterior.is_ancestor_of(actor):return {"ok":false,"error":"actor_inside_suspended_subtree"}
 if actor.global_position.distance_to(anchor)>6.0:return {"ok":false,"error":"actor_too_far_from_entrance"}
 var interior: Variant=INTERIOR.instantiate()
 host.add_child(interior)
 # Isolamento espacial: a região externa não compartilha volume de colisão.
 interior.position=Vector3(0,4096,0)
 if not bool(interior.call("initialize",plan,persisted)):
  interior.queue_free()
  failure.emit("materialization_failed")
  return {"ok":false,"error":"materialization_failed"}
 outside_parent=actor.get_parent()
 outside_scene=exterior
 outside_position=anchor
 current_actor=actor
 dungeon_id=str(plan.id)
 # Nunca reparentar o player oficial: o Game original usa player.position local.
 _suspend_exterior(exterior)
 current=interior
 actor.global_position=interior.to_global(interior.call("entry_spawn"))
 if actor is CharacterBody3D:(actor as CharacterBody3D).velocity=Vector3.ZERO
 # Generic standalone hosts have no camera. The integrated EXO host does.
 if host.get("camera") is Camera3D:
  var view:Node=Presentation.new();view.name="DungeonPresentation";interior.add_child(view)
  view.initialize(host,actor,interior.get("instance"))
 entered.emit(dungeon_id)
 return {"ok":true,"dungeon_id":dungeon_id,"scene":interior,"instance":interior.get("instance")}
func abort() -> void:
 # Falha, morte ou shutdown nunca deixam a região invisível permanentemente.
 if not active():return
 _restore_presentation()
 if is_instance_valid(current_actor) and current_actor.is_inside_tree():
  current_actor.global_position=outside_position
 _resume_exterior()
 current.queue_free()
 current=null
 current_actor=null
 outside_scene=null
 outside_parent=null
 dungeon_id=""
func leave() -> bool:
 if not active():return false
 if not is_instance_valid(current_actor) or not is_instance_valid(outside_parent):
  abort()
  failure.emit("actor_or_parent_missing")
  return false
 var old_id:=dungeon_id
 var actor:=current_actor
 if not is_instance_valid(outside_parent):return false
 _restore_presentation()
 _resume_exterior()
 actor.global_position=outside_position
 if actor is CharacterBody3D:(actor as CharacterBody3D).velocity=Vector3.ZERO
 current.queue_free()
 current=null
 current_actor=null
 outside_scene=null
 outside_parent=null
 dungeon_id=""
 left.emit(old_id)
 return true
func _restore_presentation()->void:
 if not is_instance_valid(current):return
 var view:Node=current.get_node_or_null("DungeonPresentation")
 if is_instance_valid(view):view.restore()
