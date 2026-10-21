extends Node
## Sole runtime owner of Settlement Forge building index and instantiated exteriors.
## WorldGenesis owns world placement, NPC04 owns actors, EXO Core owns saves.
const Generator = preload("res://exo_settlement_forge/runtime/urban_generator.gd")
const Architecture = preload("res://exo_settlement_forge/runtime/architecture_builder.gd")
signal settlement_ready(settlement_id: String)
signal settlement_unloaded(settlement_id: String)
var _records: Dictionary = {}
var _nodes: Dictionary = {}
var _active_plan: Dictionary = {}
var _root: Node3D

func load_plan(approved_plan: Dictionary, host_parent: Node3D) -> bool:
    if str(approved_plan.get("schema","")) != Generator.SCHEMA or not bool(approved_plan.get("ok",false)):
        return false
    if not is_instance_valid(host_parent) or not is_inside_tree():
        return false
    if not _active_plan.is_empty():
        return false
    var seen: Dictionary = {}
    for row in approved_plan.get("buildings",[]):
        var key: String = str(row.get("building_id",""))
        if key.is_empty() or seen.has(key) or str(row.get("schema","")) != "exo.settlement.building.v1":
            return false
        if str(row.get("region_id","")) != str(approved_plan.get("region_id","")):
            return false
        seen[key] = true
    _root = Node3D.new()
    _root.name = "SettlementForge_" + str(approved_plan.get("settlement_id",""))
    host_parent.add_child(_root)
    Architecture.build_roads(_root,approved_plan)
    for row in approved_plan.get("buildings",[]):
        var instance: Node3D = Architecture.build(_root,row)
        if instance == null:
            unload()
            return false
        var id: String = str(row["building_id"])
        _records[id] = row.duplicate(true)
        _nodes[id] = instance
    _active_plan = approved_plan.duplicate(true)
    settlement_ready.emit(str(_active_plan["settlement_id"]))
    return true

func unload() -> void:
    var id: String = str(_active_plan.get("settlement_id",""))
    if is_instance_valid(_root):
        _root.queue_free()
    _root = null
    _nodes.clear()
    _records.clear()
    _active_plan.clear()
    if not id.is_empty():
        settlement_unloaded.emit(id)

func get_building(building_id: String) -> Dictionary:
    return _records.get(building_id,{}).duplicate(true)

func list_by_function(function_name: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for row in _records.values():
        if function_name.is_empty() or str(row.get("function","")) == function_name:
            result.append(row.duplicate(true))
    return result

func get_npc04_station_contract(building_id: String) -> Dictionary:
    var b: Dictionary = get_building(building_id)
    if b.is_empty():
        return {"ok":false,"error":"unknown_building"}
    return {"ok":true,"schema":"exo.settlement.npc04.stations.v1", "building_id":building_id,
        "region_id":str(b["region_id"]),"function":str(b["function"]),
        "capacity":int(b["capacity"]),"occupied":int(b.get("occupied",0)),
        "access_state":str(b["access_state"]),"entrance":b["exterior_door"],
        "return_anchor":b["return_anchor"],"street_anchor":b["street_anchor"],
        "slots":b["slots"],"resident_ids":b.get("resident_ids",[]),"worker_ids":b.get("worker_ids",[]),"navigability_verified":false}

func nearest_open_door(world_pos: Vector3, radius: float = 2.9) -> Dictionary:
    var best: float = radius * radius
    var result: Dictionary = {}
    for row in _records.values():
        if str(row.get("access_state","closed")) != "open":
            continue
        var a: Array = row.get("exterior_door",[])
        if a.size() != 3:
            continue
        var d: float = Vector2(world_pos.x-float(a[0]),world_pos.z-float(a[2])).length_squared()
        if d < best:
            best = d
            result = row
    return result.duplicate(true)

func active_plan() -> Dictionary:
    return _active_plan.duplicate(true)

func get_exterior_root() -> Node3D:
    return _root

func bind_roster(people: Array) -> bool:
    # Association index only: LivingWorld remains the sole identity/roster owner.
    var staged: Dictionary=_records.duplicate(true)
    var lots: Dictionary={}
    for id in staged:
        staged[id]["resident_ids"]=[];staged[id]["worker_ids"]=[]
        lots[str(staged[id].lot_id)]=id
    var seen: Dictionary={}
    for person in people:
        var uid: String=str(person.get("id",""))
        if not uid.begins_with("npc/r") or seen.has(uid):return false
        if str(person.get("region_id",""))!=str(_active_plan.get("region_id","")):return false
        seen[uid]=true
        var home: String=str(person.get("home_slot",""))
        var work: String=str(person.get("work_slot",""))
        # Monumental/training stations can be external workplaces. Never fabricate a building.
        if lots.has(home):staged[lots[home]].resident_ids.append(uid)
        if lots.has(work):staged[lots[work]].worker_ids.append(uid)
    _records=staged
    for id in _records:
        if is_instance_valid(_nodes.get(id)):_nodes[id].set_meta("exo_settlement_record",_records[id].duplicate(true))
    var buildings: Array=[]
    for previous in _active_plan.buildings:buildings.append(_records[str(previous.building_id)].duplicate(true))
    _active_plan["buildings"]=buildings
    return true
