extends RefCounted
const PRESETS = {
    "low": {"max_effects": 4, "detail": 4, "secondary_passes": false, "dynamic_lights": 0},
    "medium": {"max_effects": 8, "detail": 9, "secondary_passes": true, "dynamic_lights": 0},
    "high": {"max_effects": 14, "detail": 18, "secondary_passes": true, "dynamic_lights": 0}
}
static func get_profile(name: String) -> Dictionary:
    return PRESETS.get(name, PRESETS.low).duplicate(true)
