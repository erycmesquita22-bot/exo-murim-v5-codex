extends "res://godot/ambient_insect.gd"
@export var model_id := "butterfly_01"
func _ready() -> void:
	preload("res://godot/modular_kit.gd").place(self,model_id,Vector3.ZERO,0,"",false)
	species = "firefly" if model_id=="firefly" else "cicada" if model_id=="cicada" else "butterfly"
	super._ready()
