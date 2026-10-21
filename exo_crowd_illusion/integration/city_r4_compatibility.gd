extends RefCounted
## Contract negotiation for City Forge R4 (0.4.0-qa) semantic plans.
## City Forge NEVER gives physical permission merely by planning districts.
## Feature gate remains OFF until host materializer provides safe zones + receipt.
const RegionAdapter = preload("res://exo_crowd_illusion/runtime/region_adapter.gd")

static func negotiate(region: Node3D, city_schema: String = "0.4.0-qa") -> Dictionary:
	if city_schema != "0.4.0-qa":
		return {"ok": false, "reason": "unsupported_city_schema", "expected": "0.4.0-qa"}
	var authorized: Dictionary = RegionAdapter.from_r13_region(region)
	if not bool(authorized.get("ok", false)):
		return {"ok": false, "reason": str(authorized.get("reason", "unavailable")),
			"city_plan_interactive": false, "physical_walking_surface_verified": false}
	return {"ok": true, "reason": "geometry_authorized", "zones": authorized.get("zones", []),
		"area_index": authorized.get("area_index", {}), "source": authorized.get("source", ""),
		"city_plan_interactive": false, "physical_walking_surface_verified": true}
