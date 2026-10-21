extends RefCounted
const LegacyLoot = preload("res://procedural/loot_generator.gd")
static func legacy_weapon_stats(item: Dictionary) -> Dictionary:
 if item.get("kind", "") != "weapon": return {}
 if not LegacyLoot.valid(item): return {}
 return LegacyLoot.weapon(item) # Only official legacy math; NEVER calculate parallel damage.
static func martial_affinities(descriptor: Dictionary) -> Dictionary:
 return {"family":descriptor.get("family", ""),"affixes":descriptor.get("affixes", []).duplicate(true),"enabled":false,"requires_approved_contract":true}
