extends RefCounted
static func for_creature(uid: String, species_id: String, region_id: int, territory: String, generation: int) -> Dictionary:
    return {"uid":uid,"species":species_id,"region":region_id,"territory":territory,"generation":generation,"owner":"regional_ecology","apply_locally":false}
