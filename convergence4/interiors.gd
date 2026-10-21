extends RefCounted
## Shared physical queries. Settlement Forge is the sole city interior owner.
static func clear_capsule(space: PhysicsDirectSpaceState3D, feet: Vector3) -> bool:
    var ray: Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(feet+Vector3.UP*.6,feet-Vector3.UP*1.2,1))
    if ray.is_empty(): return false
    var shape:=CapsuleShape3D.new();shape.radius=.4;shape.height=1.9
    var q:=PhysicsShapeQueryParameters3D.new();q.shape=shape;q.collision_mask=1|4
    q.transform=Transform3D(Basis.IDENTITY,ray.position+Vector3.UP*1.01)
    return space.intersect_shape(q).is_empty()
static func verify(region: Node3D) -> Dictionary:
    var service: Variant=region.get_meta("worldgen_v5_service") if region.has_meta("worldgen_v5_service") else null
    if not is_instance_valid(service): return {"approved":0,"owner":"monumental_only"}
    var count: int=0
    var blocked: Array=[]
    for row in service.active_plan().get("buildings",[]):
        var p: Array=row.exterior_door
        if clear_capsule(region.get_world_3d().direct_space_state,region.to_global(Vector3(p[0],p[1],p[2]))):count+=1
        else:blocked.append(row.building_id)
    var result: Dictionary={"approved":count,"blocked":blocked,"owner":"settlement_forge_01"}
    region.set_meta("settlement_physical_verification",result)
    return result
