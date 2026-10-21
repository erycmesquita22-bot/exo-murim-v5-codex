extends RefCounted
const Catalog = preload("res://exo_items/catalog/item_catalog.gd")
static func compatible(definition: Dictionary, family: String, ref: String, tags: Array, chosen: Array) -> bool:
 if family not in definition.get("families", []): return false
 if not definition.get("refs", []).is_empty() and ref not in definition.refs: return false
 var required: Array = definition.get("tags_any", [])
 if not required.is_empty():
  var matched: bool = false
  for tag in required:
   if tag in tags: matched = true
  if not matched: return false
 for current_id in chosen:
  var previous: Dictionary = Catalog.affix(str(current_id))
  if str(previous.get("group", "")) == str(definition.get("group", "")): return false
  if str(current_id) in definition.get("excludes", []): return false
  if str(definition.id) in previous.get("excludes", []): return false
 return true
static func choose(rng: RandomNumberGenerator, family: String, ref: String, tags: Array, chosen: Array, slot: String="") -> Dictionary:
 var choices: Array = []
 var weights: int = 0
 for a in Catalog.affixes:
  if not slot.is_empty() and str(a.slot) != slot: continue
  if compatible(a, family, ref, tags, chosen):
   choices.append(a)
   weights += int(a.weight)
 if weights <= 0: return {}
 var draw: int = rng.randi_range(0, weights - 1)
 for a in choices:
  draw -= int(a.weight)
  if draw < 0: return a.duplicate(true)
 return {}
