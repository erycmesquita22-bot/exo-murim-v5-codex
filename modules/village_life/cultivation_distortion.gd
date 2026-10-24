extends CanvasLayer
## Localized screen refraction around visible masters. Uses Compatibility screen texture.
const EFFECT := preload("res://modules/village_life/cultivation_distortion.gdshader")
var host: Node3D
var cover: ColorRect
var material: ShaderMaterial
var elapsed := 0.0
func configure(world: Node3D) -> void: host = world
func _ready() -> void:
 layer = 0
 cover = ColorRect.new()
 cover.name = "MurimQiRefraction"
 cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
 cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 material = ShaderMaterial.new()
 material.shader = EFFECT
 cover.material = material
 add_child(cover)
 cover.visible = false
func _process(delta: float) -> void:
 if host == null or host.village_npcs == null or host._remote(): cover.visible = false;return
 elapsed += delta
 var camera: Camera3D = get_viewport().get_camera_3d()
 if camera == null: cover.visible = false;return
 var visible_masters: Array[Dictionary] = []
 var viewport_size := get_viewport().get_visible_rect().size
 material.set_shader_parameter("aspect",viewport_size.x/maxf(viewport_size.y,1.0))
 for npc in host.village_npcs.residents.values():
  if str(npc.record.get("importance","")) != "master" or not npc.active_in_village or npc.qi_orbit == null: continue
  var power: float = npc.qi_orbit.distortion_power()
  if power < .02: continue
  var center: Vector3 = npc.body.global_position+Vector3(0,1.25,0)
  if camera.is_position_behind(center): continue
  var distance := camera.global_position.distance_to(center)
  if distance > 24: continue
  var pixel: Vector2 = camera.unproject_position(center)
  if pixel.x < -120 or pixel.x > viewport_size.x+120 or pixel.y < -120 or pixel.y > viewport_size.y+120: continue
  visible_masters.append({"power":power*(1.0-smoothstep(14.0,24.0,distance)),"center":pixel/viewport_size,"radius":clampf(1.15/maxf(distance,1.0),.055,.19)})
 visible_masters.sort_custom(func(a,b):return a.power > b.power)
 cover.visible = not visible_masters.is_empty()
 for i in 2:
  var key := "a" if i == 0 else "b"
  if i < visible_masters.size():
   material.set_shader_parameter("center_"+key,visible_masters[i].center)
   material.set_shader_parameter("radius_"+key,visible_masters[i].radius)
   material.set_shader_parameter("power_"+key,visible_masters[i].power)
  else:
   material.set_shader_parameter("center_"+key,Vector2(-2,-2))
   material.set_shader_parameter("power_"+key,0.0)
 material.set_shader_parameter("phase",elapsed)
