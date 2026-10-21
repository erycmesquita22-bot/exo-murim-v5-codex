extends RefCounted
## Translates ALREADY-APPROVED V4 parcels, no second city generator or city owner.
## All coordinates derive from V4's authoritative RegionData, preserving NPC commute IDs.
const VERSION: int = 1
const PLAN_SCHEMA: String = "exo.settlement.plan.v1"
const BUILDING_SCHEMA: String = "exo.settlement.building.v1"
const SettlementService = preload("res://exo_settlement_forge/runtime/settlement_service.gd")
const INTERIORS: Dictionary = {
    "farmstead": "casa_campesina_01", "residence": "casa_campesina_01",
    "market": "loja_mercadorias_01", "inn": "pousada_rio_04",
    "smithy": "forja_rua_01", "herbalist": "farmacia_erva_01",
    "martial_school": "escola_pequena_01", "administration": "sala_conselho_01",
    "shrine": "templo_rural_01", "warehouse": "deposito_mercantil_01"
}
const NPC_ROLES: Dictionary = {
    "farmstead": "farmer", "residence": "resident", "market": "merchant",
    "inn": "merchant", "smithy": "resident", "herbalist": "healer",
    "martial_school": "disciple", "administration": "guild_agent",
    "shrine": "master", "warehouse": "courier"
}

static func from_region(region: Node3D) -> Dictionary:
    if not is_instance_valid(region):
        return {"ok": false, "error": "invalid_region_node"}
    var data: Variant = region.get("data")
    if data == null or str(data.spec.get("kind", "")) != "settlement":
        return {"ok": false, "error": "not_a_settlement"}
    if str(data.settlement_plan.get("status", "")) != "ready":
        return {"ok": false, "error": "unapproved_city_placement"}
    var seed: String = str(data.atlas.get("seed", ""))
    var rid: int = int(data.spec.get("id", -1))
    if seed.is_empty() or rid < 0 or rid >= 88:
        return {"ok": false, "error": "invalid_world_identity"}
    var settlement_id: String = "%s/region_%02d" % [seed, rid]
    var plan: Dictionary = {"ok": true, "schema": PLAN_SCHEMA, "world_seed": seed,
        "region_id": str(rid), "settlement_id": settlement_id,
        "origin": [0.0, 0.0, 0.0], "roads": [], "buildings": [],
        "topology_source": "worldgen_v4", "placement_source": "city_forge_r4_authorized_lots",
        "profile": str(data.settlement_plan.get("city_forge_r4", {}).get("profile_id", "")),
        "scale": str(data.spec.get("settlement_scale", "village"))}
    var ids: Dictionary = {}
    for lot in data.lots:
        if not lot is Dictionary:
            return {"ok": false, "error": "invalid_lot"}
        var lot_id: String = str(lot.get("id", ""))
        var function_name: String = str(lot.get("function", ""))
        if lot_id.is_empty() or ids.has(lot_id) or not INTERIORS.has(function_name):
            return {"ok": false, "error": "unknown_or_duplicated_lot:" + lot_id}
        ids[lot_id] = true
        var model: Dictionary = lot.get("city_model", {})
        var dims: Array = model.get("size", [])
        if dims.size() != 2 or float(dims[0]) < 4.0 or float(dims[1]) < 4.0:
            return {"ok": false, "error": "unsupported_dimensions:" + lot_id}
        var p: Vector2 = lot["p"]
        var door: Vector2 = lot["door"]
        var street: Vector2 = lot["street_point"]
        var yaw: float = float(lot["yaw"])
        var floor_y: float = float(data.center_h) - 0.28
        var external_y: float = float(data.height_at(door)) + 0.05
        var outward: Vector2 = Vector2(sin(yaw), cos(yaw))
        var ret: Vector2 = door + outward * 1.9
        var canonical_id: String = (seed + "|" + str(rid) + "|" + lot_id).sha256_text().substr(0, 24)
        var entrance: Array = [door.x, external_y, door.y]
        var queue: Array = [ret.x, float(data.height_at(ret)) + 0.05, ret.y]
        var approved: Dictionary = {"schema": BUILDING_SCHEMA, "data_version": VERSION,
            "building_id": canonical_id, "region_id": str(rid), "settlement_id": settlement_id,
            "lot_id": lot_id, "function": function_name, "district": str(lot.get("district", "mixed")),
            "position": [p.x, floor_y, p.y], "yaw": yaw,
            "dimensions": [float(dims[0]), 3.4, float(dims[1])],
            "interior_id": INTERIORS[function_name], "accessible": true, "enabled_floors": 1,
            "exterior_door": entrance, "return_anchor": queue,
            "street_anchor": [street.x, float(data.height_at(street)) + 0.05, street.y],
            "capacity": 4 if function_name in ["farmstead", "residence"] else 12 if function_name == "inn" else 8,
            "occupied": 0, "resident_ids": [], "worker_ids": [],
            "interactions": ["trade"] if function_name in ["market", "inn"] else ["train"] if function_name == "martial_school" else ["work"],
            "slots": {"entrance": entrance, "work": entrance, "queue": queue,
                "patrol": [street.x, external_y, street.y],
                "training": [p.x, floor_y, p.y]}, "access_state": "open",
            "host_slot_id": lot_id, "terrain_approved_by": "WorldGenesisV4"}
        if door.distance_to(street) > 25.0 or not is_finite(floor_y):
            return {"ok": false, "error": "unreachable_door:" + lot_id}
        plan["buildings"].append(approved)
    if plan["buildings"].is_empty():
        return {"ok": false, "error": "no_authorized_lots"}
    return plan

