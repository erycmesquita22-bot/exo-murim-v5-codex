extends RefCounted
## NEW cosmetic-only geometry on the actual EXO Rig joints. Never touches UV, animation,
## skin3d layers, combat mesh, armor inventory, AI, collision shapes or the save authority.
const G = preload("res://exo_humanoids03_r2/scripts/voxel_geometry.gd")
const Selection = preload("res://exo_humanoids03_r2/scripts/preset_selector.gd")
const META_ROOTS = "exo_humanoid_r2_roots"

static func _colors(palette: String, prestige: int, variant: String) -> Dictionary:
    var palettes: Dictionary = Selection.catalog().get("factions",{})
    var paint: Dictionary = palettes.get(palette,palettes.get("neutral",{}))
    var cloth: Color = Color(str(paint.get("cloth","394f53")))
    if variant == "b": cloth = cloth.lightened(0.085)
    if variant == "c": cloth = cloth.darkened(0.085)
    var trim: Color = Color(str(paint.get("trim","bba171")))
    if prestige < 2: trim = trim.darkened(0.22)
    return {"main":cloth,"dark":cloth.darkened(0.24),"light":cloth.lightened(0.19),
            "trim":trim,"lining":Color(str(paint.get("lining","d9d2bc"))),
            "metal":Color(str(paint.get("metal","5e7277"))),
            "leather":Color("342e2d"),"jade":Color("4ca491")}

static func _pivot_root(parent: Node3D, label: String, roots: Array) -> Node3D:
    var node := Node3D.new()
    node.name = "EXOR2_"+label
    parent.add_child(node)
    roots.append(node)
    return node

static func clear(rig: Node3D) -> void:
    if rig == null or not is_instance_valid(rig): return
    for node in rig.get_meta(META_ROOTS, []):
        if node is Node3D and is_instance_valid(node):
            node.hide()
            if node.get_parent() != null:node.get_parent().remove_child(node)
            node.queue_free()
    for previous in rig.get_meta("exo_r10_legacy_hidden", []):
        if is_instance_valid(previous):previous.show()
    if rig.has_meta("exo_r10_legacy_hidden"):rig.remove_meta("exo_r10_legacy_hidden")
    if rig.has_meta(META_ROOTS): rig.remove_meta(META_ROOTS)
    if rig.has_meta("exo_humanoid_r2_selection"): rig.remove_meta("exo_humanoid_r2_selection")
    for action in ["roll","crouch","two_handed"]:
        var state_key: String = "exo_r10_last_" + action
        if rig.has_meta(state_key):rig.remove_meta(state_key)

static func _dress_torso(root: Node3D, style: Dictionary, tints: Dictionary) -> void:
    var robe: String = str(style.get("robe","short_split"))
    var long_robe: bool = robe in ["sect_split", "master_formal", "trader_layers"]
    var m: Color = tints.main
    var d: Color = tints.dark
    var l: Color = tints.light
    var trim: Color = tints.trim
    # Blocky overlapping panels make a silhouette, without flattening the original skin atlas.
    G.panel(root,"front_lapel",Vector3(-.13,.47,-.146),Vector2(.19,.045),Vector2(.23,.055),.46,m)
    G.panel(root,"right_lapel",Vector3(.13,.47,-.146),Vector2(.19,.045),Vector2(.23,.055),.46,d)
    G.part(root,"front_seam",Vector3(.02,.36,-.185),Vector3(.021,.50,.018),trim)
    G.part(root,"under_collar",Vector3(0,.707,-.012),Vector3(.55,.071,.33),l)
    G.part(root,"collar_front_L",Vector3(-.182,.652,-.167),Vector3(.082,.13,.067),trim)
    G.part(root,"collar_front_R",Vector3(.182,.652,-.167),Vector3(.082,.13,.067),trim)
    G.part(root,"waist_wrap",Vector3(0,.135,-.01),Vector3(.532,.125,.317),d)
    G.part(root,"waist_band_edge",Vector3(0,.159,-.173),Vector3(.49,.020,.018),trim)
    if robe == "master_formal":
        # Higher collar and two restrained mantle tabs, distinctive at isometric distance.
        G.panel(root,"formal_back_collar",Vector3(0,.753,.112),Vector2(.56,.21),Vector2(.52,.21),.17,l)
        for side in [-1,1]:
            G.part(root,"mantle",Vector3(side*.225,.635,.042),Vector3(.116,.21,.32),d)
            G.part(root,"mantle_tip",Vector3(side*.225,.534,-.125),Vector3(.084,.022,.042),trim)
    elif robe == "trader_layers":
        G.part(root,"merchant_wallet_strap",Vector3(.19,.34,-.173),Vector3(.053,.52,.041),tints.leather)
        G.part(root,"merchant_wallet",Vector3(.245,.082,-.125),Vector3(.165,.19,.105),d)
        G.part(root,"merchant_wallet_catch",Vector3(.245,.135,-.185),Vector3(.06,.046,.02),trim)
    elif robe == "guard_tunic":
        G.part(root,"guard_tunic_brim",Vector3(0,.21,-.18),Vector3(.49,.074,.045),trim)
    if long_robe:
        for side in [-1,1]:
            G.part(root,"side_belt_knot",Vector3(side*.235,.105,-.166),Vector3(.078,.105,.056),trim)

