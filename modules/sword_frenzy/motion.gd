extends RefCounted
static var paths: Dictionary = {}
static func sample(profile: String, phase: float) -> Vector3:
	if paths.is_empty(): paths = JSON.parse_string(FileAccess.get_file_as_string("res://modules/sword_frenzy/root_motion.json"))
	var keys: Array = paths[profile]
	for i in range(keys.size()-1):
		if phase <= keys[i+1][0]:
			var a: Array = keys[i][1];var b: Array = keys[i+1][1]
			var u: float = smoothstep(keys[i][0],keys[i+1][0],phase)
			return Vector3(a[0],a[1],a[2]).lerp(Vector3(b[0],b[1],b[2]),u)
	var p: Array = keys[-1][1];return Vector3(p[0],p[1],p[2])
static func world_delta(forward: Vector3, delta: Vector3) -> Vector3:
	return Vector3(forward.z,0,-forward.x)*delta.x+forward*delta.z
static func install(controller):
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://modules/sword_frenzy/motion_config.json"))
	controller.motion_config.merge(config,true)
	var library: AnimationLibrary = load("res://modules/sword_frenzy/motion_library.tres")
	var current: AnimationLibrary = controller.player.get_animation_library("")
	for clip in library.get_animation_list(): current.add_animation(clip,library.get_animation(clip))
