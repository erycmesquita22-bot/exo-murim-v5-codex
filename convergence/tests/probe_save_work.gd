extends SceneTree
const Save=preload("res://journey_save.gd")
func _initialize():
 var s=Save.new("user://work_probe.json",101)
 print("VALID ORIGINAL ",s.valid(s.data))
 var d=s.decode(JSON.stringify(s.data))
 print("VALID JSON ",s.valid(d), " FOUNDATIONS ",s.valid_foundations(d)," INVENTORY ",s.valid_inventory(d))
 print("WORLD ",preload("res://procedural/world_state.gd").valid(d.world))
 print("JSON ",JSON.stringify(d))
 print("WRITE ",s.write()," STATUS ",s.status)
 quit()
