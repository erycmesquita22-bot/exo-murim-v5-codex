extends RefCounted
const Generator = preload("res://exo_items/generation/item_generator.gd")
const Inventory = preload("res://exo_items/integration/inventory_adapter.gd")
static func prepare(save: Dictionary, source: String, pool: String, tier: int, base_id: String="") -> Dictionary:
 if not save.get("world") is Dictionary: return {"ok":false,"reason":"world_absent"}
 var sequence: Variant = save.get("next_item")
 if not (sequence is int or sequence is float) or not is_finite(float(sequence)) or int(sequence) != sequence or int(sequence) < 1 or int(sequence) > 2147483647:
  return {"ok":false,"reason":"uid_invalid"}
 var item: Dictionary = Generator.compatible_reward(save.world, source, pool, tier, "item_%d" % int(save.next_item), base_id)
 if item.is_empty(): return {"ok":false,"reason":"incompatible_or_repeated"}
 if not Inventory.can_stage(save, item, source): return {"ok":false,"reason":"inventory_full_or_duplicate"}
 return {"ok":true,"item":item,"committed":false,"requires_owner_transaction":true}
# The original loot owner must reserve IDs, stage events and commit exactly once.