static func _leg_flaps(leg_roots: Array, robe: String, c: Dictionary) -> void:
    # Split-leg cloth follows ORIGINAL leg pivots, not a static skirt through knees.
    var length_value: float = .39 if robe in ["sect_split","master_formal","trader_layers"] else .28
    for i in range(2):
        var lr: Node3D = leg_roots[i]
        var tint: Color = c.main if i == 0 else c.dark
        var bottom_width: float = .247 if length_value > .30 else .221
        G.panel(lr,"leg_front_panel",Vector3(0,-length_value*.5,-.145),
            Vector2(.221,.069),Vector2(bottom_width,.077),length_value,tint)
        G.part(lr,"hem",Vector3(0,-length_value+.021,-.185),Vector3(bottom_width,.022,.017),c.trim)
        if length_value > .30:
            G.panel(lr,"leg_back_panel",Vector3(0,-length_value*.5,.15),
                Vector2(.21,.052),Vector2(bottom_width,.070),length_value,c.dark)

static func _sleeves(arm_roots: Array, forearm_roots: Array, shape: String, slim: bool, c: Dictionary, weapon_state: String) -> void:
    var sleeve_width: float = .258 if slim else .319
    for i in range(2):
        var p: Node3D = arm_roots[i]
        var f: Node3D = forearm_roots[i]
        var cloth_tint: Color = c.main if i == 0 else c.dark
        G.panel(p,"upper_sleeve",Vector3(0,-.175,0),
            Vector2(sleeve_width-.029,.27),Vector2(sleeve_width,.299),.337,cloth_tint)
        G.part(p,"upper_sleeve_hem",Vector3(0,-.331,-.155),Vector3(sleeve_width,.023,.017),c.trim)
        if shape == "wide_sleeves":
            # The cuff stays near wrist; no extended rigid flap crossing the sword grip.
            G.panel(f,"martial_cuff",Vector3(0,-.148,0),
                Vector2(sleeve_width,.30),Vector2(sleeve_width+.023,.31),.198,c.dark)
            G.part(f,"cuff_trim",Vector3(0,-.252,-.160),Vector3(sleeve_width+.015,.028,.017),c.trim)
        elif shape == "wrappings":
            for y in [-.101,-.179,-.238]:
                G.part(f,"combat_binding",Vector3(0,y,-.143),Vector3(sleeve_width-.015,.035,.015),c.lining)
        else:
            G.part(f,"guard_wrist_band",Vector3(0,-.183,-.147),
                Vector3(sleeve_width+.015,.135,.033),c.leather)
        # Hands remain untouched, especially with two-handed weapon poses.

static func _headwear(head_root: Node3D, item: String, c: Dictionary) -> void:
    match item:
        "topknot_voxel":
            G.part(head_root,"hair_cap",Vector3(0,.519,.026),Vector3(.49,.09,.48),c.leather)
            G.panel(head_root,"hair_knot",Vector3(0,.645,.079),Vector2(.18,.16),Vector2(.21,.20),.21,c.leather)
            G.part(head_root,"knot_ring",Vector3(0,.576,.082),Vector3(.245,.04,.24),c.trim)
        "guard_cap":
            G.part(head_root,"hat_band",Vector3(0,.469,0),Vector3(.59,.086,.57),c.dark)
            G.panel(head_root,"hat_crown",Vector3(0,.576,0),Vector2(.35,.34),Vector2(.53,.51),.20,c.metal)
            G.part(head_root,"crest",Vector3(0,.57,-.282),Vector3(.099,.172,.031),c.trim)
        "traveler_hat":
            G.panel(head_root,"hat_crown",Vector3(0,.608,0),Vector2(.19,.19),Vector2(.52,.52),.19,c.dark)
            G.part(head_root,"hat_brim",Vector3(0,.509,0),Vector3(.83,.034,.78),c.leather)
            G.part(head_root,"hat_ribbon",Vector3(0,.535,-.271),Vector3(.36,.034,.026),c.trim)
        "hood":
            G.panel(head_root,"hood",Vector3(0,.325,.055),Vector2(.62,.60),Vector2(.61,.59),.51,c.dark)
            # Hollow face silhouette: frontal opening (no opaque cube over the face).
            G.part(head_root,"hood_brow",Vector3(0,.535,-.27),Vector3(.62,.075,.045),c.main)
            for side in [-1,1]:
                G.part(head_root,"hood_side",Vector3(side*.287,.302,-.268),Vector3(.06,.42,.046),c.main)
        "mask":
            G.part(head_root,"face_mask",Vector3(0,.153,-.305),Vector3(.435,.19,.049),c.dark)
            G.part(head_root,"face_mask_stripe",Vector3(0,.122,-.333),Vector3(.28,.029,.014),c.trim)
        _:
            pass

