extends RefCounted
## City Forge R4 materializer adapter. Physics evidence, never a City semantic approval.
## Conservative low budget: at most four 12m lanes / 24 figurants.
static func authorize(region: Node3D) -> Dictionary:
    var data: RefCounted = region.data
    if str(data.spec.get("kind", "")) != "settlement": return {"ok":false,"reason":"not_settlement"}
    var zones: Array = []
    var samples: int = 0
    var space: PhysicsDirectSpaceState3D = region.get_world_3d().direct_space_state
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.42
    capsule.height = 1.9
    var reserved: Array = preload("res://exo_crowd_illusion/runtime/region_adapter.gd")._reserved(region)
    var candidates:Array=data.settlement_roads.duplicate()
    candidates.sort_custom(func(a,b):return int(str(a.kind)!="district")<int(str(b.kind)!="district"))
    var areas:Dictionary={}
    for road in candidates:
        if zones.size() >= 4: break
        var a: Vector2 = road.a
        var b: Vector2 = road.b
        var distance: float = a.distance_to(b)
        if distance < 14.0 or float(road.get("width", 0)) < 3.2: continue
        var along: Vector2 = (b-a).normalized()
        var side := Vector2(-along.y, along.x)
        var center: Vector2 = (a+b)*0.5
        var begin: Vector2 = center-along*6.0
        var end: Vector2 = center+along*6.0
        var points: Array = []
        var safe: bool = true
        var last_h: float = NAN
        for i in range(49):
            var point: Vector2 = begin.lerp(end,float(i)/48.0)
            var h: float = NAN
            for offset in [-0.75,-0.5,-0.25,0.0,0.25,0.5,0.75]:
                var at: Vector2 = point+side*float(offset)
                for exclusion in reserved:
                    if exclusion is Vector3 and Vector2(exclusion.x,exclusion.z).distance_to(at)<2.6: safe=false;break
                if not safe: break
                var base := Vector3(at.x,float(data.center_h),at.y)+region.global_position
                var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(base+Vector3.UP*5.0,base-Vector3.UP*5.0,1))
                samples += 1
                if hit.is_empty() or float(hit.normal.y)<0.96: safe=false;break
                var y: float = float(hit.position.y)-region.global_position.y
                if offset == 0.0: h=y
                var query := PhysicsShapeQueryParameters3D.new()
                query.shape=capsule;query.collision_mask=1|4
                var excluded:Array[RID]=[]
                for actor in region.get_tree().get_nodes_in_group("enemies"):
                    if actor is CollisionObject3D:excluded.append(actor.get_rid())
                var host:Node3D=region.get_meta("world_v4",null)
                if is_instance_valid(host):
                    excluded.append(host.player.get_rid())
                    for actor in host.residents:
                        if actor is CollisionObject3D:excluded.append(actor.get_rid())
                query.exclude=excluded
                query.transform=Transform3D(Basis.IDENTITY,hit.position+Vector3.UP*1.01)
                if not space.intersect_shape(query).is_empty(): safe=false;break
                if is_finite(h) and absf(y-h)>0.08: safe=false;break
            if not safe or not is_finite(h): safe=false;break
            if is_finite(last_h) and absf(last_h-h)>0.03: safe=false;break
            last_h=h
            points.append([point.x,h+0.04,point.y])
        if not safe: continue
        # Extend the proven central lane along its actual road, stopping at
        # the first obstacle. Movement is no longer confined to a 12 m patch.
        var extra: float=6.5
        while extra<=minf(distance*0.5-3.0,48.0):
            var candidate: Vector2=center-along*extra
            var verified: Dictionary=_street_sample(region,candidate,side,reserved,capsule)
            if verified.is_empty() or absf(float(verified.y)-float(points[0][1])+0.04)>0.06:break
            points.push_front([candidate.x,float(verified.y)+0.04,candidate.y])
            extra+=0.5
        extra=6.5
        while extra<=minf(distance*0.5-3.0,48.0):
            var candidate: Vector2=center+along*extra
            var verified: Dictionary=_street_sample(region,candidate,side,reserved,capsule)
            if verified.is_empty() or absf(float(verified.y)-float(points[-1][1])+0.04)>0.06:break
            points.append([candidate.x,float(verified.y)+0.04,candidate.y])
            extra+=0.5
        # Straight roads were physically checked every 0.25/0.5 m; compact
        # collinear samples for the public maximum of 64 route points.
        var compact: Array=[]
        var hop: int=maxi(1,ceili(float(points.size())/60.0))
        for i in range(0,points.size(),hop):compact.append(points[i])
        if compact[-1]!=points[-1]:compact.append(points[-1])
        points=compact
        var zone_id:String="cf/r4_verified_%02d" % zones.size()
        var sector:Dictionary={};var nearest:float=INF
        for row in data.settlement_plan.get("city_forge_r4",{}).get("sectors",[]):
            var c:=Vector2(float(row.center[0]),float(row.center[1]))
            if c.distance_squared_to(center)<nearest:nearest=c.distance_squared_to(center);sector=row
        areas[zone_id]={"district":str(sector.get("category","residential")),"sector_id":str(sector.get("id",""))}
        zones.append({"id":zone_id,"points":points,"capacity":6,"role":"resident","activity":"walk","lateral":0.55,"safety_radius":2.6})
    if zones.is_empty(): return {"ok":false,"reason":"no_physical_lane_passed","samples":samples}
    var ids: Array = []
    for zone in zones: ids.append(str(zone.id))
    var revision: String = (str(region.get_instance_id())+str(data.spec.region_seed)+JSON.stringify(zones)).sha256_text()
    region.set_meta("exo_city_forge_crowd_zones",zones)
    region.set_meta("exo_city_forge_crowd_area_index",areas)
    region.set_meta("exo_crowd_geometry_revision",revision)
    region.set_meta("exo_crowd_geometry_receipt",{"version":"1.0.0","owner":"WorldGenesis","geometry_materialized":true,"collision_checked":true,"lane_envelopes_checked":true,"region_id":int(data.spec.id),"geometry_revision":revision,"safe_zone_ids":ids,"samples":samples})
    return {"ok":true,"zones":zones.size(),"samples":samples,"revision":revision}

static func _street_sample(region: Node3D, point: Vector2, side: Vector2, reserved: Array, capsule: Shape3D) -> Dictionary:
    var space: PhysicsDirectSpaceState3D=region.get_world_3d().direct_space_state
    var center_y: float=NAN
    for offset in [0.0,-0.75,-0.5,-0.25,0.25,0.5,0.75]:
        var at: Vector2=point+side*float(offset)
        for item in reserved:
            if item is Vector3 and Vector2(item.x,item.z).distance_to(at)<2.6:return {}
        var base:=region.to_global(Vector3(at.x,float(region.data.center_h),at.y))
        var hit: Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(base+Vector3.UP*5,base-Vector3.UP*5,1))
        if hit.is_empty() or float(hit.normal.y)<0.96:return {}
        var y: float=region.to_local(hit.position).y
        if not is_finite(center_y):center_y=y
        elif absf(y-center_y)>0.08:return {}
        var query:=PhysicsShapeQueryParameters3D.new()
        query.shape=capsule;query.collision_mask=1|4
        query.transform=Transform3D(Basis.IDENTITY,hit.position+Vector3.UP*1.01)
        var excluded: Array[RID]=[]
        for actor in region.get_tree().get_nodes_in_group("enemies"):
            if actor is CollisionObject3D:excluded.append(actor.get_rid())
        query.exclude=excluded
        if not space.intersect_shape(query).is_empty():return {}
    return {"y":center_y}
