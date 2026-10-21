extends RefCounted
const Balance = preload("res://exo_items/balance/balance_rules.gd")
static func roll(rng: RandomNumberGenerator, selected: Array, family: String, rank: int) -> Dictionary:
 var result: Dictionary = {}
 if family == "weapon": result["damage_pct"] = snappedf(0.01 + minf(0.095, float(rank) * 0.013 + rng.randf_range(0.0, 0.015)), 0.001)
 for a in selected:
  for id in a.stats:
   var bounds: Array = a.stats[id]
   var amount: float = rng.randf_range(float(bounds[0]), float(bounds[1]))
   if id in ["guard", "agilidade", "inteligencia"]: amount = roundf(amount)
   result[id] = minf(float(Balance.CAPS.get(id, 0.0)), snappedf(float(result.get(id, 0.0)) + amount, 0.001))
 return result
