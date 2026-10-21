extends RefCounted
const Catalog = preload("res://exo_items/catalog/item_catalog.gd")
static func select(rng: RandomNumberGenerator, tier: int, requested: String="") -> Dictionary:
 if not requested.is_empty(): return Catalog.rarity(requested)
 if tier < 1 or tier > 3: return {}
 var total: int = 0
 for r in Catalog.rarities: total += int(r.tier_weights[tier - 1])
 if total <= 0: return {}
 var value: int = rng.randi_range(0, total - 1)
 for r in Catalog.rarities:
  value -= int(r.tier_weights[tier - 1])
  if value < 0: return r.duplicate(true)
 return {}
