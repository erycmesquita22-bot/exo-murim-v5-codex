extends RefCounted
const OWNERS={"region_entered":"world","region_exited":"world","npc_interacted":"living_world","entity_state_changed":"combat","enemy_defeated":"combat","item_collected":"inventory","xp_gained":"journey","level_changed":"journey","quest_accepted":"journey","quest_completed":"journey","reward_claimed":"journey","narrative_decision":"narrative","reputation_changed":"journey","equipment_changed":"inventory","appearance_changed":"appearance","save_completed":"persistence","save_loaded":"persistence"}
static func valid(e: Dictionary) -> bool:
 if not e.get("id") is String or str(e.id).is_empty() or str(e.id).length()>160:return false
 if not OWNERS.has(e.get("type")) or e.get("source")!=OWNERS[e.type] or e.get("schema")!=1:return false
 if not e.get("context") is Dictionary or JSON.stringify(e.context).length()>8192:return false
 if not (e.get("region") is int or e.get("region") is float) or int(e.region)!=e.region or int(e.region)<-1 or int(e.region)>87:return false
 return true
