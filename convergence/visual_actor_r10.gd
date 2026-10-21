extends RefCounted
## R10 visual-only bridge. The existing Rig, Wardrobe, Skin3D and Arsenal stay authoritative.
## No spawns, stats, combat, faction changes, external PNGs or secondary save manager.
const R2 = preload("res://exo_humanoids03_r2/scripts/actor_visual_adapter.gd")
const Selection = preload("res://exo_humanoids03_r2/scripts/preset_selector.gd")
const Entity = preload("res://exo_core/contracts/entity_contracts.gd")
const MartialCatalog = preload("res://exo_martial/styles/martial_catalog.gd")

static func enabled() -> bool:
    return bool(ProjectSettings.get_setting("exo_murim/r10/humanoids_enabled", true))

static func _profile(role: String, faction: String, school_id: String) -> Dictionary:
    var supported: Dictionary = Selection.catalog().get("roles", {})
    var final_role: String = role if supported.has(role) else "resident"
    var palette: String = faction if Selection.catalog().get("factions", {}).has(faction) else "neutral"
    # Only a verified canonical school ID may select the proposed Jade palette.
    if not school_id.is_empty() and not MartialCatalog.school(school_id).is_empty():
        if school_id == "exo_martial.school.mosteiro_jade":palette = "jade_martial_school"
    if role == "guard" and palette == "neutral":palette = "city_guard"
    return {"role":final_role,"faction":palette}

static func apply_resident(rig: Node3D, identity: Dictionary, saved: Dictionary = {}, seed_text: String = "") -> Dictionary:
    if not enabled() or rig == null or not is_instance_valid(rig):return {}
    var uid: String = str(identity.get("id", ""))
    if not uid.begins_with("npc/r"):return {}
    var app: Dictionary = identity.get("appearance", {})
    if not app is Dictionary:return {}
    var role: String = str(identity.get("role", "resident"))
    var choice: Dictionary = _profile(role,str(identity.get("faction", "neutral")),str(identity.get("martial_school_id", "")))
    var desc: Dictionary = {"uid":uid,"world_seed":seed_text,"region_id":str(identity.get("region_id", "")),"role":choice.role,"faction":choice.faction,"prestige":2 if role == "master" else 1 if role == "guard" else 0,"weapon_id":str(rig.get_meta("weapon_id", "")),"weapon_state":"sheathed"}
    var existing: Dictionary = saved.get("visual_r2", {})
    if not Selection.valid(existing) or str(existing.get("uid", "")) != uid:
        existing = app.get("visual_r2", {})
    if not Selection.valid(existing) or str(existing.get("uid", "")) != uid:existing = {}
    var result: Dictionary = R2.on_visual_created(rig,desc,existing)
    if not result.is_empty():
        # Store only JSON data in the LivingWorld-owned canonical appearance record.
        app["visual_r2"] = result.duplicate(true)
        identity["appearance"] = app
        var spec: Dictionary = preload("res://catalog.gd").weapon(str(rig.get_meta("weapon_id","")))
        notify_action(rig,"two_handed",int(spec.get("hands",1))==2)
    return result

static func apply_player(world: Node3D) -> Dictionary:
    if not enabled() or world == null or not is_instance_valid(world.model) or world.journey == null:return {}
    var character: Dictionary = world.journey.data.get("character", {})
    if character.is_empty():return {}
    var skin_file: String = str(character.get("skin_file", ""))
    if skin_file.begins_with("user://exo_skins/") and FileAccess.file_exists(skin_file):
        # Preserve the user's literal 64x64 PNG; R2 does not add unsolicited robes.
        R2.on_visual_removed(world.model)
        return {}
    var uid: String = Entity.player_id(world.journey.data)
    if uid.is_empty():return {}
    var school_id: String = "" # No fabricated affiliation from visual clothing.
    var choice: Dictionary = _profile("player", "neutral", school_id)
    var desc: Dictionary = {"uid":uid,"world_seed":str(world.journey.data.world.seed),"region_id":str(world.journey.data.get("convergence",{}).get("current",-1)),"role":choice.role,"faction":choice.faction,"prestige":0,"weapon_id":str(character.get("weapon", "")),"weapon_state":"drawn"}
    var previous: Dictionary = character.get("visual_r2", {})
    if not Selection.valid(previous) or str(previous.get("uid", "")) != uid:previous = {}
    var result: Dictionary = R2.on_visual_created(world.model,desc,previous)
    if not result.is_empty():
        character["visual_r2"] = result.duplicate(true)
        var weapon: String = str(world.model.get_meta("weapon_id", ""))
        var spec: Dictionary = preload("res://catalog.gd").weapon(weapon)
        notify_action(world.model,"two_handed",int(spec.get("hands",1))==2)
    return result

static func apply_enemy(rig: Node3D, uid: String, role: String, seed_text: String) -> Dictionary:
    if not enabled() or rig == null or not is_instance_valid(rig) or uid.is_empty():return {}
    var roles: Dictionary = Selection.catalog().get("roles", {})
    var actual_role: String = role if roles.has(role) else "hostile_wanderer"
    var desc: Dictionary = {"uid":uid,"world_seed":seed_text,"region_id":"hostiles","role":actual_role,"faction":"neutral","weapon_id":str(rig.get_meta("weapon_id", "")),"weapon_state":"drawn"}
    var result: Dictionary = R2.on_visual_created(rig,desc)
    if not result.is_empty():
        var spec: Dictionary = preload("res://catalog.gd").weapon(str(rig.get_meta("weapon_id","")))
        notify_action(rig,"two_handed",int(spec.get("hands",1))==2)
    return result

static func notify_action(rig: Node3D, action: String, enabled_now: bool) -> void:
    if not enabled() or rig == null or not rig.has_meta("exo_humanoid_r2_selection"):return
    var key: String = "exo_r10_last_" + action
    if rig.has_meta(key) and bool(rig.get_meta(key)) == enabled_now:return
    rig.set_meta(key,enabled_now)
    R2.on_action_changed(rig,action,enabled_now)

static func cleanup(rig: Node3D) -> void:
    if rig == null or not is_instance_valid(rig):return
    R2.on_visual_removed(rig)
