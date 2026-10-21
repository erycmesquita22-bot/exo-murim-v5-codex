extends RefCounted
const Generator = preload("res://exo_items/generation/item_generator.gd")
const Inventory = preload("res://exo_items/integration/inventory_adapter.gd")
const Loot = preload("res://exo_items/integration/loot_adapter.gd")
const Economy = preload("res://exo_items/integration/economy_adapter.gd")
const Visual = preload("res://exo_items/visuals/appearance_descriptors.gd")
const Adapter = preload("res://exo_items/integration/core_adapter.gd")
var core: RefCounted
func initialize(context: RefCounted) -> bool:
 core = context
 # No save domain registered: v2 previews are never saved in the live inventory.
 # Materialized legacy weapons belong to the EXISTING inventory root.
 return Adapter.register(core, self)
func prepare_reward(source: String, pool: String, tier: int, base_id: String="") -> Dictionary:
 if core == null: return {"ok":false,"reason":"not_initialized"}
 return Loot.prepare(core.world.journey.data, source, pool, tier, base_id)
func preview_item(seed_value: int, source: String, family: String, base_id: String, level: int, quality: int=0, rarity: String="", material: String="", tier: int=1) -> Dictionary:
 return Generator.preview(seed_value, source, family, base_id, level, quality, rarity, material, tier)
func validate_item(item: Dictionary) -> bool:
 return Inventory.accepted(item)
func describe_item(item: Dictionary) -> Dictionary:
 return Economy.describe(item)
func appearance_descriptor(item: Dictionary) -> Dictionary:
 return Visual.describe(item)
func shutdown() -> void:
 core = null