static func install(region: Node3D) -> Dictionary:
    var plan: Dictionary = from_region(region)
    if not bool(plan.get("ok", false)):
        return plan
    var service = SettlementService.new()
    service.name = "EXO_SettlementForge_Service"
    region.add_child(service)
    if not service.load_plan(plan, region):
        service.queue_free()
        return {"ok": false, "error": "materialization_failed"}
    # V4 Navigation/occupancy continues using EXACT V4 lot ids and street graph.
    var host: Variant = region
    for lot in host.data.lots:
        var slot_id: String = str(lot["id"])
        var facade: Vector2 = lot["door"]
        var road: Vector2 = lot["street_point"]
        var pos: Vector3 = Vector3(facade.x, host.data.height_at(facade) + 0.05, facade.y)
        var dest: Vector3 = Vector3(road.x, host.data.height_at(road) + 0.05, road.y)
        host.station_points[slot_id] = pos
        host.route_points[slot_id] = [pos, pos, dest]
        var role: String = NPC_ROLES.get(str(lot["function"]), "resident")
        host.assigned_slots.append({"id": slot_id, "role": role,
            "work_slot": slot_id, "home_slot": slot_id})
        var original: Dictionary = lot["city_model"].duplicate(true)
        original["stories"] = 1
        original["width_m"] = float(original["size"][0])
        host.blueprints.append(original)
    for built in service.get_exterior_root().get_children():
        if built is Node3D and built.has_meta("building_id"):
            host.props.append(built)
    region.set_meta("worldgen_v5_service", service)
    region.set_meta("worldgen_v5_plan", plan.duplicate(true))
    region.set_meta("worldgen_v5_npc04_contract", "exo.settlement.npc04.stations.v1")
    return {"ok": true, "building_count": plan["buildings"].size(),
        "plan_id": str(plan["settlement_id"]), "npc04_runtime_verified": false}

static func station_manifest(region: Node3D) -> Dictionary:
    # Contract producer for NPC04. It does NOT move/spawn NPCs or imply path QA.
    if not is_instance_valid(region) or not region.has_meta("worldgen_v5_service"):
        return {"ok": false, "error": "settlement_not_loaded"}
    var service: Variant = region.get_meta("worldgen_v5_service")
    if not is_instance_valid(service):
        return {"ok": false, "error": "service_not_mounted"}
    var active: Dictionary = service.active_plan()
    var stations: Array[Dictionary] = []
    for row in active.get("buildings", []):
        var contract: Dictionary = service.get_npc04_station_contract(str(row["building_id"]))
        if not bool(contract.get("ok", false)):
            return {"ok": false, "error": "unavailable_station:" + str(row["building_id"])}
        stations.append(contract)
    return {"ok": true, "schema": "exo.worldgen.v5.npc04.handoff.v1",
        "world_seed": str(active.get("world_seed", "")),
        "region_id": str(active.get("region_id", "")),
        "stations": stations, "navigability_verified": false,
        "npc04_bound": bool(region.get_meta("npc04_bound")) if region.has_meta("npc04_bound") else false}

static func crowd_zones(region: Node3D) -> Dictionary:
    # Read-only geometry supplies categories. Crowd Illusion stays sole figurant owner.
    if not is_instance_valid(region) or not region.has_meta("worldgen_v5_plan"):
        return {"ok": false, "error": "no_settlement_plan"}
    var plan: Dictionary = region.get_meta("worldgen_v5_plan")
    var points: Array[Dictionary] = []
    for b in plan.get("buildings", []):
        var category: String = str(b.get("function", ""))
        if category not in ["market", "inn", "martial_school", "administration"]:
            continue
        points.append({"building_id": str(b["building_id"]), "function": category,
            "street_anchor": b.get("street_anchor", []), "density_policy": "crowd_owned"})
    return {"ok": true, "schema": "exo.worldgen.v5.crowd.zones.v1", "zones": points}
