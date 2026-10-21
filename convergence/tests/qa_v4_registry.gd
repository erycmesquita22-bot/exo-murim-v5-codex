extends SceneTree
func _initialize():
 var registry = preload("res://exo_core/module_registry.gd").new()
 var rows: Array = JSON.parse_string(FileAccess.get_file_as_string("res://exo_core/modules.json"))
 for row in rows:
  print(row.get("id")," REGISTER ",registry.register(row)," ",registry.errors)
 print("RESOLVE ",registry.resolve()," ",registry.errors)
 quit()
