extends Node3D
var hinges: Array = []
var opened := false
func setup() -> void:
	if not hinges.is_empty(): return
	for child in get_children():
		if child.name.begins_with("door_"):
			var hinge := Node3D.new()
			var x := -.6 if child.name.contains("left") else .6
			add_child(hinge)
			hinge.position.x = x
			child.reparent(hinge,false)
			child.position.x -= x
			hinges.append(hinge)
func set_open(value: bool) -> void:
	setup()
	opened = value
	for h in hinges: h.rotation.y = (-1 if h.position.x<0 else 1)*(-PI/2 if value else 0)
