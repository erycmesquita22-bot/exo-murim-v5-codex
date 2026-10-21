extends RefCounted
const Planner=preload("res://fortifications/planner.gd")
const Renderer=preload("res://fortifications/renderer.gd")
static func apply(root: Node3D,data: RefCounted) -> Dictionary:
	if data.spec.kind!="settlement":return {"status":"skipped","reason":"not_settlement"}
	var start_usec: int=Time.get_ticks_usec()
	var result: Dictionary=Planner.plan_region(data)
	if result.status in ["ready","partial"]:
		var built: Dictionary=Renderer.build_into(root,result,Callable(data,"height_at"))
		result["rendered"]=built.ok
	else:
		result["rendered"]=false
	result["fortification_ms"]=(Time.get_ticks_usec()-start_usec)/1000.0
	root.set_meta("fortification_ms",result["fortification_ms"])
	return result
