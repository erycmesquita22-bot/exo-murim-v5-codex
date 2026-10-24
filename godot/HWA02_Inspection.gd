extends Node3D
## EXO-Murim - HWA-02 environment inspection. NO PLAYER CHARACTER.
## The landscape and manor are constant: only heraldry changes according to the seed.

@export var world_seed: int = 101
@export_enum("AUTO", "WONG", "WUDONG") var family_override: String = "AUTO"

@onready var camera: Camera3D = $Camera3D
@onready var wong_art: Node3D = $FamilyWong
@onready var wudong_art: Node3D = $FamilyWudong
@onready var help: Label = $UI/Help

var focus: Vector3 = Vector3(-17.0, 2.0, -3.0)
var azimuth: float = -0.70
var elevation: float = 0.73
var zoom_distance: float = 200.0
var test_family: String = ""

func _ready() -> void:
	# Keep legacy village terrain/vegetation, hide outdated architecture only.
	for n in $TerrainAndArchitecture.find_children("*", "MeshInstance3D", true, false):
		if n.name in ["Terrain", "River"]:
			n.visible = false
	_apply_family()
	_update_camera()

func _resolved_family() -> String:
	if test_family != "":
		return test_family
	if family_override != "AUTO":
		return family_override
	# Only for preview. Production WorldState must persist a selected family ID.
	return "WONG" if posmod(world_seed, 2) == 1 else "WUDONG"

func _apply_family() -> void:
	var selected: String = _resolved_family()
	wong_art.visible = selected == "WONG"
	wudong_art.visible = selected == "WUDONG"
	help.text = "EXO-MURIM | HWA-02 HANEUL | CENARIO SEM PERSONAGEM\n" \
		+ "Solar fixo: familia " + selected + " | Seed " + str(world_seed) + "\n" \
		+ "Botao direito + mouse: girar | WASD: mover vista | Roda: aproximar\n" \
		+ "1: Wong (Qi fisico) | 2: Wudong (espada) | 0: voltar a seed"

func _update_camera() -> void:
	var h: float = cos(elevation)
	var orbit: Vector3 = Vector3(sin(azimuth) * h, sin(elevation), cos(azimuth) * h)
	camera.position = focus + orbit * zoom_distance
	camera.look_at(focus, Vector3.UP)

func _process(delta: float) -> void:
	var forward: Vector3 = Vector3(camera.global_transform.basis.z.x, 0.0, camera.global_transform.basis.z.z).normalized()
	var right: Vector3 = Vector3(camera.global_transform.basis.x.x, 0.0, camera.global_transform.basis.x.z).normalized()
	var motion: Vector3 = Vector3.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		motion -= forward
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		motion += forward
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		motion -= right
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		motion += right
	if motion.length_squared() > 0.0:
		focus += motion.normalized() * max(12.0, zoom_distance * 0.48) * delta
		_update_camera()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		azimuth -= event.relative.x * 0.006
		elevation = clampf(elevation - event.relative.y * 0.006, 0.19, 1.36)
		_update_camera()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_distance = maxf(12.0, zoom_distance * 0.88)
			_update_camera()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_distance = minf(390.0, zoom_distance * 1.12)
			_update_camera()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			test_family = "WONG"
			_apply_family()
		elif event.keycode == KEY_2:
			test_family = "WUDONG"
			_apply_family()
		elif event.keycode == KEY_0:
			test_family = ""
			_apply_family()