static func _insignia(chest: Node3D, shape: String, c: Dictionary, prestige: int) -> void:
    if shape == "none": return
    G.part(chest,"insignia_base",Vector3(0,.474,-.192),Vector3(.153,.155,.031),c.dark)
    if shape == "river":
        for i in range(3):
            G.part(chest,"insignia_wave",Vector3(-.047+i*.045,.48+(i%2)*.022,-.211),Vector3(.025,.096,.013),c.trim)
    elif shape == "crescent":
        G.part(chest,"insignia_moon_a",Vector3(-.025,.485,-.211),Vector3(.03,.098,.018),c.trim)
        G.part(chest,"insignia_moon_b",Vector3(.017,.52,-.211),Vector3(.062,.029,.018),c.trim)
    elif shape == "mountain":
        for i in range(3):
            G.part(chest,"insignia_peak",Vector3(-.044+i*.044,.45+(1 if i==1 else 0)*.032,-.211),
                Vector3(.033,.065+(1 if i==1 else 0)*.055,.015),c.trim)
    elif shape == "sun":
        G.part(chest,"insignia_sun",Vector3(0,.476,-.212),Vector3(.081,.084,.016),c.trim)
        G.part(chest,"insignia_sun_ray",Vector3(0,.539,-.215),Vector3(.019,.028,.012),c.trim)
    else:
        G.part(chest,"insignia_vertical",Vector3(0,.471,-.212),Vector3(.045,.10,.018),c.trim)
    if prestige >= 3:
        G.part(chest,"rank_marker",Vector3(0,.355,-.207),Vector3(.125,.026,.017),c.trim)

static func _equipment(chest: Node3D, arms: Array, shape: String, c: Dictionary) -> void:
    if shape != "sentinel": return
    G.part(chest,"guard_core_armor",Vector3(0,.417,-.204),Vector3(.45,.31,.082),c.metal)
    G.part(chest,"guard_armor_edge",Vector3(0,.248,-.238),Vector3(.51,.057,.043),c.trim)
    for i in range(2):
        var side: float = -1.0 if i == 0 else 1.0
        var a: Node3D = arms[i]
        G.panel(a,"pauldron",Vector3(side*.02,-.061,0),Vector2(.34,.33),Vector2(.37,.35),.20,c.metal)
        G.part(a,"shoulder_line",Vector3(0,-.087,-.18),Vector3(.32,.03,.026),c.trim)

static func _accessories(chest: Node3D, extra: String, c: Dictionary, sheath_ok: bool) -> void:
    match extra:
        "scroll_case":
            G.part(chest,"merchant_scroll_case",Vector3(-.27,.268,.128),Vector3(.113,.33,.125),c.leather)
            G.part(chest,"scroll_lid",Vector3(-.27,.45,.128),Vector3(.13,.057,.14),c.trim)
        "prayer_beads":
            for i in range(3):
                G.part(chest,"disciple_beads",Vector3(-.154+i*.15,.612,-.178),Vector3(.055,.05,.044),c.jade)
        "seal_tassel":
            G.part(chest,"seal",Vector3(.193,.106,-.204),Vector3(.089,.12,.05),c.trim)
            G.part(chest,"tassel",Vector3(.193,-.049,-.209),Vector3(.043,.175,.043),c.dark)
        _:
            pass
    if sheath_ok:
        # Empty scabbard only; authoritative arsenal owns the actual weapon model.
        var p:=Node3D.new()
        p.name="ScabbardSocketVisual"
        chest.add_child(p)
        p.position=Vector3(.247,.355,.221)
        p.rotation.z=.52
        G.part(p,"sword_scabbard",Vector3(0,-.255,0),Vector3(.087,.53,.109),c.leather)
        G.part(p,"mouth",Vector3(0,.012,0),Vector3(.135,.047,.13),c.trim)

