extends SceneTree
const Demo=preload("res://genesis/demo.gd")
var failures: Array=[]
var rays := 0
var max_error := 0.0
var support_points := 0
func _init() -> void:call_deferred("run")
func run() -> void:
	var world := Demo.new();root.add_child(world)
	while not world.ready_to_play:await physics_frame
	world.automated=true
	for rid in world.pilot.ids:
		if world.current!=rid:
			if not await world.change_region(rid,""):failures.append({"rid":rid,"phase":"load"});continue
		for n in range(5):await physics_frame
		world.set_physics_process(false)
		var d: RefCounted=world.active.data
		for z in range(-248,249,8):
			for x in range(-248,249,8):check_point(world,Vector2(x,z),"surface")
		for g in d.gates:
			var normal: Vector2=Vector2(-g.p.y,g.p.x).normalized()
			for k in range(0,129):
				for side in [-1,0,1]:check_point(world,g.p*k/128.0+normal*side*3,"lane")
		for lot in d.lots:
			for offset in [Vector2(-2,-2),Vector2(2,-2),Vector2(-2,2),Vector2(2,2)]:
				check_point(world,lot.p+offset,"foundation");support_points+=1
		world.set_physics_process(true)
		print("PHYSICS_REGION ",rid," checked ",rays," failures ",failures.size())
	var result := {"engine":Engine.get_version_info(),"regions":7,"terrain_raycasts":rays,"foundation_support_points":support_points,"max_triangle_surface_error_m":max_error,"failures":failures,"note":"Terrain layer 1, solid props layer 4, original player mask 1|4. Far-field samples lie on vertices; road samples compare full-resolution triangle interpolation."}
	FileAccess.open("res://evidence/physics_surfaces.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"));print(JSON.stringify(result));quit(0 if failures.is_empty() else 1)
func check_point(world: Node3D,p: Vector2,phase: String) -> void:
	if absf(p.x)>255.9 or absf(p.y)>255.9:return
	var d: RefCounted=world.active.data
	var h: float=d.height_at(p)
	var q := PhysicsRayQueryParameters3D.create(Vector3(p.x,h+100,p.y),Vector3(p.x,h-100,p.y),1)
	var hit: Dictionary=world.get_world_3d().direct_space_state.intersect_ray(q);rays+=1
	if hit.is_empty():failures.append({"rid":world.current,"phase":phase,"at":str(p),"error":"no_floor"});return
	var error: float=absf(hit.position.y-h);max_error=maxf(max_error,error)
	# Analytic curve and 1m triangulation differ slightly between vertices; exact same mesh drives render/physics.
	if error>.15:failures.append({"rid":world.current,"phase":phase,"at":str(p),"error_m":error})
