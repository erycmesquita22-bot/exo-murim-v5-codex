extends RefCounted
# Entirely optional cosmetic extension to the existing version-4 Journey Save.
const LAYERS=["head","torso","right_arm","left_arm","right_leg","left_leg"]
const SLOTS=["hair","head","collar","chest","shoulders","wrists","waist","front_skirt","back_skirt","boots","back","sheath"]
const ACCESSORY_OPTIONS={
    "hair":["topknot"], "head":["headband","face_mask","horns"], "collar":["jade_collar"],
    "chest":["martial_vest"], "shoulders":["shoulder_cloth"], "wrists":["wrist_wraps"],
    "waist":["jade_belt"], "front_skirt":["front_robe"], "back_skirt":["back_robe"],
    "boots":["travel_boots"], "back":["short_cape"], "sheath":["sword_sheath"]
}
const ARMOR_OPTIONS={
    "head":["iron_helm"],"chest":["guard_cuirass"],"shoulders":["iron_pauldron"],
    "wrists":["iron_bracers"],"boots":["iron_boots"]
}
const ATTACHMENT_IDS=["topknot","headband","face_mask","jade_collar","martial_vest","shoulder_cloth","wrist_wraps","jade_belt","front_robe","back_robe","travel_boots","short_cape","sword_sheath","horns"]
const ARMOR_IDS=["iron_helm","guard_cuirass","iron_pauldron","iron_bracers","iron_boots"]

static func defaults() -> Dictionary:
    var visibility: Dictionary={}
    for part in LAYERS:visibility[part]=true
    return {"version":1,"model":"classic","layers":visibility,"accessories":{},"equipment":{}}

static func normalized(profile: Dictionary) -> Dictionary:
    var result: Dictionary=defaults()
    var raw: Variant=profile.get("skin3d",{})
    if not raw is Dictionary:return result
    if raw.get("model")=="slim":result.model="slim"
    if raw.get("layers") is Dictionary:
        for part in LAYERS:
            if raw.layers.get(part) is bool:result.layers[part]=raw.layers[part]
    for field in ["accessories","equipment"]:
        if raw.get(field) is Dictionary:
            for slot in SLOTS:
                var item: Variant=raw[field].get(slot,"")
                if item is String and item in (ACCESSORY_OPTIONS.get(slot,[]) if field=="accessories" else ARMOR_OPTIONS.get(slot,[])):
                    result[field][slot]=item
    return result

static func valid(raw: Variant) -> bool:
    if not raw is Dictionary:return false
    if raw.get("version")!=1 or raw.get("model") not in ["classic","slim"]:return false
    if not raw.get("layers") is Dictionary:return false
    for key in raw.layers:
        if key not in LAYERS or not raw.layers[key] is bool:return false
    for field in ["accessories","equipment"]:
        if not raw.get(field,{}) is Dictionary:return false
        for slot in raw.get(field,{}):
            if slot not in SLOTS:return false
            var allowed: Array=ACCESSORY_OPTIONS.get(slot,[]) if field=="accessories" else ARMOR_OPTIONS.get(slot,[])
            if not raw[field][slot] is String or raw[field][slot] not in allowed:return false
    return true

static func with_model(profile: Dictionary, slim: bool) -> Dictionary:
    var copy: Dictionary=profile.duplicate(true)
    var cosmetic: Dictionary=normalized(copy)
    cosmetic.model="slim" if slim else "classic"
    copy.skin3d=cosmetic
    return copy
