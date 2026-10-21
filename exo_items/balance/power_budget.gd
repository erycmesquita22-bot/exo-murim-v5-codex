extends RefCounted
const Balance = preload("res://exo_items/balance/balance_rules.gd")

static func cost(stats: Dictionary) -> float:
 var total: float = 0.0
 for id in stats:
  total += float(stats[id]) * float(Balance.COSTS.get(id, 1000000.0))
 return snappedf(total, 0.001)

static func budget(rarity: Dictionary, level: int, quality: int, material: Dictionary) -> float:
 return minf(100.0, float(rarity.get("budget", 0)) + minf(6.0, float(level) / 20.0) + float(quality) * 2.0 + float(material.get("power", 0)))

static func within(stats: Dictionary, rarity: Dictionary, level: int, quality: int, material: Dictionary) -> bool:
 return Balance.known_stats(stats) and cost(stats) <= budget(rarity, level, quality, material) + 0.0001

static func fit(stats: Dictionary, rarity: Dictionary, level: int, quality: int, material: Dictionary) -> Dictionary:
 var result: Dictionary = stats.duplicate(true)
 var available: float = budget(rarity, level, quality, material)
 if not Balance.known_stats(result):
  return {} # Never attempt to balance an invalid stat or negative/non-finite value.
 if cost(result) <= available:
  return result
 # Coarse proportional adjustment. Preserve integer-only stats while reducing power.
 for _pass in range(8):
  var current: float = cost(result)
  if current <= available:
   break
  var scale: float = available / maxf(0.001, current)
  for id in result:
   if id in ["guard", "agilidade", "inteligencia"]:
    result[id] = floorf(float(result[id]) * scale)
   else:
    result[id] = maxf(0.0, snappedf(float(result[id]) * scale, 0.001))
 # Float-rounding can leave a small overspend; debit one minimum tick at a time.
 for _tick in range(2000):
  if cost(result) <= available:
   break
  var target: String = ""
  var best: float = -1.0
  for id in result:
   if id in ["guard", "agilidade", "inteligencia"] or float(result[id]) < 0.001:
    continue
   if float(Balance.COSTS[id]) > best:
    best = float(Balance.COSTS[id])
    target = str(id)
  if target.is_empty():
   break
  result[target] = maxf(0.0, snappedf(float(result[target]) - 0.001, 0.001))
 # All-integer combinations might still be above budget; trim deterministically.
 for _tick in range(16):
  if cost(result) <= available:
   break
  var target: String = ""
  var best: float = -1.0
  for id in ["guard", "agilidade", "inteligencia"]:
   if result.has(id) and float(result[id]) >= 1.0 and float(Balance.COSTS[id]) > best:
    best = float(Balance.COSTS[id])
    target = id
  if target.is_empty():
   break
  result[target] = float(result[target]) - 1.0
 return result if within(result, rarity, level, quality, material) else {}
