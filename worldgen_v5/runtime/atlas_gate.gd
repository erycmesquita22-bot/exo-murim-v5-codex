extends RefCounted
## WG5 does not reroll the V4 atlas. WorldGenesis owns topology, ids, gates and seeds.
const Planner = preload("res://genesis/world_planner.gd")
const LegacyWG4 = preload("res://genesis/v4/world_plan.gd")
const SCHEMA = "exo.worldgen.v5.atlas-approval.v1"

static func validate(atlas: Dictionary) -> Dictionary:
    var errors: Array[String] = []
    if not LegacyWG4.valid_atlas(atlas):
        errors.append("wg4_atlas_invalid")
    if not Planner.validate(atlas).is_empty():
        errors.append("region_topology_invalid")
    var regions: Array = atlas.get("regions", [])
    if regions.size() != 88:
        errors.append("region_count_not_88")
    var identifiers: Dictionary = {}
    var settlements: int = 0
    for region in regions:
        if not region is Dictionary:
            errors.append("region_record_invalid")
            continue
        var rid: int = int(region.get("id", -1))
        if rid < 0 or rid > 87 or identifiers.has(rid):
            errors.append("region_id_invalid_or_duplicated")
        identifiers[rid] = true
        if str(region.get("kind", "")) == "settlement":
            settlements += 1
    if settlements != 23:
        errors.append("settlement_quota_changed")
    var digest: String = JSON.stringify(atlas).sha256_text()
    return {"ok": errors.is_empty(), "schema": SCHEMA, "region_count": regions.size(),
        "settlement_count": settlements, "atlas_sha256": digest, "errors": errors}
