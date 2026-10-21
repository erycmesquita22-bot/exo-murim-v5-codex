extends RefCounted
const Catalog = preload("res://exo_items/catalog/item_catalog.gd")
const Materials = preload("res://exo_items/catalog/material_catalog.gd")
const Rarity = preload("res://exo_items/generation/rarity_generator.gd")
const Affixes = preload("res://exo_items/generation/affix_generator.gd")
const Stats = preload("res://exo_items/generation/stat_generator.gd")
const Names = preload("res://exo_items/generation/name_generator.gd")
const Power = preload("res://exo_items/balance/power_budget.gd")
const Validator = preload("res://exo_items/balance/stat_validator.gd")
# Legacy authoritative generator. No fork of inventory, damage calculation or loot rules.
const LegacyLoot = preload("res://procedural/loot_generator.gd")
const LegacyInventory = preload("res://inventory.gd")
const WorldSeed = preload("res://procedural/world_state.gd")

static func compatible_reward(world: Dictionary, source: String, pool: String, tier: int, uid: String, base_id: String="") -> Dictionary:
 if not WorldSeed.valid(world) or source.is_empty() or source.length() > 123: return {}
 if pool not in ["blade", "mage", "boss"] or tier < 1 or tier > 3: return {}
 if not uid.begins_with("item_") or not uid.trim_prefix("item_").is_valid_int() or int(uid.trim_prefix("item_")) < 1: return {}
 if not base_id.is_empty() and Catalog.base("weapon", base_id).is_empty(): return {}
 var key: String = "loot/" + source
 if WorldSeed.has_event(world, key): return {}
 var result: Dictionary = LegacyLoot.generate(world, key, pool, tier, uid, base_id)
 if result.is_empty() or not LegacyInventory.valid_item(result): return {}
 return result

static func preview(seed_value: int, source: String, family: String, base_id: String, level: int, quality: int=0, requested_rarity: String="", requested_material: String="", tier: int=1) -> Dictionary:
 if seed_value < 0 or seed_value >= 2147483647 or source.is_empty() or source.length() > 128: return {}
 if level < 1 or level > 100 or quality < 0 or quality > 3: return {}
 var profile: Dictionary = Catalog.base(family, base_id)
 if profile.is_empty(): return {}
 var rng := RandomNumberGenerator.new()
 var key: String = "%d|%s|%s|%s|%d|%d|%s|%s|%d|v2" % [seed_value, source, family, base_id, level, quality, requested_rarity, requested_material, tier]
 rng.seed = int(key.sha256_text().substr(0, 15).hex_to_int())
 var rarity: Dictionary = Rarity.select(rng, tier, requested_rarity)
 if rarity.is_empty(): return {}
 var material: Dictionary = Catalog.material(requested_material) if not requested_material.is_empty() else {}
 if material.is_empty() and not requested_material.is_empty(): return {}
 if material.is_empty():
  var options: Array = Materials.candidates(family)
  if options.is_empty(): return {}
  material = options[rng.randi_range(0, options.size() - 1)]
 if family not in material.get("families", []): return {}
 var chosen_ids: Array = []
 var selected: Array = []
 for idx in range(int(rarity.affixes)):
  var slot: String = "prefix" if idx == 0 else "suffix" if idx == 1 else ""
  var candidate: Dictionary = Affixes.choose(rng, family, base_id, profile.tags, chosen_ids, slot)
  if candidate.is_empty(): break # never invent incompatible modifiers to reach a quota
  chosen_ids.append(str(candidate.id))
  selected.append(candidate)
 var stats: Dictionary = Stats.roll(rng, selected, family, int(rarity.rank))
 stats = Power.fit(stats, rarity, level, quality, material)
 var item: Dictionary = {
  "schema":2, "mode":"preview_only", "id":"exo2/" + key.sha256_text().substr(0, 40),
  "seed":seed_value, "source":source, "family":family, "base_id":base_id,
  "material_id":str(material.id), "rarity_id":str(rarity.id), "level":level,
  "quality":quality, "tier":tier, "request_rarity":requested_rarity, "request_material":requested_material, "affixes":chosen_ids, "stats":stats,
  "title":Names.compose(profile, material, selected), "origin":"procedural_preview",
  "rules_version":2
 }
 if not Validator.valid_descriptor(item): return {}
 return item
