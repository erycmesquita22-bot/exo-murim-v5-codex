extends Node3D
# Local visual only: no physics body, sounds, gameplay AI, or dynamic lights.
@export var species := "butterfly"
@export var flight_radius := .6
var anchor := Vector3.ZERO
var phase := 0.0
var prepared := false
func _ready() -> void:
	anchor = position
	phase = float(get_meta("phase",0))
	prepared = true
func _process(delta: float) -> void:
	if not prepared: return
	phase += delta
	if species != "cicada":
		position = anchor+Vector3(sin(phase*.7)*flight_radius,sin(phase*1.3)*.13,cos(phase*.9)*flight_radius*.5)
	for mesh in find_children("*","MeshInstance3D",true,false):
		if mesh.name.begins_with("wing_"):
			mesh.rotation.z = sin(phase*(28 if species=="firefly" else 18))*.65*(1 if mesh.name.contains("left") else -1)
		elif species=="firefly" and mesh.name.begins_with("abdomen"): mesh.visible = sin(phase*2.3)>.05
