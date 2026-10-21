extends RefCounted
static func register(core: RefCounted, provider: RefCounted) -> bool:
 # Core owns Registry/Services. No edits to core.gd, event_bus or modules.json here.
 return core.services.register_service("exo_items", "exo_items", provider, ["prepare_reward", "preview_item", "validate_item", "describe_item", "appearance_descriptor"], "2.0.1")
