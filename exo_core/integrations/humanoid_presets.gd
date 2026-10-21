extends RefCounted
# R10: consultation service, paired with host lifecycle bridge; no legacy PNGs loaded.
const Selection=preload("res://exo_humanoids03_r2/scripts/preset_selector.gd")
func initialize(core: RefCounted) -> bool:
 if Selection.catalog().is_empty():return false
 return core.services.register_service("humanoids.presets","humanoid_presets",self,["choose","valid","status"],"1.1.0")
func choose(actor_descriptor: Dictionary) -> Dictionary:
 return Selection.choose(actor_descriptor).duplicate(true)
func valid(selection: Dictionary) -> bool:
 return Selection.valid(selection)
func status() -> Dictionary:
 return {"preview_only":false,"rig_events_bound":true,"native_qa":"NOT_RUN","commercial_legacy_skins":"QUARANTINED"}
func shutdown() -> void:pass
