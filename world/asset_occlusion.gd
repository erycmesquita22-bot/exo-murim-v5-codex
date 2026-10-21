extends Node3D
# Only imported buildings fade; collisions and quest interactions stay solid.
var visual: MeshInstance3D
var bounds: AABB
var tint: StandardMaterial3D
var opacity:=1.0
var check_timer:=0.0
var obstructed:=false
func _process(delta: float) -> void:
	var world: Node3D=get_parent()
	if not is_instance_valid(world.player) or not is_instance_valid(world.camera):return
	check_timer-=delta
	if check_timer<=0:
		check_timer=.1
		var target: Vector3=world.player.global_position+Vector3.UP*1.1
		var screen: Vector2=world.camera.unproject_position(target)
		var origin: Vector3=world.camera.project_ray_origin(screen)
		obstructed=bounds.intersects_segment(to_local(origin),to_local(target))!=null
	var desired:=.18 if obstructed else 1.0
	if is_equal_approx(opacity,desired):return
	opacity=move_toward(opacity,desired,delta*6.0)
	# Opaque houses use the normal depth pass. Only an actual obstruction uses hashing.
	tint.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED if opacity>.999 else BaseMaterial3D.TRANSPARENCY_ALPHA_HASH
	tint.albedo_color.a=opacity
	set_meta("occlusion_alpha",opacity)
