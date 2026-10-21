extends RefCounted
const Visual=preload("res://exo_creature_harmonizacao02/integration/visual_catalog.gd")
var context: RefCounted
func initialize(core: RefCounted) -> bool:
 context=core
 return core.services.register_service("creatures.visuals","creature_visuals",self,["get_visual","status"],"1.1.0")
func get_visual(species_id: String,variant_source: String="") -> Dictionary:
 var descriptor: Dictionary=Visual.get_visual(species_id,variant_source)
 if descriptor.is_empty():return {}
 var scene_path: String=str(descriptor.get("scene",""))
 if not scene_path.begins_with("res://") or not ResourceLoader.exists(scene_path):return {}
 return descriptor.duplicate(true)
func status() -> Dictionary:
 return {"registered":true,"visual_lookup_only":false,"regional_fauna_visual_bound":true,"combat_bound":false,"runtime_optional":true,"voxel_fallback":true,"native_qa":"NOT_RUN"}
func shutdown() -> void:
 context=null
