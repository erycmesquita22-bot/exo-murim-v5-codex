extends RefCounted
## Legacy-facing graphics adapter. EXO Visual settings remain separate from world saves.
const Spec=preload("res://exo_visual/spec.gd")
const Driver=preload("res://exo_visual/driver.gd")
const NAMES=Spec.PRESET_NAMES
var world: Node3D
var driver: RefCounted
var level: int=2
var values: Dictionary=Spec.defaults()
var shake_enabled:=true
var menu_style:=0
var hud: Dictionary={"style":0,"theme":0,"anchor":0,"scale":1.0,"opacity":.85,"values":true,"portrait":true,"compact":false,"target":true,"notices":true}
var ornaments:=true
var paper:=true
var preview_motion:=true
var path: String="user://graphics.cfg"
var error_message: String=""
func _init(owner_world: Node3D,file_path: String="user://graphics.cfg") -> void:
 world=owner_world
 path=file_path
 driver=Driver.new(world)
 var file:=ConfigFile.new()
 if file.load(path)==OK:
  var style_value: Variant=file.get_value("interface","menu_style",0)
  if style_value is int and style_value>=0 and style_value<4:menu_style=style_value
  for key in hud:
   var value: Variant=file.get_value("hud",key,hud[key])
   if typeof(value)==typeof(hud[key]):hud[key]=value
  hud.style=clampi(int(hud.style),0,9)
  hud.theme=clampi(int(hud.theme),0,6)
  hud.anchor=clampi(int(hud.anchor),0,8)
  hud.scale=clampf(float(hud.scale),.6,1.5)
  hud.opacity=clampf(float(hud.opacity),.2,1.0)
  var saved_level: Variant=file.get_value("exo_visual","preset",-1)
  if saved_level is int and saved_level>=0 and saved_level<=5:
   level=saved_level
  else:
   var legacy: Variant=file.get_value("display","level",1)
   level=[1,2,3][clampi(int(legacy),0,2)] if legacy is int else 2
  if file.has_section("exo_visual"):
   for key in Spec.OPTIONS:values[key]=Spec.normalize(str(key),file.get_value("exo_visual",key,values[key]))
  else:values.merge(Spec.PRESETS[level if level<5 else 2],true)
  var toggle: Variant=file.get_value("display","camera_shake",true)
  if toggle is bool:shake_enabled=toggle
  for key in ["ornaments","paper","preview_motion"]:
   var option: Variant=file.get_value("interface",key,true)
   if option is bool:set(key,option)
 else:
  values.merge(Spec.PRESETS[level],true)
func apply() -> void:
 if not is_instance_valid(world) or world.sun==null or world.environment==null:return
 driver.apply(values)
func tick(delta: float) -> void:
 driver.tick(delta)
func select(index: int) -> bool:
 if index<0 or index>=5:return false
 level=index
 # Presets change visual quality only, not existing window choices/HUD.
 values.merge(Spec.PRESETS[index],true)
 apply()
 return save_settings()
func set_option(key: String, value: int) -> bool:
 if not Spec.OPTIONS.has(key) or not Spec.available(key):return false
 var clean: int=Spec.normalize(key,value)
 values[key]=clean
 level=5
 apply()
 return save_settings()
func get_option(key: String) -> int:return int(values.get(key,0))
func option_available(key: String) -> bool:return Spec.available(key)
func renderer_name() -> String:return RenderingServer.get_current_rendering_method()
func diagnostics() -> Dictionary:return driver.capture_diagnostics()
func save_settings() -> bool:
 var file:=ConfigFile.new()
 if FileAccess.file_exists(path):file.load(path)
 file.set_value("display","level",clampi(level,0,2))
 file.set_value("exo_visual","schema",Spec.VERSION)
 file.set_value("exo_visual","preset",level)
 for key in Spec.OPTIONS:file.set_value("exo_visual",key,values[key])
 file.set_value("interface","menu_style",menu_style)
 for key in hud:file.set_value("hud",key,hud[key])
 file.set_value("display","camera_shake",shake_enabled)
 for key in ["ornaments","paper","preview_motion"]:file.set_value("interface",key,get(key))
 if file.save(path)!=OK:
  error_message="Não foi possível salvar as opções gráficas."
  return false
 error_message=""
 return true
func effect_count(base: int) -> int:
 return int(round(base*[0.0,0.35,0.70,1.0][int(values.particles)]))
func effect_budget() -> int:
 return [0,24,72,144][int(values.particles)]
func segments() -> int:
 return [10,12,16,24][int(values.particles)]
