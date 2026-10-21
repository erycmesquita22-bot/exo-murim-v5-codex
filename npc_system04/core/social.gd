extends RefCounted
## Bounded operational contact memory. Narrative remains authority for canonical story relationships.
const MAX_CONTACTS := 8
const COOLDOWN := 75.0
static func meet(a: Dictionary, b: Dictionary, now: float) -> bool:
    var ida: String = str(a.get("id", ""))
    var idb: String = str(b.get("id", ""))
    if ida.is_empty() or idb.is_empty() or ida == idb: return false
    var ma: Dictionary = a.get("social_memory", {})
    var mb: Dictionary = b.get("social_memory", {})
    if now < float(ma.get(idb, {}).get("next_clock", -1.0)) or now < float(mb.get(ida, {}).get("next_clock", -1.0)): return false
    _remember(ma, idb, now, int(a.get("preferences", {}).get("social", 50)))
    _remember(mb, ida, now, int(b.get("preferences", {}).get("social", 50)))
    a["social_memory"] = ma
    b["social_memory"] = mb
    return true

static func _remember(memory: Dictionary, other_id: String, now: float, sociability: int) -> void:
    if not memory.has(other_id) and memory.size() >= MAX_CONTACTS:
        var keys: Array = memory.keys(); keys.sort()
        var oldest: String = str(keys[0])
        for key in keys:
            if float(memory[key].get("last_clock", 0)) < float(memory[oldest].get("last_clock", 0)):
                oldest = str(key)
        memory.erase(oldest)
    var previous: Dictionary = memory.get(other_id, {})
    memory[other_id] = {"last_clock": now,
        "count": mini(100, int(previous.get("count", 0)) + 1),
        "warmth": clampi(int(previous.get("warmth", 0)) + (1 if sociability >= 45 else -1), -10, 10),
        "next_clock": now + COOLDOWN}
