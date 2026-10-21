extends RefCounted
const Catalog = preload("res://exo_items/catalog/item_catalog.gd")
const Affixes = preload("res://exo_items/generation/affix_generator.gd")
const Budget = preload("res://exo_items/balance/power_budget.gd")
const Names = preload("res://exo_items/generation/name_generator.gd")
static func valid_descriptor(item: Variant) -> bool:
 if not item is Dictionary or item.get("schema") != 2 or item.get("mode") != "preview_only": return false
 if not item.get("id") is String or not str(item.id).begins_with("exo2/"): return false
 if not item.get("seed") is int and not item.get("seed") is float: return false
 if not is_finite(float(item.seed)) or int(item.seed) != item.seed or int(item.seed) < 0 or int(item.seed) >= 2147483647: return false
 for request in ["request_rarity", "request_material"]:
  if not item.get(request) is String: return false
 if not item.get("tier") is int and not item.get("tier") is float: return false
 if item.tier != int(item.tier) or int(item.tier) < 1 or int(item.tier) > 3: return false
 if not item.get("source") is String or str(item.source).is_empty() or str(item.source).length() > 128: return false
 var family: String = str(item.get("family", ""))
 var ref: String = str(item.get("base_id", ""))
 var profile: Dictionary = Catalog.base(family, ref)
 if profile.is_empty(): return false
 var rarity: Dictionary = Catalog.rarity(str(item.get("rarity_id", "")))
 var material: Dictionary = Catalog.material(str(item.get("material_id", "")))
 if rarity.is_empty() or material.is_empty() or family not in material.families: return false
 if not str(item.request_rarity).is_empty() and str(item.request_rarity) != str(rarity.id): return false
 if not str(item.request_material).is_empty() and str(item.request_material) != str(material.id): return false
 if not item.get("level") is int and not item.get("level") is float: return false
 if not item.get("quality") is int and not item.get("quality") is float: return false
 var level: int = int(item.level)
 var quality: int = int(item.quality)
 if level != item.level or quality != item.quality or level < 1 or level > 100 or quality < 0 or quality > 3: return false
 var requested_key: String = "%d|%s|%s|%s|%d|%d|%s|%s|%d|v2" % [int(item.seed), str(item.source), family, ref, level, quality, str(item.request_rarity), str(item.request_material), int(item.tier)]
 if str(item.id) != "exo2/" + requested_key.sha256_text().substr(0, 40): return false
 if not item.get("affixes") is Array or not item.get("stats") is Dictionary: return false
 if item.affixes.size() > int(rarity.affixes): return false
 var chosen: Array = []
 var selected: Array = []
 for id in item.affixes:
  if not id is String: return false
  var a: Dictionary = Catalog.affix(id)
  if a.is_empty() or not Affixes.compatible(a, family, ref, profile.tags, chosen): return false
  chosen.append(id)
  selected.append(a)
 if not Budget.within(item.stats, rarity, level, quality, material): return false
 if not item.get("title") is String or str(item.title).length() > 180: return false
 if str(item.title) != Names.compose(profile, material, selected): return false
 return true
