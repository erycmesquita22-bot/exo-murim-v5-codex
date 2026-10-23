extends Control
## Bounded canvas animation: no particles, physics bodies or per-frame allocations.
const PETAL_COUNT := 28
const WIND_COUNT := 5
var petals: Array[Dictionary] = []
var wind: Array[Dictionary] = []
var elapsed := 0.0
var redraw_accum := 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rng.seed = 23109
	for i in range(PETAL_COUNT):
		petals.append({"x": rng.randf(), "y": rng.randf(), "speed": rng.randf_range(.035, .085), "phase": rng.randf_range(0.0, TAU), "size": rng.randf_range(3.0, 7.0)})
	for i in range(WIND_COUNT):
		wind.append({"x": rng.randf(), "y": rng.randf_range(.15, .85), "phase": rng.randf_range(0.0, TAU)})

func _process(delta: float) -> void:
	if not visible or get_viewport_rect().size.x < 1.0:
		return
	elapsed += minf(delta, .1)
	redraw_accum += delta
	if redraw_accum < 1.0 / 30.0:
		return
	redraw_accum = 0.0
	queue_redraw()

func _draw() -> void:
	var bounds: Vector2 = size
	for petal in petals:
		var px: float = fposmod(float(petal.x) + elapsed * float(petal.speed), 1.12) * bounds.x - bounds.x * .06
		var py: float = fposmod(float(petal.y) + elapsed * float(petal.speed) * .43, 1.14) * bounds.y - bounds.y * .07
		py += sin(elapsed * 2.0 + float(petal.phase)) * 9.0
		var s: float = float(petal.size)
		var shade := Color(1.0, .66, .72, .66) if int(petal.phase * 10.0) % 2 == 0 else Color(1.0, .82, .78, .58)
		# Deliberately square petals keep the voxel silhouette of the new artwork.
		draw_rect(Rect2(Vector2(px, py), Vector2(s, s * .62)), shade)
		draw_rect(Rect2(Vector2(px + s * .65, py + s * .3), Vector2(s * .45, s * .45)), shade.darkened(.12))
	for trail in wind:
		var x: float = fposmod(float(trail.x) + elapsed * .055, 1.35) * bounds.x - bounds.x * .18
		var y: float = float(trail.y) * bounds.y + sin(elapsed * .7 + float(trail.phase)) * 14.0
		draw_line(Vector2(x, y), Vector2(x + 42.0, y - 7.0), Color(.92, .89, .79, .12), 1.4, true)
