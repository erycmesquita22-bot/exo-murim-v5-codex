extends Node3D
# Preview scene for a COPY of the EXO Core project; depends on its ORIGINAL rack asset.
# Does not claim capture or completed native validation.
const Generator = preload("res://exo_items/generation/item_generator.gd")
const WorldSeed = preload("res://procedural/world_state.gd")
const RACK_PATH = "res://models/forja_v3/weapons_training_rack.tscn"
func _ready() -> void:
 var camera := Camera3D.new()
 add_child(camera)
 camera.position = Vector3(0,5.5,11.5)
 camera.look_at(Vector3(0,1.1,0),Vector3.UP)
 camera.current = true
 var light := DirectionalLight3D.new()
 add_child(light)
 light.rotation_degrees = Vector3(-55,-30,0)
 var labels: Array = ["Comum", "Com afixos", "Rara"]
 var w: Dictionary = WorldSeed.create(12345,"world_exo_items_lab")
 for i in range(3):
  var pedestal := Node3D.new()
  add_child(pedestal)
  pedestal.position.x = (float(i)-1.0)*3.6
  if ResourceLoader.exists(RACK_PATH):
   var packed: Resource = load(RACK_PATH)
   if packed is PackedScene:
    var rack: Node = packed.instantiate()
    pedestal.add_child(rack)
  var weapon: Dictionary = _find_demo(w, i)
  var label := Label3D.new()
  label.text = "%s\n%s\n%s" % [labels[i],str(weapon.get("rarity","")),str(weapon.get("stats",{}))]
  label.position = Vector3(0,2.6,0)
  label.font_size = 28
  label.pixel_size = 0.006
  label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
  pedestal.add_child(label)

func _find_demo(world: Dictionary, kind: int) -> Dictionary:
 for attempt in range(200):
  var item: Dictionary = Generator.compatible_reward(world, "qa/lab_%d_%d" % [kind, attempt], "blade", 1 if kind == 0 else 3, "item_%d" % (100 + kind * 200 + attempt), "sword")
  if item.is_empty(): continue
  if kind == 0 and item.rarity == "Comum": return item
  if kind == 1 and item.affixes.size() == 2: return item
  if kind == 2 and item.rarity == "Rara": return item
 return {}
