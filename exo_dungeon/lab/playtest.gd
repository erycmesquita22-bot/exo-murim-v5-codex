extends Node3D
## Laboratório independente, não modifica o personagem nem o input do EXO oficial.
const Generator=preload("res://exo_dungeon/generator/dungeon_generator.gd")
const Transition=preload("res://exo_dungeon/runtime/transition_service.gd")
const Exterior=preload("res://exo_dungeon/integration/exterior_entrance.gd")
const Explore=preload("res://exo_dungeon/runtime/exploration_logic.gd")
var exterior: Node3D
var character: CharacterBody3D
var trans: Variant
var cam: Camera3D
var hud: Label
var plan: Dictionary
var family: String="temple"
var world_seed:=81
func _ready() -> void:
 exterior=Node3D.new();exterior.name="Exterior";add_child(exterior)
 var floor_item:=Exterior.construct({"family":family,"region_id":14,"location_id":"lab","world_seed":world_seed,"world_id":"QA"},Vector3.ZERO)
 exterior.add_child(floor_item)
 character=CharacterBody3D.new()
 character.name="LabOnlyHero"
 character.collision_layer=2;character.collision_mask=1
 var capsule:=CollisionShape3D.new();var shape:=CapsuleShape3D.new();shape.radius=0.43;shape.height=2.1;capsule.shape=shape;character.add_child(capsule)
 var visual:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=Vector3(0.8,1.9,0.75);visual.mesh=box;character.add_child(visual)
 add_child(character);character.global_position=Vector3(0,1.5,3)
 trans=Transition.new();add_child(trans)
 cam=Camera3D.new();add_child(cam);cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.size=38;cam.current=true
 var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-50,-35,0);sun.light_energy=1.1;add_child(sun)
 var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("#1a222c");add_child(env)
 var canvas:=CanvasLayer.new();add_child(canvas);hud=Label.new();hud.position=Vector2(18,18);hud.add_theme_font_size_override("font_size",19);canvas.add_child(hud)
 _generate()
func _generate() -> void:
 plan=Generator.generate({"world_id":"QA","world_seed":world_seed,"region_id":14,"location_id":"lab","family":family,"floors":2,"rooms_per_floor":12,"difficulty":4})
func _physics_process(delta: float) -> void:
 if not is_instance_valid(character):return
 var heading:=Vector2.ZERO
 if Input.is_key_pressed(KEY_W):heading.y-=1
 if Input.is_key_pressed(KEY_S):heading.y+=1
 if Input.is_key_pressed(KEY_A):heading.x-=1
 if Input.is_key_pressed(KEY_D):heading.x+=1
 var v:=heading.normalized()
 character.velocity.x=v.x*9.0
 character.velocity.z=v.y*9.0
 character.velocity.y-=24.0*delta
 character.move_and_slide()
 cam.global_position=character.global_position+Vector3(25,32,25)
 cam.look_at(character.global_position)
 if trans.active():
  var nearby: Dictionary=Explore.nearby(trans.current.get("instance"),character)
  hud.text="EXO DUNGEON 02 - LAB (não é EXO Core)\nWASD: mover | E: interagir | R: reiniciar seed\nDentro: "+family+" / "+str(nearby.get("kind",""))
 else:hud.text="EXO DUNGEON 02 - LAB (não é EXO Core)\nWASD: mover | E: entrar | R: nova seed\nExterior: "+family
func _unhandled_key_input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.pressed or event.echo:return
 if event.keycode==KEY_R and not trans.active():world_seed+=1;_generate()
 if event.keycode!=KEY_E:return
 if not trans.active():
  var result: Dictionary=trans.enter(self,character,exterior,Vector3(0,1.5,3),plan)
  if result.get("ok",false):result["instance"].connect("transition_requested",Callable(self,"_floor_change"))
  return
 var instance: Variant=trans.current.get("instance")
 var choice: Dictionary=Explore.nearby(instance,character)
 match str(choice.get("kind","none")):
  "key":
   for room in plan.rooms:
    if room.get("keys",[]).has(str(choice.key_id)):
     instance.collect_key(str(room.id),str(choice.key_id),character)
     break
  "gate":instance.unlock_gate(str(choice.gate_id),character)
  "secret":instance.reveal_secret(str(choice.room_id))
  "floor":instance.request_floor_transition(str(choice.room_id),character)
  "exit":trans.leave()
func _floor_change(_from: String,to: String,actor: Node3D) -> void:
 var instance: Variant=trans.current.get("instance")
 actor.global_position=instance.to_global(instance.transition_anchor(to)+Vector3(0,1.2,0))
 if actor is CharacterBody3D:(actor as CharacterBody3D).velocity=Vector3.ZERO
 instance.acknowledge_floor_transition(actor)
