extends RefCounted
# One source for current capacities. Level-based unlocks can replace this policy without changing executors.
const ACTIVE=3
const PASSIVE=2
const MAX_ACTIVE=6
static func active_count(data: Dictionary) -> int:return data.get("loadout",[]).size() if not data.get("loadout",[]).is_empty() else ACTIVE