static func apply(rig: Node3D, selection: Dictionary, pose_options: Dictionary = {}) -> bool:
    if rig == null or not is_instance_valid(rig) or not Selection.valid(selection): return false
    var torso: Variant = rig.get("torso")
    var arms: Variant = rig.get("arms")
    var forearms: Variant = rig.get("forearms")
    var legs: Variant = rig.get("legs")
    if not (torso is Node3D and arms is Array and forearms is Array and legs is Array): return false
    if arms.size() != 2 or forearms.size() != 2 or legs.size() != 2 or torso.get_child_count() < 2: return false
    var head: Node3D = torso.get_child(1) as Node3D
    if head == null: return false
    # Never silently overwrite cosmetics after UID has been bound to a different actor.
    var prior: Dictionary = rig.get_meta("exo_humanoid_r2_selection",{})
    if not prior.is_empty() and str(prior.get("uid","")) != str(selection.get("uid","")): return false
    clear(rig)
    # Hide legacy robe decoration only after the official Wardrobe and Skin3D ran.
    # Never hide the skin atlas, UV layers, inventory equipment or weapon nodes.
    var replaced: Array = []
    for garment in rig.get_meta("garments", []):
        if garment is CanvasItem or garment is Node3D:
            if is_instance_valid(garment) and garment.visible:
                garment.hide()
                replaced.append(garment)
    rig.set_meta("exo_r10_legacy_hidden",replaced)
    var roots: Array = []
    var torso_root: Node3D = _pivot_root(torso,"torso",roots)
    var head_root: Node3D = _pivot_root(head,"head",roots)
    var upper_roots: Array = []
    var lower_roots: Array = []
    var leg_roots: Array = []
    for i in range(2):
        upper_roots.append(_pivot_root(arms[i],"arm_"+str(i),roots))
        lower_roots.append(_pivot_root(forearms[i],"forearm_"+str(i),roots))
        leg_roots.append(_pivot_root(legs[i],"leg_"+str(i),roots))
    var style: Dictionary = selection["style"]
    var prestige: int = int(style.get("prestige",0))
    var colors: Dictionary = _colors(str(style.get("palette","neutral")),prestige,str(style.get("variant","a")))
    var robe: String = str(style.get("robe","short_split"))
    var slim: bool = str(pose_options.get("body_model","classic")) == "slim"
    _dress_torso(torso_root,style,colors)
    _leg_flaps(leg_roots,robe,colors)
    _sleeves(upper_roots,lower_roots,str(style.get("sleeves","wrappings")),slim,colors,str(pose_options.get("weapon_state","unknown")))
    var base_cosmetics: Dictionary = rig.get_meta("skin3d_cosmetics",{})
    var base_equipment: Dictionary = base_cosmetics.get("equipment",{})
    var headwear: String = str(style.get("headwear","none"))
    # Existing vanilla/imported hair is never rewritten; extra voxel hair is opt-in.
    if headwear != "topknot_voxel" or bool(pose_options.get("allow_extra_hair",false)):
        _headwear(head_root,headwear,colors)
    var armor_exists: bool = not base_equipment.is_empty()
    if not armor_exists:
        _equipment(torso_root,upper_roots,str(style.get("armor","none")),colors)
    var emblem: String = str(style.get("emblem","neutral"))
    if bool(pose_options.get("hide_insignia",false)): emblem = "none"
    _insignia(torso_root,emblem,colors,prestige)
    var weapon_state: String = str(pose_options.get("weapon_state","unknown"))
    var base_accessories: Dictionary = base_cosmetics.get("accessories",{})
    var occupied_sheath: bool = base_accessories.has("sheath")
    var has_sword: bool = str(pose_options.get("weapon","")) in ["sword","dagger","daggers"]
    var sheath_ok: bool = weapon_state == "sheathed" and has_sword and not occupied_sheath and not is_instance_valid(rig.get_meta("carry_sheath",null))
    _accessories(torso_root,str(style.get("extra","none")),colors,sheath_ok)
    rig.set_meta(META_ROOTS,roots)
    rig.set_meta("exo_humanoid_r2_selection",selection.duplicate(true))
    rig.set_meta("exo_humanoid_r2_pose",{"weapon_state":weapon_state,"roll":false,"crouch":false,"two_handed":false})
    return true

## Explicit event adapter, NOT _process; updates only cosmetic visibility flags.
static func on_pose_event(rig: Node3D, action: String, enabled: bool) -> void:
    if rig == null or not is_instance_valid(rig): return
    if action not in ["roll","crouch","two_handed"]: return
    var poses: Dictionary = rig.get_meta("exo_humanoid_r2_pose",{})
    poses[action] = enabled
    rig.set_meta("exo_humanoid_r2_pose",poses)
    var hide_flaps: bool = bool(poses.get("roll",false)) or bool(poses.get("crouch",false))
    var hide_cuff: bool = bool(poses.get("two_handed",false))
    for root in rig.get_meta(META_ROOTS,[]):
        if not (root is Node3D and is_instance_valid(root)): continue
        if root.name.begins_with("EXOR2_leg_"):
            for child in root.get_children():
                if child.name in ["leg_front_panel","leg_back_panel","hem"]: child.visible = not hide_flaps
        if root.name.begins_with("EXOR2_forearm_"):
            for child in root.get_children():
                if child.name in ["martial_cuff","cuff_trim"]: child.visible = not hide_cuff
