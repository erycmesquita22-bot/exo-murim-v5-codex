extends RefCounted
const Slots=preload("res://exo_skin3d/attachment_slots.gd")
# Only cosmetic armor modules; existing inventory/stat bonuses remain authoritative.
const ITEM_SLOTS={"iron_helm":"head","guard_cuirass":"chest","iron_pauldron":"shoulders","iron_bracers":"wrists","iron_boots":"boots"}
const OCCLUSION={"iron_helm":["head"],"guard_cuirass":["torso"],"iron_pauldron":["right_arm","left_arm"],"iron_bracers":["right_arm","left_arm"],"iron_boots":["right_leg","left_leg"]}

static func apply(rig: Node3D,cosmetics: Dictionary,layers: Dictionary) -> Array[Node]:
    var nodes: Array[Node]=[]
    var blocked: Dictionary={}
    for slot in cosmetics.get("equipment",{}):
        var item: String=str(cosmetics.equipment[slot])
        if ITEM_SLOTS.get(item,"")!=slot:continue
        nodes.append_array(Slots.add(rig,slot,item,true))
        for part in OCCLUSION.get(item,[]):blocked[part]=true
    for part in blocked:
        for mesh in layers.get(part,[]):
            if is_instance_valid(mesh):mesh.hide()
    for slot in cosmetics.get("accessories",{}):
        var item: String=str(cosmetics.accessories[slot])
        # Armor on the same slot supersedes accessories, preserving data in the profile.
        if cosmetics.get("equipment",{}).has(slot):continue
        nodes.append_array(Slots.add(rig,slot,item,false))
    return nodes
