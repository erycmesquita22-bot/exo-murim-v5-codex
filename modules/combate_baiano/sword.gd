extends Node3D
var owner_controller
var definition: Resource
var attachment: BoneAttachment3D
var blade: Node3D
var serial := 0
var sounded_serial := -1
var victims: Dictionary = {}
var previous_base := Vector3.ZERO
var previous_tip := Vector3.ZERO
var sampled := false
var active := false
var history: Array[Dictionary] = []
var trail: MeshInstance3D
var trail_material: StandardMaterial3D
var elapsed := 0.0
func configure(controller, weapon: Resource, color: Color) -> void:
	if is_instance_valid(attachment):
		attachment.get_parent().remove_child(attachment)
		attachment.queue_free()
	if is_instance_valid(trail):
		remove_child(trail)
		trail.queue_free()
	history.clear()
	owner_controller = controller
	definition = weapon
	attachment = BoneAttachment3D.new()
	attachment.name = "SingleSwordBlade"
	attachment.bone_name = "weapon"
	attachment.visible = false
	controller.skeleton.add_child(attachment)
	blade = load(definition.blade_scene).instantiate()
	attachment.add_child(blade)
	trail = MeshInstance3D.new()
	trail.name = "SwordInkTrail"
	trail.top_level = true
	add_child(trail)
	trail_material = StandardMaterial3D.new()
	trail_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	trail_material.albedo_color = Color(color,.38)
	trail_material.no_depth_test = false
	trail.material_override = trail_material
	trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func begin_swing() -> void:
	serial += 1
	victims.clear()
	sampled = false
func points() -> Array[Vector3]:
	var transform: Transform3D = owner_controller.skeleton.global_transform*owner_controller.skeleton.get_bone_global_pose(owner_controller.weapon_bone)
	return [transform*definition.base_local,transform*definition.tip_local]
func update_visual(delta: float) -> Array[Vector3]:
	elapsed += delta
	attachment.visible = owner_controller.weapon_mode() != "waist" and not owner_controller.neutral
	var p := points()
	if active:
		history.append({"base":p[0].lerp(p[1],.24),"tip":p[1],"time":elapsed})
	while not history.is_empty() and elapsed-history[0].time > .105: history.pop_front()
	var mesh := ImmediateMesh.new()
	if history.size() >= 2:
		mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(1,history.size()):
			var a: Dictionary = history[i-1]
			var b: Dictionary = history[i]
			for v in [a.base,a.tip,b.tip,a.base,b.tip,b.base]: mesh.surface_add_vertex(v)
		mesh.surface_end()
	trail.mesh = mesh
	return p
