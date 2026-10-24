extends Node3D
const Actor = preload("res://modules/village_life/wildlife_actor.gd")
var host: Node3D
var creatures: Dictionary = {}
var active := true
var save_path := "user://exo_wildlife_slot_1.json"
var timer := 0.0
var visibility_timer := 0.0
func configure(world: Node3D) -> void: host = world
func _ready() -> void:
 var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://modules/village_life/wildlife.json"))
 for data in manifest.spawns:
  var rig: String = str(manifest.rig_contracts[str(data.rig)].base)
  var animal = Actor.new()
  animal.configure(data,host,"res://modules/village_life/assets/"+rig)
  add_child(animal)
  creatures[str(data.id)] = animal
  animal.life_changed.connect(func(_id: String,_hp: int): save_all())
 load_all()
 set_active(not host._remote())
func _process(delta: float) -> void:
 if not active: return
 visibility_timer -= delta
 if visibility_timer <= 0:
  visibility_timer = .45
  for animal in creatures.values():
   var near: bool = animal.body.global_position.distance_to(host.actor.global_position) < 78.0
   if animal.active != near: animal.set_active(near)
 timer += delta
 if timer > 20: timer = 0;save_all()
func set_active(value: bool) -> void:
 active = value
 for animal in creatures.values(): animal.set_active(value)
func use_slot(slot: int) -> void:
 save_path = "user://exo_wildlife_slot_%d.json" % clampi(slot,1,3)
 for animal in creatures.values():
  animal.hp = int(animal.spec.hp)
  animal.body.position = animal.home
  animal.state = "IDLE"
  animal.body.collision_layer = 128
  animal.hurtbox.collision_layer = 256
  animal._play("Idle",.1)
  animal._refresh_plate()
 load_all()
func reset_all() -> void:
 for animal in creatures.values():
  animal.hp = int(animal.spec.hp)
  animal.body.position = animal.home
  animal.state = "IDLE"
  animal.body.collision_layer = 128
  animal.hurtbox.collision_layer = 256
  animal._play("Idle",.1)
  animal._refresh_plate()
 save_all()
func save_all() -> void:
 var states := {}
 for id in creatures: states[id] = creatures[id].save_state()
 var file := FileAccess.open(save_path,FileAccess.WRITE)
 if file: file.store_string(JSON.stringify({"version":1,"states":states}));file.close()
func load_all() -> void:
 if not FileAccess.file_exists(save_path): return
 var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
 if not data is Dictionary or data.get("version",0)!=1: return
 for id in creatures:
  if data.get("states",{}).has(id): creatures[id].load_state(data.states[id])
