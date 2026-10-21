extends RefCounted
# Canonical IDs are qualified views over existing authoritative IDs, never replacements.
static func canonical(world_id: String,kind: String,local_id: String) -> String:
 if world_id.is_empty() or kind not in ["player","npc","enemy","item","region","building"] or local_id.is_empty():return ""
 return "exo/"+world_id+"/"+kind+"/"+local_id.uri_encode()
static func player_id(save: Dictionary) -> String:return canonical(str(save.world.id),"player","protagonist")
static func npc_id(save: Dictionary,local_id: String) -> String:
 return canonical(str(save.world.id),"npc",local_id) if save.get("living_world",{}).get("npcs",{}).has(local_id) else ""
