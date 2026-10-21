extends RefCounted
func initialize(core: RefCounted) -> bool:
 core.services.register_service("failed.example","failed_example",self,["value"])
 core.world.journey.data.failed_example={"schema":1}
 return false
func value() -> int:return -1
