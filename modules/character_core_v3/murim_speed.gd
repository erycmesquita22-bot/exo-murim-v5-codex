extends CanvasLayer
## Original runtime ink strokes: no texture, third-party art, blur or geometry edits.
var intensity := 0.0
var clock := 0.0
var enabled := true
var warp: ColorRect
var ink: Control
var shader_material: ShaderMaterial
class InkStrokes extends Control:
	var amount := 0.0
	var phase := 0.0
	func _draw() -> void:
		if amount < .002: return
		var unit := minf(size.x,size.y)
		var center := size*Vector2(.5,.46)
		for i in 60:
			var seed := fmod(float(i)*.61803398875,1.0)
			var angle := TAU*(float(i)/60.0+.009*sin(float(i)*7.13))
			var direction := Vector2(cos(angle),sin(angle))
			var normal := Vector2(-direction.y,direction.x)
			var cycle := fmod(phase*(.6+seed*.35)+seed,1.0)
			# Inner clear zone keeps face, torso and immediate route legible.
			var start := unit*(.40+cycle*.44+seed*.12)
			var length := unit*(.17+seed*.30)*amount
			var width := unit*(.0008+seed*.0017)
			var p0 := center+direction*start
			var p1 := center+direction*(start+length*.55)+normal*sin(phase*2+float(i)) * unit*.003
			var p2 := center+direction*(start+length)
			var color := Color(.055,.065,.085,.44*amount) if i%3 != 0 else Color(.94,.91,.79,.28*amount)
			draw_colored_polygon(PackedVector2Array([p0,p1+normal*width,p2,p1-normal*width*.5]),color)
func _ready() -> void:
	layer = 0 # Read the rendered world, then draw HUD on the existing layer 1.
	warp = ColorRect.new()
	warp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	warp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float strength = 0.0;
uniform float phase = 0.0;
void fragment() {
 vec2 p = SCREEN_UV - vec2(0.5,0.46);
 float radius = length(p);
 float outer = smoothstep(0.23,0.53,radius);
 // Gentle radial ink-pressure refraction, with a protected central zone.
 float wave = sin(radius*31.0-phase*5.0);
 vec2 offset = p * outer * strength * 0.008 * wave;
 vec2 uv = clamp(SCREEN_UV+offset,vec2(0.001),vec2(0.999));
 COLOR = vec4(texture(screen_texture,uv).rgb,1.0);
}
"""
	shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	warp.material = shader_material
	add_child(warp)
	ink = InkStrokes.new()
	ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ink.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ink)
	visible = false
func update_speed(speed: float, travel: bool, delta: float) -> void:
	var target := smoothstep(7.6,16.5,speed) if travel and enabled else 0.0
	intensity = move_toward(intensity,target,delta*(2.2 if target > intensity else 3.5))
	clock += delta
	visible = intensity > .002
	shader_material.set_shader_parameter("strength",intensity)
	shader_material.set_shader_parameter("phase",clock)
	ink.amount = intensity
	ink.phase = clock
	ink.queue_redraw()
