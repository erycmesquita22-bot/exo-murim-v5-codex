extends Node3D
@export_enum("ivory_charcoal","ochre_terracotta","gray_jade","clay_slate","cream_blue") var palette := "ivory_charcoal"
@export_enum("4","6","8") var width := "6"
@export_range(1,2) var stories := 2
func _ready() -> void:
	preload("res://godot/modular_kit.gd").build_house(self,palette,int(width),stories)
