extends SceneTree
func _initialize():
 var c=preload("res://exo_skill_forge/runtime/catalog.gd").new()
 print("SKILL_PROBE ",c.initialize()," ",c.issues)
 quit()
