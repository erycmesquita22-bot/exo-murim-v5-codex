extends RefCounted
## EXO Settlement Forge 01 - deterministic, data-only planning. WorldGenesis approves area.
## This function does not claim WorldGenesis placement authority.
const SCHEMA: String = "exo.settlement.plan.v1"
const CELL: float = 30.0
const CATEGORIES: Array[String] = ["residence", "market", "inn", "smithy", "martial_school", "administration"]
const TEMPLATES: Dictionary = {
    "residence": {"id":"casa_campesina_01", "w":8.0, "d":8.0, "capacity":4},
    "market": {"id":"loja_mercadorias_01", "w":9.6, "d":9.6, "capacity":5},
    "inn": {"id":"pousada_rio_04", "w":17.6, "d":17.6, "capacity":12},
    "smithy": {"id":"forja_rua_01", "w":11.2, "d":9.6, "capacity":3},
    "martial_school": {"id":"escola_pequena_01", "w":14.4, "d":11.2, "capacity":20},
    "administration": {"id":"sala_conselho_01", "w":14.4, "d":12.8, "capacity":8}
}
const SCALE_CELLS: Dictionary = {
    "hamlet": Vector2i(3,2), "village": Vector2i(4,3),
    "medium_city": Vector2i(6,4), "large_city": Vector2i(8,6)
}
const PROFILES: Dictionary = {
    "agrarian": [9,2,1,2,1,1], "commercial": [3,8,4,5,1,2],
    "martial": [3,1,2,2,9,3], "poor": [12,1,1,3,1,1],
    "wealthy": [3,7,6,4,4,5]
}

static func _sample(weights: Array, rng: RandomNumberGenerator) -> int:
    var total: int = 0
    for weight in weights:
        total += int(weight)
    var pick: int = rng.randi_range(0, total - 1)
    for i in range(weights.size()):
        pick -= int(weights[i])
        if pick < 0:
            return i
    return 0

static func _allowed(shape: String, col: int, row: int, count: Vector2i, rng: RandomNumberGenerator) -> bool:
    var x: float = (float(col) + 0.5 - float(count.x) * 0.5) / maxf(1.0, float(count.x) * 0.5)
    var y: float = (float(row) + 0.5 - float(count.y) * 0.5) / maxf(1.0, float(count.y) * 0.5)
    if shape == "circular":
        return x * x + y * y <= 1.45
    if shape == "hexagonal":
        return absf(x) + absf(y) * 0.58 <= 1.36
    if shape == "irregular":
        return (absf(x) + absf(y) < 1.25) or rng.randf() > 0.17
    return true

static func generate(world_seed: int, region_id: String, settlement_id: String,
        scale: String = "village", profile: String = "agrarian", shape: String = "rectangular",
        world_origin: Vector3 = Vector3.ZERO) -> Dictionary:
    if region_id.is_empty() or settlement_id.is_empty() or not SCALE_CELLS.has(scale) or not PROFILES.has(profile):
        return {"ok":false, "error":"invalid_request"}
    if shape not in ["square", "rectangular", "circular", "hexagonal", "irregular"]:
        return {"ok":false, "error":"unsupported_shape"}
    var counts: Vector2i = SCALE_CELLS[scale]
    var random := RandomNumberGenerator.new()
    random.seed = world_seed ^ int((region_id + "/" + settlement_id).hash())
    var width: float = float(counts.x) * CELL
    var depth: float = float(counts.y) * CELL
    var roads: Array[Dictionary] = []
    for x in range(counts.x + 1):
        var line_x: float = float(x) * CELL - width * 0.5
        roads.append({"id":"ns_%02d"%x,"start":[line_x, -depth*0.5],"end":[line_x, depth*0.5],"width":4.0})
    for z in range(counts.y + 1):
        var line_z: float = float(z) * CELL - depth * 0.5
        roads.append({"id":"ew_%02d"%z,"start":[-width*0.5, line_z],"end":[width*0.5,line_z],"width":4.0})
    var functions: Array[String] = CATEGORIES.duplicate()
    # Initial six useful types are spread across non-disabled lots deterministically.
    for i in range(functions.size() - 1, 0, -1):
        var k: int = random.randi_range(0, i)
        var swap: String = functions[i]
        functions[i] = functions[k]
        functions[k] = swap
    var buildings: Array[Dictionary] = []
    var index: int = 0
    for z in range(counts.y):
        for x in range(counts.x):
            if not _allowed(shape, x, z, counts, random):
                continue
            var function_name: String = functions[index] if index < functions.size() else CATEGORIES[_sample(PROFILES[profile], random)]
            var specification: Dictionary = TEMPLATES[function_name]
            var local_x: float = (float(x) + 0.5) * CELL - width * 0.5 + random.randf_range(-1.2, 1.2)
            var local_z: float = (float(z) + 0.5) * CELL - depth * 0.5 + random.randf_range(-0.9, 0.9)
            var front_z: float = local_z + float(specification["d"]) * 0.5 + 0.6
            var building_id: String = ("%d|%s|%s|%d|%d|%s" % [world_seed, region_id, settlement_id, x, z, function_name]).sha256_text().substr(0, 24)
            var lot_id: String = "%s/l%02d_%02d" % [settlement_id, x, z]
            var point: Vector3 = world_origin + Vector3(local_x, 0.0, local_z)
            var door: Vector3 = world_origin + Vector3(local_x, 0.0, front_z)
            var approach: Vector3 = door + Vector3(0.0, 0.0, 2.1)
            buildings.append({
                "schema":"exo.settlement.building.v1", "data_version":1,
                "building_id":building_id, "region_id":region_id, "settlement_id":settlement_id,
                "lot_id":lot_id, "function":function_name, "district":"central" if index < 6 else "mixed",
                "position":[point.x, point.y, point.z], "yaw":0.0,
                "dimensions":[float(specification["w"]), 3.4, float(specification["d"])],
                "interior_id":str(specification["id"]), "accessible":true, "enabled_floors":1,
                "exterior_door":[door.x,door.y,door.z], "return_anchor":[approach.x,approach.y,approach.z],
                "street_anchor":[approach.x,approach.y,world_origin.z + (float(z) + 1.0)*CELL - depth*0.5 - 2.2],
                "capacity":int(specification["capacity"]), "occupied":0, "resident_ids":[], "worker_ids":[],
                "interactions":["trade"] if function_name == "market" else ["train"] if function_name == "martial_school" else ["work"] if function_name == "smithy" else ["talk"],
                "slots":{"entrance":[approach.x,approach.y,approach.z],
                    "work":[door.x,door.y,door.z], "queue":[approach.x+1.2,approach.y,approach.z],
                    "patrol":[approach.x+2.4,approach.y,approach.z], "training":[approach.x-1.5,approach.y,approach.z]},
                "access_state":"open"
            })
            index += 1
    return {"ok":true, "schema":SCHEMA, "region_id":region_id,"settlement_id":settlement_id,
        "world_seed":world_seed,"shape":shape,"scale":scale,"profile":profile,
        "origin":[world_origin.x,world_origin.y,world_origin.z],"roads":roads,"buildings":buildings}
