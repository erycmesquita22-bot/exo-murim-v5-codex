extends RefCounted
# Spatial hash: neighboring residents only, rather than each actor scanning the entire roster.
const CELL:=2.6
var buckets: Dictionary={}
static func key(p: Vector3) -> Vector2i:
	return Vector2i(int(floor(p.x/CELL)),int(floor(p.z/CELL)))
func rebuild(actors: Array) -> void:
	buckets.clear()
	for actor in actors:
		if not is_instance_valid(actor) or bool(actor.sheltered):continue
		var k: Vector2i=key(actor.position)
		if not buckets.has(k):buckets[k]=[]
		buckets[k].append(actor)
func near(actor: Node3D) -> Array:
	var found: Array=[]
	var cell: Vector2i=key(actor.position)
	for x in range(-1,2):
		for y in range(-1,2):
			for other in buckets.get(cell+Vector2i(x,y),[]):
				if other!=actor:found.append(other)
	return found
