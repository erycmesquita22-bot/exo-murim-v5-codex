extends Node
## One node per slot; replacing equipment frees the previous item.
const CONTRACT := {
	"right_hand":"socket_hand_R", "left_hand":"socket_hand_L",
	"waist":"socket_waist", "back":"socket_back", "head":"socket_head"
}
var slots: Dictionary = {}
var equipped: Dictionary = {}
var rig: Skeleton3D

func configure(skeleton: Skeleton3D) -> void:
	rig = skeleton
	for slot in CONTRACT:
		assert(skeleton.find_bone(CONTRACT[slot]) >= 0,"Missing socket " + slot)
		var attachment := BoneAttachment3D.new()
		attachment.name = "Slot_" + slot
		attachment.bone_name = CONTRACT[slot]
		skeleton.add_child(attachment)
		slots[slot] = attachment

func equip(slot: String, item: Node3D, grip_transform := Transform3D.IDENTITY) -> bool:
	if not slots.has(slot) or not is_instance_valid(item): return false
	unequip(slot)
	if item.get_parent(): item.reparent(slots[slot],false)
	else: slots[slot].add_child(item)
	item.transform = grip_transform
	equipped[slot] = item
	return true

func unequip(slot: String) -> void:
	if equipped.has(slot):
		var old: Node = equipped[slot]
		if is_instance_valid(old):
			old.get_parent().remove_child(old)
			old.queue_free()
		equipped.erase(slot)

func set_safe_height(multiplier: float) -> float:
	var value := clampf(multiplier,0.95,1.05)
	# Uniform scale avoids distorting the approved silhouette. Controller collision
	# must be resized by the owner before enabling a changed height in gameplay.
	rig.scale = Vector3.ONE*value
	return value
