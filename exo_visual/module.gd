extends RefCounted
## Registered via the EXO Core's existing entrypoint contract; no extra save domain.
const Spec=preload("res://exo_visual/spec.gd")
var core: RefCounted
func initialize(context: RefCounted) -> bool:
 core=context
 if not is_instance_valid(core.world) or core.world.graphics==null:return false
 return core.services.register_service("exo_visual", "visual", self, ["get_setting","set_setting","profile","diagnostics","apply","capabilities"],"1.0.0")
func get_setting(key: String) -> int:return core.world.graphics.get_option(key)
func set_setting(key: String,value: int) -> bool:return core.world.graphics.set_option(key,value)
func profile() -> String:return core.world.graphics.NAMES[core.world.graphics.level]
func diagnostics() -> Dictionary:return core.world.graphics.diagnostics()
func apply() -> void:core.world.graphics.apply()
func capabilities() -> Dictionary:
 var values: Dictionary={}
 for key in Spec.OPTIONS:values[key]=Spec.available(key)
 return {"renderer":RenderingServer.get_current_rendering_method(),"features":values}
func shutdown() -> void:core=null
