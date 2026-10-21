extends RefCounted
## No write interface for city situations in R13 narrative_hooks; exposes unbound proposals only.
static func potential_context(city: Dictionary) -> Dictionary:
 var social: Dictionary=city.get("society",{})
 return {"region_id":city.get("region_id",-1),"families":social.get("families",[]).duplicate(true),"potential_situations":social.get("situations",[]).duplicate(true),"status":"read_only_unbound","no_events_executed":true}
