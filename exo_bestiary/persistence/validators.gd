extends RefCounted
static func valid_descriptor(value: Dictionary) -> bool:
    return not str(value.get("uid","")).is_empty() and int(value.get("region",-1))>=0 and int(value.get("generation",-1))>=0 and str(value.get("owner",""))=="regional_ecology"
