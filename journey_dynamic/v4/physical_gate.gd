extends RefCounted
# Reads real C3 atlas + host snapshot. Unknown services/locators FAIL CLOSED.
static func region_reachable(atlas: Dictionary, start: int, dest: int) -> bool:
    if not (atlas.get("regions") is Array) or atlas.regions.size()!=88:return false
    if start<0 or dest<0 or start>=88 or dest>=88:return false
    var queue: Array=[start]
    var seen: Dictionary={}
    seen[start]=true
    while not queue.is_empty():
        var cur: int=int(queue.pop_front())
        if cur==dest:return true
        var info: Variant=atlas.regions[cur]
        if not (info is Dictionary):return false
        for portal in info.get("entrances",[]):
            if not (portal is Dictionary):continue
            var n: int=int(portal.get("neighbor",-1))
            if n<0 or n>=88 or seen.has(n):continue
            seen[n]=true;queue.append(n)
    return false

static func verify(world: Object, loc: Dictionary) -> Dictionary:
    if world==null or not is_instance_valid(world):return {"ok":false,"reason":"host_unavailable"}
    var type_id: String=str(loc.get("type",""))
    if not world.get("atlas") is Dictionary:return {"ok":false,"reason":"atlas_unavailable"}
    var atlas: Dictionary=world.get("atlas")
    if not (atlas.get("regions") is Array) or atlas.regions.size()!=88:return {"ok":false,"reason":"invalid_atlas"}
    var origin: int=int(world.get("current_region"))
    var rid: int=int(loc.get("region_id",-1))
    if not region_reachable(atlas,origin,rid):return {"ok":false,"reason":"region_unreachable"}
    if type_id=="region":return {"ok":true,"source":"world_atlas","region_id":rid}
    if type_id=="npc":
        var uid: String=str(loc.get("npc_uid",""))
        if uid.is_empty():return {"ok":false,"reason":"npc_uid_missing"}
        var save: Variant=world.get("journey")
        if save==null or not save.get("data") is Dictionary:return {"ok":false,"reason":"journey_unavailable"}
        var npcs: Variant=save.data.get("living_world",{}).get("npcs",{})
        if not (npcs is Dictionary) or not npcs.has(uid):return {"ok":false,"reason":"npc_not_persistent"}
        if int(npcs[uid].get("region_id",-1))!=rid:return {"ok":false,"reason":"npc_moved"}
        if bool(npcs[uid].get("dead",false)):return {"ok":false,"reason":"npc_dead"}
        return {"ok":true,"source":"living_world_save","region_id":rid,"npc_uid":uid}
    if type_id in ["building","interior","dungeon","city_lot","market","school","loot","road","escort"]:
        return {"ok":false,"reason":"owner_service_not_approved:"+type_id}
    return {"ok":false,"reason":"unsupported_locator"}
