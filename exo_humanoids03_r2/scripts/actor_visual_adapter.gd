extends RefCounted
## Optional VISUAL event consumer. No monkey-patching, no modifications to Core/NPC/Bestiary.
const Presets = preload("res://exo_humanoids03_r2/scripts/preset_selector.gd")
const WardrobeR2 = preload("res://exo_humanoids03_r2/scripts/murim_wardrobe.gd")

## Call only after the Core's Wardrobe.apply and Skin3D.apply on the original Rig.
## Reuse saved_selection when loading a persisted character; save the returned selection.
# Character Refit 01 supersedes R2's redundant garment geometry.
# Keep stable saved visual selection and action metadata, but NEVER instantiate
# R2 meshes above the new full Murim figure. This prevents duplicate models.
static func on_visual_created(rig: Node3D, visual_event: Dictionary, saved_selection: Dictionary = {}) -> Dictionary:
    if rig == null or not is_instance_valid(rig):return {}
    var uid:String=str(visual_event.get("uid",""))
    if uid.is_empty():return {}
    var choice:Dictionary=saved_selection.duplicate(true) if not saved_selection.is_empty() else Presets.choose(visual_event)
    if not Presets.valid(choice) or str(choice.get("uid",""))!=uid:return {}
    WardrobeR2.clear(rig)
    rig.set_meta("exo_humanoid_r2_selection",choice.duplicate(true))
    rig.set_meta("exo_visual_owner","exo_character_refit01")
    return choice.duplicate(true)

static func on_wardrobe_reapplied(rig: Node3D, visual_event: Dictionary, saved_selection: Dictionary) -> bool:
    if rig==null or not Presets.valid(saved_selection):return false
    if str(saved_selection.get("uid",""))!=str(visual_event.get("uid","")):return false
    WardrobeR2.clear(rig)
    rig.set_meta("exo_humanoid_r2_selection",saved_selection.duplicate(true))
    return true

static func on_action_changed(rig: Node3D, action: String, is_active: bool) -> void:
    # Animation remains owned by Rig and Arsenal; no second wardrobe writes poses.
    if rig!=null and is_instance_valid(rig):rig.set_meta("exo_refit_action_"+action,is_active)

static func on_visual_removed(rig: Node3D) -> void:
    WardrobeR2.clear(rig)

static func _settings(rig: Node3D, visual_event: Dictionary) -> Dictionary:
    var defaults: Dictionary = rig.get_meta("skin3d_cosmetics",{})
    var model: String = str(defaults.get("model","classic"))
    if model not in ["classic","slim"]: model = "classic"
    return {"body_model":model,
        "weapon":str(visual_event.get("weapon_id","")),
        "weapon_state":str(visual_event.get("weapon_state","unknown")),
        "allow_extra_hair":bool(visual_event.get("has_imported_skin_without_geo_hair",false)),
        "hide_insignia":bool(visual_event.get("hide_insignia",false))}
