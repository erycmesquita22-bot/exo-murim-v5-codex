extends RefCounted
const LegacyInventory = preload("res://inventory.gd")
const LegacyLoot = preload("res://procedural/loot_generator.gd")
const CoreWorld = preload("res://procedural/world_state.gd")
static func accepted(item: Variant) -> bool:
 return item is Dictionary and LegacyInventory.valid_item(item)
static func can_stage(save: Dictionary, reward: Dictionary, source: String) -> bool:
 # Read-only preflight. Does not append to items, pending_loot or events.
 if not accepted(reward) or not reward.has("generation"): return false
 if not save.get("items") is Array or not save.get("pending_loot") is Array: return false
 if not save.get("world") is Dictionary or not save.world.get("events") is Dictionary: return false
 if source.is_empty() or reward.generation.get("source") != "loot/" + source: return false
 var next_item: Variant = save.get("next_item", -1)
 if not (next_item is int or next_item is float) or not is_finite(float(next_item)) or int(next_item) != next_item or int(next_item) < 1: return false
 if reward.uid != "item_%d" % int(next_item): return false
 if save.get("items", []).size() >= LegacyInventory.CAPACITY: return false
 if CoreWorld.has_event(save.world, "loot/" + source): return false
 for entry in save.pending_loot:
  if not entry is Dictionary: return false
  if str(entry.get("source", "")) == source: return false
  if not entry.get("items", []) is Array: return false
  for other in entry.get("items", []):
   if not other is Dictionary: return false
   if other.get("uid", "") == reward.uid or other.get("instance_id", "") == reward.instance_id: return false
 for existing in save.items:
  if not existing is Dictionary: return false
  if existing.get("uid") == reward.uid or existing.get("instance_id", "") == reward.instance_id: return false
 return LegacyLoot.valid(reward)
static func never_grant_preview(item: Variant) -> bool:
 return not item is Dictionary or item.get("mode", "") != "preview_only"
