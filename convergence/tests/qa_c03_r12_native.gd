extends SceneTree
# EXO-Murim C03 R12: parser/resource smoke. Run only on a COPY under Godot 4.6.2.
# This checks GDScript resource loadability but not gameplay or GPU.
var checked: int = 0
var failures: Array[String] = []
const EXCLUDE := ["res://godot/demo.gd", "res://exo_core/module_template/test.gd"]

func _initialize() -> void:
	call_deferred("_execute")

func _execute() -> void:
	_scan("res://")
	print("R12_NATIVE_PARSE total=", checked, " failed=", failures.size())
	for path in failures:
		push_error("R12_NATIVE_PARSE_FAILED " + path)
	quit(0 if failures.is_empty() else 1)

func _scan(folder: String) -> void:
	var directory := DirAccess.open(folder)
	if directory == null:
		failures.append("cannot_open:" + folder)
		return
	directory.list_dir_begin()
	while true:
		var entry := directory.get_next()
		if entry.is_empty():
			break
		if entry.begins_with("."):
			continue
		var path := folder.path_join(entry)
		if directory.current_is_dir():
			_scan(path)
		elif entry.ends_with(".gd") and not (path in EXCLUDE):
			checked += 1
			var script: Resource = load(path)
			if script == null or not script is GDScript or not script.can_instantiate():
				failures.append(path)
	directory.list_dir_end()
