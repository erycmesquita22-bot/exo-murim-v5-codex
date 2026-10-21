extends RefCounted
static func authority_descriptor(site: String, member: int, generation: int) -> Dictionary:
    return {"territory":site,"member":member,"generation":generation,"spawn_owner":"regional_ecology","defeat_owner":"regional_ecology"}
