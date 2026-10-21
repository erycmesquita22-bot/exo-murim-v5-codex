extends RefCounted
# Inherit exactly the LEGACY accepted stat vocabulary and maximums.
const CAPS = {"damage_pct":0.35,"move_pct":0.08,"guard":4.0,"mana_regen":2.0,"stamina_regen":4.0,"elemental_pct":0.18,"agilidade":2.0,"inteligencia":2.0}
const COSTS = {"damage_pct":320.0,"move_pct":500.0,"guard":12.0,"mana_regen":20.0,"stamina_regen":12.0,"elemental_pct":200.0,"agilidade":15.0,"inteligencia":15.0}
static func known_stats(stats: Dictionary) -> bool:
 for key in stats:
  if not CAPS.has(key): return false
  var v: Variant = stats[key]
  if not (v is float or v is int) or not is_finite(float(v)) or float(v) < 0 or float(v) > float(CAPS[key]) + 0.00001: return false
  if key in ["guard", "agilidade", "inteligencia"] and int(v) != v: return false
 return true
