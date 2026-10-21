extends RefCounted
static func occurrence(uid: String, species: String, region: int, action: String) -> Dictionary:
    return {"uid":uid,"species":species,"region":region,"action":action,"producer":"bestiary","requires_owner_dispatch":true}
