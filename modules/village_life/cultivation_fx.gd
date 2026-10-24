extends Node3D
## Scalable ink/Qi effects. Tier drives geometry count, pulse and local refraction.
const GLOW := preload("res://modules/village_life/qi_glow.png")
const STROKE := preload("res://modules/village_life/qi_stroke.png")
const FLAME := preload("res://modules/village_life/qi_flame.png")
var tier := 1
var qi_color := Color("54c6df")
var rings: Array[MeshInstance3D] = []
var motes: Array[Sprite3D] = []
var strokes: Array[Sprite3D] = []
var flames: Array[Sprite3D] = []
var lightning: Array[Sprite3D] = []
var ground_ring: MeshInstance3D
var release_ring: MeshInstance3D
var glow_core: Sprite3D
var night_light: OmniLight3D
var visual_time := 0.0
var active_power := 0.0
var current_stage := "off"
func configure(level: int, color: Color) -> void:
 tier = clampi(level,1,5)
 qi_color = color
func _ready() -> void:
 name = "CultivationQiFX"
 for i in (2+tier):
  var ring := _ring("MeridianOrbit_%d" % i,.52+float(i)*.17,.029)
  ring.rotation = Vector3(.28+float(i)*.33,float(i)*.72,.22)
  add_child(ring)
  rings.append(ring)
 ground_ring = _ring("NightNeonMeridian",1.08+.12*tier,.027)
 ground_ring.position.y = -1.20
 add_child(ground_ring)
 release_ring = _ring("QiReleaseWave",.88,.045)
 release_ring.position.y = -1.12
 add_child(release_ring)
 glow_core = Sprite3D.new()
 glow_core.name = "BreathCore"
 glow_core.texture = GLOW
 glow_core.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 glow_core.pixel_size = .010+.001*tier
 glow_core.shaded = false
 add_child(glow_core)
 if tier >= 2:
  for i in 2:
   var aura := Sprite3D.new()
   aura.name = "MurimFlameSheet_%d" % i
   aura.texture = FLAME
   aura.billboard = BaseMaterial3D.BILLBOARD_ENABLED
   aura.shaded = false
   aura.pixel_size = .0058+.00030*tier
   aura.position = Vector3((float(i)-.5)*.28,.12,-.23-float(i)*.04)
   add_child(aura)
   flames.append(aura)
 for i in (4+tier*2):
  var particle := Sprite3D.new()
  particle.name = "AscendingQi_%02d" % i
  particle.texture = GLOW
  particle.billboard = BaseMaterial3D.BILLBOARD_ENABLED
  particle.shaded = false
  particle.pixel_size = .0018+.00025*tier
  add_child(particle)
  motes.append(particle)
 for i in (3+tier*2):
  var line := Sprite3D.new()
  line.name = "NightNeonStroke_%02d" % i
  line.texture = STROKE
  line.billboard = BaseMaterial3D.BILLBOARD_ENABLED
  line.shaded = false
  line.pixel_size = .0045+.00035*tier
  add_child(line)
  strokes.append(line)
 if tier >= 2:
  for i in 5:
   var bolt := Sprite3D.new()
   bolt.name = "ReleaseLightning_%d" % i
   bolt.texture = STROKE
   bolt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
   bolt.shaded = false
   bolt.pixel_size = .0042
   bolt.position = Vector3(cos(float(i)*TAU/5.0)*1.15,-.14,sin(float(i)*TAU/5.0)*1.15)
   bolt.rotation.z = float(i)*.36-.7
   add_child(bolt)
   lightning.append(bolt)
 if tier >= 2:
  night_light = OmniLight3D.new()
  night_light.name = "NightQiLight"
  night_light.light_color = qi_color
  night_light.omni_range = 3.2+.30*tier
  night_light.shadow_enabled = false
  night_light.light_energy = 0
  add_child(night_light)
 visible = false
func _ring(label: String, radius: float, width: float) -> MeshInstance3D:
 var visual := MeshInstance3D.new()
 visual.name = label
 var torus := TorusMesh.new()
 torus.inner_radius = radius-width
 torus.outer_radius = radius+width
 visual.mesh = torus
 var mat := StandardMaterial3D.new()
 mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 mat.cull_mode = BaseMaterial3D.CULL_DISABLED
 mat.albedo_color = Color(qi_color.r,qi_color.g,qi_color.b,.55)
 mat.emission_enabled = true
 mat.emission = qi_color
 mat.emission_energy_multiplier = 1.4
 visual.material_override = mat
 return visual
