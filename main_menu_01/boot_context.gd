extends Node
## The one-shot handoff between the menu and Convergence.
## No menu nodes survive the scene switch.
var requested_mode: String = "continue"
func choose(mode: String) -> void:
	requested_mode = mode if mode in ["continue", "new", "load"] else "continue"
func take() -> String:
	var chosen: String = requested_mode
	requested_mode = "continue"
	return chosen
