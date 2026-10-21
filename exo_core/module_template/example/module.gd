extends RefCounted
var core: RefCounted
func initialize(context: RefCounted) -> bool:
 core=context
 if not core.services.register_service("example.counter","example",self,["count"]):return false
 if not core.world.journey.save_coordinator.register_domain("example","example",valid):return false
 if not core.world.journey.data.has("example"):core.world.journey.data.example={"schema":1,"count":0}
 return core.events.subscribe("equipment_changed","example",on_equipment)
static func valid(data: Variant) -> bool:
 return data is Dictionary and data.get("schema")==1 and (data.get("count") is int or data.get("count") is float) and int(data.count)==data.count and data.count>=0
func on_equipment(_event: Dictionary) -> bool:
 var state: Dictionary=core.world.journey.data.example
 state.count=int(state.count)+1
 return true
func count() -> int:return int(core.world.journey.data.example.count)
func shutdown() -> void:core=null
