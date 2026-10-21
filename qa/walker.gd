extends CharacterBody3D
## Physics QA actor used only by godot/demo.gd house-door tests.
## Does not participate in the game's live NPC, Crowd or player systems.
@export var speed: float = 3.0
var direction: Vector3 = Vector3.ZERO

func _physics_process(delta: float) -> void:
    var horizontal: Vector3 = Vector3(direction.x, 0.0, direction.z)
    if horizontal.length_squared() > 1.0:
        horizontal = horizontal.normalized()
    velocity.x = horizontal.x * speed
    velocity.z = horizontal.z * speed
    if not is_on_floor():
        velocity.y -= 24.0 * delta
    else:
        velocity.y = -0.1
    move_and_slide()
