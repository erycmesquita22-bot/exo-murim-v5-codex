extends RefCounted
## R4: a city plan is NOT a walking surface. Only a receipt from materialized
## WorldGenesis/Forja geometry may authorize crowd lanes. This module never
## creates an authorization receipt or writes host metadata.
const Planner = preload("res://exo_crowd_illusion/runtime/planner.gd")
const META_ZONES = "exo_city_forge_crowd_zones"
const META_INDEX = "exo_city_forge_crowd_area_index"
const META_RECEIPT = "exo_crowd_geometry_receipt"

static func from_r13_region(region: Node3D) -> Dictionary:
	if not is_instance_valid(region):
		return _blocked("region_missing")
	var data: Variant = region.get("data")
	if data == null or not data is RefCounted:
		return _blocked("data_missing")
	var raw_spec: Variant = data.get("spec")
	if not raw_spec is Dictionary:
		return _blocked("spec_missing")
	var spec: Dictionary = raw_spec
	if str(spec.get("kind", "")) != "settlement":
		return _blocked("not_settlement")
	var scale := str(spec.get("settlement_scale", ""))
	if scale not in ["village", "town", "city"]:
		return _blocked("unknown_settlement_scale")
	var region_id := int(spec.get("id", -1))
	if region_id < 0 or region_id >= 88:
		return _blocked("region_out_of_range")
	var authored: Variant = region.get_meta(META_ZONES, [])
	if not authored is Array or authored.is_empty():
		return _blocked("village_requires_authored_safe_zones" if scale == "village" else "city_requires_authored_safe_zones")
	var physical: Variant = region.get_meta("city_forge_physical", {})
	if not physical is Dictionary or physical.get("owner") != "settlement_forge_01" or int(physical.get("buildings",0)) < 1 or region.get_child_count() < 1:
		return _blocked("settlement_forge_physical_geometry_required")
	var plan: Variant = data.get("settlement_plan")
	if not plan is Dictionary or str(plan.get("status", "")) != "ready":
		return _blocked("settlement_plan_not_ready")
	# City Forge R4 semantic slots explicitly DO NOT grant this receipt.
	var receipt: Variant = region.get_meta(META_RECEIPT, {})
	if not receipt is Dictionary or not _receipt_valid(receipt, region_id):
		return _blocked("physical_geometry_receipt_required")
	# An independent marker from the currently materialized scene is required
	# to detect a stale receipt after regeneration/reentry/rollback.
	var live_revision: String = str(region.get_meta("exo_crowd_geometry_revision", ""))
	if live_revision.is_empty() or live_revision != str(receipt.get("geometry_revision", "")):
		return _blocked("geometry_revision_mismatch")
	var allowed: Array = receipt.get("safe_zone_ids", [])
	var accepted: Array = []
	var seen := {}
	for row in authored:
		if not row is Dictionary or not Planner.valid_zone(row):
			continue
		var zone_id := str(row.get("id", ""))
		if not zone_id in allowed or seen.has(zone_id):
			continue
		# A receipt authorizes a FINISHED lane. All geometry sampling, slope,
		# gates, doors, lots and R7 footprints remain the host's responsibility.
		seen[zone_id] = true
		accepted.append(row.duplicate(true))
	if accepted.is_empty():
		return _blocked("no_approved_materialized_lanes")
	var meta_index: Variant = region.get_meta(META_INDEX, {})
	var reserved: Array = _reserved(region)
	return {"ok": true, "source": "city_forge_authorized_geometry", "zones": accepted,
		"area_index": meta_index if meta_index is Dictionary else {},
		"reserved": reserved, "receipt_version": "1.0.0", "context": _official_context(region)}

static func _receipt_valid(receipt: Dictionary, region_id: int) -> bool:
	if str(receipt.get("version", "")) != "1.0.0":
		return false
	if str(receipt.get("owner", "")) not in ["WorldGenesis", "Forja"]:
		return false
	if not bool(receipt.get("geometry_materialized", false)) or not bool(receipt.get("collision_checked", false)) or not bool(receipt.get("lane_envelopes_checked", false)):
		return false
	if int(receipt.get("region_id", -1)) != region_id:
		return false
	if str(receipt.get("geometry_revision", "")).is_empty():
		return false
	var approved: Variant = receipt.get("safe_zone_ids", null)
	if not approved is Array or approved.is_empty():
		return false
	for id in approved:
		if not id is String or str(id).is_empty():
			return false
	return true

static func _official_context(region: Node3D) -> Dictionary:
	# World/Economy services may opt in by publishing an already validated
	# snapshot. These are *inputs*, never wealth/economy calculations.
	var payload: Variant = region.get_meta("exo_crowd_context", {})
	if not payload is Dictionary or not bool(payload.get("verified", false)):
		return {}
	if str(payload.get("owner", "")) not in ["WorldGenesis", "Economy"]:
		return {}
	return {"authority": "CrowdHostApproved", "weather": str(payload.get("weather", "unknown")),
		"official_population_factor": payload.get("official_population_factor", 1.0)}

static func _reserved(region: Node3D) -> Array:
	var reserved: Array = []
	var stations: Variant = region.get("station_points")
	if stations is Dictionary:
		for key in stations:
			var p: Variant = stations[key]
			if p is Vector3 and p.is_finite():
				reserved.append(p)
	var data: Variant = region.get("data")
	if data != null and data is RefCounted:
		var lots: Variant = data.get("lots")
		if lots is Array:
			for lot in lots:
				if lot is Dictionary and lot.get("door") is Vector2:
					var p: Vector2 = lot["door"]
					if p.is_finite() and data.has_method("height_at"):
						var h: float = float(data.height_at(p))
						if is_finite(h):
							reserved.append(Vector3(p.x, h, p.y))
	var extra: Variant = region.get_meta("exo_crowd_reserved_positions", [])
	if extra is Array:
		for p in extra:
			if p is Vector3 and p.is_finite():
				reserved.append(p)
	return reserved

static func _blocked(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason, "zones": [], "reserved": []}
