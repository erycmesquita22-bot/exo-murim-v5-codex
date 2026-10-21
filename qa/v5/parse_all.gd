extends SceneTree
var failures: Array=[]
var checked: int=0
func _initialize() -> void:
    scan("res://")
    print("V5_PARSE_RESULT ",JSON.stringify({"checked":checked,"failures":failures}))
    quit(0 if failures.is_empty() else 1)
func scan(path: String) -> void:
    var d:=DirAccess.open(path)
    for name in d.get_directories():
        if name.begins_with(".") or path.path_join(name)=="res://exo_core/module_template":continue
        scan(path.path_join(name))
    for name in d.get_files():
        if not name.ends_with(".gd") and not name.ends_with(".tscn") and not name.ends_with(".tres"):continue
        var file: String=path.path_join(name)
        var s=load(file)
        checked+=1
        if s==null or (s is Script and not s.can_instantiate()):failures.append(file)
