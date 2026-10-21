extends RefCounted
# Semantic station names are optional contracts, not newly spawned architecture.
# Fall back to physically routed @activity, @square, or the existing home lot.
const ALIASES={
	"market_stall":"@activity","workshop_station":"@activity",
	"training_courtyard":"@activity","martial_hall":"@activity",
	"master_station":"@activity","disciple_station":"@activity",
	"guard_post":"@activity","patrol_waypoint":"@square",
	"social_area":"@square"}
static func resolve(semantic: String,person: Dictionary,available: Dictionary={}) -> String:
	var fallback: String=str(ALIASES.get(semantic,"@activity"))
	if available.has(semantic) and available[semantic] is Array and not available[semantic].is_empty():return semantic
	if fallback=="@activity" and str(person.get("work_slot","")).is_empty():return str(person.get("home_slot",""))
	return fallback
