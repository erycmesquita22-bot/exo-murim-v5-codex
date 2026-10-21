extends RefCounted
# Official martial definitions; catalog only. Enrollment/skills remain disabled until
# Narrative's trusted authorization, real Qi/stamina proofs and Native QA are ready.
const Catalog=preload("res://exo_martial/styles/martial_catalog.gd")
func initialize(core: RefCounted) -> bool:
 if not bool(Catalog.valid_catalogs().get("ok",false)):return false
 return core.services.register_service("martial.catalog","martial_catalog",self,["summary","schools","styles","techniques"],"1.0.0")
func summary() -> Dictionary:return Catalog.valid_catalogs()
func schools() -> Array:return Catalog.schools().duplicate(true)
func styles() -> Array:return Catalog.styles().duplicate(true)
func techniques() -> Array:return Catalog.techniques().duplicate(true)
func shutdown() -> void:pass