func update_fx(enabled: bool, stage: String, progress: float, night: bool, delta: float) -> void:
 visible = enabled
 current_stage = stage if enabled else "off"
 if not enabled:
  active_power = 0
  if night_light != null: night_light.light_energy = 0
  return
 visual_time += delta
 var t := clampf(progress,0,1)
 var lift := (0.72 if stage == "gather" else (1.0 if stage in ["circulate","form"] else (1.55 if stage == "release" else .55)))
 var neon := 1.45 if night else .78
 active_power = clampf((.23+.17*float(tier))*lift,0,1.8)
 rotation.y += delta*(.18+.10*tier)
 var breath := .5+.5*sin(visual_time*3.4)
 for i in rings.size():
  var ring := rings[i]
  ring.rotation.z += delta*(.17+.07*i)*(1 if i%2==0 else -1)
  var size := 1.0+.055*sin(visual_time*2.3+float(i))
  ring.scale = Vector3.ONE*size
  _alpha(ring,.15+.34*active_power*neon)
 var floor_size := 1.0+.07*breath
 ground_ring.scale = Vector3.ONE*floor_size
 _alpha(ground_ring,(.16+.36*active_power)*neon)
 release_ring.visible = stage == "release"
 if release_ring.visible:
  release_ring.scale = Vector3.ONE*(.65+t*2.25)
  _alpha(release_ring,(1.0-t)*.75*neon)
 glow_core.modulate = Color(qi_color.r,qi_color.g,qi_color.b,clampf(.11+.24*active_power*neon,0,.85))
 glow_core.scale = Vector3.ONE*(.9+.16*breath)
 for i in flames.size():
  var aura := flames[i]
  aura.scale = Vector3.ONE*((1.0+.10*breath)*(1.28 if stage == "release" else .95))
  aura.position.y = .10+.08*sin(visual_time*2+float(i))
  aura.modulate = Color(qi_color.r,qi_color.g,qi_color.b,clampf((.26+.25*active_power)*neon,0,.95))
 for i in motes.size():
  var seed := float(i)/float(motes.size())
  var rise := fposmod(visual_time*(.31+.10*tier)+seed,1.0)
  var angle := seed*TAU+visual_time*(.28+.04*tier)
  var radius := .45+.15*sin(seed*13.0+visual_time)
  var mote := motes[i]
  mote.position = Vector3(cos(angle)*radius,-.85+rise*2.35,sin(angle)*radius)
  mote.modulate = Color(qi_color.r,qi_color.g,qi_color.b,(.22+.43*active_power)*neon*(1.0-rise*.8))
 for i in strokes.size():
  var seed := float(i)/float(strokes.size())
  var sweep := fposmod(visual_time*(.27+.055*tier)+seed,1.0)
  var theta := seed*TAU+visual_time*.19
  var line := strokes[i]
  line.position = Vector3(cos(theta)*(.72+.10*sin(visual_time+float(i))),-.73+sweep*1.75,sin(theta)*(.72+.10*sin(visual_time+float(i))))
  line.rotation.z = .10*sin(visual_time*2+float(i))
  line.modulate = Color(qi_color.r,qi_color.g,qi_color.b,clampf((.10+.27*active_power)*neon*(1.0-sweep*.7),0,.9))
 for i in lightning.size():
  var bolt := lightning[i]
  bolt.visible = stage == "release"
  if bolt.visible:
   bolt.scale = Vector3.ONE*(.65+t*.85)
   bolt.modulate = Color(qi_color.r,qi_color.g,qi_color.b,clampf((1.0-t)*.85*neon,0,1))
 if night_light != null: night_light.light_energy = (.34+.38*active_power) if night else 0
func _alpha(ring: MeshInstance3D, value: float) -> void:
 var material: StandardMaterial3D = ring.material_override
 var c := material.albedo_color
 c.a = clampf(value,0,.93)
 material.albedo_color = c
func distortion_power() -> float:
 if not visible or tier < 2: return 0
 var boost := 1.65 if current_stage == "release" else (1.08 if current_stage == "circulate" else .70)
 return clampf(active_power*boost*(float(tier)-1.0)*.31,0,1.25)
