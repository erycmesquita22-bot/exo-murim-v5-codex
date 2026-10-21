extends RefCounted
## Capture immutable canonical appearance profiles for visual-only full EXO rigs.
static func capture(region: Node3D, residents: Array) -> Dictionary:
    var profiles: Array = []
    for actor in residents:
        if not is_instance_valid(actor) or actor.identity.is_empty():continue
        profiles.append(actor.identity.duplicate(true))
        if profiles.size() >= 64:break
    region.set_meta("exo_crowd_visual_profiles",profiles)
    return {"ok":not profiles.is_empty(),"profiles":profiles.size(),"source":"NPC04.identity","full_rig":true}
